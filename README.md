# YawslDocker 🐳

**Yet Another WSL Docker** - A lightweight, Docker-enabled WSL distribution
based on Alpine Linux.

[![Build and Push yawsldocker](https://github.com/antoinemartin/yawsldocker/actions/workflows/yawsldocker.yml/badge.svg)](https://github.com/antoinemartin/yawsldocker/actions/workflows/yawsldocker.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Overview

YawslDocker is a custom WSL distribution designed to provide a seamless Docker
development experience on Windows. Built on Alpine Linux, it comes
pre-configured with Docker, BuildKit, and a beautiful Zsh environment powered by
Oh My Zsh and Powerlevel10k.

### ✨ Features

- 🐧 **Alpine Linux 3.23** - Lightweight and secure base
- 🐳 **Docker & Docker Compose** - Ready-to-use container runtime
- 🏗️ **BuildKit** - Advanced Docker build features
- 🎨 **Oh My Zsh + Powerlevel10k** - Beautiful and functional shell
- 🔐 **doas** - Lightweight sudo replacement
- 🌐 **TCP Docker daemon** - Accessible from Windows host
- 👤 **Non-root user** - Secure default user setup
- 🔧 **Pre-configured** - Works out of the box

## 📦 Quick Start

### Prerequisites

- Windows 10 version 2004 or higher, or Windows 11
- WSL 2 enabled
- Docker CLI installed on Windows (optional, for host access)

### Installation

#### Automated Installation (Recommended)

The easiest way to install YawslDocker is using the PowerShell installation
script:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://raw.githubusercontent.com/antoinemartin/yawsldocker/refs/heads/main/Get-YawslDocker.ps1 | Invoke-Expression
```

You can set environment variables instead:

- `$env:YAWSLDOCKER_VERSION` - Image version (default: `latest`)
- `$env:YAWSLDOCKER_NAME` - Distribution name (default: `yawsldocker`)
- `$env:YAWSLDOCKER_DIR` - Installation directory (default:
  `$env:LOCALAPPDATA\yawsldocker`)

Example:

```powershell
$env:YAWSLDOCKER_VERSION = "v1.0.0"
$env:YAWSLDOCKER_NAME = "mydocker"
$env:YAWSLDOCKER_DIR = "C:\WSL\mydocker"
Invoke-RestMethod -Uri https://raw.githubusercontent.com/antoinemartin/yawsldocker/refs/heads/main/Get-YawslDocker.ps1 | Invoke-Expression
```

#### Manual Installation (Alternative)

1. **Download the latest release:**

   ```powershell
   # Download from GitHub releases
   Invoke-WebRequest -Uri "https://github.com/antoinemartin/yawsldocker/releases/latest/download/yawsldocker.rootfs.tar.gz" -OutFile "yawsldocker.rootfs.tar.gz"
   ```

2. **Import into WSL:**

   ```powershell
   wsl --import yawsldocker C:\WSL\yawsldocker yawsldocker.rootfs.tar.gz
   ```

3. **Clean up:**
   ```powershell
   Remove-Item yawsldocker.rootfs.tar.gz
   ```

### Starting YawslDocker

1. **Start the Docker daemon:**

   ```powershell
   wsl -d yawsldocker --user root openrc default
   ```

2. **Access your new environment:**
   ```powershell
   wsl -d yawsldocker
   ```

### Using Docker from Windows Host

If you want to use the Docker CLI from Windows to access the Docker daemon
running in WSL:

1. **Install Docker CLI** (using Scoop):

   ```powershell
   scoop install docker
   ```

2. **Set the Docker host environment variable:**

   ```powershell
   $env:DOCKER_HOST="tcp://localhost"
   ```

3. **Test the connection:**
   ```powershell
   docker ps
   docker run --rm -it alpine:latest
   ```

### Working with Bind Mounts

When using bind mounts from Windows, the source path must be specified in Unix
format with `/mnt/c/...` notation:

```powershell
# Convert Windows path to WSL path
$unixPath = wsl -d yawsldocker wslpath "$env:APPDATA".Replace('\','\\')

# Use in docker command
docker run -v "${unixPath}:/data" alpine:latest
```

**Tip**: Create a PowerShell function for easy path conversion:

```powershell
function ConvertTo-WslPath {
    param([string]$Path)
    wsl -d yawsldocker wslpath ($Path -replace '\\','\\\\')
}

# Usage
$wslPath = ConvertTo-WslPath "C:\Users\MyUser\Documents"
docker run -v "${wslPath}:/workspace" alpine:latest
```

### Updating YawslDocker

To update YawslDocker while preserving your Docker images and containers, ensure
that docker is not running and follow these steps:

#### 1. Download and Import New Version

```powershell
$env:YAWSLDOCKER_NAME = "newdocker"
Invoke-RestMethod -Uri https://raw.githubusercontent.com/antoinemartin/yawsldocker/refs/heads/main/Get-YawslDocker.ps1 | Invoke-Expression
```

#### 2. Mount Old Docker Data

```powershell
wsl -d yawsldocker --user root sh -c 'mkdir -p /mnt/wsl/olddocker && mount --bind /var/lib/docker /mnt/wsl/olddocker'
```

#### 3. Synchronize Docker Data

```powershell
# Options: a: archive, q: quiet, H: preserve hard links, A: preserve ACLs, X: preserve extended attributes, S: sparse files, numeric-ids: preserve UIDs/GIDs
wsl -d newdocker --user root sh -c 'rsync -aqHAXS --numeric-ids /mnt/wsl/olddocker/ /var/lib/docker'
```

#### 4. Delete Old Distribution and Rename

```powershell
# Unmount old docker data
wsl -d yawsldocker --user root umount /mnt/wsl/olddocker

# Terminate both distributions
wsl --terminate yawsldocker
wsl --terminate newdocker

# Unregister the old distribution
wsl --unregister yawsldocker

# Rename newdocker to yawsldocker via registry
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
$distros = Get-ChildItem -Path $registryPath

foreach ($distro in $distros) {
    $distroName = (Get-ItemProperty -Path $distro.PSPath).DistributionName
    if ($distroName -eq "newdocker") {
        Set-ItemProperty -Path $distro.PSPath -Name "DistributionName" -Value "yawsldocker"
        Write-Host "Successfully renamed newdocker to yawsldocker"
        break
    }
}
```

#### 5. Verify the Update

```powershell
# List distributions
wsl -l -v

# Start the updated distribution
wsl -d yawsldocker --user root openrc default

# Verify Docker images and containers are preserved
wsl -d yawsldocker
docker images
docker ps -a
```

## 🏗️ What's Included

### Software Stack

- **Base OS**: Alpine Linux 3.23
- **Container Runtime**: Docker with Docker Compose
- **Build System**: BuildKit
- **Shell**: Zsh with Oh My Zsh
- **Theme**: Powerlevel10k
- **Security**: doas (sudo replacement)
- **Networking**: iproute2, socat, openssh
- **Development**: git, gnupg

### User Configuration

- **Default user**: `alpine` (non-root)
- **Groups**: `wheel`, `docker`
- **Shell**: Zsh with custom configuration
- **SSH**: Pre-configured with relaxed host checking
- **Docker**: Experimental features enabled

### Services

- **Docker daemon**: Listens on TCP (0.0.0.0:2376) and Unix socket
- **BuildKit daemon**: Advanced build features
- **OpenRC**: Service management

## 🔧 Configuration

### Docker Configuration

The Docker daemon is configured to:

- Listen on TCP port 2375 (accessible from Windows)
- Listen on Unix socket (for internal use)
- Run on system startup via OpenRC

### Shell Configuration

- **Oh My Zsh** with plugins: `git`, `zsh-autosuggestions`
- **Powerlevel10k** theme with lean configuration
- **Custom prompt** optimized for development workflow

### Security

- Non-root default user with Docker group membership
- doas configured for passwordless sudo for wheel group
- SSH configured with relaxed host key checking for development

## 🛠️ Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/antoinemartin/yawsldocker.git
cd yawsldocker

# Build the Docker image
docker build -t yawsldocker .

# Export as rootfs
docker run --rm yawsldocker tar -C / -c . | gzip > yawsldocker.rootfs.tar.gz

# Import into WSL
wsl --import yawsldocker-dev C:\WSL\yawsldocker-dev yawsldocker.rootfs.tar.gz
```

### Project Structure

```
yawsldocker/
├── Dockerfile          # Main build configuration
├── rc.conf             # OpenRC configuration
├── wsl.conf            # WSL-specific configuration
├── p10k.zsh            # Powerlevel10k theme configuration
├── RELEASE.md          # Release notes template
└── .github/
    └── workflows/
        └── yawsldocker.yml  # CI/CD pipeline
```

## 🚦 Usage Examples

### Basic Docker Operations

```bash
# Inside WSL
docker run hello-world
docker-compose up -d
docker build -t myapp .
```

### Development Workflow

```bash
# Start services
sudo openrc default

# Check status
sudo rc-status

# Development with hot reload
docker run -it -v $(pwd):/workspace alpine/git
```

### Advanced BuildKit Features

```bash
# Multi-platform builds
docker buildx build --platform linux/amd64,linux/arm64 .

# Build secrets
docker build --secret id=mysecret,src=./secret.txt .
```

## 🔍 Troubleshooting

### Docker Daemon Not Starting

```bash
# Check service status
sudo rc-status

# Start Docker manually
sudo rc-service docker start

# Check logs
sudo rc-service docker status
```

### Connection Issues from Windows

```bash
# Verify Docker is listening
sudo netstat -tlnp | grep 2375

# Test connection
telnet localhost 2375
```

### Permission Issues

```bash
# Add user to docker group
sudo addgroup $USER docker

# Restart WSL
wsl --terminate yawsldocker
```

## 📋 System Requirements

- **Windows**: 10 (2004+) or 11
- **WSL**: Version 2
- **Memory**: 2GB+ recommended
- **Storage**: 1GB+ for base system

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major
changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a local build
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file
for details.

## 🙏 Acknowledgments

- [Alpine Linux](https://alpinelinux.org/) - The base distribution
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Docker](https://docker.com/) - Container platform

## 📞 Support

- 🐛 **Issues**:
  [GitHub Issues](https://github.com/antoinemartin/yawsldocker/issues)
- 💬 **Discussions**:
  [GitHub Discussions](https://github.com/antoinemartin/yawsldocker/discussions)
- 📧 **Email**:
  [Issues only](https://github.com/antoinemartin/yawsldocker/issues/new)

---

**Made with ❤️ for the Docker + WSL community**
