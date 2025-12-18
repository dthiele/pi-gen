#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

# Enable watchdog
sed -i -e 's/^#*\(RuntimeWatchdogSec=\).*/\115/;s/^#*\(RebootWatchdogSec=\).*/\110min/;s/^#*\(WatchdogDevice=\).*/\1\/dev\/watchdog/' "${ROOTFS_DIR}/etc/systemd/system.conf"
