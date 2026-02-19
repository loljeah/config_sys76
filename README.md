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
mkdir -p ~/.config/hypr
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Screenshots

# Copy configs
cp sway-config ~/.config/sway/config
cp waybar-config ~/.config/waybar/config
cp style.css ~/.config/waybar/style.css
cp foot.ini ~/.config/foot/foot.ini
cp mako-config ~/.config/mako/config
cp hyprlock.conf ~/.config/hypr/hyprlock.conf

# Auto-start sway on TTY1
cat >> ~/.bash_profile << 'BASH'
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec sway
fi
BASH
```

---

## Lock Screen (Hyprlock)

Simple lock screen with clock and date display.

### Keybinding
| Key | Action |
|-----|--------|
| Super + Escape | Lock screen |

---

## All Files Summary

| File | Destination |
|------|-------------|
| `configuration.nix` | `/etc/nixos/configuration.nix` |
| `sway-config` | `~/.config/sway/config` |
| `waybar-config` | `~/.config/waybar/config` |
| `style.css` | `~/.config/waybar/style.css` |
| `foot.ini` | `~/.config/foot/foot.ini` |
| `mako-config` | `~/.config/mako/config` |
| `hyprlock.conf` | `~/.config/hypr/hyprlock.conf` |
| `init.lua` | `~/.config/nvim/init.lua` |
| `gtk-3.0-settings.ini` | `~/.config/gtk-3.0/settings.ini` |
| `gtk-4.0-settings.ini` | `~/.config/gtk-4.0/settings.ini` |

### Quick Deploy
```bash
./deploy.sh
```

---

## Browser

Using **Floorp** (Firefox-based) instead of LibreWolf for better performance:
- Native vertical tabs and workspaces
- Built-in privacy features
- Comparable to Firefox performance
- Hardware acceleration works with Intel iHD driver

Launched via firejail for sandboxing.

---

## Neovim

Config: `~/.config/nvim/init.lua`

### Features
- System clipboard integration (Ctrl+C/V work)
- Mouse support
- GUI-style shortcuts (Ctrl+S save, Ctrl+Z undo)
- Cyberpunk dark theme matching Sway
- Relative line numbers

See `neovim.md` for full keybinding reference.

---

## GTK Theme

Apps like pwvucontrol use GTK4. Dark theme is forced via:
- `gtk-theme-name=Adwaita-dark` in GTK settings
- `gsettings` commands in sway autostart
- `gtk-application-prefer-dark-theme=1`

---

## Firejail Sandbox

All high-risk applications run in firejail sandboxes with restricted permissions.

### Sandboxed Applications

| App | Network | Filesystem | Notes |
|-----|---------|------------|-------|
| **Floorp** | Yes | ~/Downloads, ~/Pictures | Browser, read-only gitZ |
| **Thunderbird** | Yes | ~/Downloads | Email client |
| **Signal** | Yes | Minimal | Encrypted messenger |
| **LibreOffice** | No | ~/Documents, ~/Downloads | Office suite |
| **VLC** | No | ~/Videos, ~/Music, /media | Media player |
| **Handbrake** | No | ~/Videos, /media | Video converter |
| **Audacity** | No | ~/Music | Audio editor |
| **GIMP** | No | ~/Pictures | Image editor |
| **imv** | No | Read-only | Image viewer |
| **Zathura** | No | Read-only | PDF viewer |
| **Calibre** | No | ~/Calibre Library | E-book manager |
| **Orca-slicer** | No | ~/3DPrinting | 3D print slicer |
| **qBittorrent** | Yes | ~/Downloads | Torrent client |

### Common Sandbox Flags

| Flag | Purpose |
|------|---------|
| `--caps.drop=all` | Drop all Linux capabilities |
| `--nonewprivs` | Prevent privilege escalation |
| `--noroot` | Block fakeroot/newuidmap |
| `--seccomp` | System call filtering |
| `--net=none` | No network access |
| `--private-tmp` | Isolated /tmp |
| `--whitelist=~/path` | Only allow specific directories |

### Verify Sandbox

```bash
# Check if app is sandboxed
firejail --list

# Test sandbox restrictions
firejail --debug firefox
```

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
