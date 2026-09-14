#!/usr/bin/env bash
# verify.sh <target> - single entry point for both the sync workflow and the PR drift check.
# Derives <target> in the working tree, then asserts the result looks right.
set -eu

target=${1:?usage: verify.sh <target>}
./derive/derive.sh "$target"

cp sublime.env.example sublime.env
docker compose config -q
rm -f sublime.env

# 1. Service-set drift guard - catches services added/renamed/removed on main.
actual=$(yq '.services | keys | .[]' docker-compose.yml | sort)
expected=$(sort "derive/$target/expected-services.txt")
if [ "$actual" != "$expected" ]; then
  echo "::error::Service set mismatch for $target. Add/remove the service in" \
       "derive/$target/expected-services.txt or derive/common/deletes.txt." >&2
  diff <(echo "$expected") <(echo "$actual") || true
  exit 1
fi

# 2. Intent assertions - catches restructuring *inside* a service, which (1) can't see because
#    del()/deep-merge are silent on a moved or renamed path. One assertion per transform in
#    deletes.txt/overlay.yml whose *intent*, not just presence, matters.
[ "$(yq '.services.sublime_dashboard.depends_on' docker-compose.yml)" = "null" ]
[ "$(yq '.services.sublime_hydra.environment | has("WORKER_TIMEOUT")' docker-compose.yml)" = "false" ]
[ "$(yq '.services.sublime_hydra.environment | has("GRACEFUL_WORKER_TIMEOUT")' docker-compose.yml)" = "false" ]
[ "$(yq '.volumes | has("persistent_storage")' docker-compose.yml)" = "false" ]
[ "$(yq '.services.sublime_hydra.environment.WORKERS' docker-compose.yml)" = "2" ]
[ "$(yq '.services.sublime_dashboard.image' docker-compose.yml | grep -c ':dev$')" = "1" ]
[ "$(yq '.services.sublime_hydra.image' docker-compose.yml | grep -c ':dev$')" = "1" ]
[ "$(yq '.services.sublime_postgres.ports' docker-compose.yml | grep -c '5432:5432')" = "1" ]
[ "$(yq '.services.sublimes3.ports' docker-compose.yml | grep -c '8110:8110')" = "1" ]
[ "$(yq '.services.sublime_create_buckets.command' docker-compose.yml | grep -c -- '--ignore-existing')" = "1" ]
for svc in sublime_mantis sublime_bora_lite sublime_nginx_letsencrypt sublime_nginx_custom_ssl; do
  [ "$(yq ".services | has(\"$svc\")" docker-compose.yml)" = "false" ]
done

# Sanity check that no port mapping resolved to a non-string node (e.g. a bare int). Verified
# empirically that yq's -P output and docker compose's own parser both keep "N:N" port strings
# as strings rather than resolving them as YAML 1.1 sexagesimal ints, but this is cheap insurance
# against a future toolchain change silently doing otherwise.
[ "$(yq '[.services[].ports // [] | .[] | select(tag != "!!str")] | length' docker-compose.yml)" = "0" ]

echo "verify.sh: $target OK"
