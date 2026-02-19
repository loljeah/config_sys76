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

# ──────────────────────────────────────────────────────────────────
#  Executable scripts
# ──────────────────────────────────────────────────────────────────
printf "\n── Executables ────────────────────────────────────────────\n"

deploy  netinfo               ~/.local/bin/netinfo
chmod +x ~/.local/bin/netinfo 2>/dev/null && ok "chmod +x  ~/.local/bin/netinfo"

deploy  waybar-todo          ~/.local/bin/waybar-todo
chmod +x ~/.local/bin/waybar-todo 2>/dev/null && ok "chmod +x  ~/.local/bin/waybar-todo"

# ──────────────────────────────────────────────────────────────────
#  Standard directories
# ──────────────────────────────────────────────────────────────────
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/3DPrinting
mkdir -p ~/.local/share/waybar-todo
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
#  Reload compositor + display profiles
# ──────────────────────────────────────────────────────────────────
printf "\n── Reloading ──────────────────────────────────────────────\n"

if swaymsg reload 2>/dev/null; then
    ok "swaymsg reload"
else
    warn "swaymsg reload failed (sway not running?)"
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
