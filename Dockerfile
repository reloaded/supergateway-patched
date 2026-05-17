# syntax=docker/dockerfile:1.7

# supergateway built from a pinned upstream release with selected OPEN
# upstream fix PR(s) applied, so stateful Streamable HTTP works with
# standard MCP SDK clients (upstream issue 126; fix = upstream PR 136,
# unreleased). Reproducible from a tag: every input is a pinned ARG.
#
#   NODE_VERSION       node base (upstream uses node:20-alpine)
#   SUPERGATEWAY_REF   upstream release ref (v3.4.3 == main at build time)
#   PATCH_PR136_REF    upstream PR ref to merge (the SSE-conflict fix)
#   PATCH_PR136_SHA    head SHA of that PR, recorded for provenance
#
# Image variant mirrors upstream `:uvx` (node + python3 + uv) so it
# can wrap both npx- and uvx-based stdio MCP servers.

ARG NODE_VERSION=20

# ---------------------------------------------------------------------------
# Builder — clone the pinned release, merge the fix PR, build (tsc), pack.
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS builder

ARG SUPERGATEWAY_REF=v3.4.3
ARG PATCH_PR136_REF=pull/136/head
ARG PATCH_PR136_SHA=dfa619b66881

# hadolint ignore=DL3018
RUN apk add --no-cache git
WORKDIR /src

# Clone the pinned release, then merge the open fix PR. v3.4.3 == main
# at pin time and PR 136's base is main (MERGEABLE), so this is a
# clean merge. The PR ref is fetched explicitly and its head SHA is
# asserted so the build fails loudly if upstream force-pushes the PR.
RUN git clone https://github.com/supercorp-ai/supergateway.git . \
 && git -c advice.detachedHead=false checkout "${SUPERGATEWAY_REF}" \
 && git fetch origin "${PATCH_PR136_REF}" \
 && test "$(git rev-parse --short=12 FETCH_HEAD)" = "${PATCH_PR136_SHA}" \
 && git -c user.email=build@local -c user.name=build \
      merge --no-edit FETCH_HEAD

# HUSKY=0 + --ignore-scripts: `prepare: husky` only sets up dev git
# hooks and would fail / is unwanted in a container build. Build is
# just `tsc -p tsconfig.build.json`. Pack the patched build so the
# runtime stage installs it exactly like the upstream image installs
# the published package.
ENV HUSKY=0
RUN npm ci --ignore-scripts \
 && npm run build \
 && npm pack \
 && mv supergateway-*.tgz /supergateway-patched.tgz

# ---------------------------------------------------------------------------
# Runtime — upstream `:uvx`-equivalent: node:alpine + python3 + uv/uvx,
# with the patched supergateway installed globally from the tarball.
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine AS runtime

ARG SUPERGATEWAY_REF
ARG PATCH_PR136_SHA

LABEL org.opencontainers.image.source="https://github.com/reloaded/supergateway-patched" \
      org.opencontainers.image.description="supergateway (pinned) + open upstream fix PR(s) for stateful Streamable HTTP MCP-SDK interop" \
      org.opencontainers.image.licenses="MIT" \
      io.supergateway-patched.upstream-ref="${SUPERGATEWAY_REF}" \
      io.supergateway-patched.applied-pr="supercorp-ai/supergateway#136" \
      io.supergateway-patched.applied-pr-sha="${PATCH_PR136_SHA}"

# python3 + coreutils + Astral uv/uvx == upstream's `:uvx` variant.
# hadolint ignore=DL3018
RUN apk add --no-cache python3 coreutils
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install the patched build globally (creates the `supergateway` bin
# with the correct shebang, exactly as upstream's image does for the
# published package), then drop npm's cache.
COPY --from=builder /supergateway-patched.tgz /tmp/sg.tgz
RUN npm install -g /tmp/sg.tgz \
 && rm -f /tmp/sg.tgz \
 && npm cache clean --force \
 && useradd 2>/dev/null --create-home --uid 10001 supergateway \
    || adduser -D -u 10001 supergateway

USER supergateway
EXPOSE 8000
ENTRYPOINT ["supergateway"]
CMD ["--help"]
