#!/usr/bin/env bash
set -Eeuo pipefail

# Tạo file theme tạm và auto dọn khi shell kết thúc
THEME_FILE="$(mktemp -t dialog-theme.XXXXXX)"
_theme_cleanup() { rm -f "$THEME_FILE" 2>/dev/null || true; }
trap _theme_cleanup EXIT

_write_theme() {
  # $1 = style
  case "${1:-default}" in
    default)
      cat >"$THEME_FILE" <<'EOF'
use_shadow = no
use_colors = yes
screen_color = (WHITE,BLUE,ON)
border_color = (WHITE,BLUE,ON)
title_color  = (WHITE,BLUE,ON)
dialog_color = (WHITE,BLACK,OFF)
item_color   = (CYAN,BLACK,OFF)
item_selected_color = (BLACK,CYAN,ON)
button_active_color   = (WHITE,BLUE,ON)
button_inactive_color = (WHITE,BLACK,ON)
button_key_active_color   = (YELLOW,BLUE,ON)
button_key_inactive_color = (YELLOW,BLACK,ON)
checkbox_color = (CYAN,BLACK,OFF)
checkbox_selected_color = (BLACK,CYAN,ON)
EOF
      ;;
    dracula)
      cat >"$THEME_FILE" <<'EOF'
use_shadow = no
use_colors = yes
screen_color = (WHITE,BLACK,ON)
border_color = (MAGENTA,BLACK,ON)
title_color  = (MAGENTA,BLACK,ON)
dialog_color = (WHITE,BLACK,OFF)
item_color   = (CYAN,BLACK,OFF)
item_selected_color = (BLACK,MAGENTA,ON)
button_active_color   = (WHITE,MAGENTA,ON)
button_inactive_color = (WHITE,BLACK,ON)
button_key_active_color   = (YELLOW,MAGENTA,ON)
button_key_inactive_color = (YELLOW,BLACK,ON)
checkbox_color = (CYAN,BLACK,OFF)
checkbox_selected_color = (BLACK,CYAN,ON)
EOF
      ;;
    solarized-dark)
      cat >"$THEME_FILE" <<'EOF'
use_shadow = no
use_colors = yes
screen_color = (WHITE,BLACK,ON)
border_color = (YELLOW,BLACK,ON)
title_color  = (YELLOW,BLACK,ON)
dialog_color = (WHITE,BLACK,OFF)
item_color   = (CYAN,BLACK,OFF)
item_selected_color = (BLACK,YELLOW,ON)
button_active_color   = (BLACK,YELLOW,ON)
button_inactive_color = (WHITE,BLACK,ON)
button_key_active_color   = (BLACK,YELLOW,ON)
button_key_inactive_color = (YELLOW,BLACK,ON)
checkbox_color = (CYAN,BLACK,OFF)
checkbox_selected_color = (BLACK,CYAN,ON)
EOF
      ;;
    light)
      cat >"$THEME_FILE" <<'EOF'
use_shadow = no
use_colors = yes
screen_color = (BLACK,WHITE,ON)
border_color = (BLACK,WHITE,ON)
title_color  = (BLACK,WHITE,ON)
dialog_color = (BLACK,WHITE,OFF)
item_color   = (BLUE,WHITE,OFF)
item_selected_color = (WHITE,BLUE,ON)
button_active_color   = (WHITE,BLUE,ON)
button_inactive_color = (BLACK,WHITE,ON)
button_key_active_color   = (YELLOW,BLUE,ON)
button_key_inactive_color = (YELLOW,WHITE,ON)
checkbox_color = (BLUE,WHITE,OFF)
checkbox_selected_color = (WHITE,BLUE,ON)
EOF
      ;;
    *)
      echo "[theme] Unknown theme: $1 → fallback default" >&2
      _write_theme default
      return
      ;;
  esac
}

# Test nhanh dialog với theme; nếu fail thì bỏ theme
_apply_theme_safely() {
  export DIALOGRC="$THEME_FILE"
  # Test hộp nhỏ; nếu dialog trả về ≠0 thì xem như theme lỗi
  if ! dialog --backtitle "Theme check" --msgbox "Theme loaded OK" 6 30 2>/dev/null; then
    echo "[theme] dialog failed with current theme. Disabling theme." >&2
    unset DIALOGRC
    return 1
  fi
  return 0
}

# API ngoài:
apply_theme() {
  local style="${1:-default}"
  _write_theme "$style"
  _apply_theme_safely || true
}
