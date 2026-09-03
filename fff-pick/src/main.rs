//! fff-pick -- interactive file picker for the shell, backed by the fff search
//! engine (the same index and frecency database fff.nvim uses).
//!
//! fff is a library, not a CLI: it wants to live in a long-running process that
//! keeps the index warm. So this binary indexes once, then re-runs
//! `fuzzy_search` on every keystroke. A query is stateless, so backspace is
//! just a re-query of the shorter string -- nothing incremental to unwind.
//!
//! The UI is drawn on stderr so the selection can be captured from stdout.
//! Selected paths are printed one per line. Exit 130 means cancelled.

use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::Duration;

use crossterm::event::{self, Event, KeyCode, KeyEventKind, KeyModifiers};
use crossterm::style::{Attribute, Print, SetAttribute};
use crossterm::terminal::{Clear, ClearType};
use crossterm::{cursor, queue, terminal};

use fff_search::file_picker::FilePicker;
use fff_search::frecency::FrecencyTracker;
use fff_search::query_tracker::QueryTracker;
use fff_search::{
    FFFMode, FilePickerOptions, FileSearchConfig, FuzzySearchOptions, PaginationArgs, QueryParser,
    SharedFilePicker, SharedFrecency, SharedQueryTracker,
};

type Res<T> = Result<T, Box<dyn std::error::Error>>;

/// Result cap per query. The list only ever shows a screenful; the rest exists
/// so scrolling past the fold has somewhere to go.
const MAX_RESULTS: usize = 300;
const SCAN_TIMEOUT: Duration = Duration::from_secs(30);
/// Below this width the preview pane is dropped and the list takes the screen.
const MIN_WIDTH_FOR_PREVIEW: u16 = 80;

fn main() -> ExitCode {
    match run() {
        Ok(Some(paths)) => {
            let mut out = io::stdout().lock();
            for path in paths {
                let _ = writeln!(out, "{path}");
            }
            ExitCode::SUCCESS
        }
        Ok(None) => ExitCode::from(130),
        Err(err) => {
            eprintln!("fff-pick: {err}");
            ExitCode::from(2)
        }
    }
}

fn run() -> Res<Option<Vec<String>>> {
    let mut args = std::env::args().skip(1);
    let mut filter = None;
    let mut dir = None;
    while let Some(arg) = args.next() {
        match arg.as_str() {
            // Non-interactive: print the ranked matches and exit. Handy for
            // scripting, and the only mode that works without a tty.
            "-f" | "--filter" => filter = Some(args.next().unwrap_or_default()),
            "-h" | "--help" => {
                eprintln!("usage: fff-pick [--filter QUERY] [DIR]");
                return Ok(Some(Vec::new()));
            }
            _ => dir = Some(arg),
        }
    }

    let base = match dir {
        Some(dir) => PathBuf::from(dir),
        None => std::env::current_dir()?,
    };
    let base = base.canonicalize()?;

    let picker = SharedFilePicker::default();
    let frecency = SharedFrecency::default();
    let queries = SharedQueryTracker::default();

    // Share the databases fff.nvim writes to, so files opened in the editor
    // rank higher in the shell and vice versa.
    if let Some(path) = frecency_db_path() {
        if let Ok(tracker) = FrecencyTracker::open(path) {
            frecency.init(tracker)?;
        }
    }
    if let Some(path) = query_db_path() {
        if let Ok(tracker) = QueryTracker::open(path) {
            queries.init(tracker)?;
        }
    }

    FilePicker::new_with_shared_state(
        picker.clone(),
        frecency.clone(),
        FilePickerOptions {
            base_path: base.to_string_lossy().into_owned(),
            mode: FFFMode::Neovim,
            // The process lives for as long as the picker is open, so a
            // filesystem watcher would only pay off for a session that never
            // ends. The initial scan is the whole index we need.
            watch: false,
            ..Default::default()
        },
    )?;

    let interactive = filter.is_none();
    if interactive {
        eprint!("fff-pick: indexing...");
        io::stderr().flush()?;
    }
    picker.wait_for_scan(SCAN_TIMEOUT);
    if interactive {
        eprint!("\r\x1b[2K");
        io::stderr().flush()?;
    }

    let mut app = App::new(base);
    if let Some(query) = filter {
        app.query = query;
        app.requery(&picker, &queries)?;
        return Ok(Some(app.results));
    }
    app.requery(&picker, &queries)?;

    let _term = Term::enter()?;
    let selection = app.event_loop(&picker, &queries)?;
    drop(_term);

    if let Some(paths) = &selection {
        if let Ok(guard) = frecency.read() {
            if let Some(tracker) = guard.as_ref() {
                for path in paths {
                    let _ = tracker.track_access(&app.base.join(path));
                }
            }
        }
    }

    Ok(selection)
}

fn frecency_db_path() -> Option<PathBuf> {
    if let Some(path) = std::env::var_os("FFF_FRECENCY_DB") {
        return Some(PathBuf::from(path));
    }
    Some(cache_home()?.join("nvim/fff_nvim"))
}

fn query_db_path() -> Option<PathBuf> {
    if let Some(path) = std::env::var_os("FFF_QUERY_DB") {
        return Some(PathBuf::from(path));
    }
    Some(data_home()?.join("nvim/fff_queries"))
}

fn cache_home() -> Option<PathBuf> {
    std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| Some(PathBuf::from(std::env::var_os("HOME")?).join(".cache")))
}

fn data_home() -> Option<PathBuf> {
    std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .or_else(|| Some(PathBuf::from(std::env::var_os("HOME")?).join(".local/share")))
}

/// Raw mode + alternate screen, restored on drop so an error path cannot leave
/// the terminal wedged.
struct Term;

impl Term {
    fn enter() -> Res<Self> {
        terminal::enable_raw_mode()?;
        let mut out = io::stderr();
        queue!(out, terminal::EnterAlternateScreen, cursor::Hide)?;
        out.flush()?;
        Ok(Self)
    }
}

impl Drop for Term {
    fn drop(&mut self) {
        let mut out = io::stderr();
        let _ = queue!(out, cursor::Show, terminal::LeaveAlternateScreen);
        let _ = out.flush();
        let _ = terminal::disable_raw_mode();
    }
}

struct App {
    base: PathBuf,
    parser: QueryParser<FileSearchConfig>,
    query: String,
    /// Highlighted row, as an index into `results`.
    cursor: usize,
    /// First visible row.
    offset: usize,
    /// Tab-marked paths, in the order they were marked.
    marked: Vec<String>,
    results: Vec<String>,
    total_matched: usize,
    total_files: usize,
    /// Rendered preview keyed by `width:path`, since bat lays out to a width.
    preview_cache: HashMap<String, Vec<String>>,
}

impl App {
    fn new(base: PathBuf) -> Self {
        Self {
            base,
            parser: QueryParser::default(),
            query: String::new(),
            cursor: 0,
            offset: 0,
            marked: Vec::new(),
            results: Vec::new(),
            total_matched: 0,
            total_files: 0,
            preview_cache: HashMap::new(),
        }
    }

    fn requery(&mut self, picker: &SharedFilePicker, queries: &SharedQueryTracker) -> Res<()> {
        let guard = picker.read()?;
        let Some(picker) = guard.as_ref() else {
            self.results.clear();
            return Ok(());
        };
        let query_guard = queries.read()?;

        let parsed = self.parser.parse(&self.query);
        let result = picker.fuzzy_search(
            &parsed,
            query_guard.as_ref(),
            FuzzySearchOptions {
                max_threads: 0,
                current_file: None,
                pagination: PaginationArgs {
                    offset: 0,
                    limit: MAX_RESULTS,
                },
                ..Default::default()
            },
        );

        self.results = result
            .items
            .iter()
            .map(|item| item.relative_path(picker))
            .collect();
        self.total_matched = result.total_matched;
        self.total_files = result.total_files;
        self.cursor = 0;
        self.offset = 0;
        Ok(())
    }

    fn event_loop(
        &mut self,
        picker: &SharedFilePicker,
        queries: &SharedQueryTracker,
    ) -> Res<Option<Vec<String>>> {
        loop {
            self.render()?;

            let Event::Key(key) = event::read()? else {
                continue;
            };
            if key.kind != KeyEventKind::Press {
                continue;
            }
            let ctrl = key.modifiers.contains(KeyModifiers::CONTROL);

            match key.code {
                KeyCode::Esc => return Ok(None),
                KeyCode::Char('c' | 'g' | 'q') if ctrl => return Ok(None),
                KeyCode::Enter => return Ok(Some(self.take_selection())),
                KeyCode::Tab => self.toggle_mark(),
                KeyCode::Down => self.move_cursor(1),
                KeyCode::Up => self.move_cursor(-1),
                KeyCode::Char('n' | 'j') if ctrl => self.move_cursor(1),
                KeyCode::Char('p' | 'k') if ctrl => self.move_cursor(-1),
                KeyCode::PageDown => self.move_cursor(10),
                KeyCode::PageUp => self.move_cursor(-10),
                KeyCode::Backspace => {
                    self.query.pop();
                    self.requery(picker, queries)?;
                }
                KeyCode::Char('u') if ctrl => {
                    self.query.clear();
                    self.requery(picker, queries)?;
                }
                KeyCode::Char('w') if ctrl => {
                    let trimmed = self.query.trim_end();
                    let keep = trimmed
                        .rfind(|c: char| c.is_whitespace() || c == '/')
                        .map_or(0, |i| i + 1);
                    self.query.truncate(keep);
                    self.requery(picker, queries)?;
                }
                KeyCode::Char(c) if !ctrl => {
                    self.query.push(c);
                    self.requery(picker, queries)?;
                }
                _ => {}
            }
        }
    }

    fn take_selection(&mut self) -> Vec<String> {
        if !self.marked.is_empty() {
            return std::mem::take(&mut self.marked);
        }
        self.results
            .get(self.cursor)
            .map(|path| vec![path.clone()])
            .unwrap_or_default()
    }

    fn toggle_mark(&mut self) {
        let Some(path) = self.results.get(self.cursor) else {
            return;
        };
        match self.marked.iter().position(|p| p == path) {
            Some(i) => {
                self.marked.remove(i);
            }
            None => self.marked.push(path.clone()),
        }
        self.move_cursor(1);
    }

    fn move_cursor(&mut self, delta: isize) {
        if self.results.is_empty() {
            return;
        }
        let last = self.results.len() - 1;
        let next = self.cursor as isize + delta;
        self.cursor = next.clamp(0, last as isize) as usize;
    }

    fn render(&mut self) -> Res<()> {
        // A pty with no window size reports 0x0; fall back rather than draw
        // nothing at all.
        let (cols, rows) = match terminal::size() {
            Ok((0, _)) | Ok((_, 0)) | Err(_) => (80, 24),
            Ok(size) => size,
        };
        // Row 0 is the prompt, row 1 the counter, the rest is the list.
        let list_height = rows.saturating_sub(2) as usize;
        if list_height == 0 {
            return Ok(());
        }

        let (list_width, preview_width) = if cols >= MIN_WIDTH_FOR_PREVIEW {
            let list = cols / 2;
            (list, cols - list - 1)
        } else {
            (cols, 0)
        };

        // Keep the cursor inside the visible window.
        if self.cursor < self.offset {
            self.offset = self.cursor;
        } else if self.cursor >= self.offset + list_height {
            self.offset = self.cursor + 1 - list_height;
        }

        let preview = if preview_width > 0 {
            self.results
                .get(self.cursor)
                .cloned()
                .map(|path| self.preview(&path, preview_width, list_height))
                .unwrap_or_default()
        } else {
            Vec::new()
        };

        let mut out = io::stderr();
        queue!(out, Clear(ClearType::All), cursor::MoveTo(0, 0))?;

        let prompt = format!("> {}", self.query);
        queue!(out, Print(truncate_end(&prompt, list_width as usize)))?;
        queue!(out, cursor::MoveTo(0, 1))?;
        let counter = if self.marked.is_empty() {
            format!("  {}/{}", self.total_matched, self.total_files)
        } else {
            format!(
                "  {}/{} ({} marked)",
                self.total_matched,
                self.total_files,
                self.marked.len()
            )
        };
        queue!(out, Print(truncate_end(&counter, list_width as usize)))?;

        for row in 0..list_height {
            let y = (row + 2) as u16;
            queue!(out, cursor::MoveTo(0, y))?;

            if let Some(path) = self.results.get(self.offset + row) {
                let selected = self.offset + row == self.cursor;
                let mark = if self.marked.iter().any(|p| p == path) {
                    '+'
                } else {
                    ' '
                };
                // 3 columns of gutter: cursor, mark, space.
                let text = truncate_start(path, list_width.saturating_sub(3) as usize);
                let line = format!(
                    "{}{} {:<width$}",
                    if selected { '>' } else { ' ' },
                    mark,
                    text,
                    width = list_width.saturating_sub(3) as usize
                );
                if selected {
                    queue!(out, SetAttribute(Attribute::Reverse), Print(line))?;
                    queue!(out, SetAttribute(Attribute::Reset))?;
                } else {
                    queue!(out, Print(line))?;
                }
            }

            if preview_width > 0 {
                queue!(out, cursor::MoveTo(list_width, y), Print('\u{2502}'))?;
                if let Some(line) = preview.get(row) {
                    queue!(out, cursor::MoveTo(list_width + 1, y), Print(line))?;
                }
            }
        }

        out.flush()?;
        Ok(())
    }

    fn preview(&mut self, path: &str, width: u16, height: usize) -> Vec<String> {
        let key = format!("{width}:{path}");
        if let Some(lines) = self.preview_cache.get(&key) {
            return lines.clone();
        }
        let lines = load_preview(&self.base.join(path), width, height);
        self.preview_cache.insert(key, lines.clone());
        lines
    }
}

/// Renders a preview via bat, which lays out to `--terminal-width` so the
/// colored output never has to be truncated mid escape sequence.
fn load_preview(path: &Path, width: u16, height: usize) -> Vec<String> {
    let bat = Command::new("bat")
        .args(["--color=always", "--style=numbers", "--paging=never"])
        .arg("--wrap=never")
        .arg(format!("--terminal-width={width}"))
        .arg(format!("--line-range=:{height}"))
        .arg(path)
        .stderr(Stdio::null())
        .output();

    if let Ok(output) = bat {
        if output.status.success() {
            return String::from_utf8_lossy(&output.stdout)
                .lines()
                .take(height)
                .map(str::to_string)
                .collect();
        }
    }

    match fs::read_to_string(path) {
        Ok(text) => text
            .lines()
            .take(height)
            .map(|line| truncate_end(line, width as usize))
            .collect(),
        Err(err) => vec![truncate_end(&err.to_string(), width as usize)],
    }
}

fn truncate_end(text: &str, width: usize) -> String {
    if text.chars().count() <= width {
        return text.to_string();
    }
    text.chars().take(width).collect()
}

/// Truncates from the left, so the filename stays visible on long paths.
fn truncate_start(text: &str, width: usize) -> String {
    let len = text.chars().count();
    if len <= width || width == 0 {
        return text.to_string();
    }
    let skip = len - width + 1;
    let mut out = String::from("\u{2026}");
    out.extend(text.chars().skip(skip));
    out
}
