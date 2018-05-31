#!/bin/bash -e

echo "AS THE BIOS BOOT, YOU NOW NEED TO LINK TO THE NETWORK:"
echo "Running 'fullnode1' through Docker."
docker -H $fullnode1_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir:/etc/nodeos -v $eos_data_dir:/data \
       -p $fullnode1_http_port:8888 -p $fullnode1_p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Running 'fullnode2' through Docker."
docker -H $fullnode2_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir:/etc/nodeos -v $eos_data_dir:/data \
       -p $fullnode2_http_port:8888 -p $fullnode2_p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Press ENTER when that is done"
read
