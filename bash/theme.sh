#!/usr/bin/env bash
# theme.sh - module quản lý theme cho dialog

THEME_FILE="$(mktemp)"
trap 'rm -f "$THEME_FILE"' EXIT

set_theme() {
  local style="${1:-default}"
  case "$style" in
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
      echo "[theme] Unknown theme: $style → fallback default"
      set_theme default
      return
    ;;
  esac
}

apply_theme() {
  local chosen="${1:-default}"
  set_theme "$chosen"
  export DIALOGRC="$THEME_FILE"
}
