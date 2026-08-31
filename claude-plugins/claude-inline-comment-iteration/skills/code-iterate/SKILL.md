---
name: code-iterate
description: >-
  Resolve `cc:` / `cc?` / `cc!` feedback markers the user left in source-code
  comments, without clobbering their manual edits. Use whenever the user asks to
  "address my cc comments", "resolve the markers", "I left comments in the code",
  "apply my inline feedback", "iterate on this file/package", or points at source
  files and asks for another pass. It checkpoints the worktree with a non-invasive
  git stash object, diffs against the last pass to detect the user's own edits,
  greps for markers anchored on comment leaders, resolves each with surgical Edit
  calls (never a whole-file rewrite), deletes resolved markers, then builds and
  tests the touched packages. For Markdown notes use doc-iterate instead. Trigger
  it even when the ask is terse ("another pass on mailbox.rs") — source files plus
  a revise intent is the signal.
---

# Code Iterate

Resolve `cc` markers in source files, treating **what is on disk as the single source
of truth** and the user's manual edits as authoritative.

**Read `${CLAUDE_PLUGIN_ROOT}/references/cc-comment-grammar.md` first.** It is the authoritative
marker grammar — scope (inline vs `cc*` general), type (`:` note, `?` question, `!`
blocking), code scope rules, and the grep patterns. Do not re-derive them here.

Two rules are not negotiable, because the default revise loop loses work — the agent
regenerates a file from its own (possibly compacted) context and silently drops code
the user wrote by hand:

1. **Never `Write` an existing file.** Every change is a targeted `Edit`. `Write` is
   only for a brand-new file.
2. **Read the file immediately before editing it**, every run. Never rely on a version
   held in context from earlier in the conversation or a prior session.

## Why a git checkpoint, not `/rewind`

Claude Code's checkpoints (`/rewind`, `Esc Esc`) do not cover the failure modes here:
files the user edited **outside** Claude Code are not tracked, files changed by **bash
commands** are not tracked, and **subagent** edits are usually not restored. The
user's own nvim edits between passes are exactly the thing that must not be lost.

So take a git checkpoint. Use `git stash create` — it records the worktree as a real
commit object **without touching the worktree or the index**, so a carefully staged
partial hunk survives untouched.

## Workflow

### 1. Resolve the scope

If the user named files or a package, use that. If they were vague, find the markers
first and let them define the scope — do not ask them to enumerate files:

```bash
cd "<repo root>"
rg -l --no-heading -e '(//|#|--|;|/\*|\*|"""|<!--)\s*cc\*?[:?!]' | head -40
```

Restrict to tracked files if the repo has large build/vendor trees (`rg` respects
`.gitignore` by default). If the hit list spans unrelated packages, report it and
confirm the scope before editing.

### 2. Checkpoint before touching anything

```bash
cd "<repo root>"
git status --short
SHA=$(git stash create) && [ -n "$SHA" ] && \
  git stash store -m "code-iterate checkpoint: <scope>" "$SHA" && echo "$SHA"
```

An empty `$SHA` means the worktree is clean — nothing to checkpoint, and HEAD is
already the restore point. Report either the stash SHA or the HEAD SHA so the user can
`git stash apply <sha>` / `git diff`. If the files are not in a git repo, say plainly
that changes will not be revertible and proceed only on their confirmation.

Do **not** `git add`, `git commit`, or `git stash push` — those mutate index or
worktree state the user may have arranged deliberately.

### 3. Detect the user's own edits since the last pass

This is the step that stops the clobbering. The user edits in nvim between runs and
**will not always mention it**.

```bash
git diff -- <paths>              # unstaged: their in-flight work
git diff --staged -- <paths>     # staged: also theirs
git log --oneline -15 -- <paths>
git diff <prev-checkpoint-sha> -- <paths>   # if a previous pass left a checkpoint
```

Read those diffs before planning any change. Their edits **outrank** anything in your
context and anything you previously wrote:

- If an edit already satisfies a marker → delete the marker, change nothing else, say so.
- If an edit **contradicts** a plan from earlier in the conversation → the edit wins.
  Note the divergence in the report; do not "restore" your version.
- If an edit is mid-thought (a stub function, a `todo!()`, a half-written match arm) →
  leave it alone unless a marker asks you to finish it.

When the harness reports a file was "modified by the user or by a linter", treat it as
the user unless you can point at a demonstrably active formatter (a `conform.nvim`
format-on-save config, a pre-commit hook). Never revert such a change as noise.

### 4. Collect the markers, then read the code

Grep per the GRAMMAR patterns — **general (`cc*`) markers first**, they frame
everything else. Then `Read` each file that has markers, in full. You need the
surrounding code to make a correct edit, and the `Read` also clears the staleness flag
so `Edit` will not warn spuriously.

Build an explicit list: file, line, **scope** (inline / general), **type** (note /
question / blocking), the syntactic item the marker anchors to, and what it asks for.

Use the language's structure — not a line offset — to decide what an own-line marker
covers. Where treesitter or the LSP is available, prefer symbol lookup over guessing an
extent. If a marker asks for a change whose blast radius escapes the marked item (a
signature change with call sites elsewhere), find the call sites before editing:

```bash
rg -n --no-heading '\b<symbol>\b'
```

If there are zero markers **and** no new user edits, say so and stop — do not invent
improvements nobody asked for.

### 5. Resolve each marker with surgical edits

Plan against the general (`cc*`) markers first, per file, then work the inline ones in
file order. If a general marker calls for restructuring, sequence it as multiple `Edit`
calls — still never a whole-file `Write`. If restructuring removes or moves code that
carries inline markers, address those inline markers as part of the restructure and say
so, rather than resolving them separately as if nothing moved.

For each marker:

1. `Edit` the *code* to address the feedback. Keep the change scoped to what the marker
   asks for — no opportunistic refactoring of neighbouring code, no renaming for
   consistency, no reordering imports.
2. `Edit` again (or in the same call) to **delete the resolved marker**, including the
   comment leader if the marker was the whole line, so no blank comment remains:
   `let n = a + b; // cc: use checked_add` → `let n = a.checked_add(b)?;`
3. For `cc?`, answer in the reply to the user. Only edit the code if the answer changes
   it. If the question stays open, **leave the marker in place**.
4. If you disagree or cannot resolve it, **leave the marker** and add a sibling reply
   comment rather than deleting their note:
   ```rust
   // cc: <their text>
   // claude: did not change this because <reason>
   ```

Never run a repo-wide formatter or linter autofix as part of resolving a marker — it
buries the real change in unrelated diff noise. If a change needs formatting, format
only the lines you touched.

### 6. Verify: build, then test

Detect the toolchain from the package, and run it for **each touched package**. Log
verbose output to a file and read the tail rather than dumping it:

| marker in | build / typecheck | tests |
|---|---|---|
| `Cargo.toml` | `cargo check` (or `cargo clippy`) | `cargo test` |
| Brazil `Config` | `brazil-build release > build.log 2>&1` then `tail -n 20 build.log` | included in `brazil-build release` |
| `package.json` | `npm run build` / `tsc --noEmit` | `npm test` |
| `pyproject.toml` | `ruff check` / `mypy` | `pytest` |
| `Makefile` | `make` | `make test` |

For an embedded/no-std target, respect the package's own documented command (README,
`.cargo/config.toml` target, `brazil-build` wrapper) rather than a bare `cargo` default.
If the correct build or test command cannot be determined, say so explicitly in the
report rather than silently skipping verification.

**A build or test failure caused by your edit is a headline item, not a footnote.**
Fix it. If a failure pre-existed your change, prove it (stash your edits or check the
checkpoint) and report it as pre-existing.

### 7. Verify markers, then report

```bash
rg -n --no-heading -e '(//|#|--|;|/\*|\*|"""|<!--)\s*cc\*?[:?!]' <paths>
git diff --stat -- <paths>
```

Expect only intentional leftovers. Confirm no `cc!` blockers remain unresolved.

**Do not commit.** The user commits their own work; a `code-iterate` pass is not a
commit boundary. If markers remain and the user is about to commit, warn them — markers
are scaffolding and should not land in shared history.

Report, short and factual:

- **User edits detected**: what changed since the last pass, and how it affected the
  plan — especially anything that overrode a previous decision.
- **General direction applied**: what each `cc*` marker asked for and what you
  restructured. Lead with this; it is the largest blast radius.
- **Markers resolved**: one line each — `path:line`, the marker, what you changed.
- **Markers left open**: which, and why (disagreement, needs their input, blocked).
- **Questions answered**: answers to `cc?` markers.
- **Verification**: exact build/test commands run and their result. Say plainly if a
  step was skipped and why.
- **Checkpoint**: the stash or HEAD SHA to diff or restore from.

State plainly if you changed nothing. Do not claim a marker is resolved if you only
partially addressed it.

## Anti-patterns

- ❌ `Write` on an existing source file — the one operation that silently destroys work.
- ❌ Refactoring code no marker pointed at, "while we're here".
- ❌ Running a formatter or `clippy --fix` across the repo and burying the real change.
- ❌ Reverting a user edit because it conflicts with your earlier draft.
- ❌ Deleting a marker you did not actually resolve.
- ❌ Editing from a version of the file held in context rather than re-reading disk.
- ❌ Committing, staging, or `git stash push` — never mutate their index or worktree state.
- ❌ Reporting done without building, or calling a failure unrelated without proving it.
- ❌ Relying on `/rewind` as the safety net; it does not track their nvim edits.
