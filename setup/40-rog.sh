#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
source "${ROOT_DIR}/bash/lib.sh"

print_title "Install ROG apps phase"
require_pacman

# Import keys
run sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
run sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35

# Add repo g14 (append once)
append_once "" /etc/pacman.conf
append_once "[g14]" /etc/pacman.conf
append_once "Server = https://arch.asus-linux.org" /etc/pacman.conf

# Refresh
ensure_pkg sudo pacman -Suy --noconfirm

# Core packages
ensure_pkg sudo pacman -S --needed --noconfirm \
  asusctl supergfxctl rog-control-center power-profiles-daemon switcheroo-control

# Enable services
enable_service_now power-profiles-daemon
enable_service_now supergfxd
enable_service_now switcheroo-control

ok "ROG apps installed and services enabled."