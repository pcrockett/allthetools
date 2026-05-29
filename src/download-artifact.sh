#!/usr/bin/env bash
set -euo pipefail

main() {
  url="$1"
  output_path="$2"
  expected_sha="$3"
  curl -fsSL "${url}" -o "${output_path}"
  echo "${expected_sha}  ${output_path}" | sha256sum -c -
}

main "$@"
