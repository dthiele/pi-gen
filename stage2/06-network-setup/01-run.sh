#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"
IFNAME="eth0"
VLAN_ID="224"

# Use systemd-networkd instead of NetworkManager
on_chroot << EOF
systemctl disable NetworkManager
systemctl enable systemd-networkd
EOF

# Configure network interface
cat << EOF > "${ROOTFS_DIR}/etc/systemd/network/10-${IFNAME}.network"
[Match]
Name=${IFNAME}

[Network]
DHCP=no
VLAN=${IFNAME}.${VLAN_ID}
EOF

cat << EOF > "${ROOTFS_DIR}/etc/systemd/network/20-${IFNAME}.${VLAN_ID}.netdev"
[NetDev]
Name=${IFNAME}.${VLAN_ID}
Kind=vlan

[VLAN]
Id=${VLAN_ID}
EOF

cat << EOF > "${ROOTFS_DIR}/etc/systemd/network/21-${IFNAME}.${VLAN_ID}.network"
[Match]
Name=${IFNAME}.${VLAN_ID}

[Network]
DHCP=no

[Address]
Address=10.0.${VLAN_ID}.10/24
DNS=10.0.2.1
DNS=9.9.9.9

[Route]
Gateway=10.0.${VLAN_ID}.1
EOF
