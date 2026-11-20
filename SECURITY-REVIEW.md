# ARTEX-Mobile security review

Review date: 2026-11-20

## Scope and method

This review covered the independent GitHub repository, imported Git refs, repository workflows, permission declarations, bot execution paths, license/security-policy preservation, and the available GitHub ruleset state. It used read-only repository inspection, static workflow/source review and GitHub Actions as the execution test environment.

This is **not a complete application penetration test**. The ARTEX server, browser extension, scanner integrations, Android host, remote worker, and live network attack surface were not built and subjected to an end-to-end dynamic assessment in this repository setup. No third-party system was scanned or exploited.

## Findings

### Fixed — privileged pull-request workflow could execute contributor-controlled code

The inherited bot workflow originally used the `pull_request` event, checked out the pull request merge ref and then ran `.github/scripts/bot.sh` while the job had issue/PR write permissions and could receive `DEEPSEEK_API_KEY`. This created a privileged workflow/code-execution risk for same-repository pull requests.

Remediation applied:
- Changed the event to `pull_request_target`.
- Explicitly checks out the repository default branch, not the pull request head.
- Disabled persisted checkout credentials; the script uses the narrowly scoped `GH_TOKEN` supplied to the step.
- Updated the script to handle the trusted `pull_request_target` event.
- Excluded `Mohamed2820` from automatic PR/comment replies and treated the account as a maintainer for issue triage.

Do not add any checkout or execution of the pull request head to this privileged workflow.

### Hardened — GitHub Actions token permissions

- The main CI workflow now declares `contents: read`.
- The release workflow now defaults to `contents: read`; its release job retains the write/attestation permissions it needs.
- The bot workflow retains only the write permissions needed for issues and pull requests, plus read-only contents access.
- The new integrity and upstream-drift workflows request `contents: read` only.

### Residual — mutable third-party Action references

Inherited workflows still use version tags such as `actions/checkout@v4`, `actions/setup-go@v5` and other Action tags. Tags are less immutable than full commit-SHA pins. Dependabot is configured to check GitHub Actions, Go modules and npm dependencies weekly; the inherited Action references have not all been converted to commit-SHA pins in this pass.

### Residual — external LLM data sharing in the repository bot

When `DEEPSEEK_API_KEY` is configured, the bot sends issue titles/bodies, repository path summaries and a bounded pull-request diff to the DeepSeek API. Keep secrets, customer data and private findings out of public issue/PR content. The bot does not need the secret when the repository secret is absent and skips model requests in that case.

### Pending — branch protection is not yet active

The repository rulesets API currently returns an empty list. Importable configurations are stored at:
- `docs/github-rulesets/source-main.json`
- `docs/github-rulesets/main.json`

They must still be imported from GitHub **Settings → Rules → Rulesets → New ruleset → Import a ruleset**. Until then, GitHub does not enforce the documented branch rules. The classic branch-protection read endpoint was not accessible to the connected integration, so no claim is made about classic rules.

### Preserved upstream security notes

The original upstream `SECURITY.md` is preserved verbatim at `docs/upstream/SECURITY.md`. Its documented accepted design gaps and operator guidance remain relevant to the inherited ARTEX code and must be considered during later runtime testing.

## Test status

Repository integrity and upstream-drift workflows were added. Their actual GitHub Actions conclusions must be checked after GitHub finishes running them. A queued or in-progress run is not a pass.

No destructive operations, credential extraction, external target scanning, or unauthorized exploitation were performed.
