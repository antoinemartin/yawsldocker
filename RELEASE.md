## Quick Start

Download the rootfs tarball and import it into WSL using the following command:

```bash
wsl --import yawsldocker yawsldocker.rootfs.tar.gz
```

After importing, you can start docker with the following command:

```bash
wsl -d yawsldocker --user root openrc default
```

Install the docker cli, for instance via [scoop](https://scoop.sh/):

```powershell
scoop install docker
```

and define the `DOCKER_HOST` environment variable to access the docker instance:

````

You can then use the docker cli as usual.

```bash
PS> $env:DOCKER_HOST="tcp://localhost:2376"
PS> docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
PS> docker run --rm -it alpine:latest
/ # cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.22.1
PRETTY_NAME="Alpine Linux v3.22"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://gitlab.alpinelinux.org/alpine/aports/-/issues"
/ # exit
PS> docker images
REPOSITORY                               TAG             IMAGE ID       CREATED          SIZE
alpine                                   latest          9234e8fb04c4   3 weeks ago      8.31MB
````
