# Power Management for System76 Serval WS 13 (serw13)
# Intel Core i9-14900HX
#
# NOTE: Voltage undervolting is BLOCKED by firmware (Plundervolt protection)
# MSR 0x150 writes are rejected. Only power limits and temp targets are used.
#
# To enable voltage undervolting, you'd need to:
#   1. Modify System76 Open Firmware to disable CFG Lock / Undervolt Protection
#   2. Rebuild and flash custom firmware
#   See: https://github.com/system76/firmware-open
#
# Check status:
#   sudo journalctl -u undervolt
#   cat /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
#
# Alternative thermal management: system76-power (already enabled via hardware.system76)

{ config, pkgs, lib, ... }:

{
  services.undervolt = {
    enable = true;
    verbose = true;
    useTimer = true;

    # DISABLED - firmware blocks voltage changes
    # coreOffset = -80;
    # uncoreOffset = -50;
    # gpuOffset = -50;
    # analogioOffset = 0;

    #####################################################################
    # TEMPERATURE TARGETS (may still work)
    #####################################################################
    tempAc = 95;
    tempBat = 85;

    #####################################################################
    # POWER LIMITS - These often work even when voltage is locked
    #####################################################################
    p1 = {
      limit = 45;    # Sustained power limit (Watts) - lowered for battery life
      window = 28;   # Time window (seconds)
    };

    p2 = {
      limit = 90;    # Turbo power limit (Watts) - lowered for battery life
      window = 0.002;
    };
  };

  boot.kernelModules = [ "msr" ];
}
