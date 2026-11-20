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

### Fixed — third-party GitHub Action references pinned

All 39 external Action references in the default-branch workflows were checked and pinned to immutable 40-character commit SHAs, including checkout, setup-go, setup-node, setup-python, CodeQL, Docker build/publish actions, release actions and Gitleaks. The provenance attestation action was already pinned. Dependabot remains configured to check Actions and dependencies weekly.

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


### Added — static analysis and dependency audits

- Added CodeQL analysis for Go, JavaScript/TypeScript and Python, using the currently supported CodeQL Action v4. The first full CodeQL run is configured but was still queued at the time of this update.
- Added a Go vulnerability database audit using `govulncheck`.
- Added an npm audit job for the locked web dependencies; it fails on high-severity findings or above.
- Added weekly Dependabot update checks and capped each ecosystem at three open update PRs to avoid flooding CI with a large batch.

The Go and npm audit jobs had been queued and their conclusions were not yet available at the time of this update. A queued run is not evidence of a clean scan.

### Verified repository-integrity results

GitHub Actions completed the repository-integrity check successfully on the following development branches:
- `development`
- `android-port`
- `integration/mcp`
- `cloud-runtime`

The check also passed on `main` after the import-manifest correction. The last manifest inspection showed all 188 imported upstream refs (184 branches plus 4 tags) present with matching object IDs, while `source/main` remained at the recorded upstream commit.

### Remaining limitations

- The repository rulesets are still not active; the Rulesets API returned an empty list. The two JSON configurations must be imported through the GitHub repository Settings UI by an account administrator.
- The full CI, CodeQL and dependency-audit runs on the final HEAD had not all completed at the time of this review.
- No running ARTEX deployment, Android application, scanner integration, or remote Linux agent was available for authenticated/unauthenticated DAST, API abuse testing, Android IPC testing, or end-to-end exploitation. This report therefore must not be represented as a complete penetration test of the ARTEX application.


## Vulnerability scan findings

### High priority — Go dependency and toolchain findings

The first `govulncheck` execution on the imported application code reported two vulnerabilities with call paths in the ARTEX program:

1. **GO-2026-6865 / CVE-2026-116591 — `github.com/klauspost/compress`**
   - Locked version: `v1.18.6`.
   - Fixed version: `v1.20.2`.
   - govulncheck reported reachable symbols through the egress transport's compression/decompression path.
   - Upgrade the dependency and run the full Go test suite before release.

2. **GO-2026-6859 / CVE-2026-97054 — Go standard library `net/http`**
   - CI used Go `1.26.10`.
   - Fixed release: Go `1.26.11`.
   - The issue is a conditional HTTP/1 server crash/race involving `MaxBytesReader`/ `MaxBytesHandler` when request-body reads race with response-header writes. govulncheck reported application call paths to `net/http` symbols; it did not prove that the exact vulnerable concurrency condition is reachable in a live request.
   - Upgrade the build toolchain to at least Go `1.26.11`, then rerun govulncheck and the full suite.

These are dependency/toolchain vulnerability findings, not successful exploit demonstrations.

### High/Critical — Web dependency audit

The initial `npm audit` run reported **21 vulnerabilities: 1 critical, 12 high and 8 moderate** in the lockfile.

Notable findings:
- **GHSA-jqcg-44mw-7w3h / CVE-2026-90711 — `proxy-addr@2.0.7`**, fixed in `2.0.8`. The advisory describes IP spoofing when an application configures an IPv4-mapped IPv6 trust subnet with an IPv4-sized prefix. The current lockfile marks this package as a development dependency, pulled indirectly through Express → the MCP SDK → the `shadcn` development tool. This reduces its production exposure, but the vulnerable package remains installed in developer/CI environments. The condition was not dynamically tested.
- `zod@4.4.3` is a direct web dependency and is below the patched version `4.6.6` identified by the audit.
- `source-map-js@1.2.1` and `baseline-browser-mapping@2.10.40` were also flagged; the lockfile does not mark these entries as development-only.
- Other affected packages identified in the audit include `hono`, `ip-address`, `js-yaml`, `undici`, `systeminformation`, `body-parser`, `qs`, `brace-expansion`, `browserslist`, `fast-uri`, and `postcss-selector-parser`.

A separate `npm audit --omit=dev` check was added to distinguish production dependencies from development tools. Its final run had not completed at the time this report was updated. No bulk `npm audit fix` was applied, because dependency upgrades may introduce breaking changes and need their own review and test cycle.

### CodeQL and integrity run results

- CodeQL completed successfully on the application code for Go, JavaScript/TypeScript and Python in run [44731658277](https://github.com/Mohamed2820/ARTEX-Mobile/actions/runs/44731658277). This confirms the scan jobs executed; it is not a claim that no CodeQL alerts exist.
- Repository-integrity passed on the current main branch and on the four development branches, including the final `android-port` check [44732138201](https://github.com/Mohamed2820/ARTEX-Mobile/actions/runs/44732138201).
- The latest full CI and the latest split production/development dependency-audit jobs were still queued; earlier dependency-audit runs failed because the scanner found the findings above.

## Remediation status

The repository/workflow risks described as fixed above were changed in this repository. The Go and npm dependency findings are **open remediation items**. Do not describe the inherited ARTEX codebase as vulnerability-free or release-ready until those upgrades are made and their tests pass.


### Added — full-history secret scan

A `secret-history-scan` workflow now checks out complete Git history (`fetch-depth: 0`) and runs Gitleaks v3 on pushes to `main`, weekly, and on manual dispatch. The first run was queued when this review was finalized; no clean result is claimed yet. GitHub also makes Secret Scanning available for public repositories, but the connected GitHub interface did not expose secret-scanning alerts/settings for independent verification.

### Latest repository foundation checks

- The latest main-branch repository-integrity run completed successfully.
- The upstream drift check completed successfully and matched the recorded upstream baseline.
- Integrity runs on all four development branches passed immediately before the final documentation-only synchronization; the latest runs after that synchronization were queued.
- The latest full CI, CodeQL, dependency-audit and Gitleaks jobs were not all complete at the time of final review.

The repository bootstrap is therefore reproducible and its Git integrity is verified, but branch protection and full application security acceptance remain open.
