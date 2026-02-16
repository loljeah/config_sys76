# System76 Serval WS 13 (serw13) Power Management Guide

## Real-World Use Cases

### Use Case 1: Working at a Coffee Shop (No Power Outlet)
```bash
# Before leaving home
charge-full           # Charge to 100%
gpu-integrated        # Disable NVIDIA completely
# Reboot required for GPU change

# At coffee shop (automatic, but can verify)
power-status          # Should show "Battery" profile
```
**Expected runtime**: 8-10 hours for coding, browsing, documents

---

### Use Case 2: Daily Office Work (Plugged In Most of Day)
```bash
# One-time setup for battery longevity
charge-health         # Limit charge to 60%
gpu-hybrid            # NVIDIA on-demand
```
**Result**: Battery stays healthy for years, NVIDIA available when needed

---

### Use Case 3: Gaming Session
```bash
# Prepare for gaming
charge-full           # Need full battery as backup
power-perf            # Maximum CPU/GPU performance
nvidia-offload steam  # Launch Steam with NVIDIA
```
**Note**: Keep plugged in - draws 150W+ under full load

---

### Use Case 4: Video Editing / 3D Rendering
```bash
power-perf                    # Full performance
nvidia-offload blender        # Blender with CUDA
nvidia-offload davinci-resolve
```
**Tip**: Monitor temps with `nvtop` during long renders

---

### Use Case 5: Presentation / Meeting
```bash
gpu-integrated        # Disable NVIDIA (reboot)
power-bat             # Silent operation
charge-balanced       # 90% is enough
```
**Result**: Silent laptop, no fan noise during presentation

---

### Use Case 6: Traveling (Flight/Train)
```bash
# Before departure
charge-full           # Maximum runtime
gpu-integrated        # Disable dGPU (reboot)

# During travel - automatic but verify
power-status          # Confirm battery profile
```
**Expected runtime**: 10+ hours light use

---

### Use Case 7: Software Compilation
```bash
power-perf            # All cores at max
# Compiling...
power-bal             # Return to balanced after
```
**Example**: Kernel compilation uses all 24 cores, benefits from performance profile

---

### Use Case 8: Overnight / Extended Plugged-In Use
```bash
charge-health         # 60% max - preserves battery
gpu-hybrid            # Default mode
```
**Why**: Keeping Li-ion at 100% degrades it. 60% = 3-4x longer battery lifespan

---

## Hardware Overview

| Component | Model |
|-----------|-------|
| CPU | Intel Core i9-14900HX (24 cores, 32 threads) |
| dGPU | NVIDIA RTX 4060 Mobile (8GB GDDR6) |
| iGPU | Intel UHD Graphics (integrated) |
| RAM | 32GB DDR5 |
| Firmware | Custom EC with silent fan curve |

---

## Power Profiles

System76 laptops have three power profiles managed by `system76-power`:

### Battery Profile (`power-bat`)
```bash
sudo system76-power profile battery
```
- **CPU**: Powersave governor, turbo disabled
- **GPU**: NVIDIA dGPU powered off (D3 state)
- **Fan curve**: Minimum speed, quiet operation
- **Best for**: Maximum battery life, light tasks (browsing, documents, coding)
- **Expected battery life**: 6-10 hours depending on workload

### Balanced Profile (`power-bal`)
```bash
sudo system76-power profile balanced
```
- **CPU**: Schedutil governor, dynamic turbo
- **GPU**: NVIDIA available on-demand (hybrid mode)
- **Fan curve**: Normal response
- **Best for**: Mixed workloads, plugged in or moderate battery use
- **Expected battery life**: 3-5 hours

### Performance Profile (`power-perf`)
```bash
sudo system76-power profile performance
```
- **CPU**: Performance governor, full turbo boost
- **GPU**: NVIDIA fully powered, maximum clocks
- **Fan curve**: Aggressive cooling
- **Best for**: Gaming, rendering, compilation, heavy workloads
- **Note**: Use only when plugged in (high power draw)

---

## Automatic Profile Switching

The system automatically switches profiles based on AC power state:

| Event | Action |
|-------|--------|
| Unplug AC adapter | Switch to **Battery** profile |
| Plug in AC adapter | Switch to **Balanced** profile |

This is handled by udev rules in `configuration.nix`. The switch happens instantly when you plug/unplug.

To check current profile:
```bash
power-status
```

---

## Battery Charge Thresholds

Limiting charge level extends battery lifespan significantly. Lithium batteries degrade faster when kept at 100%.

### Full Charge (`charge-full`)
```bash
sudo system76-power charge-thresholds --profile full_charge
```
- Charges to **100%**
- Use when you need maximum runtime
- Not recommended for daily use

### Balanced Charge (`charge-balanced`)
```bash
sudo system76-power charge-thresholds --profile balanced
```
- Charges to **90%**
- Good balance between runtime and longevity
- Recommended for normal use

### Max Lifespan (`charge-health`)
```bash
sudo system76-power charge-thresholds --profile max_lifespan
```
- Charges to **60%**
- Maximum battery longevity
- Best when laptop stays plugged in most of the time

### Battery Health Tips
- If plugged in >80% of the time: use `charge-health` (60%)
- If mixed use: use `charge-balanced` (90%)
- Only use `charge-full` (100%) before travel or when you need max runtime

---

## GPU Modes (Wayland / PRIME Offload)

> **Note**: `system76-power graphics` switching requires X11 and doesn't work on pure Wayland setups. On Wayland with PRIME offload, the NVIDIA dGPU automatically sleeps when not in use and wakes when needed.

### How It Works on Wayland

Your setup uses **PRIME Offload** mode:
- Intel iGPU renders the desktop (low power)
- NVIDIA dGPU sleeps in D3 state (nearly zero power)
- NVIDIA wakes on-demand when you launch apps with `nvidia-offload`
- NVIDIA sleeps again automatically when the app closes

This is actually **better for battery** than traditional GPU switching because:
- No reboot required
- dGPU truly powers off between uses
- Seamless switching per-application

### Check GPU Power State
```bash
gpu-status
```

Output meanings:
- `suspended` = dGPU is OFF, drawing ~0W (good for battery)
- `active` = dGPU is running, drawing 15-75W

### Run Apps on NVIDIA
```bash
gpu-run <application>
# or
nvidia-offload <application>
```

Examples:
```bash
gpu-run steam
gpu-run blender
gpu-run obs
nvidia-offload chromium --enable-features=VaapiVideoDecoder
```

### GPU Aliases
| Alias | Description |
|-------|-------------|
| `gpu-status` | Show power state + nvidia-smi stats |
| `gpu-run <app>` | Run app on NVIDIA (alias for nvidia-offload) |
| `gpu-wake` | Manually wake dGPU |
| `gpu-force-off` | Force dGPU power management to auto |

### If dGPU Won't Sleep
Check what's keeping it awake:
```bash
# Check power state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status

# Check for processes using NVIDIA
lsof /dev/nvidia* 2>/dev/null

# Force auto power management
gpu-force-off
```

---

## Quick Reference: All Aliases

### Power Profiles
| Alias | Description |
|-------|-------------|
| `power` | Show current power profile |
| `power-bat` | Switch to battery profile (max battery life) |
| `power-bal` | Switch to balanced profile (default) |
| `power-perf` | Switch to performance profile (max power) |
| `power-status` | Show profile + charge thresholds |

### Charge Thresholds
| Alias | Max Charge | Use Case |
|-------|------------|----------|
| `charge-full` | 100% | Before travel |
| `charge-balanced` | 90% | Daily use |
| `charge-health` | 60% | Plugged in most of time |

### GPU Control
| Alias | Description |
|-------|-------------|
| `gpu-status` | Show GPU mode + NVIDIA stats |
| `gpu-integrated` | Intel only (reboot required) |
| `gpu-hybrid` | Intel + NVIDIA on-demand (reboot required) |
| `gpu-nvidia` | NVIDIA only (reboot required) |

---

## Power Limits (Undervolt Configuration)

Power limits are set in `undervolt.nix`:

| Setting | Value | Description |
|---------|-------|-------------|
| P1 (Sustained) | 45W | Long-term power limit |
| P2 (Turbo) | 90W | Short burst power limit |
| Temp AC | 95C | Throttle temperature on AC |
| Temp Battery | 85C | Throttle temperature on battery |

**Note**: Voltage undervolting is blocked by System76 firmware (Plundervolt protection). Only power limits and temperature targets are active.

---

## TLP Settings (Battery Optimization)

TLP provides additional power management:

| Setting | On AC | On Battery |
|---------|-------|------------|
| CPU Governor | performance | powersave |
| CPU Turbo | enabled | **disabled** |
| HWP Dynamic Boost | enabled | disabled |
| WiFi Power Save | off | on |
| PCIe ASPM | default | powersupersave |

---

## Sleep & Hibernate

### Behavior
| Trigger | On Battery | On AC |
|---------|------------|-------|
| Lid close | Suspend, hibernate after 5min | Suspend only |
| Lid close (docked) | Ignore | Ignore |
| Power button | Suspend | Suspend |
| Idle 15min | Suspend, hibernate after 5min | Suspend, hibernate after 5min |

### Manual Commands
```bash
# Suspend (sleep)
systemctl suspend

# Hibernate (save to disk)
systemctl hibernate

# Suspend then hibernate after 5min
systemctl suspend-then-hibernate
```

### Hibernate Requirements
- 32GB swapfile at `/var/lib/swapfile`
- Resume device configured in boot params
- NVIDIA `PreserveVideoMemoryAllocations=1` enabled

---

## Custom EC Firmware

Located in `~/gitZ/costumsys76firm/`

### Silent Fan Curve
The custom EC firmware uses a quiet-optimized fan curve:

| Temperature | Fan Speed |
|-------------|-----------|
| < 55C | Off (0%) |
| 55C | 20% |
| 60C | 25% |
| 65C | 30% |
| 70C | 40% |
| 75C | 50% |
| 80C | 65% |
| 85C | 80% |
| 90C | 100% |

**Timing:**
- Heatup delay: 8 seconds (ignore brief spikes)
- Cooldown delay: 30 seconds (prevent fan cycling)

### Building Custom Firmware
```bash
cd ~/gitZ/costumsys76firm
nix-shell
./setup.sh
./build-container.sh  # Safe build with correct SDCC version
```

### Protecting Custom Firmware from fwupd
Add your firmware GUIDs to `DisabledDevices` in `configuration.nix` to prevent automatic overwrites.

---

## Monitoring Commands

```bash
# CPU temperature
sensors

# NVIDIA GPU stats
nvidia-smi

# GPU top (real-time monitoring)
nvtop

# Intel iGPU usage
sudo intel_gpu_top

# Power consumption (if supported)
powerstat -d 1

# Battery status
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# System76 power status
system76-power profile
system76-power charge-thresholds
system76-power graphics
```

---

## Troubleshooting

### NVIDIA Not Powering Down
Check if processes are keeping it awake:
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
lsof /dev/nvidia*
```

### Fan Always Running
- Check thermal paste (may need reapplication after 2-3 years)
- Verify custom EC firmware is flashed
- Check for runaway processes: `htop`

### Hibernate Not Working
```bash
# Check swap
swapon --show

# Check resume device
cat /proc/cmdline | grep resume

# Test manually
sudo systemctl hibernate
```

### Battery Draining Fast
1. Check GPU mode: `gpu-status`
2. Check power profile: `power-status`
3. Look for power-hungry processes: `powertop`
4. Verify TLP is active: `sudo tlp-stat -s`
