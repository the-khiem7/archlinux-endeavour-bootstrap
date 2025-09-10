#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
source "${ROOT_DIR}/bash/lib.sh"

print_title "Install essential apps phase"
require_pacman

# Bạn muốn cả yay và paru
ensure_yay
ensure_paru

# Dùng paru để cài list bạn cần
# Lưu ý: một số package AUR có thể đổi tên theo thời gian.
ensure_pkg paru -S --needed --noconfirm \
  zen-browser-bin \
  zalo-macos \
  visual-studio-code-bin \
  vesktop-bin \
  openai-codex-bin \
  onlyoffice-bin \
  octopi \
  obs-studio-git \
  notion-app-electron \
  neofetch \
  gemini-cli \
  cursor-bin

ok "Essential apps installed."
