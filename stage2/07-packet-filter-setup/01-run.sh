#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

j2 -f json files/nftables.conf.j2 ${CONFIG_JSON} > "${ROOTFS_DIR}/etc/nftables.conf"

on_chroot << EOF
systemctl enable nftables
EOF
