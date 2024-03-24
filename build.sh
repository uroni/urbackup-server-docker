#!/bin/bash
set -x

# Accepted values for ARCH are amd64, armhf, arm64, i386
ARCH=${1:-amd64}
VERSION=${2:-2.4.15}
TARGETPLATFORM="linux/${ARCH}"
OPTS=${3}
TAG=${VERSION}_${ARCH}

case ${ARCH} in
    "amd64")  IMAGE_ARCH="$BASE" ;;
    "armhf")  IMAGE_ARCH="arm32v7/$BASE" ;;
    "arm64")  IMAGE_ARCH="arm64v8/$BASE" ;;
    "i386")   IMAGE_ARCH="i386/$BASE" ;;
    *) echo "unrecognized architecture '$ARCH'" >>/dev/stderr ; exit 1 ;;
esac

if [[ " ${*} " =~ " btrfs " ]]; then
    BTRFS=1
    TAG=${TAG}_btrfs
fi

if [[ " ${*} " =~ " zfs " ]]; then
    if [[ "$ARCH" != "amd64" ]]; then
        echo "ZFS is only supported on amd64" ; exit 0
    fi
    ZFS=1
    TAG=${TAG}_zfs
fi

docker build \
          --build-arg ARCH=${ARCH} \
          --build-arg VERSION=${VERSION} \
          --build-arg TARGETPLATFORM=${TARGETPLATFORM} \
          --build-arg IMAGE_ARCH=${IMAGE_ARCH} \
          --build-arg BTRFS=${BTRFS} \
          --build-arg ZFS=${ZFS} \
          -t urbackup-server:${TAG} \
          .
