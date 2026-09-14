#!/usr/bin/env bash
# derive.sh <target> - mutates the working tree in place, deriving <target>'s
# docker-compose.yml (and file layout) from main's.
set -eu

target=${1:?usage: derive.sh <target>}
[ -d "derive/$target" ]

for d in common "$target"; do
  f="derive/$d/deletes.txt"
  if [ -f "$f" ]; then
    paths=$(grep -v -E '^\s*(#|$)' "$f" | paste -sd, -)
    if [ -n "$paths" ]; then
      yq -i "del($paths)" docker-compose.yml
    fi
  fi
done

for d in common "$target"; do
  f="derive/$d/overlay.yml"
  if [ -f "$f" ]; then
    # -P forces block-style output; without it, merging against a flow-style ({}) overlay
    # collapses the whole document to flow style and turns bare (null) volume keys into "".
    yq -i -P eval-all 'select(fi==0) * select(fi==1)' docker-compose.yml "$f"
  fi
done

grep -v -E '^\s*(#|$)' derive/common/remove-files.txt | while read -r p; do
  rm -rf "$p"
done
