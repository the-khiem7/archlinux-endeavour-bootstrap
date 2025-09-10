#!/usr/bin/env bash
set -euo pipefail

# Flags có thể set qua env: DRY_RUN=true NO_CONFIRM=true
DRY_RUN="${DRY_RUN:-false}"
NO_CONFIRM="${NO_CONFIRM:-false}"

# ===== UI =====
_color() { printf "\e[%sm" "$1"; }
nc() { _color "0"; }
cblue() { _color "34"; }
cgreen() { _color "32"; }
cred() { _color "31"; }
cyellow() { _color "33"; }
ccyan() { _color "36"; }
cbold() { _color "1"; }

print_title() { echo -e "$(cbold)$(ccyan)=== $* ===$(nc)"; }
print_step()  { echo -e "$(cblue)> $*$(nc)"; }
ok()          { echo -e "$(cgreen)✔ $*$(nc)"; }
warn()        { echo -e "$(cyellow)! $*$(nc)"; }
err()         { echo -e "$(cred)✘ $*$(nc)"; }
notice()      { echo -e "$(ccyan)- $*$(nc)"; }
print_done()  { echo -e "$(cgreen)=== $* ===$(nc)"; }

ask_yes_no() {
  local msg="$1"
  if [[ "${NO_CONFIRM}" == "true" ]]; then
    return 0
  fi
  read -r -p "$msg [y/N]: " ans
  [[ "$ans" =~ ^[yY](es)?$ ]]
}

run() {
  # run "cmd" [args...]
  echo -e "$(cbold)\$ $*$(nc)"
  if [[ "${DRY_RUN}" == "true" ]]; then
    return 0
  fi
  if [[ "${NO_CONFIRM}" != "true" ]]; then
    ask_yes_no "Execute?" || { warn "Skipped."; return 0; }
  fi
  "$@"
}

require_pacman() {
  command -v pacman >/dev/null 2>&1 || {
    err "pacman not found. This repo is for Arch/Arch-based only."
    exit 1
  }
}

ensure_pkg() {
  # ensure_pkg sudo pacman -S pkgA pkgB ...
  # hoặc ensure_pkg yay -S something
  run "$@"
}

ensure_yay() {
  if ! command -v yay >/dev/null 2>&1; then
    print_step "Installing yay (AUR helper)"
    run sudo pacman -S --needed --noconfirm base-devel git
    run bash -c 'tmpdir="$(mktemp -d)"; cd "$tmpdir"; git clone https://aur.archlinux.org/yay.git; cd yay; makepkg -si --noconfirm'
  else
    ok "yay found."
  fi
}

ensure_paru() {
  if ! command -v paru >/dev/null 2>&1; then
    print_step "Installing paru (AUR helper)"
    run sudo pacman -S --needed --noconfirm base-devel git
    run bash -c 'tmpdir="$(mktemp -d)"; cd "$tmpdir"; git clone https://aur.archlinux.org/paru.git; cd paru; makepkg -si --noconfirm'
  else
    ok "paru found."
  fi
}

enable_service_now() {
  # enable_service_now systemd-unit [--user]
  local unit="$1"; shift || true
  run sudo systemctl enable --now "$unit"
}

enable_service_now_user() {
  local unit="$1"
  run systemctl --user enable --now "$unit"
}

append_once() {
  # append_once "line" file
  local line="$1" file="$2"
  grep -Fqx -- "$line" "$file" 2>/dev/null || echo "$line" | run sudo tee -a "$file" >/dev/null
}