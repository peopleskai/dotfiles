# fff-pick

Interactive shell file picker backed by the [fff](https://github.com/dmtrKovalenko/fff)
search engine -- an experiment in replacing fzf's `CTRL-T` widget with the same
engine that powers `fff.nvim`.

**Status: parked, not wired up.** `CTRL-T` in `zsh/dot-zshrc` is still fzf. The
crate is kept here in working order in case it is worth revisiting; see
[Why it is parked](#why-it-is-parked) for the reasoning.

This is not a stow package -- it is a Rust crate. `stow` is only ever invoked
with explicit package names, so it is ignored by the usual setup.

## How fff actually works

There is no fff daemon. fff is a **library linked into each host process**, not
a service. Grepping `fff-search` 0.10.5 for `UnixListener|UnixStream|TcpListener|daemon|socket`
turns up exactly one hit: the string `"Library/Daemon Containers"` in an ignore
list. No IPC layer exists.

```
nvim process                   fff-pick process              fff-mcp process
 |- libfff_nvim.so              |- fff-search crate           |- fff-search crate
 \- index in nvim RAM           \- index in its own RAM       \- index in its own RAM
        |                              |                            |
        \--------------+---------------+----------------------------/
                       v
        ~/.cache/nvim/fff_nvim           (frecency, LMDB)
        ~/.local/share/nvim/fff_queries  (query history, LMDB)
                  <- the only shared state, on disk
```

Every shipping form of fff is a binding around the same core crate, and each one
owns a private index: `fff-nvim` is a cdylib nvim loads as a Lua module,
`fff-mcp` is a long-lived binary (one per MCP client -- it does not serve nvim),
plus `fff-c` / `fff-python` / `fff-node` / `fff-bun` for other hosts.

So when the upstream README sells "way faster in any long-running process", the
long-running process is *the host* -- nvim, an MCP server, an agent -- not a
shared fff service you connect to.

The design follows from zero-copy results: a `FileItem` holds arena offsets, so
materializing a path needs the picker itself (`item.relative_path(picker)`). An
IPC boundary would force serializing every result, which is the cost fff exists
to avoid.

### What is and is not shared with fff.nvim

| | Shared? | Where |
|---|---|---|
| Frecency database | yes | `${XDG_CACHE_HOME:-~/.cache}/nvim/fff_nvim`, override `FFF_FRECENCY_DB` |
| Query history | yes | `${XDG_DATA_HOME:-~/.local/share}/nvim/fff_queries`, override `FFF_QUERY_DB` |
| File index | **no** | process memory only; `fff-search` has no on-disk index |

Sharing frecency is the real payoff: files opened in the editor rank first in
the shell, and `fff-pick` calls `track_access` on accept so shell picks feed back
into editor ranking.

Concurrent use is safe. `FrecencyTracker::new(path, use_unsafe_no_lock)` is
deprecated since 0.7.0 -- "LMDB unsafe no-lock mode is no longer supported... The
`_use_unsafe_no_lock` argument is ignored" -- so both processes take normal LMDB
locks, even though fff.nvim still passes `true`.

## Why a custom binary was needed

Upstream is blunt about it: "FFF is a file search library, not a CLI." The only
binary it ships is `fff-mcp`, an MCP stdio server with no picker UI. The one
third-party CLI frontend that exists (`magnusmalm/fff-cli`) is non-interactive --
print-and-exit, no preview, no keybindings.

Wiring a one-shot CLI into `fzf --bind 'change:reload(...)'` would rebuild the
index on every keystroke. `fff-pick` instead indexes once at startup and re-runs
`fuzzy_search` per keystroke against the warm index. A query is stateless, so
backspace is just a re-query of the shorter string -- nothing incremental to
unwind.

## Why it is parked

The warm index does not amortize *across* invocations, only *within* one. Each
`CTRL-T` is a fresh process: one scan, then sub-millisecond queries for the rest
of that session. Measured scan cost:

| Tree | Files | Wall time |
|---|---|---|
| this dotfiles repo | ~300 | 28 ms |
| `~/.cargo/registry/src` | 8,967 | 72 ms |
| `$HOME` | huge (brazil-pkg-cache, wezterm deps) | 1.27 s |

Invisible in a repo, noticeable in `$HOME`. The scan is already parallel (627%
CPU on the `$HOME` run), so it is I/O-and-cores bound rather than flag-tunable.
fzf pays a walk per invocation too, so per-invocation cost is not a regression
against it -- the gain over fzf would be frecency ranking and fff's matcher, not
startup. Not enough to justify owning a bespoke picker.

If it is ever worth revisiting, the options are a `--serve` daemon holding the
`FilePicker` behind a unix socket (still a separate index from nvim's), or
persisting an index snapshot to disk with staleness checks, as fff-cli does.

Side finding: `FilePickerOptions::enable_home_dir_scanning` defaults to `false`,
yet indexing `$HOME` worked anyway -- that guard does not block what its name
suggests, so do not rely on it to prevent scanning a giant tree.

## Build and install

Needs a Rust toolchain (edition 2024, so 1.85 or newer) and `bat` on `PATH` for
previews.

```sh
cargo build --release
cp target/release/fff-pick ~/.local/bin/
```

The `fff-search` dependency is pinned loosely at `"0.10"`. It is pre-1.0, so a
minor bump can break the build -- pin `=0.10.5` to freeze it.

## Usage

```sh
fff-pick [DIR]                 # interactive picker, prints selection to stdout
fff-pick --filter QUERY [DIR]  # non-interactive, prints ranked matches
```

Defaults to the current directory. The UI is drawn on stderr so the selection can
be captured from stdout. Exits 130 when cancelled.

### Keys

| Key | Action |
|---|---|
| any character | extend the query |
| `Backspace` / `CTRL-U` / `CTRL-W` | delete char / query / word |
| `Up` `Down`, `CTRL-P` `CTRL-N`, `CTRL-K` `CTRL-J` | move the cursor |
| `PageUp` / `PageDown` | move ten rows |
| `Tab` | mark for multi-select |
| `Enter` | accept marked paths, or the highlighted one |
| `Esc` / `CTRL-C` / `CTRL-G` / `CTRL-Q` | cancel |

Query constraints are the fff ones, e.g. `git:modified src/**/*.rs !target/ foo`.

## Re-enabling the CTRL-T binding

Build and install the binary, then add this to `zsh/dot-zshrc` *after*
`source <(fzf --zsh)`, which binds `CTRL-T` to `fzf-file-widget`, and drop
`FZF_CTRL_T_OPTS`:

```zsh
if command -v fff-pick &> /dev/null; then
  fff-pick-widget() {
    local out
    out=$(fff-pick)
    if [[ -n "$out" ]]; then
      local -a files=("${(@f)out}")
      LBUFFER+="${(j: :)${(@q)files}} "
    fi
    zle reset-prompt
  }
  zle -N fff-pick-widget
  bindkey -M emacs '^T' fff-pick-widget
  bindkey -M viins '^T' fff-pick-widget
fi
```

`CTRL-R` history and `ALT-C` directory jumping stay on fzf either way.
