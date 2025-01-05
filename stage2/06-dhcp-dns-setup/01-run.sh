#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

# DNS server
on_chroot << EOF
tsig-keygen -a hmac-sha256 kea-dhcp-ns > /etc/kea-dhcp-ns.key
chmod 640 /etc/kea-dhcp-ns.key
chown root:bind /etc/kea-dhcp-ns.key
EOF

for zone in $(jq -r ".dns.zones[].zone" ${CONFIG_JSON}); do
        jq ".dns.zones[] | select(.zone==\"${zone}\")" ${CONFIG_JSON} | j2 -f json files/forward.zone.j2 > "${ROOTFS_DIR}/var/lib/bind/${zone}.zone"
        REVERVSE=$(jq -r ".dns.zones[] | select(.zone==\"${zone}\").reverse" ${CONFIG_JSON})
        jq ".dns.zones[] | select(.zone==\"${zone}\")" ${CONFIG_JSON} | j2 -f json --customize files/j2_custom.py files/reverse8.zone.j2 > "${ROOTFS_DIR}/var/lib/bind/${REVERVSE}.zone"
done
## Extend $CONFIG_JSON with properties extracted from the TSIG key file
jq ". |= (.dns.ddns.key = \"$(grep secret ${ROOTFS_DIR}/etc/kea-dhcp-ns.key | sed -e 's/.*secret "//;s/";.*//')\") | (.dns.ddns.key_name = \"$(grep ^key ${ROOTFS_DIR}/etc/kea-dhcp-ns.key | sed -e 's/^key "\(.*\)".*/\1/')\")" ${CONFIG_JSON} | j2 -f json files/named.conf.zones.j2 > "${ROOTFS_DIR}/etc/bind/named.conf.zones"
j2 -f json files/named.conf.options.j2 ${CONFIG_JSON} > "${ROOTFS_DIR}/etc/bind/named.conf.options"
j2 -f json files/named.conf.j2 ${CONFIG_JSON} > "${ROOTFS_DIR}/etc/bind/named.conf"


# DHCP server
mkdir -p "${ROOTFS_DIR}/etc/kea"
j2 -f json files/kea-dhcp4.conf.j2  ${CONFIG_JSON} > "${ROOTFS_DIR}/etc/kea/kea-dhcp4.conf"
## Extend $CONFIG_JSON with properties extracted from the TSIG key file
jq ". |= (.dns.ddns.key = \"$(grep secret ${ROOTFS_DIR}/etc/kea-dhcp-ns.key | sed -e 's/.*secret "//;s/";.*//')\") | (.dns.ddns.key_name = \"$(grep ^key ${ROOTFS_DIR}/etc/kea-dhcp-ns.key | sed -e 's/^key "\(.*\)".*/\1/')\")" ${CONFIG_JSON} | j2 -f json files/kea-dhcp-ddns.conf.j2 > "${ROOTFS_DIR}/etc/kea/kea-dhcp-ddns.conf"

# Resolver
j2 -f json files/resolved.conf.j2  ${CONFIG_JSON} > "${ROOTFS_DIR}/etc/systemd/resolved.conf"

on_chroot << EOF
systemctl enable systemd-resolved
EOF
