## Quick Start

### Automated Installation (Recommended)

Install YawslDocker using the PowerShell installation script:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://raw.githubusercontent.com/antoinemartin/yawsldocker/refs/heads/main/Get-YawslDocker.ps1 | Invoke-Expression
```

The script will automatically:

- Download the Docker image from GitHub Container Registry
- Extract the linux/amd64 layer
- Import it as a WSL distribution named `yawsldocker`

You can customize the installation with parameters:

```powershell
# Set environment variables for custom installation
$env:YAWSLDOCKER_VERSION = 'latest'
$env:YAWSLDOCKER_NAME = 'yawsldocker'
$env:YAWSLDOCKER_DIR = "$env:LOCALAPPDATA\yawsldocker"

# Then run the installer
Invoke-RestMethod -Uri https://raw.githubusercontent.com/antoinemartin/yawsldocker/refs/heads/main/Get-YawslDocker.ps1 | Invoke-Expression
```

### Manual Installation (Alternative)

Download the rootfs tarball and import it into WSL using the following commands:

```powershell
# Download the latest release
Invoke-WebRequest -Uri "https://github.com/antoinemartin/yawsldocker/releases/latest/download/yawsldocker.rootfs.tar.gz" -OutFile "yawsldocker.rootfs.tar.gz"

# Import into WSL
wsl --import yawsldocker "$env:LOCALAPPDATA\yawsldocker" yawsldocker.rootfs.tar.gz

# Clean up
Remove-Item yawsldocker.rootfs.tar.gz
```

## Starting and Using YawslDocker

After installation, start docker with the following command:

```powershell
wsl -d yawsldocker --user root openrc default
```

Install the docker cli, for instance via [scoop](https://scoop.sh/):

```powershell
scoop install docker
```

Define the `DOCKER_HOST` environment variable to access the docker instance:

```powershell
$env:DOCKER_HOST="tcp://localhost"
```

You can then use the docker cli as usual:

```console
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
```

## Working with Bind Mounts

When using bind mounts from Windows, specify paths in Unix format with
`/mnt/c/...`:

```powershell
# Convert Windows path to WSL path
$unixPath = wsl -d yawsldocker wslpath "$env:APPDATA".Replace('\','\\')

# Use in docker command
docker run -v "${unixPath}:/data" alpine:latest
```

### PowerShell Helper Function:

Your can create a helper function to convert Windows paths to WSL paths:

```powershell
function ConvertTo-WslPath {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Path
    )
    wsl -d yawsldocker wslpath ($Path -replace '\\','\\\\')
}

```

You can add it to your PowerShell profile for permanent availability.

**Usage examples:**

```powershell
# convert and use
$wslPath = ConvertTo-WslPath "C:\Users\MyUser\Documents"
docker run --rm -it -v "${wslPath}:/workspace" alpine:latest
```

```powershell
# convert on the fly
docker run --rm -it -v "$("$HOME\Documents" | ConvertTo-WslPath):/workspace" alpine:latest ls /workspace

```
