# supergateway-patched

A pinned build of [supergateway](https://github.com/supercorp-ai/supergateway)
with selected **open upstream fix PRs** applied, published to GHCR.

## Why

Upstream supergateway's **stateful Streamable HTTP** mode is broken for
standard MCP SDK clients: when a client opens the server→client SSE
stream and later reconnects without an explicit `DELETE`, supergateway
raises *"Conflict: Only one SSE stream is allowed per session"* via
`transport.onerror` and treats it as **fatal** — it SIGTERMs the
wrapped stdio child and destroys the session, so the client's next
request fails with HTTP 400. This makes the official MCP SDK clients
(used by common LLM gateways and chat UIs) unable to list/call tools,
even though the network path and `initialize` succeed.

Upstream tracks this as issue #126; the fix is open PR #136
("treat SSE-conflict onerror as recoverable, not fatal") but is
**not in any release**. This repo builds the latest release with that
fix applied, so SDK clients work.

## What it builds

A single image equivalent to upstream's `:uvx` variant
(`node:20-alpine` + `python3` + Astral `uv`/`uvx`, so it can wrap both
`npx`- and `uvx`-based stdio servers), built from a pinned
supergateway release **plus the applied fix PR(s)**. All inputs are
pinned build args; the image is reproducible from a tag.

```
ghcr.io/reloaded/supergateway-patched:<tag>
```

## Image

```
ghcr.io/reloaded/supergateway-patched:<tag>
```

Tags are set by the release pipeline from the pushed git tag
(`X.Y.Z`, `X.Y`, `latest`). `linux/amd64`.

## Applied patches

| Upstream PR | Fixes | Why |
|---|---|---|
| [supercorp-ai/supergateway#136](https://github.com/supercorp-ai/supergateway/pull/136) | issue 126 | stateful Streamable HTTP: treat the "Conflict: Only one SSE stream is allowed per session" `onerror` as recoverable instead of fatal, so a client SSE reconnect no longer SIGTERMs the wrapped stdio child (which made the next request 400). |

Pinned base: supergateway `v3.4.3` (== upstream `main` at pin time, so
the PR merges cleanly). The PR head SHA is asserted in the build and
recorded in image labels.

## Build (local)

```bash
docker buildx build -t supergateway-patched:dev .
```

CI: `ci` (lint) on every PR/push; `build` (real image build, no push)
on every PR + `workflow_dispatch`; `release` (build **and** push to
GHCR) on a `v*` tag only.

## Lifecycle

This repo is **temporary**. When the applied PR(s) merge upstream and
ship in a supergateway release, retire this repo and switch consumers
back to `supercorp/supergateway` / `ghcr.io/supercorp-ai/supergateway`.

## License

[MIT](LICENSE) (same as upstream supergateway).
