#!/bin/bash
set -e

# Parse arguments
if [ -z "$1" ] || [ $# -gt 1 ]; then
    echo -e "Usage: $0 [VERSION]\n\nE.g. $0 1.5.7" >/dev/stderr
    exit 2
else
    VERSION="$1"
fi

# Sanity check: we must be inside the v2raya-snap repo root
P_DIR=$PWD
if [ "$(basename $P_DIR)" != "v2raya-snap" ]; then
    echo -e "The script should be run from the v2raya-snap directory, not from $PWD" >/dev/stderr
    exit 2
fi

# Required tools – fail early if something is missing
if [ -z "$(git --version)" ] || [ -z "$(wget --version)" ] || [ -z "$(snapcraft --version)" ] || [ -z "$(python3 -m yq --version)" ]; then
    echo "git, wget, yq, and snapcraft are required, but not installed"
    exit 1
fi

# Fetch geoip.dat and geosite.dat once (they are arch‑independent)
if [ ! -d "geo_data" ]; then
    mkdir -p geo_data
    echo "Downloading geoip.dat ..."
    curl -L -o geo_data/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    echo "Downloading geosite.dat ..."
    curl -L -o geo_data/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
fi

export SNAPCRAFT_BUILD_ENVIRONMENT=lxd
declare readonly architectures=("arm64 riscv64 x64")   # add more if needed

for ARCH in ${architectures[@]}; do
    # v2rayA release uses the same arch names as we do, except for x64 (it stays x64)
    v2raya_arch="$ARCH"


    # Download the v2raya_core binary (the actual v2ray executable)  from v2rayA's own release assets.
	
    v2raya_core_url="https://github.com/v2rayA/v2rayA/releases/download/v${VERSION}/v2raya_core_linux_${v2raya_arch}_${VERSION}"
    mkdir -p "./v2ray_bin_${ARCH}"
    echo "Downloading v2raya_core for ${ARCH} from ${v2raya_core_url}"
    curl -L -o "./v2ray_bin_${ARCH}/v2ray" "$v2raya_core_url"
    chmod +x "./v2ray_bin_${ARCH}/v2ray"

    # Grab the matching .deb installer for v2rayA itself
    if [ ! -e "installer_debian_${ARCH}_${VERSION}.deb" ]; then
        wget --quiet "https://github.com/v2rayA/v2rayA/releases/download/v${VERSION}/installer_debian_${ARCH}_${VERSION}.deb" \
            -O "$P_DIR/installer_debian_${ARCH}_${VERSION}.deb"
    fi


    # Generate the final snapcraft.yaml by substituting:
    #   - version
    #   - v2raya deb source
    #   - v2ray-core source (now pointing to our local binary dir)

    python3 -m yq -Y ".version=\"${VERSION}\" | \
                       .parts.v2raya.source=\"installer_debian_${ARCH}_${VERSION}.deb\" | \
                       .parts.\"v2ray-core\".source=\"./v2ray_bin_${ARCH}\"" \
        snapcraft.yaml.template > snap/snapcraft.yaml

    # snapcraft uses "amd64" instead of "x64"
    if [[ "$ARCH" == "x64" ]]; then
        export SNAPCRAFT_BUILD_FOR="amd64"
    else
        export SNAPCRAFT_BUILD_FOR="$ARCH"
    fi
done
