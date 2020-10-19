# Developer Scripts

[English](README.MD)|[简体中文](README-CN.MD)

This folder contains scripts and docker compose files to quickly set up the EMQ X Edge Stack.

## Running on Linux

### Install docker & docker-compose

**Docker**

Refer to [install docker document](https://docs.docker.com/get-docker/) for more detailed information.

**Docker-compose**

Below is an example for how to install docker-compose in centos-7, you can find docker-compose install instruction for other Linux system through Google.

https://linuxize.com/post/how-to-install-and-use-docker-compose-on-centos-7/

### Up & running

For convenience, the `run.sh` will help you get up and running. It will add,

- The local Kuiper, Neuron and Edge nodes; 
- Setup the TDengine plugin in Kuiper; 
- Create a default database in TDengine and add it to Grafana data source.  

```bash
git clone git@github.com:emqx/edge-stack.git
cd $edge-stack
developer-scripts/run.sh
```

### Setup Neuron

**A Modbus TCP mockup tool**

TODO...

**Object settings**

TODO...

Import Neuron object settings... [neuron_batch_modbus_5.xlsx](neuron_batch_modbus_5.xlsx)

### Setup Kuiper

#### Create a Neuron stream

TODO..

#### Create a rule 

A rule will be created for subscribing data published by Neuron, and send the analysis result to TDengine. 

```json
{
  "sql": "SELECT tele[0]->Tag00001 AS temperature, tele[0]->Tag00002 AS humidity FROM neuron",
  "actions": [
    {
      "tdengine": {
        "ip": "taos",
        "port": 0,
        "user": "root",
        "password": "taosdata",
        "database": "db",
        "table": "t",
        "fields": ["temperature","humidity"],
        "provideTs": false,
        "tsFieldName": "ts"
      }
    }
  ]
}
```



### Query data in TDengine

TODO...

### Data visualization data with Grafana

TODO...



## How to reset test environment

If you having any problems with your environment, then you can run following command to reset your environment. 

```shell
cd developer-scripts
docker-compose stop
docker rm `docker ps -qa`
docker volume prune
```

*Please notice that command `docker rm docker ps -qa` will remove all of docker instances, if you have docker instances other than edge-stacks and do not want to have all of them removed, please remove edge stack instances one by one.*



## Appendix

### Run docker compose directly

The default running compose file is `docker-compose.yml`. To run another docker compose file, use:

```bash
./run.sh docker-compose-test.yml
```

To stop the current stack, run the command in the current folder.

```bash
docker-compose stop
```

Please refer to [docker compose doc](https://docs.docker.com/compose/reference/overview/) for more cli commands.

If you only need to start up all dependant docker container without initializing any data, you can just run the docker compose file directly.

### Run docker compose

Run docker compose in this folder.

```bash
docker-compose up -d
```

Edge manager will run at `http://yourhost:9082`. Two nodes are ready:

1. Kuiper: `http://manager-kuiper:9081`.
2. Edge: `http://manager-edge:8081`.
3. Neuron: `http://manager-neuron:7000`

Notice that, these three nodes are running internally. If you need to access them externally, please modify the `ports` in docker-compose.yml to remove `127.0.0.1`. For example, kuiper ports `"127.0.0.1:9081:9081"` should be changed to `"9081:9081"`.

You can add nodes in the edge manager nodes page.

### Run Docker compose test

For testing docker images, modify the `docker-compose-test.yml` to point the image to local images and run it.

```bash
docker-compose -f docker-compose-test.yml up -d
```

Modify the `docker-compose-test.yml` to configure the ports, environment variables etc.
