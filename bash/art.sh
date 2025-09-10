run_dialog_menu() {
  TMP_OUT="$(mktemp)"; trap 'rm -f "$TMP_OUT"' EXIT

  # 1) ASCII banner cố định
  BANNER=$(cat <<'EOF'
 _____ _                _     _               _____ 
/__   \ |__   ___  /\ /\ |__ (_) ___ _ __ ___|___  |
  / /\/ '_ \ / _ \/ //_/ '_ \| |/ _ \ '_ ` _ \  / / 
 / /  | | | |  __/ __ \| | | | |  __/ | | | | |/ /  
 \/   |_| |_|\___\/  \/|_| |_|_|\___|_| |_| |_/_/   
                                                    
EOF
)

  # 2) Tính size “responsive” theo banner + terminal
  #   - width >= chiều dài dòng dài nhất + padding
  #   - height đủ chứa banner + text intro + list
  mapfile -t _lines < <(printf "%s\n" "$BANNER")
  maxlen=0; for l in "${_lines[@]}"; do (( ${#l} > maxlen )) && maxlen=${#l}; done

  cols=$(tput cols 2>/dev/null || stty size 2>/dev/null | awk '{print $2}')
  rows=$(tput lines 2>/dev/null || stty size 2>/dev/null | awk '{print $1}')
  (( cols == 0 )) && cols=100
  (( rows == 0 )) && rows=30

  pad=8
  width=$(( maxlen + pad ))
  (( width > cols-4 )) && width=$(( cols-4 ))
  (( width < 70 )) && width=70

  list_h=10
  text_h=$(( ${#_lines[@]} + 3 ))
  height=$(( text_h + list_h + 7 ))
  (( height > rows-2 )) && height=$(( rows-2 ))
  (( height < 20 )) && height=20

  # Nếu banner vẫn dài hơn width, cắt bớt (tránh wrap)
  trimmed_banner=$(printf "%s\n" "$BANNER" | cut -c1-$((width-4)))

  # 3) Build message
  MSG=$(printf "%s\n\nSelect phases (SPACE to toggle, ENTER to confirm):" "$trimmed_banner")

  # 4) Build checklist items
  CHECK_ARGS=(); idx=1
  for item in "${PHASES[@]}"; do
    label="${item##*::}"
    CHECK_ARGS+=("$idx" "$label" "off"); ((idx++))
  done

  # 5) dialog: force output to stdout and capture it
  if dialog --no-collapse \
            --title "Archlinux Endeavour Bootstrap by TheKhiem7" --backtitle "https://github.com/the-khiem7/archlinux-endeavour-bootstrap" \
            --output-fd 1 \
            --separate-output --checklist "$MSG" "$height" "$width" "$list_h" \
            "${CHECK_ARGS[@]}" >"$TMP_OUT" 2>/dev/null
  then
    mapfile -t CHOSEN < "$TMP_OUT"
    echo "[debug] chosen: ${CHOSEN[*]}" >&2
    if ((${#CHOSEN[@]}==0)); then
      echo "[bootstrap] No selection. Exiting."
      exit 0
    fi
  else
    echo "[bootstrap] Cancelled."
    exit 0
  fi
}