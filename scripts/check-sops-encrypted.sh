#!/usr/bin/env bash
set -euo pipefail

status=0

if [ "$#" -eq 0 ]; then
  exit 0
fi

for file in "$@"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  # Skip example files
  if [[ "$file" == *.example ]]; then
    continue
  fi

  # Check for SOPS metadata block (present in all SOPS-encrypted files)
  if grep -q "^sops:$" "$file"; then
    continue
  fi

  echo "ERROR: $file is not SOPS-encrypted (missing sops: metadata block)" >&2
  echo "       Run: sops -e -i $file" >&2
  status=1
done

exit "$status"
