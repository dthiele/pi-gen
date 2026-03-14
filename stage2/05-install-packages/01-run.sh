#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

# Prevent "The currently running kernel version is not the expected kernel version 6.12.62+rpt-rpi-v8." error
sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" "${ROOTFS_DIR}/etc/needrestart/needrestart.conf"

# Install yq
GOBIN=/usr/local/bin/ go install github.com/mikefarah/yq/v4@latest

# Enable watchdog
sed -i -e 's/^#*\(RuntimeWatchdogSec=\).*/\115/;s/^#*\(RebootWatchdogSec=\).*/\110min/;s/^#*\(WatchdogDevice=\).*/\1\/dev\/watchdog/' "${ROOTFS_DIR}/etc/systemd/system.conf"
