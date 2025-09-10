# Repository Guidelines

## Project Structure & Module Organization
- `bootstrap.sh` — single entrypoint. Runs locally (TUI/CLI) or clones this repo to `~/.cache/Endeavour-EndoSetup` and re-executes.
- `bash/lib.sh` — shared helpers for UI, prompts, idempotent ops (`run`, `ensure_pkg`, `append_once`, service helpers).
- `setup/*.sh` — ordered phases executed independently or via the TUI. Naming pattern: `NN-name.sh` (e.g., `10-network.sh`, `50-nvidia.sh`).

## Build, Test, and Development Commands
- Run locally: `./bootstrap.sh` (uses `dialog` if available; falls back to prompts).
- Run a phase directly: `bash setup/20-essential.sh`
- Dry run (print commands only): `DRY_RUN=true ./bootstrap.sh`
- Non-interactive (auto-confirm): `NO_CONFIRM=true ./bootstrap.sh`
- Lint scripts: `shellcheck bash/lib.sh setup/*.sh`
- Format (if installed): `shfmt -w bash/lib.sh setup/*.sh`
Note: Arch/EndeavourOS only; requires `pacman` and may use `sudo`.

## Coding Style & Naming Conventions
- Language: Bash with `#!/usr/bin/env bash` and `set -Eeuo pipefail` (or `-euo` in phases).
- Indentation: 2 spaces; no tabs. Lines <= 100 chars.
- Functions: `lower_snake_case` (e.g., `ensure_paru`, `enable_service_now`).
- Phases: two-digit order + concise kebab label (e.g., `60-audio.sh`). Favor idempotency (guard checks, `append_once`). Use provided wrappers instead of raw commands where possible.

## Testing Guidelines
- Syntax check: `bash -n bash/lib.sh setup/*.sh`
- Static analysis: `shellcheck` (address warnings or add justified `# shellcheck disable=` hints).
- Manual verification: start with `DRY_RUN=true`, then execute in a VM or fresh install. Validate side-effects (services enabled, configs appended) and re-run to confirm idempotency.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat(setup): add audio phase` / `fix(bootstrap): retry fetch`.
- Keep commits focused; explain rationale for system-level changes (GRUB, services). Include sample commands and expected output.
- PRs must include: summary, scope (files/phases affected), testing notes (commands/logs), and any screenshots of dialogs.

## Security & Configuration Tips
- Arch-based only; scripts modify `/etc`, bootloader, and services—review diffs carefully.
- Avoid secrets in scripts. Prefer env vars and prompt where applicable.
- When adding a phase, update `PHASES` in `bootstrap.sh` with a clear label and ensure safe re-runs.