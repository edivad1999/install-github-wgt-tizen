# Tizen GitHub WGT Installer

[![Build and Publish Docker Image](https://github.com/YOUR_USERNAME/tizen-github-wgt-installer/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/YOUR_USERNAME/tizen-github-wgt-installer/actions/workflows/docker-publish.yml)

A generalized Docker container for installing any Tizen `.wgt` package on Samsung Smart TVs. This tool simplifies the process of downloading, optionally signing, and installing Tizen applications from GitHub releases or any direct download URL.

> **Note:** Replace `YOUR_USERNAME` in all examples with your GitHub username or organization name.

## Features

- 🚀 Install any Tizen app from a direct `.wgt` URL
- 🔐 Optional package signing with custom certificates
- 🐳 Docker-based for easy cross-platform usage
- 📦 No SDK installation required on your machine
- 🤖 Automated builds published to GitHub Container Registry

## Prerequisites

### On Your Computer

- Install [Docker](https://www.docker.com/get-started/)
- Enable any necessary [Virtualization](https://support.microsoft.com/en-us/windows/enable-virtualization-on-windows-11-pcs-c5578302-6e43-4b4b-a449-8ced115f58e1) features
- Ensure you are connected to the same network as your Samsung TV

### On Your Samsung TV

#### 1. Enable Developer Mode

- Open the "Smart Hub" on your TV
- Select the "Apps" panel
- Press the "123" button (or long press Home) and type "12345" with the on-screen keyboard
- Toggle the `Developer` switch to `On`
- Enter the `Host PC IP` address of the computer running this container

#### 2. Find Your TV's IP Address

Exact instructions vary by TV model. Generally found in Settings → Network or Settings → About.

Make note of this IP address as you'll need it for installation.

#### 3. Uninstall Existing App (If Reinstalling)

If you're reinstalling an app, uninstall the existing version first. Follow [Samsung's uninstall instructions](https://www.samsung.com/in/support/tv-audio-video/how-to-uninstall-an-app-on-samsung-smart-tv/).

## Installation

The Docker image is automatically built and published to GitHub Container Registry.

### Pull the Latest Image

```bash
docker pull ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest
```

## Usage

### Basic Installation

```bash
docker run --rm ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest <TV_IP> <WGT_URL>
```

**Arguments:**
- `<TV_IP>` - IP address of your Samsung TV (required)
- `<WGT_URL>` - Direct URL to the `.wgt` file (required)
- `[CERT_PASSWORD]` - Certificate password for custom signing (optional)

### Examples

#### Install Jellyfin from GitHub Releases

```bash
docker run --rm ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest \
  192.168.0.10 \
  "https://github.com/jeppevinkel/jellyfin-tizen-builds/releases/download/2024-11-24-0431/Jellyfin.wgt"
```

#### Install with Custom Certificates

For newer TV models that require custom certificates:

```bash
docker run --rm \
  -v "$(pwd)/author.p12":/certificates/author.p12 \
  -v "$(pwd)/distributor.p12":/certificates/distributor.p12 \
  ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest \
  192.168.0.10 \
  "https://example.com/app.wgt" \
  'YourCertPassword123!'
```

### ARM Platforms (Apple Silicon, Raspberry Pi)

For ARM-based systems like MacOS M1/M2/M3 chips:

1. Ensure Docker has the "Virtualization Framework" enabled
2. Verify qemu is installed:
   ```bash
   docker run --rm --platform linux/amd64 alpine uname -m
   ```
   Should output: `x86_64`

3. Add `--platform linux/amd64` to your docker command:
   ```bash
   docker run --rm --platform linux/amd64 \
     ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest \
     192.168.0.10 \
     "https://example.com/app.wgt"
   ```

## Custom Certificates

Recent Samsung TV models may require apps to be signed with certificates specific to your TV.

See [Samsung's official documentation](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html) for creating certificates.

To use custom certificates:
1. Create `author.p12` and `distributor.p12` files
2. Mount them to `/certificates/` in the container
3. Provide the certificate password as the third argument

## Troubleshooting

### Common Errors

**`library initialization failed - unable to allocate file descriptor table`**

Add `--ulimit nofile=1024:65536` to your docker command:

```bash
docker run --ulimit nofile=1024:65536 --rm \
  ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest <TV_IP> <WGT_URL>
```

**`install failed[118, -11], reason: Author certificate not match`**

Uninstall the existing app from your Samsung TV, then run the installation again.

**`install failed[118, -12], reason: Check certificate error : Invalid certificate chain`**

Your TV model requires custom certificates. See the Custom Certificates section above.

**`Unable to find the TV name`**

Ensure:
1. TV is in Developer Mode
2. TV's "Host PC IP" is set to your computer's IP address
3. TV and computer are on the same network
4. No firewall is blocking the connection

### Success Indicators

If successful, you'll see output similar to:

```
Installed the package: Id(com.example.app)
Tizen application is successfully installed.
Total time: 00:00:12.205
```

The app will appear in: **Apps → Downloaded** (scroll down)

## Development

### Building Locally

To build and run locally:

```bash
# Build the image
docker build -t tizen-installer .

# Run it
docker run --rm tizen-installer <TV_IP> <WGT_URL>
```

### Automated Builds

This project uses GitHub Actions to automatically build and publish Docker images to GitHub Container Registry.

**Triggers:**
- Push to `main` or `master` branch → builds `latest` tag
- Push version tags (e.g., `v1.0.0`) → builds versioned tags
- Pull requests → builds but doesn't publish

**Available Tags:**
- `latest` - Latest build from main branch
- `v1.0.0` - Specific version (when tagged)
- `v1.0` - Major.minor version
- `v1` - Major version only
- `main-abc123` - Commit SHA on main branch

**Workflow file:** `.github/workflows/docker-publish.yml`

### Creating a Release

To create a new versioned release:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

The GitHub Action will automatically build and publish the image with tags:
- `ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:latest`
- `ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:v1.0.0`
- `ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:v1.0`
- `ghcr.io/YOUR_USERNAME/tizen-github-wgt-installer:v1`

## Finding Tizen Apps

Many Tizen apps are distributed via GitHub releases. Look for:
- Files with `.wgt` extension
- Direct download links in release assets
- Pre-built packages in repositories

## Credits

This project was inspired by:
- [install-jellyfin-tizen](https://github.com/Georift/install-jellyfin-tizen) - Original Jellyfin installer
- [jellyfin-tizen](https://github.com/jellyfin/jellyfin-tizen) - Jellyfin for Tizen
- [vitalets/docker-tizen-webos-sdk](https://github.com/vitalets/docker-tizen-webos-sdk) - Docker container with Tizen SDK

## License

MIT License - Feel free to use and modify as needed.
