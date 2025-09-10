#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
source "${ROOT_DIR}/bash/lib.sh"

print_title "NVIDIA driver phase (dracut-based EndeavourOS)"

require_pacman

warn "This will install nvidia-dkms & set nvidia_drm.modeset=1; regenerate initramfs with dracut, then you should reboot."

# 1) Backup grub
run sudo cp /etc/default/grub /etc/default/grub.bak

# 2) Install NVIDIA packages
ensure_pkg sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings

# 3) Edit GRUB_CMDLINE_LINUX_DEFAULT: append nvidia_drm.modeset=1 (idempotent)
GRUB_FILE="/etc/default/grub"
if ! grep -q 'nvidia_drm.modeset=1' "$GRUB_FILE"; then
  notice "Appending nvidia_drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT"
  run sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia_drm.modeset=1"/' "$GRUB_FILE"
else
  ok "GRUB already contains nvidia_drm.modeset=1"
fi

# 4) Update GRUB
ensure_pkg sudo grub-mkconfig -o /boot/grub/grub.cfg

# 5) dracut rebuild (EndeavourOS dùng dracut)
if command -v dracut >/dev/null 2>&1; then
  # Endeavour có tiện ích wrapper: dracut-rebuild (nếu có thì dùng)
  if command -v dracut-rebuild >/dev/null 2>&1; then
    ensure_pkg sudo dracut-rebuild
  else
    # Rebuild default kernel image
    KVER="$(uname -r)"
    notice "Rebuilding initramfs for kernel $KVER via dracut"
    ensure_pkg sudo dracut --force "/boot/initramfs-${KVER}.img" "${KVER}"
  fi
else
  warn "dracut not found. If your system still uses mkinitcpio, rebuild accordingly."
fi

echo
notice "Reboot is recommended. After reboot, check with:"
echo "  lspci -k | grep -EA3 'VGA|3D'"
ok "NVIDIA phase finished."