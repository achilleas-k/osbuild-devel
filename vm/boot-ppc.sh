#!/usr/bin/bash

set -euo pipefail

baseimg="${1}"
image="${2}-$(basename "${baseimg}")"

if [[ ! -e "${image}" ]]; then
    echo "Creating overlay ${image} from ${baseimg}"
    qemu-img create -o backing_file="${baseimg}",backing_fmt=qcow2 -f qcow2 "${image}"
    qemu-img resize "${image}" 100G
fi

qemu-system-ppc \
    -m 2047M \
    -device virtio-net-pci,netdev=n0,mac="FE:0B:6E:23:3D:9A" \
    -netdev user,id=n0,net=10.0.2.0/24,hostfwd=tcp::2222-:22 \
    -drive file="${image}"
