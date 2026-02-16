# ~/.bash_aliases - Shell aliases

# ls with color, human sizes, and classification
alias ls='ls --color=auto -hF'
alias ll='ls -la'
alias la='ls -A'

# grep with color and line numbers
alias grep='grep -i --color=auto -n'

# df/du human-readable by default
alias df='df -h'
alias du='du -h'

# git create repo from foldername
alias gitinit='git init && git remote add origin "git@github.com:loljeah/$(basename "$PWD").git"'
alias gitpush='git add . && git commit && git push -u origin main'
alias firefox='librewolf'

# NASA Wallpaper aliases
alias wallpaper='~/.local/bin/nasa-wallpaper'
alias wallpaper-new='~/.local/bin/nasa-wallpaper random'
alias wallpaper-loop='~/.local/bin/nasa-wallpaper loop &'
alias wallpaper-local='~/.local/bin/nasa-wallpaper local &'
alias wallpaper-count='~/.local/bin/nasa-wallpaper count'

# Reload sway & kanshi
alias wreload='swaymsg reload && pkill -HUP kanshi 2>/dev/null'

#microtik serial
alias microtik='minicom -D /dev/ttyUSB0 -b 115200'

# Reinit PipeWire audio (fix missing devices)
alias reinitsound='wpctl set-profile 53 1 && echo "Audio reinitialized"'

# Quick Power Presets (use case scenarios)
# Coffee shop - no outlet, max battery life
alias power-coffeeshop='sudo system76-power charge-thresholds --profile full_charge && sudo system76-power profile battery && gpu-force-off && echo "☕ Coffee shop: battery profile, 100% charge, dGPU off | 8-10 hours"'

# Daily office - plugged in most of day, preserve battery health
alias power-office='sudo system76-power charge-thresholds --profile max_lifespan && sudo system76-power profile balanced && echo "🏢 Office: balanced profile, 60% charge limit | Battery stays healthy"'

# Gaming - maximum performance, keep plugged in
alias power-gaming='sudo system76-power charge-thresholds --profile full_charge && sudo system76-power profile performance && echo "🎮 Gaming: performance profile, 100% charge | Keep plugged in!"'

# Video editing / 3D rendering - performance with nvidia-offload
alias power-video='sudo system76-power charge-thresholds --profile full_charge && sudo system76-power profile performance && echo "🎬 Video/3D: performance profile, 100% charge | Use: gpu-run <app>"'

# Presentation - silent operation, no fan noise
alias power-present='sudo system76-power charge-thresholds --profile balanced && sudo system76-power profile battery && gpu-force-off && echo "📊 Presentation: battery profile, 90% charge, dGPU off | Silent"'

# Travel - flight/train, maximum runtime
alias power-travel='sudo system76-power charge-thresholds --profile full_charge && sudo system76-power profile battery && gpu-force-off && echo "✈️  Travel: battery profile, 100% charge, dGPU off | 10+ hours"'

# Compiling - all 24 cores at max
alias power-compile='sudo system76-power profile performance && echo "🔨 Compile: performance profile, all 24 cores | Keep plugged in"'

# Overnight - plugged in long term, max battery lifespan
alias power-overnight='sudo system76-power charge-thresholds --profile max_lifespan && sudo system76-power profile balanced && echo "🌙 Overnight: balanced profile, 60% charge | 3-4x battery lifespan"'

# System76 Power Profiles
alias power='system76-power profile'
alias power-bat='sudo system76-power profile battery && echo "🔋 Battery profile active"'
alias power-bal='sudo system76-power profile balanced && echo "⚖️  Balanced profile active"'
alias power-perf='sudo system76-power profile performance && echo "🚀 Performance profile active"'
alias power-status='system76-power profile && echo "" && system76-power charge-thresholds'

# System76 Charge Thresholds (battery longevity)
alias charge-full='sudo system76-power charge-thresholds --profile full_charge && echo "Charge: 100%"'
alias charge-balanced='sudo system76-power charge-thresholds --profile balanced && echo "Charge: 90%"'
alias charge-health='sudo system76-power charge-thresholds --profile max_lifespan && echo "Charge: 60% (max lifespan)"'

# GPU control (Wayland/PRIME offload mode)
# Note: system76-power graphics switching requires X11, not available on pure Wayland
# Instead, use nvidia-offload for apps and check power state directly
alias gpu-status='echo "GPU Power State:" && cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status && echo "" && nvidia-smi --query-gpu=name,power.draw,temperature.gpu --format=csv,noheader 2>/dev/null || echo "dGPU suspended (off)"'
alias gpu-wake='nvidia-smi -q > /dev/null && echo "dGPU woken" && gpu-status'
alias gpu-sleep='echo "dGPU will sleep automatically when not in use"'
alias gpu-run='nvidia-offload'

# Force dGPU off (requires root, use if stuck active)
alias gpu-force-off='echo auto | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control && echo "Forced auto power management"'
