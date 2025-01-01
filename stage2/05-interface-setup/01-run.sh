#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

# Configure non-VLAN interfaces
VLAN_BASE_INTERFACES=$(cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan'].base_interface" | jq 'sort | unique ')
for ifname in $(cat ${CONFIG_JSON} | jq -r --argjson vlan_base_interfaces "${VLAN_BASE_INTERFACES}" '.interfaces[] | select(.type=="ethernetCsmacd") | select( .name as $in | $vlan_base_interfaces | index($in) | not).name'); do
        cat ${CONFIG_JSON} | jp "interfaces[?type=='ethernetCsmacd' && name=='${ifname}']|[0]" | j2 -f json files/network.j2 > "${ROOTFS_DIR}/etc/systemd/network/10-${ifname}.network"
done

# Configure VLAN base interfaces
for ifname in $(cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan'].base_interface" | jq -r 'sort | unique | .[]'); do
        cat ${CONFIG_JSON} | jp "interfaces[?type=='ethernetCsmacd' && name=='${ifname}']|[0]" | jq --argjson vlan_ifnames "$(cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan' && base_interface=='${ifname}'].name")" '.vlan_interfaces = $vlan_ifnames' | j2 -f json files/network.j2 > "${ROOTFS_DIR}/etc/systemd/network/10-${ifname}.network"
done

# Configure VLAN interfaces
for ifname in $(cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan'].name" | jq -r '.[]'); do
        cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan' && name=='${ifname}']|[0]" | j2 -f json files/netdev.j2 > "${ROOTFS_DIR}/etc/systemd/network/20-${ifname}.netdev"
        cat ${CONFIG_JSON} | jp "interfaces[?type=='l2vlan' && name=='${ifname}']|[0]" | j2 -f json files/network.j2 > "${ROOTFS_DIR}/etc/systemd/network/30-${ifname}.network"
done

# Enable routing
cat << EOF > "${ROOTFS_DIR}/etc/sysctl.d/10-router.conf"
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
EOF

# Use systemd-networkd instead of NetworkManager
on_chroot << EOF
systemctl disable NetworkManager
systemctl enable systemd-networkd
EOF
