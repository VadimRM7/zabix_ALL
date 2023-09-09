#!/bin/bash

docker-compose -f $HOME/kroma-up/docker-compose.yml --profile validator down -v
rm -rf kroma-up/
docker volume rm kroma-up_db
echo "yes" | sudo -u geth /home/geth/eth-docker/ethd terminate
