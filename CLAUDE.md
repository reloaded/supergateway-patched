# Project: supergateway-patched

Builds upstream [supergateway](https://github.com/supercorp-ai/supergateway)
from a **pinned release** with selected **open upstream fix PRs**
applied, and publishes a container image to GHCR. The product of this
repository is a `Dockerfile` + a release pipeline — nothing else.
Keep the surface that small.

## What this repo is (and is not)

- **Is:** a reproducible, pinned, patched build of supergateway whose
  only deviation from upstream is a small, documented set of *open*
  fix PRs cherry-picked to make stateful Streamable HTTP work with
  standard MCP SDK clients.
- **Is not:** a fork, a place for features, or a long-term divergence.
  Track upstream. When the applied PRs merge and release, **retire
  this repo** and switch consumers back to the official image. Never
  add a patch that isn't an upstream PR/commit reference.

## Repository layout

- `Dockerfile` — pinned build (clone release → apply PR(s) → build).
- `.github/workflows/` — CI (lint + build on PRs) + release (tag → GHCR).
- `.devcontainer/` — dev environment (docker-in-docker, lint tools).
- `CLAUDE.md` — this file: conventions any contributor follows.

## Build / release model

- **Pin everything.** Upstream release ref and each applied PR ref are
  build args with explicit defaults; record applied-patch SHAs in
  image labels. A build must be reproducible from a tag alone.
- **Minimal patch set.** Apply only the PR(s) that fix a verified
  problem. Each must be an upstream PR (link it in the Dockerfile +
  release notes). Prefer the smallest surgical set.
- **Releases are tag-driven.** Pushing a semver tag (`vX.Y.Z`) builds
  and pushes to GHCR. No manual image pushes. The image tag scheme is
  documented in the README; don't repurpose a published tag.
- Image variant mirrors upstream's `:uvx` (node + python3 + uv) so it
  can wrap both `npx`- and `uvx`-based stdio servers.

## Commit style

- Concise, imperative mood, 1–2 sentence summary focused on *why*.
- Do **not** add `Co-Authored-By` trailers.
- One logical change per commit.

## Git workflow

- **Never commit/push directly to `main`** except the single
  repository-seeding commit on an empty repo. All other work is a
  `workitem/<topic>` branch → **draft** PR (`gh pr create --draft`);
  one logical task = one commit (squash-merged, so the PR title is the
  final message — make it a clear imperative sentence). Don't flip a
  PR's draft/ready state on later pushes. PR body summarises the full
  scope.

### GitHub `#N` autolink hygiene

GitHub auto-links bare `#N` to issue/PR N everywhere. Only write `#N`
for a real cross-reference. Note: upstream-PR references in this repo
(e.g. "PR 136") are in the *upstream* repo, not here — write them as
"upstream PR 136" / a full URL, never bare `#136`, so they don't
autolink to an unrelated local number.

## Concurrent work with worktrees

(No separate `docs/worktrees.md` by design — guidance lives here.)
Each parallel session uses a git worktree:
`git worktree add ../wt-<topic> -b workitem/<topic>`; isolated working
dir sharing history; two worktrees can't check out the same branch.
Pull/rebase `main` before starting; remove the worktree after merge
(`git worktree remove`). Worktrees are local-only (never pushed).

## Self-improvement

When you learn a durable repo-wide lesson (a convention, a recurring
mistake, a build gotcha), add it to this `CLAUDE.md` via a small
focused PR — don't keep it only in ephemeral context. Scope it
tightly; title it as a convention/process change.

## Propose before implementing

A question about a significant/architectural concern is a request for
analysis + a recommendation, not authorization to build it. Small,
clearly-scoped, explicitly-requested changes: implement directly.
Anything that changes the patch strategy, build base, or release
model: propose first and get an explicit go-ahead.

## Hard rules

- **Public repository.** Never commit secrets, credentials, private
  hostnames, internal infrastructure details, employer/organization
  names, or anything not strictly about building patched supergateway.
  When in doubt, leave it out.
- No unpinned upstream refs, no unsigned/floating base images, no
  curl-pipe-to-shell of unverified sources in the image build.
