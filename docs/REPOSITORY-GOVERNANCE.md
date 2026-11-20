# Repository governance

## Branch model

| Branch | Purpose |
|---|---|
| `main` | Integration branch and repository-level CI/configuration |
| `source/main` | Snapshot of upstream ARTEX main at import time; do not modify |
| `development` | General integration and shared development |
| `android-port` | Android host, UI, lifecycle and device integration |
| `integration/mcp` | MCP adapters, tool routing and external integrations |
| `cloud-runtime` | Remote Linux runtime, Codespaces and task-resumption work |

The imported upstream branches and tags are retained. The exact 184 branch refs and 4 tag refs are captured in `docs/upstream/refs-manifest.tsv`.

## Change flow

1. Make focused changes on the matching development branch.
2. Run the repository CI and security checks.
3. Open a pull request into `main`; describe behavior changes, tests and security impact.
4. Keep `source/main` unchanged. Upstream refreshes must be reviewed and recorded as a separate synchronization change.
5. Record project-specific changes in `PORTING-CHANGELOG.md`.

## Recommended GitHub rules

These rules should be enabled in GitHub **Settings → Rules → Rulesets** (or Branches → Branch protection rules):

### `source/main`
- Restrict updates and deletion.
- Block force pushes.
- Do not add a bypass actor for routine work.

### `main`
- Require pull requests before merging.
- Require the applicable CI checks to pass.
- Require conversation resolution.
- Block force pushes and deletion.
- Do not require an approving review while this repository has only one active maintainer; that would prevent the owner from merging their own reviewed PR.

### Development branches
- Block force pushes and deletion after work begins.
- Prefer pull requests for integration into `main`.

Importable ruleset files are provided:
- `docs/github-rulesets/source-main.json` locks the source snapshot against updates, deletion and force pushes.
- `docs/github-rulesets/main.json` requires pull requests for main, blocks deletion and force pushes, and does not require an approving review (to avoid a single-maintainer deadlock).
- `docs/github-rulesets/development-branches.json` requires pull requests for the four development branches and blocks deletion and force pushes.

To activate them, open repository **Settings → Rules → Rulesets → New ruleset → Import a ruleset**, import each JSON file, review it, and create it. The rulesets are not active until imported. After the first successful CI run, add the repository's verified CI check names as required status checks to the main ruleset.

## Security and automation

- Workflows should declare the smallest practical `GITHUB_TOKEN` permissions.
- Third-party Actions should be pinned to immutable commit SHAs where practical.
- Never store credentials in the repository, workflow files, issues, or pull requests.
- The inherited ARTEX triage bot sends bounded issue/PR content to the configured DeepSeek API when `DEEPSEEK_API_KEY` is present. Do not include secrets or private customer data in public issue/PR content.
- Run ARTEX only against targets you own or are explicitly authorized to test.
