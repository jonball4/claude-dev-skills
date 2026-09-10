# Create PR Skill

`create-pr` is an evidence-aware GitHub publication skill for a compatible agent harness. It analyzes the current branch and uses the authenticated `gh` CLI to create or update a pull request. It is not an implementation, testing, review, or workflow-orchestration skill.

## When to use

- A user explicitly requests a pull request; or
- the `build` workflow requests publication after its approved handoff.

## Prerequisites

- `gh` is installed and authenticated;
- the checkout is on a non-detached branch with commits beyond its verified base;
- the working tree and index are clean, unless remaining changes are explicitly covered by the handoff;
- supplied handoff and review evidence matches the current diff identity;
- no unresolved actionable review finding remains;
- the invoking harness can inspect commits, diffs, files, and command output.

When invoked by `build`, the handoff and review evidence are required inputs. The skill stops rather than inventing missing decisions, test results, review status, migration notes, or issue links.

## What it does

1. Determines the base branch from `origin/HEAD` or an explicitly supplied base.
2. Reads the complete commit history and diff from base to the current branch.
3. Checks whether the branch already has an open pull request.
4. Regenerates the title and complete body from current evidence.
5. Pushes the branch when required.
6. Creates a new PR or updates the existing PR for that branch.
7. Returns a context dump in chat; it does not save that dump as a file.

An existing open PR switches the skill to update mode. It never creates a duplicate PR for the same branch and does not preserve stale sections from the existing description.

## Generated PR structure

The body uses these sections, populated from actual branch and handoff evidence:

- Summary and issue context;
- Decision Record, including reasoning and alternatives;
- Contract Updates;
- Breaking Changes and migration path;
- Testing & Verification, including commands and observed results;
- Checklist;
- Related links and artifacts.

The title format is `[Type]: Brief description` with a maximum length of 50 characters. The exact body is regenerated on every create or update; placeholders and unsupported claims are not valid output.

## Usage

Invoke the skill through the host harness when ready to publish:

```text
Create a PR for this feature
Open a pull request
Make a PR
```

The build workflow supplies the issue context, handoff file, and review evidence. Direct callers may supply equivalent context. The skill does not fetch issue context independently.

## What it does not do

- implement or modify product source;
- run the project's tests or replace review;
- infer missing technical decisions;
- decide whether a review is complete;
- create a PR when the current evidence does not match the current diff;
- maintain long-term workflow artifacts.

## Troubleshooting

**`gh: command not found`**

Install GitHub CLI, for example on macOS:

```bash
brew install gh
```

**Not authenticated**

```bash
gh auth login
```

**No commits found**

Use a branch with commits beyond the verified base. If `origin/HEAD` is unavailable, supply the intended base branch rather than guessing.

**Evidence or diff mismatch**

Re-run the build review and produce a handoff for the current committed tree. Do not bypass the identity check.
