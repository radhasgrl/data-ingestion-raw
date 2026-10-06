# Openflow ingestion pattern (reserved, not yet implemented)

This folder exists to prove the "one workflow per ingestion pattern" structure
generalizes beyond Snowpipe — it is deliberately **dormant**: `active_domains.json` here
is `[]`, so `.github/workflows/deploy-openflow.yml` never deploys anything, no matter what
changes.

When a real Openflow ingestion domain is onboarded:

1. Add `sql/*.sql` here (or whatever Openflow's actual deployable artifacts are),
   Jinja2-templated the same way `patterns/snowpipe/sql/` is.
2. Add that domain's `sources/<domain>/openflow-params.yml`.
3. Add `{"name": "<domain>", "target": "<DOMAIN>", "github_environment": "..."}` to this
   folder's `active_domains.json`.

`deploy-openflow.yml` already has the detect-changed-domains + matrix-deploy mechanism
wired up and ready — nothing in that workflow needs to change.
