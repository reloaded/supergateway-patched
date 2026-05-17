#!/usr/bin/env bash
# Install the lint tooling CI uses (the linter name is written
# indirectly: a comment starting with the literal "# <linter>" token
# is parsed by that linter as a directive and fails the run).
set -euo pipefail

ARCH="$(uname -m)"
HADOLINT_VERSION="v2.12.0"
case "${ARCH}" in
  x86_64) HADOLINT_ARCH="x86_64" ;;
  aarch64 | arm64) HADOLINT_ARCH="arm64" ;;
  *) HADOLINT_ARCH="x86_64" ;;
esac
sudo curl -fsSL \
  "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-${HADOLINT_ARCH}" \
  -o /usr/local/bin/hadolint
sudo chmod +x /usr/local/bin/hadolint

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends shellcheck
sudo rm -rf /var/lib/apt/lists/*

echo "post-create complete: $(hadolint --version), $(shellcheck --version | sed -n '2p')"
