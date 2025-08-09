ARG BASE_IMAGE=debian:bullseye
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git vim parted \
        quilt coreutils qemu-user-static debootstrap zerofree zip dosfstools \
        libarchive-tools libcap2-bin rsync grep udev xz-utils curl xxd file kmod bc \
        binfmt-support ca-certificates fdisk gpg pigz arch-test \
        j2cli jq openssl ssh wget \
    && rm -rf /var/lib/apt/lists/*
RUN wget https://github.com/jmespath/jp/releases/latest/download/jp-linux-amd64 -O /usr/local/bin/jp  && \
	chmod +x /usr/local/bin/jp

COPY . /pi-gen/

VOLUME [ "/pi-gen/work", "/pi-gen/deploy"]
