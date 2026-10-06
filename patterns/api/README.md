# API-polling ingestion pattern (reserved, not yet implemented)

Same status as `patterns/openflow/` — dormant by design. See that folder's README for the
exact mechanism; this one is a custom API-poller pattern instead of Openflow, but the
onboarding procedure is identical: add templated SQL/deploy artifacts here, add a
`sources/<domain>/api-params.yml`, add an entry to this folder's `active_domains.json`.
`deploy-api.yml` is already wired up and ready.
