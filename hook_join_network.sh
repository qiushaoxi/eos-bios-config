#!/bin/bash -e

# `join_network` hook:
# $1 = genesis_json
# $2 = p2p_address_statements like "p2p-peer-address = 1.2.3.4\np2p-peer-address=2.3.4.5"
# $3 = p2p_addresses to connect to, split by comma
# $4 = producer-name statements, like: "producer-name = hello\nproducer-name = hello.a"
#      You will have many only when joining a net with less than 21 producers.
# $5 = producer-name you should handle, split by comma


# WARN: this is SAMPLE keys configuration to get your keys into your config.
#       You'll want to adapt that to your infrastructure, `cat` it from a file,
#       use some secrets management software or whatnot.
#
#       They need to reflect your `target_initial_authority`
#       strucuture in your `my_discovery_file.yaml`.
#
PUBKEY=EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
PRIVKEY=5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3


echo "Load env config"
source set-env.sh


echo "Removing old nodeos data (you might be asked for your sudo password)..."
sudo rm -rf $eos_data_dir
mkdir -p $eos_data_dir

echo "Writing genesis.json"
echo $1 > genesis.json

# Your base_config.ini shouldn't contain any `producer-name` nor `private-key`
# nor `enable-stale-production` statements.
echo "Copying base config"
cp base_config.ini config.ini
echo "$2" >> config.ini
echo "$4" >> config.ini
echo "p2p-peer-address = $fullnode1_ip:$fullnode1_p2p_port" >> config.ini
echo "p2p-peer-address = $fullnode2_ip:$fullnode2_p2p_port" >> config.ini
echo "private-key = [\"$PUBKEY\",\"$PRIVKEY\"]" >> config.ini
echo "plugin = eosio::producer_api_plugin" >> config.ini


# add none bp fullnode
rm -rf fullnode
mkdir fullnode
cp base_config.ini fullnode/config.ini
cp genesis.json fullnode/genesis.json
echo "$2" >> fullnode/config.ini
echo "$4" >> fullnode/config.ini
echo "p2p-peer-address = $bpnode_ip:$bpnode_p2p_port" >> fullnode/config.ini



# sftp put config file to fullnode
sftp $fullnode1_username@$fullnode1_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/fullnode/* $eos_config_dir/$stage_name
quit
EOF

sftp $fullnode2_username@$fullnode2_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/fullnode/* $eos_config_dir/$stage_name
quit
EOF


echo "Running 'fullnode1' through Docker."
docker -H $fullnode1_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name/`date +%s`:/data \
       -p $fullnode1_http_port:8888 -p $fullnode1_p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Running 'fullnode2' through Docker."
docker -H $fullnode2_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name/`date +%s`:/data \
       -p $fullnode2_http_port:8888 -p $fullnode2_p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""

echo "Running 'nodeos' through Docker."
docker run -ti --detach --name bpnode-$stage_name \
       -v `pwd`:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $bpnode_http_port:8888 -p $bpnode_p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json


echo ""
echo "   View logs with: docker logs -f nodeos-bios"
echo ""

echo "Waiting 3 secs for nodeos to launch through Docker"
sleep 3

echo "Hit ENTER to continue"
read
