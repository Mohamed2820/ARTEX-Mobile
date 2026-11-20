# Upstream relationship

This repository is an independent, non-fork import of [BaaRai/ARTEX](https://github.com/BaaRai/ARTEX).

- Upstream remote URL: https://github.com/BaaRai/ARTEX.git
- Upstream default branch: `main`
- Import baseline commit: `ab40834567475c449bb34f84a9aa50a6587cb471`
- Local immutable-intent reference branch: `source/main`
- The import snapshot contains 184 upstream branch refs and 4 tags. Their exact names and object IDs are recorded in [docs/upstream/refs-manifest.tsv](docs/upstream/refs-manifest.tsv).

## Add the upstream remote to a local clone

Git remotes are local Git configuration; GitHub does not store a persistent `upstream` remote for an independent repository. Run these commands in each local clone:

```bash
git remote add upstream https://github.com/BaaRai/ARTEX.git
git fetch upstream --prune --tags
git fetch origin source/main:refs/remotes/origin/source/main
```

Compare the imported snapshot with upstream:

```bash
git log --oneline --left-right origin/source/main...upstream/main
git diff --stat origin/source/main...upstream/main
```

Do not merge upstream changes directly into the Android or MCP implementation branches. Review the upstream diff, identify conflicts and behavioral changes, then integrate deliberately through a pull request.

## Automated upstream drift check

The `.github/workflows/upstream-check.yml` workflow checks the upstream `main` commit on a weekly schedule and on manual dispatch. It reports drift; it does not merge, push, or overwrite any branch.

## Preserving the source

- Do not commit implementation changes to `source/main`.
- The original import refs are frozen by the manifest. Updating the snapshot requires a deliberate, reviewed manifest refresh.
- `main` is the integration point for repository-level configuration and subsequent reviewed work.
