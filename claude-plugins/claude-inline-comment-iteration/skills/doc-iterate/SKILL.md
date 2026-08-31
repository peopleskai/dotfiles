---
name: doc-iterate
description: >-
  Iterate on a Markdown/Obsidian note using the in-document `%%cc:%%` feedback
  markers written by the Obsidian cc-comment plugin (or typed by hand), without
  ever clobbering the user's manual edits. Use whenever the user asks to "iterate
  on the doc", "address my comments", "apply my feedback", "revise this note",
  "I left comments in <doc>", "pick up my edits", or points at a Markdown note and
  asks for another pass. It snapshots the note's repo to git first, diffs against
  the last agent-written state to detect the user's own edits, finds the `%%cc:%%`
  markers, resolves each one with surgical Edit calls (never a whole-file rewrite),
  removes resolved markers, and reports what changed. Trigger it even when the ask
  is terse ("another pass on the design doc") — a note plus a revise intent is the
  signal.
---

# Doc Iterate

Apply in-document `%%cc:%%` feedback to a Markdown note, treating **what is on disk as
the single source of truth** and the user's manual edits as authoritative.

This skill is the agent-side counterpart to the Obsidian cc-comment plugin: the plugin
writes the markers, this skill resolves them. It works equally well on markers typed by
hand, and on any Markdown file in any vault or repo — nothing here is specific to a
person, employer, or directory layout.

It exists because the default revise loop loses work: the agent regenerates a doc from
its own (possibly compacted) context and silently drops paragraphs the user wrote by
hand. Two rules prevent that, and they are not negotiable:

1. **Never `Write` an existing doc.** Every change is a targeted `Edit`. `Write` is
   only for a brand-new file.
2. **Read the file immediately before editing it**, every run. Never rely on a
   version held in context from earlier in the conversation or a prior session.

## Ground rules

- **Marker syntax is native Obsidian `%% ... %%`** — invisible in Reading view, so it
  needs no plugin to be safe to leave in a note. The cc-comment plugin adds authoring
  and navigation on top of the same syntax.
- **"Modified by the user or by a linter" means the user, unless proven otherwise.**
  When the harness reports that a file changed underneath you, treat it as intentional
  feedback. Only attribute it to tooling if you can point at an active formatter (e.g.
  an `obsidian-linter` config with `lintOnSave`/`lintOnFileChange` enabled and rules
  turned on, or a repo pre-commit hook). Never revert such a change as "noise".
- **Stay local.** Everything this skill does is local file editing plus local git. Do
  not push, publish, or send note content anywhere. The user's notes may be private or
  under handling restrictions you cannot see from the file.

## Comment marker formats

**Read `${CLAUDE_PLUGIN_ROOT}/references/cc-comment-grammar.md` first.** It is the authoritative marker
grammar — scope (inline vs `cc*` general), type (`:` note, `?` question, `!` blocking),
the prose `%%cc: …%%` form and its `==anchor text==%%cc: …%%` anchored variant, the grep
patterns, and the shared resolution rules. Do not re-derive them here.

Prose-specific reminders:

- General (`%%cc*…%%`) markers sit after the frontmatter or at the bottom, and **position
  carries no meaning** — one at the bottom is not feedback about the last section. Typical
  content: "restructure around the polling model", "add an Alternatives section", "too
  long, tighten by half". Read them all before planning any inline edit.
- Resolving an anchored marker deletes the `==...==` highlight wrapper too, so the anchor
  text returns to plain prose.
- Markdown has no build step to catch a mistake, so re-read the rendered structure
  (headings, list nesting, code fences) around every edit.

For markers in source-code comments, use the `code-iterate` skill instead.

## Workflow

### 1. Resolve the target doc

If the user named a doc, use it. If they were vague ("the design doc"), search the vault
or repo they are working in — the directory of a recently discussed note, the current
working directory, or a vault root they have configured — and confirm before editing:

```bash
find "<vault-or-repo-root>" -name '*.md' -newermt '-14 days' \
  -not -path '*/.obsidian/*' -printf '%T+ %p\n' | sort -r | head -20
```

Do not guess between two plausible docs — ask. If no root is known, ask for the path
rather than searching the whole home directory.

### 2. Snapshot to git BEFORE touching anything

This is the safety net that makes every later step reversible. Work from the git root
that contains the doc (`git -C "<doc dir>" rev-parse --show-toplevel`). If the doc is
not in a repo, offer to initialise one at the vault root before editing; if the user
declines, say plainly that changes will not be revertible and proceed only on their
confirmation.

When initialising, keep the repo to text — a vault's attachment directory is typically
hundreds of MB of binaries and should stay ignored:

```bash
cd "<vault-root>"
if [ ! -d .git ]; then
  git init
  printf '.obsidian/workspace.json\n.trash/\n' > .gitignore
  # add the vault's attachment/assets directory to .gitignore as well
  git add -A && git commit -m 'chore: initial vault snapshot'
fi
git add -A && git commit -m "snapshot: before doc-iterate on <doc name>" || true
```

An empty commit failing is fine (`|| true`) — it just means nothing changed since
the last snapshot. Report the commit SHA so the user can `git diff` or revert.

### 3. Detect the user's own edits since the last pass

This is the step that stops the clobbering. The user edits in Obsidian between runs and
**will not always mention it**.

```bash
cd "<vault-root>"
git log --oneline -15 -- "<relative/path/to/doc.md>"
# diff the doc against the snapshot from the previous doc-iterate run:
git diff <prev-snapshot-sha> -- "<relative/path/to/doc.md>"
```

Read that diff before planning any change. Their edits **outrank** anything in your
context and anything you previously wrote:

- If an edit already fixed what a `%%cc:%%` marker asked for → remove the marker,
  change nothing else, and say so.
- If an edit **contradicts** a plan from earlier in the conversation → the edit
  wins. Note the divergence in the report; do not "restore" your version.
- If an edit is mid-thought (a stub heading, a dangling sentence) → leave it alone
  unless a marker asks you to finish it.

### 4. Read the doc in full, then collect the comments

```bash
# document-level direction FIRST — this frames everything else
grep -nE '%%cc\*[:?!]?' "<path>"
# every marker, with the line that follows (the usual anchor target)
grep -nE -A1 '%%cc' "<path>"
# anchored comments specifically
grep -oE '==[^=]+==%%cc\*?[:?!]?[^%]*%%' "<path>"
# blocking markers at either scope — these gate "done"
grep -nE '%%cc\*?!' "<path>"
```

Then `Read` the whole doc. You need surrounding context to make a good edit, and the
`Read` also clears the staleness flag so `Edit` will not warn spuriously.

Build an explicit list of markers: line number, **scope** (inline / general), **type**
(note / question / blocking), anchor text if any, and what it asks for. If there are zero
markers **and** no new user edits, say so and stop — do not invent improvements nobody
asked for.

### 5. Resolve each comment with surgical edits

**Plan against the general (`cc*`) comments first**, then work the inline ones in
document order. If a general comment calls for restructuring, sequence it as multiple
`Edit` calls — still never a whole-file `Write`. If restructuring would remove or move a
section that has inline comments in it, address those inline comments as part of the
restructure and say so, rather than resolving them separately as if nothing moved.

For each marker, in document order:

1. `Edit` the *content* to address the feedback. Keep the change scoped to what the
   comment asks for — do not opportunistically rewrite neighbouring prose.
2. `Edit` again (or in the same call) to **delete the resolved marker**, including
   the `==...==` highlight wrapper so the anchor text returns to plain prose:
   `==pushed to the host==%%cc: wrong, it is polled%%` → `polled by the host`
3. For `%%cc? ...%%`, answer in your reply to the user. Only edit the doc if the answer
   changes its content. If you leave the question open, **leave the marker in place**.
4. If you disagree with a comment or cannot resolve it, **leave the marker** and add
   a sibling reply rather than deleting their note:
   `%%cc: <their text>%% %%claude: did not change this because <reason>%%`

Never batch comments into a single whole-file rewrite. One marker, one focused edit.
If a comment genuinely requires restructuring many sections, do it as a sequence of
`Edit` calls and say so in the report.

### 6. Verify, then snapshot again

```bash
grep -nE '%%cc' "<path>"          # remaining markers — expect only intentional leftovers
cd "<vault-root>" && git diff --stat -- "<path>"
git add -A && git commit -m "doc-iterate: <doc name> — resolved N comments"
```

Confirm no `cc!` blocking markers remain unresolved. If any do, that is a headline
item in the report, not a footnote.

### 7. Report

Keep it short and factual:

- **User edits detected**: what changed since the last pass, and how it affected the
  plan (especially anything that overrode a previous decision).
- **General direction applied**: what each `cc*` comment asked for and what you
  restructured in response. Lead with this — it is the largest-blast-radius change.
- **Comments resolved**: one line each — the marker and what you changed.
- **Comments left open**: which, and why (disagreement, needs their input, blocked).
- **Questions answered**: answers to `cc?` markers.
- **Git**: before/after commit SHAs so they can diff or revert.

State plainly if you changed nothing. Do not claim a comment is resolved if you only
partially addressed it.

## Anti-patterns

- ❌ `Write` on an existing doc — the one operation that silently destroys the user's work.
- ❌ Regenerating a section "to be consistent" when no marker asked for it.
- ❌ Reverting a user edit because it conflicts with your earlier draft.
- ❌ Deleting a `%%cc:%%` marker you did not actually resolve.
- ❌ Editing from a version of the doc held in context rather than re-reading disk.
- ❌ Skipping the git snapshot because "it's a small change".
