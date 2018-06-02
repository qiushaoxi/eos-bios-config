#!/bin/bash -e

echo "Load env config"
source set-env.sh

date_dir_name=`date +%s`

echo "AS THE BIOS BOOT, YOU NOW NEED TO LINK TO THE NETWORK:"
echo "Running 'fullnode1' through Docker."
docker -H $fullnode1_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $ttp_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Running 'fullnode2' through Docker."
docker -H $fullnode2_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json                              
echo ""

echo "Running 'fullnode3' through Docker."
docker -H $fullnode3_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json                              
echo ""

echo "Press ENTER when that is done"
read
