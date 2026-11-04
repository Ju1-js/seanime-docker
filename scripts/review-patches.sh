#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd "${1:?Pass the prepared Seanime source directory}" && pwd)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tool_dir=$(mktemp -d)
trap 'rm -rf -- "$tool_dir"' EXIT

cp "$script_dir/patch-deps.go" "$tool_dir/"
(
    cd "$tool_dir"
    go mod init local/patch-review >&2
    go get golang.org/x/mod@v0.42.0 >&2
    go build -o patch-review.exe patch-deps.go
)
cd "$source_dir"
"$tool_dir/patch-review.exe" -audit
