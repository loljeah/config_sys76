# NixOS Sway Migration - Installation Guide

## Files to Update

### System Configuration
```bash
sudo cp configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

### User Configuration Files
```bash
# Create config directories
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/.config/foot
mkdir -p ~/.config/mako
mkdir -p ~/.config/kanshi
mkdir -p ~/.config/hypr
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/.local/share/wallpapers/nasa

# Copy configs
cp sway-config ~/.config/sway/config
cp waybar-config ~/.config/waybar/config
cp waybar-style.css ~/.config/waybar/style.css
cp foot.ini ~/.config/foot/foot.ini
cp mako-config ~/.config/mako/config
cp kanshi-config ~/.config/kanshi/config
cp hyprlock.conf ~/.config/hypr/hyprlock.conf

# NASA wallpaper script
cp nasa-wallpaper ~/.local/bin/nasa-wallpaper
chmod +x ~/.local/bin/nasa-wallpaper

# Auto-start sway on TTY1
cat >> ~/.bash_profile << 'BASH'
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec sway
fi
BASH
```

---

## Cyberpunk Lock Screen (Hyprlock)

Neon-noir aesthetic with:
- Blurred screenshot background (darkened)
- Large cyan neon digital clock with glow
- Magenta accent seconds display
- Cyan neon password input field
- "SYSTEM LOCKED" header
- Decorative tech elements (system stats, network status)

### Keybinding
| Key | Action |
|-----|--------|
| Super + Escape | Lock screen |

### Color Scheme
| Element | Color |
|---------|-------|
| Primary | Cyan `#00ffff` |
| Accent | Magenta `#ff00ff` |
| Success | Green `#00ff00` |
| Error | Hot pink `#ff0055` |
| Warning | Orange `#ffaa00` |

---

## All Files Summary

| File | Destination |
|------|-------------|
| `configuration.nix` | `/etc/nixos/configuration.nix` |
| `sway-config` | `~/.config/sway/config` |
| `waybar-config` | `~/.config/waybar/config` |
| `waybar-style.css` | `~/.config/waybar/style.css` |
| `foot.ini` | `~/.config/foot/foot.ini` |
| `mako-config` | `~/.config/mako/config` |
| `kanshi-config` | `~/.config/kanshi/config` |
| `hyprlock.conf` | `~/.config/hypr/hyprlock.conf` |
| `nasa-wallpaper` | `~/.local/bin/nasa-wallpaper` (chmod +x) |

---

## Troubleshooting

### Hyprlock doesn't accept password
```bash
# Check PAM config
grep hyprlock /etc/pam.d/*
```
Ensure `security.pam.services.hyprlock = {};` is in configuration.nix

### Clock/stats not updating
The `cmd[update:N]` syntax runs commands every N milliseconds. Ensure the commands work in your shell.

---

## USB/External Drive RW Mounting

The configuration now includes comprehensive support for mounting external drives with read-write access:

### What's configured

| Component | Purpose |
|-----------|---------|
| `services.udisks2` | Disk management with proper mount options |
| `services.gvfs` | Virtual filesystem for Thunar integration |
| `udiskie` | Tray icon + automount + notifications |
| `polkit rules` | Passwordless mount/unmount for wheel group |
| `udev rules` | Proper device permissions |
| `programs.fuse.userAllowOther` | Allow user FUSE mounts |
| `boot.supportedFilesystems` | NTFS, exFAT, ext4, btrfs support |
| `ntfs3` kernel module | Native in-kernel NTFS write support |

### User groups

Your user is now in these groups:
- `wheel` - Admin, passwordless mounts
- `storage` - Storage device access
- `users` - General user group
- `plugdev` - Pluggable device access

### New packages

| Package | Purpose |
|---------|---------|
| `ntfs3g` | NTFS userspace driver (fallback) |
| `exfatprogs` | exFAT filesystem tools |
| `fuse3` | FUSE support |
| `mtpfs` / `jmtpfs` | Android phone MTP access |

### Udiskie config file

```bash
mkdir -p ~/.config/udiskie
cp udiskie-config.yml ~/.config/udiskie/config.yml
```

### Troubleshooting RO mounts

If drives still mount as read-only:

1. **Check filesystem errors:**
   ```bash
   # For NTFS (Windows was not shut down properly)
   sudo ntfsfix /dev/sdX1
   
   # Force mount RW
   sudo mount -o rw,remount /media/DRIVENAME
   ```

2. **Windows Fast Startup** - If NTFS drive was used with Windows:
   - Boot Windows → Disable "Fast Startup" in Power Options
   - Or: Fully shut down Windows (not hibernate)

3. **Manual mount with options:**
   ```bash
   # NTFS
   sudo mount -t ntfs3 -o rw,uid=1000,gid=100 /dev/sdX1 /mnt/usb
   
   # exFAT
   sudo mount -t exfat -o rw,uid=1000,gid=100 /dev/sdX1 /mnt/usb
   ```

4. **Check mount status:**
   ```bash
   mount | grep /media
   # Look for 'rw' in the options
   ```

5. **Restart udiskie after config change:**
   ```bash
   pkill udiskie
   udiskie --automount --notify --tray --file-manager thunar &
   ```
