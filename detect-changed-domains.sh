#!/usr/bin/env bash
# Determines which domains' deploy job actually needs to run for a given ingestion
# *pattern*, based on changed files -- same mechanism and rationale as
# snowflake-platform-tf's dcm/detect-changed-domains.sh (Repo 1), generalized here to work
# across multiple ingestion patterns (Snowpipe today; Openflow/API reserved, see
# patterns/openflow/ and patterns/api/).
#
# A domain only ever runs if it's listed in patterns/<pattern>/active_domains.json.
#
# Outputs a JSON array of {"name": ..., "target": ..., "github_environment": ...} objects
# to stdout (possibly empty: "[]") -- consumed directly as a GitHub Actions
# `matrix.include` value.
#
# Usage:
#   detect-changed-domains.sh <pattern> ALL                   # force every active domain for this pattern
#   detect-changed-domains.sh <pattern> <base-sha> <head-sha> # only domains with changed files in that range
set -euo pipefail

PATTERN="${1:?Usage: detect-changed-domains.sh <pattern> ALL | detect-changed-domains.sh <pattern> <base-sha> <head-sha>}"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVE_DOMAINS_FILE="${SCRIPT_DIR}/patterns/${PATTERN}/active_domains.json"

if [ ! -f "${ACTIVE_DOMAINS_FILE}" ]; then
  echo "Error: ${ACTIVE_DOMAINS_FILE} does not exist -- is '${PATTERN}' a real pattern?" >&2
  exit 1
fi

if [ "${1:-}" = "ALL" ]; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

BASE_SHA="${1:?Usage: detect-changed-domains.sh <pattern> ALL | detect-changed-domains.sh <pattern> <base-sha> <head-sha>}"
HEAD_SHA="${2:?Usage: detect-changed-domains.sh <pattern> ALL | detect-changed-domains.sh <pattern> <base-sha> <head-sha>}"

# All-zero SHA shows up as `github.event.before` on a branch's first-ever push -- fall back
# to the safe default (redeploy every active domain for this pattern) rather than erroring
# on a nonexistent ref.
if [ "${BASE_SHA}" = "0000000000000000000000000000000000000000" ]; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

CHANGED_FILES="$(git diff --name-only "${BASE_SHA}" "${HEAD_SHA}")"

# The pattern's own template affects every domain using it -- a change under
# patterns/<pattern>/ means every active domain for that pattern must be redeployed, not
# just whichever domain's own sources/ file happened to also change in the same commit.
if echo "${CHANGED_FILES}" | grep -q "^patterns/${PATTERN}/"; then
  jq -c . "${ACTIVE_DOMAINS_FILE}"
  exit 0
fi

# Otherwise, only a domain whose own sources/<domain>/<pattern>-params.yml changed gets a
# job -- scoped to this specific pattern's params file, not the whole sources/<domain>/
# folder, since a domain could use multiple patterns independently in future.
jq -c --argjson changed "$(echo "${CHANGED_FILES}" | jq -R . | jq -s .)" --arg pattern "${PATTERN}" '
  [.[] | select(. as $d | $changed | any(. == ("sources/" + $d.name + "/" + $pattern + "-params.yml")))]
' "${ACTIVE_DOMAINS_FILE}"
