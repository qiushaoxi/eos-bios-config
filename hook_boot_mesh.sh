#!/bin/bash -e

echo "AS THE BIOS BOOT, YOU NOW NEED TO LINK TO THE NETWORK:"
echo "Running 'fullnode' through Docker."
docker -H 10.10.0.54:5555 run -ti --detach --name fullnode \
       -v /eos:/etc/nodeos \
       -p 18888:8888 -p 19876:9876 \
       eoscanada/eos:dawn-v4.2.0 \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Press ENTER when that is done"
read
