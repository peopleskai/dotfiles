# cc-comment marker grammar

Single source of truth for the `cc` feedback-marker grammar. Both `doc-iterate`
(prose/Markdown notes) and `code-iterate` (source files) read this file first.

A marker is a comment the human leaves *in place* saying what they want changed,
asked, or blocked. An agent resolves it and deletes it. Markers are scaffolding —
they are not meant to survive into a commit or a shared doc.

## Two axes

Every marker has a **scope** (where it applies) and a **type** (what to do about it).

| | Note — change something | Question — answer, don't edit | Blocking — must resolve |
|---|---|---|---|
| **Inline** (line / span / block) | `cc:` | `cc?` | `cc!` |
| **General** (whole file) | `cc*:` | `cc*?` | `cc*!` |

Type semantics are identical at both scopes:

- **Note** — do the thing. Scoped edit, nothing more.
- **Question** — answer it in the reply to the user. Only edit if the answer
  changes the file's content. If the question stays open, the marker stays.
- **Blocking** — gates "done". An unresolved blocker is a headline item in the
  report, never a footnote.

**General markers are file-level direction and take priority.** Read every general
marker before planning any inline edit: they set the frame the inline markers operate
inside, and can make an inline marker moot (a general "delete this whole section"
makes a `cc:` note inside that section irrelevant). **Position carries no meaning** for
a general marker — one at the bottom of the file is not feedback about the last
section. If a general marker conflicts with an inline one, ask rather than guess.

## Prose form (Markdown / Obsidian)

Wrapped in native Obsidian comment delimiters — `%% ... %%` is invisible in Reading
view, so a marker is safe to leave in a note. This is the form the Obsidian cc-comment
plugin writes.

```markdown
==anchor text==%%cc: this is wrong, it is polled%%   <- anchored to the highlighted span
%%cc? is this reachable from an ISR%%                 <- applies to the block that follows
%%cc! must resolve before sharing%%
%%cc*: restructure around the polling model%%         <- whole-document direction
```

- A bare marker on its own line applies to the **line/block that follows**.
- A marker may span lines: `%%cc:` … `%%`.
- A missing type sigil means *note*, so legacy `%%cc …%%` and `%%cc* …%%` still parse.
- Resolving an anchored marker deletes the `==...==` highlight wrapper too, so the
  anchor text returns to plain prose.

### Prose grep

```bash
grep -nE '%%cc\*[:?!]?' "<path>"                    # general first — frames everything
grep -nE -A1 '%%cc' "<path>"                        # every marker + the following line
grep -oE '==[^=]+==%%cc\*?[:?!]?[^%]*%%' "<path>"   # anchored markers
grep -nE '%%cc\*?!' "<path>"                        # blockers — these gate done
```

## Code form (source files)

No `%%` wrapper. The language's **own comment leader** delimits the marker, so it
never breaks a build and needs no tooling to be safe to leave in a file.

```rust
// cc: use checked_add here, this can wrap
let n = a + b;                  // cc? is this ever called with a > isize::MAX
/* cc! must resolve before merge */
// cc*: this module should own retry, not the caller
```

```python
# cc: guard against an empty batch
```

```lua
-- cc: this should read commentstring, not hardcode //
```

**In code the type sigil is mandatory.** `cc:`, `cc?`, `cc!`, `cc*:`, `cc*?`, `cc*!`
only. There is no bare `cc` note form, because `cc` alone collides with real
identifiers and would produce false positives on every grep.

### Code scope rules

- **Trailing on a code line** → applies to that line.
- **On its own line** → applies to the syntactic item that follows: the next
  statement, block, function, struct, or match arm. Use the language's structure to
  decide the extent, not a fixed line count.
- **Inside a doc comment** (`///`, `"""`, `/** */`) → applies to the item that doc
  comment documents.
- **`cc*` anywhere in the file** → whole-file direction for that file. Conventionally
  placed at the top, but position carries no meaning.

### Code grep

Anchor on a comment leader so `cc:` inside a string literal or an email address does
not match:

```bash
# general first — file-level direction
rg -n --no-heading -e '(//|#|--|;|/\*|\*|"""|<!--)\s*cc\*[:?!]' <paths>
# every marker
rg -n --no-heading -e '(//|#|--|;|/\*|\*|"""|<!--)\s*cc\*?[:?!]' <paths>
# blockers — these gate done
rg -n --no-heading -e '(//|#|--|;|/\*|\*|"""|<!--)\s*cc\*?!' <paths>
```

## Resolution rules (both forms)

1. **One marker, one focused edit.** Never batch markers into a whole-file rewrite.
   Never `Write` an existing file — always a targeted `Edit`.
2. **Read the file from disk immediately before editing it.** Never edit from a
   version held in context from earlier in the conversation or a prior session.
3. **Delete the marker only when actually resolved.** Partially addressed is not
   resolved.
4. **Disagreement leaves the marker in place** and adds a sibling reply rather than
   deleting the human's note:
   - prose: `%%cc: <their text>%% %%claude: did not change this because <reason>%%`
   - code: `// cc: <their text>` then `// claude: did not change this because <reason>`
5. **The human's own edits outrank everything** — your context, your earlier plan,
   anything you previously wrote. If their edit already satisfies a marker, delete the
   marker, change nothing else, and say so.
6. **Do not invent work.** Zero markers and no new human edits means say so and stop.

## Authoring markers in nvim

Snippet prefixes are registered for every filetype with a known comment leader (see
`~/.config/nvim/snippets/`). Expand with blink.cmp, advance tabstops with `<C-l>`:

| prefix | inserts | prefix | inserts |
|---|---|---|---|
| `ccn` | `// cc: ` note | `ccgn` | `// cc*: ` general note |
| `ccq` | `// cc? ` question | `ccgq` | `// cc*? ` general question |
| `ccb` | `// cc! ` blocker | `ccgb` | `// cc*! ` general blocker |

Line-comment forms put the final tabstop on a fresh line below, so `<C-l>` escapes the
comment and leaves the cursor on the code the marker anchors to.

`/* … */` languages (`cc-slash.json`: rust, c/cpp, go, zig, java, js/ts, …) also get
`ccnw` / `ccqw` / `ccbw` (wrapped), where the final tabstop sits **past the closing
delimiter** — the escape to use for a trailing marker on a code line.

Comment leader families live in `~/.config/nvim/snippets/`: `cc-slash.json` (`//`),
`cc-hash.json` (`#` — python, sh, yaml, toml, make, …), `cc-dash.json` (`--` — lua, sql,
…). To cover a new filetype, add its name to the matching `language` array in
`snippets/package.json`; blink.cmp accepts an array and merges multiple entries per
filetype, so an existing per-language file is not displaced. Markdown is deliberately
absent — prose markers come from the Obsidian cc-comment plugin.
