#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
source "${ROOT_DIR}/bash/lib.sh"

print_title "Install app for Dual screen phase"
require_pacman
ensure_paru
ensure_pkg paru -S --needed --noconfirm wdisplays
ok "wdisplays installed."
