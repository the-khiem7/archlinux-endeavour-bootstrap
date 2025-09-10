#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ME="-->online-setup<--"
REMOTE_REPO="the-khiem7/archlinux-endeavour-bootstrap"   # đổi nếu cần
BRANCH="main"
INSTALL_DIR="${HOME}/.cache/${REMOTE_REPO##*/}"

# Xác định đang trong repo (LOCAL MODE)
IN_REPO_LOCAL="false"
[[ -d "${SCRIPT_DIR}/setup" && -f "${SCRIPT_DIR}/bash/lib.sh" ]] && IN_REPO_LOCAL="true"

have() { command -v "$1" >/dev/null 2>&1; }
try() { "$@" || sleep 0; }
x() {
  if "$@"; then cmdstatus=0; else cmdstatus=1; fi
  while [ "$cmdstatus" = 1 ]; do
    echo -e "\e[31m$ME: Command \"\e[32m$*\e[31m\" failed.\e[0m"
    echo "  r = Repeat (DEFAULT)"
    echo "  e = Exit"
    read -r -p " [R/e]: " p
    case "$p" in
      [eE]) echo -e "\e[34m$ME: Exit.\e[0m"; break ;;
      *)    echo -e "\e[34m$ME: Repeating...\e[0m"
            if "$@"; then cmdstatus=0; else cmdstatus=1; fi ;;
    esac
  done
  case "$cmdstatus" in
    0) echo -e "\e[34m$ME: \"\e[32m$*\e[34m\" finished.\e[0m" ;;
    1) echo -e "\e[31m$ME: \"\e[32m$*\e[31m\" failed. Exiting...\e[0m"; exit 1 ;;
  esac
}

arch_guard() {
  have pacman || { echo "\"pacman\" not found. Arch(-based) only. Aborting..."; exit 1; }
}
ensure_net_tools() {
  if ! have curl && ! have wget; then
    echo -e "\e[33m$ME: curl/wget not found → installing curl\e[0m"
    x sudo pacman -S --needed --noconfirm curl
  fi
}
ensure_git() {
  if ! have git; then
    echo -e "\e[33m$ME: git not found → installing git & base-devel\e[0m"
    x sudo pacman -S --needed --noconfirm git base-devel
  fi
}

# =========================
# LOCAL MODE – chạy TUI phase, KHÔNG clone
# =========================
if [[ "$IN_REPO_LOCAL" == "true" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/bash/lib.sh"
  source "${SCRIPT_DIR}/bash/art.sh"

  print_title "Bootstrap (LOCAL MODE)"
  notice "DRY_RUN=${DRY_RUN:-false} | NO_CONFIRM=${NO_CONFIRM:-false}"

  PHASES=(
    "10-network.sh::Network installing phase"
    "20-essential.sh::Install essential apps phase"
    "30-dualscreen.sh::Install app for Dual screen phase"
    "40-rog.sh::Install ROG apps phase"
    "50-nvidia.sh::NVIDIA driver phase"
  )

  # ===== Phase selection w/ optional dialog install =====
  CHOSEN=()

  have_dialog() { command -v dialog >/dev/null 2>&1; }

  run_dialog_menu

  run_text_menu() {
    echo
    echo "dialog not installed -> using text menu"
    echo "Phases:"
    idx=1
    for item in "${PHASES[@]}"; do
      label="${item##*::}"
      printf "  %d) %s\n" "$idx" "$label"
      ((idx++))
    done
    echo
    read -r -p "Chọn (vd: 1,3,5) | Enter = ALL: " PICK
    if [[ -z "${PICK// }" ]]; then
      CHOSEN=(1 2 3 4 5)
    else
      IFS=',' read -r -a CHOSEN <<<"$PICK"
    fi
  }

  if have_dialog; then
    run_dialog_menu
  else
    echo
    echo "'dialog' is not installed."
    read -r -p "Install 'dialog' now for nicer TUI? [Y/n]: " _ans
    case "$_ans" in
      [nN]*)
        run_text_menu
        ;;
      *)
        if x sudo pacman -S --needed --noconfirm dialog; then
          run_dialog_menu
        else
          echo "[bootstrap] Failed to install 'dialog' -> falling back to text menu."
          run_text_menu
        fi
        ;;
    esac
  fi
  # ===== end phase selection =====

  # === run selected phases ===
  SORTED=($(printf "%s\n" "${CHOSEN[@]}" | sed 's/[^0-9]//g' | awk 'NF' | sort -n | uniq))
  if ((${#SORTED[@]}==0)); then
    echo "[bootstrap] Nothing selected. Exiting."
    exit 0
  fi

  for n in "${SORTED[@]}"; do
    i=$((n-1))
    (( i>=0 && i<${#PHASES[@]} )) || { warn "Skip invalid index: $n"; continue; }
    file="${PHASES[$i]%%::*}"
    label="${PHASES[$i]##*::}"
    print_step "[$n] $label"
    bash "${SCRIPT_DIR}/setup/${file}"
    ok "Done: $label"
  done

  print_done "All selected phases finished."
  exit 0
fi

# =========================
# ONLINE MODE – clone repo rồi exec lại (local)
# =========================
arch_guard
if [[ "$REMOTE_REPO" == *"<YOUR_USER>"* || "$REMOTE_REPO" == *"<YOUR_REPO>"* ]]; then
  echo "$ME: Please set REMOTE_REPO correctly (user/repo). Current: '$REMOTE_REPO'"
  exit 1
fi

ensure_net_tools
ensure_git

echo "$ME: Downloading repo to $INSTALL_DIR ..."
x mkdir -p "$INSTALL_DIR"
x rm -rf "${INSTALL_DIR}/.git" || true
x cd "$INSTALL_DIR"

if [ -z "$(ls -A 2>/dev/null || true)" ]; then
  x git init -b "$BRANCH"
  x git remote add origin "https://github.com/${REMOTE_REPO}"
else
  if [ ! -d .git ]; then
    echo "Dir \"$INSTALL_DIR\" is not empty and not a git repo. Aborting..."
    exit 1
  fi
  git remote get-url origin >/dev/null 2>&1 || x git remote add origin "https://github.com/${REMOTE_REPO}"
  if ! git remote get-url origin | grep -q "$REMOTE_REPO"; then
    echo "Dir \"$INSTALL_DIR\" is a git repo but not $REMOTE_REPO. Aborting..."
    exit 1
  fi
fi

x git fetch origin "$BRANCH" --depth=1
x git checkout -B "$BRANCH" "origin/$BRANCH"
x git submodule update --init --recursive
echo "$ME: Downloaded."

chmod +x "${INSTALL_DIR}/bootstrap.sh" 2>/dev/null || true

echo "$ME: Running local bootstrap ..."
exec "${INSTALL_DIR}/bootstrap.sh" "$@"