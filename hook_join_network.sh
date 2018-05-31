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


echo "Removing old nodeos data (you might be asked for your sudo password)..."
sudo rm -rf /tmp/nodeos-data

echo "Writing genesis.json"
echo $1 > genesis.json

# Your base_config.ini shouldn't contain any `producer-name` nor `private-key`
# nor `enable-stale-production` statements.
echo "Copying base config"
cp base_config.ini config.ini
echo "$2" >> config.ini
echo "$4" >> config.ini
echo "p2p-peer-address = 10.10.0.54:19876" >> config.ini
echo "private-key = [\"$PUBKEY\",\"$PRIVKEY\"]" >> config.ini

# add none bp fullnode
rm -rf fullnode
mkdir fullnode
cp bash_config.ini fullnode/config.ini
cp genesis.json fullnode/genesis.json
echo "$2" >> fullnode/config.ini
echo "$4" >> fullnode/config.ini
echo "p2p-peer-address = 10.10.0.229:9876" >> fullnode/config.ini



# sftp put config file to fullnode
sftp centos@10.10.0.9 << EOF
rm /eos/*
put `pwd`/fullnode/* /eos/
quit
EOF

sftp ubuntu@10.10.0.54 << EOF
rm /eos/*
put `pwd`/fullnode/* /eos/
quit
EOF

echo "Running 'fullnode' through Docker."
docker -H 10.10.0.54:5555 run -ti --detach --name fullnode \
       -v /eos:/etc/nodeos \
       -p 18888:8888 -p 19876:9876 \
       eoscanada/eos:dawn-v4.2.0 \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json 

echo "Running 'nodeos' through Docker."
docker run -ti --detach --name nodeos-bios \
       -v `pwd`:/etc/nodeos \
       -p 8888:8888 -p 9876:9876 \
       eoscanada/eos:dawn-v4.2.0 \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --genesis-json=/etc/nodeos/genesis.json \
                             --config-dir=/etc/nodeos

echo ""
echo "   View logs with: docker logs -f nodeos-bios"
echo ""

echo "Waiting 3 secs for nodeos to launch through Docker"
sleep 3

echo "Hit ENTER to continue"
read
