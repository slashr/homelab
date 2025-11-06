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

  if head -n 1 "$file" | grep -q "^\$ANSIBLE_VAULT;"; then
    continue
  fi

  echo "ERROR: $file is not ansible-vault encrypted (missing \$ANSIBLE_VAULT header)" >&2
  status=1
done

exit "$status"
