#!/usr/bin/env bash
# Determines which ingestion domains' Snowpipe deploy job actually needs to run, based on
# changed files -- same mechanism and rationale as snowflake-platform-tf's
# dcm/detect-changed-domains.sh (Repo 1), applied here to the Snowpipe ingestion pattern.
#
# A domain only ever runs if it's listed in sql/active_ingestion_domains.json.
#
# Outputs a JSON array of {"name": ..., "target": ...} objects to stdout (possibly empty:
# "[]") -- consumed directly as a GitHub Actions `matrix.include` value.
#
# Usage:
#   detect-changed-domains.sh ALL                  # force every active domain (workflow_dispatch)
#   detect-changed-domains.sh <base-sha> <head-sha> # only domains with changed files in that range
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_DOMAINS_FILE="${SCRIPT_DIR}/active_ingestion_domains.json"

if [ "${1:-}" = "ALL" ]; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

BASE_SHA="${1:?Usage: detect-changed-domains.sh ALL | detect-changed-domains.sh <base-sha> <head-sha>}"
HEAD_SHA="${2:?Usage: detect-changed-domains.sh ALL | detect-changed-domains.sh <base-sha> <head-sha>}"

# All-zero SHA shows up as `github.event.before` on a branch's first-ever push -- fall back
# to the safe default (redeploy every active domain) rather than erroring on a nonexistent ref.
if [ "${BASE_SHA}" = "0000000000000000000000000000000000000000" ]; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

CHANGED_FILES="$(git diff --name-only "${BASE_SHA}" "${HEAD_SHA}")"

# The shared template affects every domain's rendered SQL -- a template change means every
# active domain must be redeployed, not just whichever domain's own config happened to also
# change in the same commit.
if echo "${CHANGED_FILES}" | grep -q '^sql/_template/'; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

jq -c --argjson changed "$(echo "${CHANGED_FILES}" | jq -R . | jq -s .)" '
  [.[] | select(. as $d | $changed | any(startswith("sql/domains/" + $d.name + "/")))]
' "${ACTIVE_DOMAINS_FILE}"
