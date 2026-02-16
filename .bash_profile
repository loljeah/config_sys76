# ~/.bash_profile - Login shell configuration

# Source .bashrc if it exists (for interactive login shells)
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Auto-start Sway on TTY1 after login
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec sway
fi
