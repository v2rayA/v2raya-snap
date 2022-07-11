#/bin/bash

sudo /bin/bash -c "\
echo 'Please wait...';\
sleep 10;
snap connect v2raya:firewall-control;\
snap connect v2raya:network;\
snap connect v2raya:network-bind;\
snap connect v2raya:network-control;\
snap connect v2raya:network-observe;\
snap connect v2raya:v2raya-files;\
snap start v2raya;"
