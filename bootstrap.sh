#!/usr/bin/env bash
# Smart bootstrap: chạy được cả online (clone về) *và* local (TUI) trong 1 file.
set -Eeuo pipefail

ME="-->online-setup<--"
# Nhớ sửa đúng repo bạn nhé:
REMOTE_REPO="the-khiem7/archlinux-endeavour-bootstrap"   # ví dụ: user/repo
BRANCH="main"
INSTALL_DIR="${HOME}/.cache/${REMOTE_REPO##*/}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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
# LOCAL MODE (trong repo) – chạy TUI phase, KHÔNG clone
# =========================
if [[ "$IN_REPO_LOCAL" == "true" && "${BOOTSTRAP_ONLINE:-}" != "1" ]]; then
  # TUI local (giữ code TUI ngắn gọn; bạn đã có các file trong setup/ & bash/lib.sh)
  source "${SCRIPT_DIR}/bash/lib.sh"

  print_title "Bootstrap (LOCAL MODE)"
  notice "DRY_RUN=${DRY_RUN:-false} | NO_CONFIRM=${NO_CONFIRM:-false}"

  PHASES=(
    "10-network.sh::Network installing phase"
    "20-essential.sh::Install essential apps phase"
    "30-dualscreen.sh::Install app for Dual screen phase"
    "40-rog.sh::Install ROG apps phase"
    "50-nvidia.sh::NVIDIA driver phase"
  )

  # Nếu có dialog dùng checklist, không thì fallback
  if command -v dialog >/dev/null 2>&1; then
    TMP_OUT="$(mktemp)"; trap 'rm -f "$TMP_OUT"' EXIT
    CHECK_ARGS=(); idx=1
    for item in "${PHASES[@]}"; do
      label="${item##*::}"
      CHECK_ARGS+=("$idx" "$label" "off"); ((idx++))
done
    dialog --separate-output --checklist "Select phases (SPACE to toggle, ENTER to confirm):" 20 80 10 \
      "${CHECK_ARGS[@]}" 2> "$TMP_OUT" || { warn "Cancelled."; exit 1; }
    mapfile -t CHOSEN < "$TMP_OUT"
    if ((${#CHOSEN[@]}==0)); then
      ask_yes_no "No phase selected. Run ALL phases?" && CHOSEN=(1 2 3 4 5) || { warn "Nothing to do."; exit 0; }
    fi
  else
    echo; echo "Phases:"; idx=1
    for item in "${PHASES[@]}"; do label="${item##*::}"; printf "  %d) %s\n" "$idx" "$label"; ((idx++)); done
    echo; read -r -p "Chọn (vd: 1,3,5) | Enter = ALL: " PICK
    if [[ -z "${PICK// }" ]]; then CHOSEN=(1 2 3 4 5); else IFS=',' read -r -a CHOSEN <<<"$PICK"; fi
  fi

  SORTED=($(printf "%s\n" "${CHOSEN[@]}" | sed 's/[^0-9]//g' | awk 'NF' | sort -n | uniq))
  for n in "${SORTED[@]}"; do
    i=$((n-1)); (( i>=0 && i<${#PHASES[@]} )) || { warn "Skip invalid index: $n"; continue; }
    file="${PHASES[$i]%%::*}"; label="${PHASES[$i]##*::}"
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

# Chặn case bạn quên đổi placeholder
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

# đảm bảo file thực thi
chmod +x "${INSTALL_DIR}/bootstrap.sh" 2>/dev/null || true

echo "$ME: Running local bootstrap ..."
# Đặt cờ để nhánh LOCAL biết là từ online (tránh tự clone nữa)
export BOOTSTRAP_ONLINE=1
# Pass-through flags nếu bạn muốn:
# export DRY_RUN=${DRY_RUN:-false}
# export NO_CONFIRM=${NO_CONFIRM:-false}
exec "${INSTALL_DIR}/bootstrap.sh" "$@"
