# claude-inline-comment-iteration

A Claude Code plugin that resolves `cc:` / `cc?` / `cc!` inline feedback markers you
leave in comments, without clobbering your manual edits.

## Skills

- **code-iterate** — resolves markers in source-code comments. Checkpoints the worktree
  with a non-invasive `git stash create`, diffs against the last pass to detect your own
  edits, resolves each marker with surgical `Edit` calls (never a whole-file rewrite),
  deletes resolved markers, then builds and tests the touched packages.
- **doc-iterate** — the prose counterpart for Markdown/Obsidian notes, using the native
  `%%cc: ...%%` marker form written by the Obsidian cc-comment plugin.

Both skills read the shared marker grammar in
[`references/cc-comment-grammar.md`](references/cc-comment-grammar.md), which defines the
scope (inline vs `cc*` general) and type (`:` note, `?` question, `!` blocking) axes and
the grep patterns.

## Marker grammar (quick reference)

|  | Note — change it | Question — answer | Blocking — must resolve |
|---|---|---|---|
| **Inline** | `cc:` | `cc?` | `cc!` |
| **General** (whole file) | `cc*:` | `cc*?` | `cc*!` |

In source code the type sigil is mandatory (`cc:` etc.); in Markdown the marker is
wrapped in `%% ... %%`.

## Companion nvim snippets

The `dot-config/nvim/snippets/cc-*.json` files in this dotfiles repo register snippet
prefixes (`ccn`, `ccq`, `ccb`, `ccgn`, …) for authoring these markers in Neovim. See the
"Authoring markers in nvim" section of the grammar reference.

## Install

From the dotfiles repo (or its GitHub source):

```
claude plugin marketplace add peopleskai/dotfiles
claude plugin install claude-inline-comment-iteration@peopleskai-dotfiles
```
