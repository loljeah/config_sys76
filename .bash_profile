# ~/.bash_profile - Login shell configuration

# Source .bashrc if it exists (for interactive login shells)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# SSH agent via keychain - persists across sessions, auto-loads keys
# Add key names to load automatically (without path), e.g.: keychain --quiet id_ed25519 github_key
if command -v keychain &> /dev/null; then
    eval "$(keychain --eval --quiet)"
fi

# Auto-start Sway on TTY1 after login
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec sway
fi
