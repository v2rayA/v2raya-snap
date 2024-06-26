#!/bin/bash
set -eu

# Parse arguments
if [ -z "$1" ] || [ $# -gt 1 ]; then
	echo -e "Usage: $0 [VERSION]\n\nE.g. $0 1.5.7" >/dev/stderr
	exit 2
else
	VERSION="$1"
fi


# Sanity check
P_DIR=$PWD
if [ "$(basename $P_DIR)" != "v2raya-snap" ]; then
	echo -e "The script should be run from the v2raya-snap directory, not from $PWD" >/dev/stderr
	exit 2
fi
if [ -z "$(git --version)" ] || [ -z "$(wget --version)" ] || [ -z "$(snapcraft --version)" ] || [ -z "$(yq --version)" ]; then
       echo "git, wget, yq and snapcraft are required, but not installed"
	exit 1
fi


export SNAPCRAFT_BUILD_ENVIRONMENT=multipass
declare readonly architectures=("arm64 riscv64 x64") # Add your architectures here
for ARCH in ${architectures[@]}; do
	# Workaround around v2rayA and v2ray-core using different architecture names
	if [[ $ARCH == "x64" ]]; then
		v2ray_core_arch="64";
	elif [[ $ARCH == "arm64" ]]; then
		v2ray_core_arch="arm64-v8a";
	else v2ray_core_arch=$ARCH;
	fi

	# Download the latest version of v2ray-core
	v2ray_core_url=$(curl -sH "Accept: application/vnd.github.v3+json" https://api.github.com/repos/v2fly/v2ray-core/releases/latest |\
		jq -r $".assets[].browser_download_url | select(test(\"v2ray-linux-${v2ray_core_arch}\\\.zip$\"))")
	yq -Y $".version=\"${VERSION}\" | .parts.v2raya.source=\"installer_debian_${ARCH}_${VERSION}.deb\" | .parts.\"v2ray-core\".source=\"${v2ray_core_url}\"" \
		snapcraft.yaml.template > snap/snapcraft.yaml ||\
		v2ray_core_url="https://github.com/v2fly/v2ray-core/releases/download/v5.16.1/v2ray-linux-64.zip"

	if [ ! -e "installer_debian_${ARCH}_${VERSION}.deb" ]; then
	wget "https://github.com/v2rayA/v2rayA/releases/download/v${VERSION}/installer_debian_${ARCH}_${VERSION}.deb" \
		-O "$P_DIR/installer_debian_${ARCH}_${VERSION}.deb"
	fi

	# Workaround around v2rayA and snapcraft using different names for the amd64/x64 architecture
	if [[ "$ARCH" == "x64" ]]; then export SNAPCRAFT_BUILD_FOR="amd64"; else export SNAPCRAFT_BUILD_FOR="$ARCH"; fi
	cat snap/snapcraft.yaml
	sudo -E snapcraft pack --build-for $SNAPCRAFT_BUILD_FOR --output v2raya_${VERSION}_${ARCH}.snap \
		|| cat ~/.local/state/snapcraft/log/snapcraft-*.log
done
