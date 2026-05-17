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

> Bootstrapping in progress — Dockerfile, CI, and the applied-patch
> set are added in follow-up changes. Track upstream: when the fix
> PRs merge and release, this repo is retired in favour of the
> official image.

## License

[MIT](LICENSE) (same as upstream supergateway).
