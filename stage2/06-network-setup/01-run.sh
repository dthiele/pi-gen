#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"
WIFI_DEV="wlan0"

# Use systemd-networkd instead of NetworkManager
on_chroot << EOF
systemctl disable NetworkManager
systemctl enable systemd-networkd
EOF

# Ensure that WiFi is not soft-blocked by creating the following service.
cat << EOF > "${ROOTFS_DIR}/etc/systemd/system/rfkill_unblock.service"
[Unit]
Description=Unblock WiFi Devices
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/rfkill unblock wifi
ExecStop=
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

on_chroot << EOF
systemctl enable rfkill_unblock.service
EOF

# Configure WiFi interface
cat << EOF > "${ROOTFS_DIR}/etc/systemd/network/30-wlan.network"
[Match]
Name=${WIFI_DEV}
Type=wlan
WLANInterfaceType=station

[Network]
DHCP=ipv4

[DHCP]
UseDNS=yes
EOF

cat << EOF > "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant-${WIFI_DEV}.conf"
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
update_config=1
EOF

/usr/bin/wpa_passphrase "$(jq -r '.wifi.ssid' ${CONFIG_JSON})" "$(jq -r '.wifi.password' ${CONFIG_JSON})" >> "${ROOTFS_DIR}/etc/wpa_supplicant/wpa_supplicant-${WIFI_DEV}.conf"

on_chroot << EOF
systemctl enable wpa_supplicant@${WIFI_DEV}.service
EOF
