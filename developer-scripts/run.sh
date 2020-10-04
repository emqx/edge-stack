#!/bin/sh

COMPOSE_FILE=${1:-docker-compose.yml}

echo -e "\033[0;32mStarting.. $COMPOSE_FILE\033[0m"
docker-compose -f "$COMPOSE_FILE" up -d || { echo "Error: fail to run docker compose";  exit 1; }

# Define variables
LOCALHOST="http://127.0.0.1"
KUIPER="$LOCALHOST:9081"
MANAGER="$LOCALHOST:9082/api"
GRAFANA="http://admin:admin@127.0.0.1:3000/api"
JSONHEADER="Content-Type: application/json"
KUIPER_ENDPOINT="http://manager-kuiper:9081"
NANO_ENDPOINT="http://manager-nano:8081"
NEURON_ENDPOINT="http://manager-neuron:7000"
TAOS_ENDPOINT="http://taos:6041"
#TDENGINE_PLUGIN="http://52.53.170.189/kuiper-plugins/0.9.1-26-g6a718e3/debian/sinks/tdengine_amd64.zip"

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
### Add tdengine plugin
#curl -d "{\"name\":\"tdengine\",\"file\":\"$TDENGINE_PLUGIN\",\"shellParas\": [\"2.0.3.1\"]}" $KUIPER/plugins/sinks || echo "Error: fail to add taos plugin to kuiper"
### Create nano stream
#curl -d '{"sql":"CREATE STREAM extK (count bigint) WITH (DATASOURCE=\"users\", FORMAT=\"JSON\")"}' $KUIPER/streams ||  echo "Error: fail to create stream"
### Create rule

## Init manager
echo "init manager"
json=$(curl $MANAGER/login -sH "$JSONHEADER" -d '{"username":"admin","password":"public"}')
token=$(echo $json | sed "s/{.*\"token\":\"\([^\"]*\).*}/\1/g")
### Add nodes: neuron, nano, kuiper
curl -d "{\"category\":0, \"nodetype\":0, \"name\":\"local_kuiper\", \"endpoint\":\"$KUIPER_ENDPOINT\"}" -H "$JSONHEADER" -H "Authorization: $token" $MANAGER/nodes || { echo "Error: fail to add default kuiper node";}
curl -d "{\"category\":1, \"nodetype\":0, \"name\":\"local_neuron\", \"endpoint\":\"$NEURON_ENDPOINT\", \"apiVersion\": 1}" -H "$JSONHEADER" -H "Authorization: $token"  $MANAGER/nodes || { echo "Error: fail to add default neuron node";}
curl -d "{\"category\":2, \"nodetype\":0, \"name\":\"local_nano\", \"endpoint\":\"$NANO_ENDPOINT\", \"apiVersion\": 4,\"key\": \"admin\",\"secret\": \"public\"}" -H "$JSONHEADER" -H "Authorization: $token"  $MANAGER/nodes || { echo "Error: fail to add default nano node";}

## Init Grafana
echo "init grafana"
### Create datasource
curl --basic -u admin:admin -X POST -H "Content-Type: application/json" --data-binary '{"name":"TDengine","type":"taosdata-tdengine-datasource","typeLogoUrl":"","access":"proxy","url":"http://taos:6041","password":"","user":"","database":"","basicAuth":false,"basicAuthUser":"","basicAuthPassword":"","withCredentials":false,"isDefault":true,"jsonData":{"user":"root","password":"taosdata"},"secureJsonFields":{},"version":1,"readOnly":false}' $GRAFANA/datasources || { echo "Error: fail to create grafana data source";}
### Create report
curl --basic -u admin:admin -X POST -H "Content-Type: application/json" --data-binary "{\"dashboard\":{\"annotations\":{\"list\":[{\"builtIn\":1,\"datasource\":\"-- Grafana --\",\"enable\":true,\"hide\":true,\"iconColor\":\"rgba(0, 211, 255, 1)\",\"name\":\"Annotations & Alerts\",\"type\":\"dashboard\"}]},\"editable\":true,\"gnetId\":null,\"graphTooltip\":0,\"id\":null,\"links\":[],\"panels\":[{\"aliasColors\":{},\"bars\":false,\"dashLength\":10,\"dashes\":false,\"datasource\":\"TDengine\",\"fieldConfig\":{\"defaults\":{\"custom\":{}},\"overrides\":[]},\"fill\":1,\"fillGradient\":0,\"gridPos\":{\"h\":9,\"w\":12,\"x\":0,\"y\":0},\"hiddenSeries\":false,\"id\":2,\"legend\":{\"avg\":false,\"current\":false,\"max\":false,\"min\":false,\"show\":true,\"total\":false,\"values\":false},\"lines\":true,\"linewidth\":1,\"nullPointMode\":\"null\",\"options\":{\"alertThreshold\":true},\"percentage\":false,\"pluginVersion\":\"7.2.0\",\"pointradius\":2,\"points\":false,\"renderer\":\"flot\",\"seriesOverrides\":[],\"spaceLength\":10,\"stack\":false,\"steppedLine\":false,\"targets\":[{\"refId\":\"A\",\"sql\":\"select ts, temperature from db.t;\",\"target\":\"select metric\",\"type\":\"timeserie\"}],\"thresholds\":[],\"timeFrom\":null,\"timeRegions\":[],\"timeShift\":null,\"title\":\"Panel Title\",\"tooltip\":{\"shared\":true,\"sort\":0,\"value_type\":\"individual\"},\"type\":\"graph\",\"xaxis\":{\"buckets\":null,\"mode\":\"time\",\"name\":null,\"show\":true,\"values\":[]},\"yaxes\":[{\"format\":\"short\",\"label\":null,\"logBase\":1,\"max\":null,\"min\":null,\"show\":true},{\"format\":\"short\",\"label\":null,\"logBase\":1,\"max\":null,\"min\":null,\"show\":true}],\"yaxis\":{\"align\":false,\"alignLevel\":null}}],\"schemaVersion\":26,\"style\":\"dark\",\"tags\":[],\"templating\":{\"list\":[]},\"time\":{\"from\":\"now-6h\",\"to\":\"now\"},\"timepicker\":{},\"timezone\":\"\",\"title\":\"taos\",\"uid\":\"\",\"version\":0,\"hideControls\":false},\"message\":\"\",\"overwrite\":false,\"folderId\":0}" $GRAFANA/dashboards/db || { echo "Error: fail to create grafana dashboard";}

echo "All set up, please create the report in Grafana"
