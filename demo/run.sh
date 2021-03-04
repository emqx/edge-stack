#!/bin/bash

COMPOSE_FILE=${1:-docker-compose.yml}

echo -e "\033[0;32mStarting.. $COMPOSE_FILE\033[0m"
docker-compose -f "$COMPOSE_FILE" -p "emqx_edge_stack" up -d || { echo "Error: fail to run docker compose";  exit 1; }

# Define variables
LOCALHOST="http://127.0.0.1"
KUIPER="$LOCALHOST:9081"
NEURON="$LOCALHOST:7000/api/v1"

## Init neuron
echo "init neuron"
### Get uuid
json=$(curl -X PUT -d "{\"func\":74,\"wtrm\":\"neruon\"}" $NEURON/funcno74 || { echo "Error: fail to add default neuron node";})
nid=$(echo $json | sed "s/{.*\"uuid\":\"\([^\"]*\).*}/\1/g")
echo "get neuron uuid $nid"

## Init Kuiper
echo "init kuiper"
### Add tdengine plugin
#curl -d "{\"name\":\"tdengine\",\"file\":\"$TDENGINE_PLUGIN\",\"shellParas\": [\"2.0.3.1\"]}" $KUIPER/plugins/sinks || echo "Error: fail to add taos plugin to kuiper"
### Create neuron stream
curl -d "{\"sql\":\"CREATE STREAM neuron() WITH (DATASOURCE=\\\"Neuron/Telemetry/$nid\\\")\"}" $KUIPER/streams ||  echo "Error: fail to create stream"

echo -e ""
echo "All set up, enjoy"