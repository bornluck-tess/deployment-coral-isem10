# deployment-coral-isem10

This repository contains the deployment and integration code for the Coral iSEM10 application.

## Structure

- `CORAL_iSEM10_v2-be/` — Backend services and solutions for Coral iSEM10.
- `CORAL_iSEM10_v2-fe/` — Frontend application for Coral iSEM10.
- `AMLWSVIEW_FE_2024/` — AML witness view frontend application.
- `ISEM-EOD-BATCH-TEST/` — Batch processing and testing components.
- `TxnScreenAPI/` — Transaction screening API project.

## Getting Started

1. Open the workspace in your editor.
2. Review project-specific README files inside each folder for setup and usage details.
3. Use the appropriate solution or package manager for the component you want to work on.

## Repository Sync

- `sync.sh` updates the repository to the latest `master` branch and syncs all Git submodules.
- It clones or refreshes submodules defined in `.gitmodules`, checks out their configured branches, and verifies they are not empty.
- Run it from the repository root with:

```bash
./sync.sh
```

## Notes

- Each subfolder may contain its own documentation and configuration.
- This root README is intended as a quick entry point for the overall repository.

