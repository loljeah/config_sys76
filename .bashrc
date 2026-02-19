# ~/.bashrc - Interactive non-login shell configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Enable programmable completion
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Load aliases
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# SSH agent is managed by NixOS (programs.ssh.startAgent)
# Keys are auto-added on first use via AddKeysToAgent

# Idle timeout - auto logout after 15 minutes of inactivity
TMOUT=900

# Prompt (simple, functional)
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
