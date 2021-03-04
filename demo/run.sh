#!/bin/bash

COMPOSE_FILE=${1:-docker-compose.yml}

echo -e "\033[0;32mStarting.. $COMPOSE_FILE\033[0m"
docker-compose -f "$COMPOSE_FILE" -p "emqx_edge_stack" up -d || { echo "Error: fail to run docker compose";  exit 1; }

# Define variables
LOCALHOST="http://127.0.0.1"
KUIPER="$LOCALHOST:9081"
NEURON="$LOCALHOST:7000/api/v1"

# Define healthCheck function
## Check if the service is ready. $1 is the health check function
HealthCheck () {
  counter=0
  delay=5
  echo "Health check executing: $1"
  while [ $counter -le 10 ]; do
      status_code=$($1)
      curl_code=$?

      # Curl error code CURLE_COULDNT_CONNECT (7) means fail to connect to host or proxy.
      # It occurs, in particular, in case when connection refused.
      if [ $curl_code -ne 0 ] && [ $curl_code -ne 7 ]; then
          echo "Connection is not established"
          exit 1
      fi

      if [ $curl_code = 7 ] || [ $status_code = 503 ]; then
          echo "Connection has not been established yet, because connection refused or service unavailable. Trying to connect again"
          sleep $delay
          let counter=$counter+$delay
          continue
      elif [ $status_code = 200 ] || [ $status_code = 201 ]; then
          echo "Connection is successfully established"
          break
      else
          echo "Service unavailable with status: $status_code"
          break
      fi
  done
}

NeuronCheck () {
  HealthCheck "curl -X PUT -d \"{\\\"func\\\":74,\\\"wtrm\\\":\\\"neruon\\\"}\" -s -o /dev/null -w %{http_code} $NEURON/funcno74"
}

## $1 is the url to ping
PingCheck () {
  HealthCheck "curl -L -s -o /dev/null -w %{http_code} $1"
}

## Init neuron
echo "init neuron"
NeuronCheck
### Get uuid
json=$(curl -s -X PUT -d "{\"func\":74,\"wtrm\":\"neruon\"}" $NEURON/funcno74 || { echo "Error: fail to add default neuron node";})
nid=$(echo $json | sed "s/{.*\"uuid\":\"\([^\"]*\).*}/\1/g")
echo "get neuron uuid $nid"

## Init Kuiper
echo "init kuiper"
PingCheck $KUIPER/ping
### Add tdengine plugin
#curl -d "{\"name\":\"tdengine\",\"file\":\"$TDENGINE_PLUGIN\",\"shellParas\": [\"2.0.3.1\"]}" $KUIPER/plugins/sinks || echo "Error: fail to add taos plugin to kuiper"
### Create neuron stream
curl -s -d "{\"sql\":\"CREATE STREAM neuron() WITH (DATASOURCE=\\\"Neuron/Telemetry/$nid\\\")\"}" $KUIPER/streams ||  echo "Error: fail to create stream"

echo -e ""
echo "All set up, enjoy"