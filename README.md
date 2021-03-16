# Development environment scripts for osbuild and osbuild-composer

1. [Container setup](#osbuild-container-setup)
2. [VM setup](#osbuild-vm-setup)

## OSBuild container setup

This section describes how to set up and run multiple containers for developing and testing *osbuild-composer* and *osbuild*. This setup requires running two containers, one for *osbuild-composer* and other for *osbuild-worker* and *osbuild* together.

**NB:** The container setup is going through a bit of a redesign right now, so some paths may differ, but the setup should still work as described.

### Overview

1. [Configure source directory](#configure-source-directory)
2. [Generate SSL certs](#generate-ssl-certs)
3. [Build container images](#build-container-images)
4. [Start multi-container environment](#start-multi-container-environment)
5. [Generate request data](#generate-request-data)
6. [Submit request](#submit-request)

#### Configure source directory

The setup requires defining the path to the osbuild-composer source repository. This should be defined in the [`./docker/.env`](./docker/.env) file (as `$OSBUILD_COMPOSER_SOURCE`).

#### Generate SSL certs

The [gen-certs.sh](./docker/gen-certs.sh) script is a copy of the certificate generation part of the `provision.sh` script from *osbuild-composer*. Run:
```
./docker/gen-certs.sh ./docker/openssl.cnf ./docker/config ./docker/config/ca
```
to generate cert files and place them into the [`config`](./docker/config) directory. This directory already contains configuration files for *osbuild-composer* and it will be mounted into the containers that need it.

#### Build container images

To build the two container images, from the [./docker](./docker) directory, run:
```
docker-compose build
```

*The worker Dockerfile isn't in the main repository. For now, check out [the dockerfile-worker branch on my fork](https://github.com/achilleas-k/osbuild-composer/blob/docker-compose/distribution/Dockerfile-worker).*

#### Start multi-container environment

To start both containers, from the [`./docker`](./docker) directory of this repository, run:
```
docker-compose up composer worker
```

*The [`docker-compose.yml`](./docker/docker-composer.yml) file defines some more containers which aren't documented yet.*

This will set up both containers with access to the [`./docker/config`](./docker/config) directory for configurations and certs. It will also set an internal network where the two containers can communicate via their service names. This is important for the certificates that are issued for the hostname `org.osbuild.composer`.

#### Generate request data

The [`makedata.sh`](./makedata.sh) script is a copy of the request data generation section section of the `test/cases/api.sh` script from *osbuild-composer*. Running it will generate a file called `request.json` that can be used to submit a request to *osbuild-composer*. Note that the values in the `upload_requests` block are not valid and will cause the final upload steps to fail unless modified.

#### Submit request

To submit a compose job, run:
```
curl -k --cert ./docker/composer-config/client-crt.pem --cacert ./docker/composer-config/ca-crt.pem --key ./docker/composer-config/client-key.pem https://172.30.0.10:9196/api/composer/v1/compose --data @request.json --header 'Content-Type: application/json'
```
to send the request with the data to the composer API.

The `-k` flag is necessary to make curl ignore the certificate mismatch for the hostname (`172.30.0.10`).

## OSBuild VM setup

The [vm](./vm) directory contains scripts for setting up a VM for developing and testing *osbuild-composer* and *osbuild*.  This setup is meant for testing local setups (i.e., non-cloud APIs) though the Weldr API.  Some scripts use the [composer-cli](https://weldr.io/lorax/composer-cli.html), which is included in the VM too for convenience.

### Overview

1. [Setting up](#setting-up)
2. [Starting](#starting)
3. [Updating](#updating)
4. [Convenience scripts](#convenience-scripts)

### Setting up

Some things to note (and potentially change) before running:
- All the scripts in this section assume that the VM is reachable at `localvm`.  The following host configuration is assumed.  Add and/or adjust in `$HOME/.ssh/config` as necessary:
```
Host localvm
    Hostname localhost
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    Port 2222
```
- The script creates a user with the same username as the user running the script.  A public key is added to the user account, taken from `$HOME/.ssh/<hostname>.pub`.  This can be changed in the [vm/start](vm/start) script.
- The locations of the images to run for each VM should be set in the [vm/start](vm/start) script.
- Similarly, the locations of the sources for *osbuild* and *osbuild-composer* should be set in the [vm/update](vm/update) script.

### Starting

The [vm/start](./vm/start) script starts the VM, installs *osbuild* and *osbuild-composer* from the distribution repositories, and starts the services.  It requires specifying a distro, either `rhel` (RHEL 8.4) or `fedora` (Fedora 33) must be specified on the command line. *The RHEL 8.4 repositories require a RH VPN connection to access.*

### Updating

The [vm/update](./vm/update) script stops the container services, copies the sources for the two projects into the VM, updates the projects, and restarts the services.

For *osbuild*, it builds, packages, and installs RPMs.

For *osbuild-composer*, it simply compiles the binaries for `osbuild-composer` and `osbuild-worker` and copies them to the system-wide path using `make install`.  This is much faster than building RPMs, but be aware it may not update other system-wide configurations.  Check the [osbuild-composer](https://github.com/osbuild/osbuild-composer) [Makefile](https://github.com/osbuild/osbuild-composer/blob/main/Makefile) to make sure the command updates the component you are developing and/or testing.

### Convenience scripts

- [pushbp](./pushbp) copies all blueprints from the [blueprints](./blueprints) directory of this repository into the container and pushes them to *osbuild-composer*.
- [startcompose](./startcompose) takes two arguments, a blueprint name and a compose type, and starts a compose job in the VM.
- [dlcompose](./dlcompose) takes two arguments, a UUID and a path, and downloads the result of the given compose (defined by the UUID) to the path as a single tarball.  Specifying `all` in place of the UUID will download the results of all *finished* and *failed* jobs.
