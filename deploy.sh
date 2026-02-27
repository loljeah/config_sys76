#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
#  deploy.sh  –  copy config_home files to their live locations
#
#  Usage:
#      bash deploy.sh
#
#  configuration.nix is intentionally excluded — it requires
#  sudo + nixos-rebuild and is printed as a manual reminder.
# ──────────────────────────────────────────────────────────────────
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── colour helpers ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { printf "${GREEN}  [ok]${NC}  %s\n" "$*"; }
warn() { printf "${YELLOW}  [!]${NC}  %s\n" "$*"; }
err()  { printf "${RED} [!!]${NC}  %s\n" "$*"; }

ERRORS=0

# ── deploy: mkdir -p then cp ─────────────────────────────────────
deploy() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
        err "missing: $src"
        ERRORS=$((ERRORS + 1))
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    ok "$src  →  $dst"
}

# ──────────────────────────────────────────────────────────────────
#  User config files
# ──────────────────────────────────────────────────────────────────
printf "\n── User configs ───────────────────────────────────────────\n"

deploy  sway-config           ~/.config/sway/config
deploy  waybar-config         ~/.config/waybar/config
deploy  style.css             ~/.config/waybar/style.css
deploy  foot.ini              ~/.config/foot/foot.ini
deploy  mako-config           ~/.config/mako/config
deploy  hyprlock.conf         ~/.config/hypr/hyprlock.conf
deploy  config                ~/.config/hypr/config
deploy  udiskie-config.yml    ~/.config/udiskie/config.yml
deploy  init.lua              ~/.config/nvim/init.lua

# GTK theme settings (consistent look across apps)
deploy  gtk-3.0-settings.ini  ~/.config/gtk-3.0/settings.ini
deploy  gtk-4.0-settings.ini  ~/.config/gtk-4.0/settings.ini

# XDG portal config (fixes oversized file dialogs)
deploy  sway-portals.conf     ~/.config/xdg-desktop-portal/sway-portals.conf

# Kanshi display profile manager
deploy  kanshi-config         ~/.config/kanshi/config

# Firejail global rules (SSH/GPG protection for ALL sandboxed apps)
deploy  firejail-globals.local ~/.config/firejail/globals.local

# ──────────────────────────────────────────────────────────────────
#  Executable scripts
# ──────────────────────────────────────────────────────────────────
printf "\n── Executables ────────────────────────────────────────────\n"

deploy  netinfo               ~/.local/bin/netinfo
chmod +x ~/.local/bin/netinfo 2>/dev/null && ok "chmod +x  ~/.local/bin/netinfo"

deploy  waybar-notes          ~/.local/bin/waybar-notes
chmod +x ~/.local/bin/waybar-notes 2>/dev/null && ok "chmod +x  ~/.local/bin/waybar-notes"

deploy  yubikey-idle-check.sh ~/.local/bin/yubikey-idle-check.sh
chmod +x ~/.local/bin/yubikey-idle-check.sh 2>/dev/null && ok "chmod +x  ~/.local/bin/yubikey-idle-check.sh"

# ──────────────────────────────────────────────────────────────────
#  Standard directories
# ──────────────────────────────────────────────────────────────────
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/3DPrinting
# Notes files are in ~ (notes.md, todos.md)
mkdir -p ~/Documents
mkdir -p ~/Videos
mkdir -p ~/Music
mkdir -p ~/Calibre\ Library

# ──────────────────────────────────────────────────────────────────
#  Shell config files
# ──────────────────────────────────────────────────────────────────
printf "\n── Shell config ───────────────────────────────────────────\n"

deploy  .bashrc               ~/.bashrc
deploy  .bash_profile         ~/.bash_profile
deploy  .bash_aliases         ~/.bash_aliases

# Restrict shell configs to owner only (prevent info disclosure)
chmod 600 ~/.bashrc ~/.bash_profile ~/.bash_aliases 2>/dev/null && ok "chmod 600  shell configs"

# ──────────────────────────────────────────────────────────────────
#  NixOS system config  (needs sudo — manual step)
# ──────────────────────────────────────────────────────────────────
printf "\n── NixOS system config (manual) ───────────────────────────\n"

if [[ -f configuration.nix ]]; then
    warn "run these yourself:"
    warn "    sudo cp configuration.nix undervolt.nix /etc/nixos/"
    warn "    sudo nixos-rebuild switch"
fi

# ──────────────────────────────────────────────────────────────────
#  Cursor theme (green with purple outline)
# ──────────────────────────────────────────────────────────────────
printf "\n── Cursor theme ───────────────────────────────────────────\n"

if [[ -x generate-cyber-cursor.sh ]]; then
    if command -v xcursorgen >/dev/null 2>&1 && command -v magick >/dev/null 2>&1; then
        if ./generate-cyber-cursor.sh; then
            ok "cyber-cursor theme generated"
        else
            warn "cursor theme generation failed (run manually after nixos-rebuild)"
        fi
    else
        warn "xcursorgen or magick (imagemagick) not found — run after: sudo nixos-rebuild switch"
        warn "then run: ./generate-cyber-cursor.sh"
    fi
else
    warn "generate-cyber-cursor.sh not found"
fi

# ──────────────────────────────────────────────────────────────────
#  Reload compositor + display profiles
# ──────────────────────────────────────────────────────────────────
printf "\n── Reloading ──────────────────────────────────────────────\n"

if swaymsg reload 2>/dev/null; then
    ok "swaymsg reload"
else
    warn "swaymsg reload failed (sway not running?)"
fi

if pkill -HUP kanshi 2>/dev/null; then
    ok "kanshi reloaded"
else
    warn "kanshi not running (will start on next sway session)"
fi

# ──────────────────────────────────────────────────────────────────
#  Summary
# ──────────────────────────────────────────────────────────────────
printf "\n"
if [[ $ERRORS -eq 0 ]]; then
    ok "All files deployed."
else
    err "$ERRORS source file(s) missing — see warnings above"
    exit 1
fi
