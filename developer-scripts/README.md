# Developer Scripts

This folder contains scripts and docker compose files to quickly set up the emqx edge stack.

## Running on linux

For convenience, the `run.sh` will help you get up and running. It will add the local kuiper, neuron and edge nodes; setup the taos plugin in kuiper; create a default database in TDEngine and add it to grafana data source. Switch to this folder and run:

```bash
./run.sh
```

The default running compose file is `docker-compose.yml`.
To run another docker compose file, use:

```bash
./run.sh docker-compose-test.yml
```

To stop the current stack, run the command in the current folder.

```bash
docker-compose stop
```

Please refer to [docker compose doc](https://docs.docker.com/compose/reference/overview/) for more cli commands.

## Run docker compose directly

If you only need to start up all dependant docker container without initializing any data, you can just run the docker compose file directly.

### Run docker compose

Run docker compose in this folder.

```bash
docker-compose up -d
```

Edge manager will run at `http://yourhost:9082`. Two nodes are ready:

1. Kuiper: `http://manager-kuiper:9081`.
2. Emqx edge: `http://manager-edge:8081`.
3. Neuron: `http://manager-neuron:7000`

Notice that, these three nodes are running internally. If you need to access them externally, please modify the `ports` in docker-compose.yml to remove `127.0.0.1`. For example, kuiper ports `"127.0.0.1:9081:9081"` should be changed to `"9081:9081"`.

You can add nodes in the edge manager nodes page.

### Run Docker compose test

For testing docker images, modify the `docker-compose-test.yml` to point the image to local images and run it.

```bash
docker-compose -f docker-compose-test.yml up -d
```

Modify the `docker-compose-test.yml` to configure the ports, environment variables etc.
