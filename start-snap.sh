#/bin/bash

sudo /bin/bash <<EOF
echo 'Please wait...'
sleep 10 # Launching snap instantly after the installation sometimes breaks, so it's better to play safe
snap connect v2raya:firewall-control
snap connect v2raya:network-control
snap start v2raya
EOF
