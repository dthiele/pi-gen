#!/bin/bash -e

CONFIG_JSON="${BASE_DIR}/config.json"

mkdir -p "${ROOTFS_DIR}/srv/compose/zigbee2mqtt/data"

j2 -f json files/configuration.yaml.j2 "${CONFIG_JSON}" > "${ROOTFS_DIR}/srv/compose/zigbee2mqtt/data/configuration.yaml"

cat << 'EOF' > "${ROOTFS_DIR}/srv/compose/zigbee2mqtt/docker-compose.yml"
services:
    zigbee2mqtt:
        platform: linux/arm64
        container_name: zigbee2mqtt
        image: ghcr.io/koenkk/zigbee2mqtt:2.7
        restart: unless-stopped
        volumes:
            - ./data:/app/data
            - /run/udev:/run/udev:ro
        ports:
            - 8080:8080
        environment:
            - TZ=Europe/Berlin
            - DONGLE_DEV=${DONGLE_DEV:?error}
        devices:
            - ${DONGLE_DEV}:/dev/ttyUSB0
EOF

# Create an environment file with the dongle device for docker-compose-zigbee2mqtt.service. For some reason, this cannot be done in docker-compose-zigbee2mqtt.service with a ExecStartPre statement.
cat << 'EOF' > "${ROOTFS_DIR}/etc/systemd/system/dongle-dev.service"
[Unit]
Description=dongle device service
Requires=docker.service network-online.target
After=docker.service network-online.target

[Service]
WorkingDirectory=/srv/compose/zigbee2mqtt
Type=oneshot
RemainAfterExit=yes

ExecStart=/usr/bin/bash -c 'echo "DONGLE_DEV=$(ls /dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_* | tail -1)" > /srv/compose/zigbee2mqtt/zigbee2mqtt.service.env'

[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > "${ROOTFS_DIR}/etc/systemd/system/docker-compose-zigbee2mqtt.service"
[Unit]
Description=docker-compose zigbee2mqtt service
Requires=docker.service network-online.target dongle-dev.service
After=docker.service network-online.target dongle-dev.service

[Service]
WorkingDirectory=/srv/compose/zigbee2mqtt
Type=simple
TimeoutStartSec=15min
Restart=always

ExecStartPre=/usr/bin/docker-compose pull --quiet --ignore-pull-failures
ExecStartPre=/usr/bin/docker-compose build --pull
EnvironmentFile=-/srv/compose/zigbee2mqtt/zigbee2mqtt.service.env

ExecStart=/usr/bin/docker-compose up --remove-orphans

ExecStop=/usr/bin/docker-compose down --remove-orphans

ExecReload=/usr/bin/docker-compose pull --quiet --ignore-pull-failures
ExecReload=/usr/bin/docker-compose build --pull

[Install]
WantedBy=multi-user.target
EOF

on_chroot << EOF
systemctl enable dongle-dev.service
systemctl enable docker-compose-zigbee2mqtt.service
EOF
