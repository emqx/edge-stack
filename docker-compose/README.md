# Docker Compose

Run docker compose in this folder.

```bash
docker-compose up -d
```

Edge manager will run at `http://yourhost:9082`. Two nodes are ready:

1. Kuiper: `http://manager-kuiper:9081`.
2. Emqx edge(nano): `http://manager-nano:9081`.

Notice that, these two nodes are running internally. If you need to access them externally, please modify the `ports` in docker-compose.yml to remove `127.0.0.1`. For example, kuiper ports `"127.0.0.1:9081:9081"` should be changed to `"9081:9081"`.

You can add nodes in the edge manager nodes page.

## Docker compose test

For testing docker images, modify the `docker-compose-test.yml` to point the image to local images and run it.

```bash
docker-compose -f docker-compose-test.yml up -d
```

Modify the `docker-compose-test.yml` to configure the ports, environment variables etc.
