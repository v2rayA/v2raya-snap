#/bin/bash

sudo /bin/bash <<EOF
snap connect v2raya:firewall-control
snap connect v2raya:network-control
snap start v2raya
EOF
