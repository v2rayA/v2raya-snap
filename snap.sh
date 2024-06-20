#!/bin/bash
# Parse arguments
if [ -z "$1" ] || [ $# -gt 1 ]; then
	echo -e "Usage: $0 [VERSION]\n\nE.g. $0 1.5.7" >/dev/stderr
	exit 2
else
	VERSION="$1"
fi
set -eu


# Sanity check
P_DIR=$PWD
if [ "$(basename $P_DIR)" != "v2raya-snap" ]; then
	echo -e "The script should be run from the v2raya-snap directory, instead of $PWD" >/dev/stderr
	exit 2
fi
if [ -z "$(git --version)" ] || [ -z "$(wget --version)" ] || [ -z "$(snapcraft --version)" ] || [ -z "$(yq --version)" ]; then
       echo "git, wget, yq and snapcraft are required, but not installed"
	exit 1
fi

declare readonly architectures=("x64") # Add your architectures here
for ARCH in ${architectures[@]}; do
	yq -Y $".\"version\"=\"${VERSION}\" | .parts.v2raya.\"source\"=\"installer_debian_${ARCH}_${VERSION}.deb\"" snap/snapcraft.yaml.template > snap/snapcraft.yaml
	if [ ! -e "installer_debian_${ARCH}_${VERSION}.deb" ]; then
	wget "https://github.com/v2rayA/v2rayA/releases/download/v${VERSION}/installer_debian_${ARCH}_${VERSION}.deb" \
	-O "$P_DIR/installer_debian_${ARCH}_${VERSION}.deb"
	fi
	snapcraft snap --output v2raya_${VERSION}_${ARCH}.snap
done

# Should publish snap here, but it's a really good idea to smoke test it by hand before pushing to the stable chanell
#snapcraft export-login snapcraft-credfile
#export SNAPCRAFT_STORE_CREDENTIALS=$(cat snapcraft-credfile)
#snapcraft login
#snapcraft upload v2raya_${VERSION}_amd64.snap --release stable
