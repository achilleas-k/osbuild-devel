# OSBuild container setup

This document describes how to set up and run multiple containers for developing and testing *osbuild-composer* and *osbuild*. This setup requires running two containers, one for *osbuild-composer* and other for *osbuild-worker* and *osbuild* together.

## Overview

1. [Generate SSL certs](#generate-ssl-certs)
2. [Build container images](#build-container-images)
3. [Start multi-container environment](#start-multi-container-environment)
4. [Generate request data](#generate-request-data)
5. [Submit request](#submit-request)

### Source directory

The setup requires defining the path to the osbuild-composer source repository. This should be defined in the [`./docker/.env`](./docker/.env) file (as `$OSBUILD_COMPOSER_SOURCE`).

### Generate SSL certs

The [gen-certs.sh](./docker/gen-certs.sh) script is a copy of the certificate generation part of the `provision.sh` script from *osbuild-composer*. Run:
```
./docker/gen-certs.sh ./docker/openssl.cnf ./docker/config ./docker/config/ca
```
to generate cert files and place them into the [`config`](./docker/config) directory. This directory already contains configuration files for *osbuild-composer* and it will be mounted into the containers that need it.

### Build container images

To build the two container images, from the [./docker](./docker) directory, run:
```
docker-compose build
```

*The worker Dockerfile isn't in the main repository. For now, check out [the dockerfile-worker branch on my fork](https://github.com/achilleas-k/osbuild-composer/blob/docker-compose/distribution/Dockerfile-worker).*

### Start multi-container environment

To start both containers, from the [`./docker`](./docker) directory of this repository, run:
```
docker-compose up composer worker
```

*The [`docker-compose.yml`](./docker/docker-composer.yml) file defines some more containers which aren't documented yet.*

This will set up both containers with access to the [`./docker/config`](./docker/config) directory for configurations and certs. It will also set an internal network where the two containers can communicate via their service names. This is important for the certificates that are issued for the hostname `org.osbuild.composer`.

### Generate request data

The [`makedata.sh`](./makedata.sh) script is a copy of the request data generation section section of the `test/cases/api.sh` script from *osbuild-composer*. Running it will generate a file called `request.json` that can be used to submit a request to *osbuild-composer*. Note that the values in the `upload_requests` block are not valid and will cause the final upload steps to fail unless modified.

### Submit request

To submit a compose job, run:
```
curl -k --cert ./docker/composer-config/client-crt.pem --cacert ./docker/composer-config/ca-crt.pem --key ./docker/composer-config/client-key.pem https://172.30.0.10:9196/api/composer/v1/compose --data @request.json --header 'Content-Type: application/json'
```
to send the request with the data to the composer API.

The `-k` flag is necessary to make curl ignore the certificate mismatch for the hostname (`172.30.0.10`).
