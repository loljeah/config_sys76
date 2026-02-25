#!/usr/bin/env bash
# yubikey-idle-check.sh
# Only execute the given command if YubiKey is NOT connected
# Usage: yubikey-idle-check.sh <command>
#
# Yubico vendor ID: 1050

if lsusb 2>/dev/null | grep -qi "1050:"; then
    # YubiKey connected - skip idle action
    exit 0
fi

# YubiKey not connected - execute the command
exec "$@"
