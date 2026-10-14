#!/usr/bin/env bash
set -euo pipefail

repo="https://github.com/est57/echoproof"
version="${ECHOPROOF_VERSION:-latest}"
if [[ "$version" == "latest" ]]; then
  tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$repo/releases/latest")"
  tag="${tag##*/}"
else
  tag="v${version#v}"
fi
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "echoproof-action: unexpected version '$tag'" >&2
  exit 2
fi

case "${RUNNER_OS}-${RUNNER_ARCH}" in
  Linux-X64) target="x86_64-unknown-linux-gnu" ;;
  Linux-ARM64) target="aarch64-unknown-linux-gnu" ;;
  macOS-X64) target="x86_64-apple-darwin" ;;
  macOS-ARM64) target="aarch64-apple-darwin" ;;
  *) echo "echoproof-action: unsupported runner ${RUNNER_OS}-${RUNNER_ARCH}" >&2; exit 2 ;;
esac

name="echoproof-${tag}-${target}"
dir="${RUNNER_TEMP}/echoproof-${tag}"
mkdir -p "$dir"
cd "$dir"
curl -fsSLO "$repo/releases/download/$tag/$name.tar.gz"
curl -fsSLO "$repo/releases/download/$tag/$name.tar.gz.sha256"
expected="$(cut -d' ' -f1 "$name.tar.gz.sha256")"
if command -v sha256sum >/dev/null; then
  actual="$(sha256sum "$name.tar.gz" | cut -d' ' -f1)"
else
  actual="$(shasum -a 256 "$name.tar.gz" | cut -d' ' -f1)"
fi
if [[ "$expected" != "$actual" ]]; then
  echo "echoproof-action: checksum mismatch for $name.tar.gz" >&2
  exit 2
fi
tar xzf "$name.tar.gz"
echo "$dir/$name" >> "$GITHUB_PATH"
"$dir/$name/echoproof" --version
