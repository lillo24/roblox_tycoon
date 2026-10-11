# Validation and manual development deployment

- `validate.yml` reports the required `validate` PR status and supports a manual
  full checkpoint. Only Markdown-only PRs skip tools; source, scene, root config,
  workflows and PowerShell changes run the complete validator. No duplicate main
  push run is added. The validator includes offline deployment regressions.
- `deploy-development.yml` is **workflow_dispatch only**. It rejects any ref or
  default branch other than `main`, resolves current main at job checkout, runs
  full validation and publishes one fresh gameplay-only scene. The job's fixed
  concurrency group serializes the single development start place without
  canceling a running upload. `contents: read` is the sole token permission;
  maintained actions are pinned to commit SHAs as in validation. It uses the
  `roblox-development` environment and a three-day, single-file build artifact.
  It never invokes deployment automatically when this workflow or game code merges.

Full validation per manual deployment is intentional: publishing must validate
the actual checkout, regardless of earlier PR results. Ordinary PR trigger/scope
behavior remains unchanged. Environment secrets/settings and first manual run
are owner actions; see [`MOBILE_DEPLOYMENT.md`](../../docs/MOBILE_DEPLOYMENT.md).
