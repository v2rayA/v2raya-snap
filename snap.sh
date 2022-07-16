#!/bin/bash
# Parse arguments
if [ -z "$1" ] || [ $# -gt 1 ]; then
	echo -e "Usage: $0 [VERSION]\n\nE.g. $0 1.5.7" >/dev/stderr
	exit 1
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
if [ -z "$(wget --version)" ] || [ -z "$(snapcraft --version)" ]; then
	echo "wget and snapcraft are required, but not installed"
	exit 3
fi


sed -i.backup "s/@VERSION@/$VERSION/g" snap/snapcraft.yaml
declare readonly architectures=("amd64") # Add your architectures here
for ARCH in ${architectures[@]}; do
	sed -i.backup-arch "s/@ARCH@/$ARCH/g" snap/snapcraft.yaml
	if [ ! -e "installer_debian_${ARCH}_${VERSION}.deb" ]; then
	wget "https://github.com/v2rayA/v2rayA/releases/download/v${VERSION}/installer_debian_${ARCH}_${VERSION}.deb" \
	-O "$P_DIR/installer_debian_${ARCH}_${VERSION}.deb"
	fi
	snapcraft snap --output v2raya_${VERSION}_${ARCH}.snap
	mv -f snap/snapcraft.yaml.backup-arch snap/snapcraft.yaml
done


mv -f snap/snapcraft.yaml.backup snap/snapcraft.yaml


# Should publish snap here, but it's a really good idea to smoke test it by hand before pushing to the stable chanell
#snapcraft export-login snapcraft-credfile
#export SNAPCRAFT_STORE_CREDENTIALS=$(cat snapcraft-credfile)
#snapcraft login
#snapcraft upload v2raya_${VERSION}_amd64.snap --release stable
