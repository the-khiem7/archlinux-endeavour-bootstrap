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

safe_clean_dir() {
  local dir="$1"
  # CHỐT AN TOÀN: chỉ cho phép xoá nếu nằm trong $HOME/.cache và đúng tên dự án
  case "$dir" in
    "$HOME/.cache/"*"/archlinux-endeavour-bootstrap") ;;
    "$HOME/.cache/archlinux-endeavour-bootstrap") ;;
    *) echo "[bootstrap] Refuse to clean suspicious path: $dir"; return 1 ;;
  esac

  # Không xoá chính $HOME/.cache, chỉ xoá bên trong thư mục đích
  if [[ -d "$dir" ]]; then
    rm -rf -- "$dir"/* "$dir"/.[!.]* "$dir"/..?* 2>/dev/null || true
  fi
}


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

  # ====== HYBRID LOOP: checklist -> run -> ask to repeat ======
  while :; do
    CHOSEN=()
    have_dialog() { command -v dialog >/dev/null 2>&1; }

    if have_dialog; then
      # Hàm này ở bash/art.sh: fill CHOSEN hoặc exit nếu Cancel
      run_dialog_menu
    else
      # Fallback text menu
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
      read -r -p "Chọn (vd: 1,3,5) | Enter = ALL | q = quit: " PICK
      if [[ "$PICK" =~ ^[qQ]$ ]]; then
        echo "[bootstrap] Quit."; exit 0
      fi
      if [[ -z "${PICK// }" ]]; then
        CHOSEN=(1 2 3 4 5)
      else
        IFS=',' read -r -a CHOSEN <<<"$PICK"
      fi
    fi

    # Run selected phases
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

    # Ask to run again
    if command -v dialog >/dev/null 2>&1; then
      dialog --title "Archlinux Endeavour Bootstrap by TheKhiem7" --yesno "Finished selected phases.\nRun again to pick more?" 8 52
      resp=$?; clear
      [[ $resp -eq 0 ]] && continue || break
    else
      read -r -p "Run again to pick more? [y/N]: " more
      [[ "$more" =~ ^[yY] ]] && continue || break
    fi
  done

  exit 0
  # ====== END HYBRID LOOP ======
  
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
x cd "$INSTALL_DIR"

if [ -d .git ]; then
  # đã là git repo
  git remote get-url origin >/dev/null 2>&1 || x git remote add origin "https://github.com/${REMOTE_REPO}"
  if ! git remote get-url origin | grep -q "$REMOTE_REPO"; then
    echo "[bootstrap] Repo remote khác -> clean và re-init."
    x safe_clean_dir "$INSTALL_DIR"
    x git init -b "$BRANCH"
    x git remote add origin "https://github.com/${REMOTE_REPO}"
  fi
else
  # chưa là git repo -> nếu có rác thì dọn rồi init
  if [ -n "$(ls -A 2>/dev/null || true)" ]; then
    echo "[bootstrap] $INSTALL_DIR not a git repo → cleaning up."
    x safe_clean_dir "$INSTALL_DIR"
  fi
  x git init -b "$BRANCH"
  x git remote add origin "https://github.com/${REMOTE_REPO}"
fi


x git fetch origin "$BRANCH" --depth=1
x git checkout -B "$BRANCH" "origin/$BRANCH"
x git submodule update --init --recursive
echo "$ME: Downloaded."

chmod +x "${INSTALL_DIR}/bootstrap.sh" 2>/dev/null || true

echo "$ME: Running local bootstrap ..."
exec "${INSTALL_DIR}/bootstrap.sh" "$@"