# ARTEX-Mobile porting change log

This file records changes made for the independent Android/cloud adaptation. It is separate from the upstream project's `CHANGELOG.md`.

## 2026-11-20 — Repository foundation

- Imported the upstream Git history into the independent repository `Mohamed2820/ARTEX-Mobile`; verified `fork=false`.
- Compared all imported refs against `BaaRai/ARTEX`: 184 branch refs and 4 tag refs had identical names and object IDs at the time of verification.
- Preserved the AGPL-3.0 license and upstream notices.
- Created `source/main` as an untouched snapshot branch at `ab40834567475c449bb34f84a9aa50a6587cb471`.
- Created separate branches: `development`, `android-port`, `integration/mcp`, and `cloud-runtime`.
- Added an upstream reference manifest, synchronization instructions, repository governance, integrity workflow and upstream drift workflow.
- Security review is limited to repository/workflow configuration and non-destructive checks; no third-party target was scanned or exploited.
