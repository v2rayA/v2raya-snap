# v2raya-snap
Snapcraft files for v2rayA

To build the snap yourself, just run the command below. Replace `1.5.8.1` by the version you need.
```
./snap.sh 1.5.8.1
```

To install the freshly-built snap, run
```
snap install --dangerous --jailmode ./v2raya_1.5.8.1_amd64.snap
```
(omit the `--jailmode` flag on non-Ubuntu systems)


Then give it all the required  permissions, and start:
```
./start-snap.sh
```

The `start-snap.sh` script is only needed when installing from a `.snap` file for development/testing purposes. The end user wishing to install v2rayA from snapcraft.io doesn't have to paste all these commands. A simple `snap install v2raya` is enough to install the snap from snapcraft.io.
