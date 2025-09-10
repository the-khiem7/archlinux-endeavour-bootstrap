#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
source "${ROOT_DIR}/bash/lib.sh"

print_title "Network installing phase"
require_pacman
ensure_pkg sudo pacman -S --needed --noconfirm network-manager-applet nm-connection-editor
ok "Network tools installed."
