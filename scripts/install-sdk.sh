#!/bin/bash
# scripts/install-sdk.sh — install the Yocto SDK to ./sdk for F´ cross-compilation.
# Prereq: bitbake core-image-full-cmdline -c populate_sdk   (see README)
set -eu
cd "$(dirname "$0")/.."

installer=(build-k26/tmp/deploy/sdk/*toolchain*.sh)
[ -f "${installer[0]}" ] || { echo "No SDK installer. Run: bitbake core-image-full-cmdline -c populate_sdk"; exit 1; }

"${installer[0]}" -d sdk -y
