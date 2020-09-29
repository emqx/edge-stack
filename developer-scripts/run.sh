#!/bin/sh

COMPOSE_FILE=${1:-docker-compose.yml}

echo "\033[0;32mStarting.. $COMPOSE_FILE\033[0m"
docker-compose -f "$COMPOSE_FILE" up -d || { echo "Error: fail to run docker compose";  exit 1; }

# Define variables
LOCALHOST="http://127.0.0.1"
KUIPER="$LOCALHOST:9081"
MANAGER="$LOCALHOST:9082/api"
GRAFANA="http://admin:admin@127.0.0.1:3000/api"
JSONHEADER="Content-Type: application/json"
KUIPER_ENDPOINT="http://manager-kuiper:9081"
NANO_ENDPOINT="http://manager-nano:8081"
TAOS_ENDPOINT="http://taos:6041"

## Init nano
### Create topic?

## Init neuron
### Create stream

## Init Taos
echo "init taos"
### Create DB
docker exec manager-taos bash -c 'taos -s "create database db; use db; create table t (ts timestamp, temperature int, humidity int);"' || echo "Error: fail to create sample taos db"

## Init Kuiper
echo "init kuiper"
### Add taos plugin

### Create nano stream
curl -d '{"sql":"CREATE STREAM extK (count bigint) WITH (DATASOURCE=\"users\", FORMAT=\"JSON\")"}' -H "$JSONHEADER" $KUIPER/streams || { echo "Error: fail to create stream";  exit 1; }
### Create rule

## Init manager
echo "init manager"
json=$(curl $MANAGER/login -sH "$JSONHEADER" -d '{"username":"admin","password":"public"}')
token=$(echo $json | sed "s/{.*\"token\":\"\([^\"]*\).*}/\1/g")
### Add nodes: neuron, nano, kuiper
curl -d "{\"category\":0, \"nodetype\":0, \"name\":\"local_kuiper\", \"endpoint\":\"$KUIPER_ENDPOINT\"}" -H "$JSONHEADER" -H "Authorization: $token" $MANAGER/nodes || { echo "Error: fail to add default kuiper node";}
curl -d "{\"category\":2, \"nodetype\":0, \"name\":\"local_nano\", \"endpoint\":\"$NANO_ENDPOINT\", \"apiVersion\": 4,\"key\": \"admin\",\"secret\": \"public\"}" -H "$JSONHEADER" -H "Authorization: $token"  $MANAGER/nodes || { echo "Error: fail to add default nano node";}

## Init Grafana
echo "init grafana"
### Create datasource
curl -d "{\"name\":\"root/taosdata\",\"type\":\"graphite\", \"url\":\"$TAOS_ENDPOINT\",\"access\":\"proxy\"}" -H "$JSONHEADER" $GRAFANA/datasources || { echo "Error: fail to create grafana data source";}
### Create report
echo "All set up, please create the report in Grafana"
