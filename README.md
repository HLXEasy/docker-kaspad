# Kaspa as Docker container

Dockerized version of [kaspad](https://github.com/kaspanet/kaspad), the Kaspa Daemon and it's cmdline tools.

## License
* SPDX-FileCopyrightText: © 2022 Kaspa Developers
* SPDX-License-Identifier: MIT

## Usage

This repository contains some compose files for easy usage of provided Docker images.

### kaspad standalone

To simple start kaspad as a container, you can use `docker-compose-kaspad.yaml` like this:

```bash
docker compose -f docker-compose-kaspad.yaml up --detach
```

This will start `kaspad` on a container instance and put all data onto a separate Docker volume. So these data is persistent and will be reused if the container is destroyed/restarted.

To see the logs just use this cmd:

```bash
docker compose -f docker-compose-kaspad.yaml logs -f
```

To shutdown the instance properly, you should use this cmd:

```bash
docker compose -f docker-compose-kaspad.yaml down
```

### kaspad with kaspawallet

With the compose file `docker-compose-kaspawallet.yaml` it is possible to run kaspad and kaspawallet. In detail there will be a container which runs `kaspad` and a second one which runs `kaspawallet`.

The `kaspad` Container is similar to the standalone version from the section before. The `kaspawallet` container interacts with the `kaspad` container and uses it's own Docker volume to persist data.

## Build from scratch

To build from scratch you can use the helper script `buildImages.sh`. This script will perform the following steps:

* Optionally create and run a local Docker registry

  To build multi arch images the usage of a Docker registry is required. So if you want to build pure locally (without pushing to a public registry), a local Registry is started.

* Create a Docker BuildX builder instance
* Build and push Docker images for all supported architectures

  The "build" is a real build. To do so the [kaspad Github repository](https://github.com/kaspanet/kaspad) is cloned. After that the latest release tag will be checked out and build. Currently as of 2023-01-01 this is [v0.12.11](https://github.com/kaspanet/kaspad/releases/tag/v0.12.11). The resulting Docker image is based on [Alpine Linux](https://www.alpinelinux.org/) and contains the binaries `genkeypair`, `kaspactl`, `kaspad`, `kaspaminer` and `kaspawallet`, all installed at `/usr/local/bin/`.

Here's the help output of the build script:

```bash
❯ ./buildImages.sh -h

    Helper script to build and push multiarch kaspad Docker image.

    Per default a local Docker registry at port 5000 is spawned. To use
    hub.docker.io, have a look at options -r and -a below.

    Usage: ./buildImages.sh [options]

    Options:
    -a <account-name>
        .. If a remote registry shoule be used (see option -r), you need to
           give the corresponding account name. Currently only DockerHub is
           supported.
    -b <builder_name>
        .. Name of Docker builder. Default: kaspa_builder
    -f  .. Force creation of Docker builder. If already existing, the
           builder will be removed and recreated.
    -p <platform-list>
        .. List of plattforms separated by comma.
           Default: linux/arm64/v8,linux/amd64
    -r  .. Use remote Docker registry. Without this option, a local registry
           instance at port 5000 will be spawned.
    -t <tag>
        .. Image tag to use. Default: latest
    -h  .. Show this help

```

### Simple local build:

```bash
❯ ./buildImages.sh
Info   : Checking local Docker registry
...
Info   :  -> Done
Info   : Get the image with the following cmd:
Info   : docker pull 192.168.248.226:5000/docker-kaspad:latest
```

Notice the last line on the output, which shows the cmd to pull the image.

_Note: The IP there is the automatically determined by the build script to access the local Docker registry and might be different at your setup. As the local build is using http, you need to activate usage of insecure registries on your Docker configuration and add the local registry explicitly._

Example for Docker Desktop (Windows):

```json
{
  "insecure-registries": [
    "192.168.248.226:5000"
  ]
}
```

After this is configured, docker pull should work as expected:

```bash
❯ docker pull 192.168.248.226:5000/docker-kaspad:latest
latest: Pulling from docker-kaspad
...
Status: Downloaded newer image for 192.168.248.226:5000/docker-kaspad:latest
192.168.248.226:5000/docker-kaspad:latest
```



### Build using remote registry

To build the images using a remote registry, you need to login to that registry, so that the build script is able to push the image layers and all the created metadata:
```bash
❯ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: hlxeasy
Password:
Login Succeeded
```

To push to a remote registry you need to use optione `-r` and `-a` with your DockerHub account name. Example:

```bash
❯ ./buildImages.sh -r -a hlxeasy
Info   : Checking local Docker registry
...
Info   :  -> Done
Info   : Get the image with the following cmd:
Info   : docker pull hlxeasy/docker-kaspad:latest
```
