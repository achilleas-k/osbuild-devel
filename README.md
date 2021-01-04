# OSBuild container setup

This document describes how to set up and run multiple containers for developing and testing *osbuild-composer* and *osbuild*. This setup requires running two containers, one for *osbuild-composer* and other for *osbuild-worker* and *osbuild* together.

## Overview

1. [Generate SSL certs](#generate-ssl-certs)
2. [Build container images](#build-container-images)
3. [Start multi-container environment](#start-multi-container-environment)
4. [Generate request data](#generate-request-data)
5. [Submit request](#submit-request)

### Generate SSL certs

The [mkcerts.sh](./docker/mkcerts.sh) script is a copy of the certificate generation part of the `provision.sh` script from *osbuild-composer*. Run:
```
./docker/mkcerts.sh ./docker/composer-config
```
to generate cert files and place them into the `composer-config` directory. This directory already contains configuration files for *osbuild-composer* and it will be mounted into both containers.

### Build container images

To build the two container images, from the [*osbuild-composer*](https://github.com/osbuild/osbuild-composer) repository root, run:
```
docker build -f ./distribution/Dockerfile-worker . --tag local/osbuild-worker

docker build -f ./distribution/Dockerfile-ubi . --tag local/osbuild-composer
```

Note that the container for *osbuild-worker* clones *osbuild* from GitHub and installs it in the container. If you want to work on *osbuild* and test your local version with this method, you will have to change the Dockerfile to copy the sources from your local clone.

### Start multi-container environment

To start both containers, from the [`./docker`](./docker) directory of this repository, run:
```
docker-compose up
```

This will set up both containers with access to the [`./docker/composer-config`](./docker/composer-config) directory for configurations and certs. It will also set an internal network where the two containers can communicate via their service names. This is important for the certificates that are issued for the hostname `composer`.

### Generate request data

The [`makedata.sh`](./makedata.sh) script is a copy of the request data generation section section of the `test/cases/api.sh` script from *osbuild-composer*. Running it will generate a file called `request.json` that can be used to submit a request to *osbuild-composer*. Note that the values in the `upload_requests` block are not valid and will cause the final upload steps to fail unless modified.

### Submit request

To submit a compose job, first run:
```
docker cp request.json osbuild_composer_1:.
```
to copy the `request.json` file into the composer container and then run:
```
docker exec -it osbuild_composer_1 curl --cert /etc/osbuild-composer/client-crt.pem --cacert /etc/osbuild-composer/ca-crt.pem --key /etc/osbuild-composer/client-key.pem https://composer/api/composer/v1/compose --data @request.json --header 'Content-Type: application/json'
```
to send the request with the data to the composer API.

Note that this doesn't necessarily need to be sent from inside the `composer` container. The main issue is that the request needs to be sent to the composer API at the hostname `composer`, which matches the SSL certs we generated earlier. Any container in the same network will do, since the internal docker-compose resolver will use that hostname to point to the `composer` container. Other solutions for this could be:
- Using the `worker` container instead (not really any difference, practically).
- Using a dedicated *client* container that also has access to the certs (i.e., also maps `./composer-config` to `/etc/osbuild-composer`).
- Configuring the host machine to resolve the name `composer` to the IP address of the composer container: `172.30.0.10` (e.g., by setting it in `/etc/hosts`).
- Generating the certificates so that they are valid for both `composer` and `localhost`, publishing the `composer` container port to the host machine, and using the address `https://localhost:<hostport>` to send the request.
