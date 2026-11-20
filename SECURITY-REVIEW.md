# ARTEX-Mobile security review

Review date: 2026-11-20
Repository commit reviewed: `97a69ea3ae19272eea8c4ea2e20a0ff7188e1333`

## Scope and limits

This review covers the repository bootstrap and inherited project baseline: Git refs and source provenance, workflow trust boundaries and permissions, dependency health, static analysis, secret-history scanning, and available CI tests.

It is not a full penetration test of a deployed ARTEX product. No running ARTEX server, browser extension, Android app, scanner integration, or remote worker was provided as a live target. Therefore authenticated/unauthenticated DAST, API abuse testing, Android IPC testing, exploit validation against a running service, and end-to-end attack-chain testing have not been performed. No third-party systems were scanned or exploited.

## Verified repository provenance

- The repository is an independent repository, not a GitHub fork.
- The import manifest contains 188 upstream refs: 184 branch refs and 4 tags.
- Each of the 188 refs was compared with its imported counterpart; every recorded object ID matched. The upstream `main` ref is preserved as `source/main`.
- `source/main` matched `BaaRai/ARTEX/main` at commit `ab40834567475c449bb34f84a9aa50a6587cb471` when checked.
- The upstream licence and security policy remain preserved in the repository.

## Findings and remediation

### Fixed — privileged pull-request workflow trust boundary

The inherited bot workflow previously checked out contributor-controlled pull-request code in a workflow with write permissions and access to a model API secret.

Remediation:
- The workflow now uses `pull_request_target` but checks out only the trusted default branch.
- Checkout credentials are not persisted.
- The bot receives only the issue and pull-request permissions needed for its actions, plus read-only contents.
- The workflow does not check out or execute the pull-request head.
- The bot script handles the trusted event type and skips self/maintainer/bot replies.

### Hardened — workflow permissions and immutable Actions

- Repository workflows declare explicit least-privilege token permissions.
- Release write/attestation permissions are limited to the release job.
- External GitHub Actions in the default-branch workflows are pinned to immutable commit SHAs.
- Dependabot is configured to check Actions, Go modules, and npm dependencies weekly.

### Fixed — Go dependency and toolchain vulnerabilities

The initial Go audit identified reachable call paths in `github.com/klauspost/compress v1.18.6` and the Go `net/http` implementation in toolchain 1.26.10.

Remediation merged in PR #16:
- Go toolchain directive upgraded to 1.26.11.
- `github.com/klauspost/compress` upgraded to v1.20.2.
- The post-remediation `govulncheck` job reported zero vulnerabilities in code paths the application appears to call. It still reported two vulnerabilities in required/imported modules that the code does not appear to call; this distinction is preserved rather than calling the entire module graph vulnerability-free.

### Fixed — npm dependency vulnerabilities

The initial web dependency audit reported 21 findings (1 critical, 12 high, 8 moderate).

The remediation PR updated the lockfile and applied a targeted `minimatch` override rather than forcing a potentially breaking major dependency upgrade. The post-remediation workflow completed both:
- `npm audit --omit=dev`: zero vulnerabilities.
- Full `npm audit`: zero vulnerabilities.

### Passed — automated security and build checks

The completed CI run on remediation PR #16 (head `4527956eca1ccf00a28221bba6ae9e896f12e2e6`) succeeded:
- Go formatting, build, vet, full tests, SQL migration/index scripts, and race tests.
- Go stable-toolchain build, vet, and tests.
- Python posture tests.
- Web `npm ci`, TypeScript check, polling/replay/upload/i18n tests, static build.
- ShellCheck and shell-script tests.

The same PR's CodeQL jobs completed successfully for Go, JavaScript/TypeScript, and Python. This records successful execution of those scans; it is not a claim that the CodeQL alert inventory is empty.

The dependency-audit jobs completed successfully. Gitleaks completed successfully against the complete Git history on the main branch after the merge. Repository-integrity checks passed.

### Residual — external LLM data sharing

When `DEEPSEEK_API_KEY` is configured, the repository bot sends bounded issue/PR content, repository path summaries, and a truncated PR diff to the DeepSeek API. Do not place secrets, private customer data, or non-public findings in public issues or pull requests. This is a documented data-sharing design choice, not a claim that the model provider is part of the repository's trusted boundary.

### Residual — inherited ARTEX application risks

The upstream security policy documents design limitations in areas including scanner-output trust/scope handling and filesystem operations involving uploads, archive handling, and symlinks. The upstream policy is retained verbatim at `docs/upstream/SECURITY.md`. Those inherited application behaviors have not been dynamically tested or comprehensively remediated as part of the repository-bootstrap stage. Changes to `source/main` would also compromise its role as an unchanged source snapshot; any application-level fix must be made on an implementation branch and independently tested.

## Repository security controls still not active

Three importable repository ruleset configurations are present:
- `docs/github-rulesets/source-main.json`
- `docs/github-rulesets/main.json`
- `docs/github-rulesets/development-branches.json`

However, the GitHub Rulesets API returned an empty list. The rulesets are therefore **not active**. The connected GitHub integration does not expose permission to create repository rulesets or read classic branch-protection settings. Do not treat the checked-in JSON files as enforcement. They must be imported and activated by a repository administrator in GitHub Settings → Rules → Rulesets.

## Current assessment

The repository import, provenance verification, dependency remediation, automated security checks, and CI test suite described above have been completed and the dependency remediation PR has been merged.

The repository-bootstrap stage cannot be represented as fully security-approved while branch protection remains inactive. Also, a full application penetration test remains out of scope until a runnable ARTEX deployment and the Android/remote components exist. The accurate status is: **repository bootstrap and automated remediation completed; GitHub enforcement and full application DAST remain open items.**

No destructive operations, credential extraction, external target scanning, or unauthorized exploitation were performed.
