# Docker Compose Usage Guide

This guide explains how to use Docker Compose to easily install multiple Tizen apps on your Samsung TV using environment variables.

## Quick Start

### 1. Setup Environment

Copy the example environment file and configure your TV IP:

```bash
cp .env .env
```

Edit `.env` and set your TV IP address:

```env
TV_IP=192.168.0.10
```

### 2. Install Apps

Simple commands to install apps:

```bash
# Install Jellyfin (latest version)
docker compose up jellyfin

# Install Moonlight (latest version)
docker compose up moonlight

# Install Litefin (latest version)
docker compose up litefin

# Install custom app (configure CUSTOM_* variables in .env first)
docker compose up custom
```

## Environment Variable Approach

The installer now supports a flexible environment variable approach where you specify:

1. **`REPO_URL`** - The GitHub repository URL (mandatory)
2. **`WGT_FILE`** - The .wgt filename (mandatory, supports version placeholders)
3. **`VERSION`** - Specific release version (optional - fetches latest if not specified)

### Version Placeholders (Parametric Releases)

When a project embeds the release version in its asset filenames, put a placeholder in
`WGT_FILE` instead of hardcoding the version:

| Placeholder | Expands to | Example (tag `v1.8.0`) |
|-------------|------------|------------------------|
| `{version}` | Release tag without the leading `v` | `1.8.0` |
| `{tag}`     | Release tag as-is | `v1.8.0` |

The leading `v` is only stripped from v-prefixed version tags, so date/build style tags
(`2024-11-24-0431`, `samsung_wasm-19389899315`) are left untouched.

### Example Configuration

```env
# Jellyfin with latest version
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
JELLYFIN_VERSION=

# Jellyfin with specific version
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
JELLYFIN_VERSION=2024-11-24-0431
```

## Available Services

| Service | App | Description |
|---------|-----|-------------|
| `jellyfin` | Jellyfin | Media server client (configure via `JELLYFIN_*` env vars) |
| `moonlight` | Moonlight | Game streaming client (configure via `MOONLIGHT_*` env vars) |
| `litefin` | Litefin | Lightweight Jellyfin client, versioned asset names (configure via `LITEFIN_*` env vars) |
| `custom` | Any App | Install any app (configure via `CUSTOM_*` env vars) |

## Configuration Examples

### Install Latest Jellyfin

```env
TV_IP=192.168.0.10
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
JELLYFIN_VERSION=
```

```bash
docker compose up jellyfin
```

### Install Specific Jellyfin Version

```env
TV_IP=192.168.0.10
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
JELLYFIN_VERSION=2024-11-24-0431
```

```bash
docker compose up jellyfin
```

### Install Jellyfin TrueHD Variant

```env
TV_IP=192.168.0.10
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin-TrueHD.wgt
JELLYFIN_VERSION=
```

```bash
docker compose up jellyfin
```

### Install Latest Moonlight

```env
TV_IP=192.168.0.10
MOONLIGHT_REPO_URL=https://github.com/OneLiberty/moonlight-chrome-tizen
MOONLIGHT_WGT_FILE=Moonlight.wgt
MOONLIGHT_VERSION=
```

```bash
docker compose up moonlight
```

### Install Latest Litefin

Litefin releases assets like `Litefin-1.8.0-Tizen-Modern.wgt` under tag `v1.8.0`, so the
filename is written with a `{version}` placeholder:

```env
TV_IP=192.168.0.10
LITEFIN_REPO_URL=https://github.com/MoazSalem/litefin
LITEFIN_WGT_FILE=Litefin-{version}-Tizen-Modern.wgt
LITEFIN_VERSION=
```

```bash
docker compose up litefin
```

### Install Specific Litefin Version

```env
TV_IP=192.168.0.10
LITEFIN_REPO_URL=https://github.com/MoazSalem/litefin
LITEFIN_WGT_FILE=Litefin-{version}-Tizen-Modern.wgt
LITEFIN_VERSION=v1.8.0
```

```bash
docker compose up litefin
```

Downloads `https://github.com/MoazSalem/litefin/releases/download/v1.8.0/Litefin-1.8.0-Tizen-Modern.wgt`.

### Install Custom App

```env
TV_IP=192.168.0.10
CUSTOM_REPO_URL=https://github.com/username/my-tizen-app
CUSTOM_WGT_FILE=MyApp-{version}.wgt
CUSTOM_VERSION=v1.0.0
```

```bash
docker compose up custom
```

### With Custom Certificates

For newer TV models requiring custom certificates:

1. Place your `author.p12` and `distributor.p12` files in a directory
2. Update `.env`:

```env
TV_IP=192.168.0.10
CERT_PASSWORD=YourCertPassword123!
CERT_DIR=/path/to/certificates

JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
```

3. Run the installation:

```bash
docker compose up jellyfin
```

## Inline Environment Variables

You can also override environment variables inline:

```bash
# Install specific Jellyfin version without editing .env
JELLYFIN_VERSION=2024-11-24-0431 docker compose up jellyfin

# Install custom app
CUSTOM_REPO_URL=https://github.com/user/app \
CUSTOM_WGT_FILE=App.wgt \
docker compose up custom
```

## ARM Platforms (Apple Silicon)

For M1/M2/M3 Macs, add to your `.env`:

```env
COMPOSE_DOCKER_CLI_BUILD=1
DOCKER_DEFAULT_PLATFORM=linux/amd64
```

Or use the platform flag:

```bash
docker compose up jellyfin --platform linux/amd64
```

## How Version Auto-Detection Works

When `VERSION` is empty or not set:

1. The script resolves the latest release tag from the repository
2. Expands any `{version}` / `{tag}` placeholders in `WGT_FILE` with that tag
3. Constructs the download URL: `{REPO_URL}/releases/download/{resolved tag}/{WGT_FILE}`
4. Downloads and installs the latest version

When `VERSION` is specified:

1. Uses the exact version you provided
2. Expands any `{version}` / `{tag}` placeholders in `WGT_FILE` with it
3. Constructs the download URL: `{REPO_URL}/releases/download/{VERSION}/{WGT_FILE}`
4. Downloads and installs that specific version

The same placeholders work in the direct-URL (command line) mode. There, when `VERSION`
is not set, the repository is derived from the part of the URL before `/releases/` and
its latest tag is resolved:

```bash
docker run --rm ghcr.io/edivad1999/install-github-wgt-tizen:latest \
  192.168.0.10 \
  "https://github.com/MoazSalem/litefin/releases/download/{tag}/Litefin-{version}-Tizen-Modern.wgt"
```

## Available WGT Files

### Jellyfin Variants
From [jeppevinkel/jellyfin-tizen-builds](https://github.com/jeppevinkel/jellyfin-tizen-builds):
- `Jellyfin.wgt` - Standard build
- `Jellyfin-TrueHD.wgt` - TrueHD audio support
- `Jellyfin-master.wgt` - Master branch build
- `Jellyfin-master-TrueHD.wgt` - Master with TrueHD
- `Jellyfin-secondary.wgt` - Secondary build

### Moonlight
From [OneLiberty/moonlight-chrome-tizen](https://github.com/OneLiberty/moonlight-chrome-tizen):
- `Moonlight.wgt` - Game streaming client

### Litefin Variants
From [MoazSalem/litefin](https://github.com/MoazSalem/litefin) (filenames carry the version,
so use `{version}`):
- `Litefin-{version}-Tizen-Modern.wgt` - Tizen 6.5+
- `Litefin-{version}-Tizen-Normal.wgt` - Standard build
- `Litefin-{version}-Tizen-Normal-Oblong.wgt` - Standard build, oblong screens
- `Litefin-{version}-Tizen-Legacy.wgt` - Older TVs
- `Litefin-{version}-Tizen-Ultra-Legacy.wgt` - Oldest TVs
- `Litefin-{version}-Tizen-Ultra-Legacy-NoService.wgt` - Oldest TVs, no background service

## Troubleshooting

### Error: Could not fetch latest release

**Cause:** Repository doesn't have releases or GitHub API is unreachable.

**Solution:** Specify a `VERSION` explicitly:
```env
JELLYFIN_VERSION=2024-11-24-0431
```

### Error: Failed to download the package

**Cause:** The WGT file name doesn't exist in the release.

**Solution:** Check the repository's releases page and verify the exact filename:
```bash
# Check what files are available in the latest release
curl -s https://api.github.com/repos/jeppevinkel/jellyfin-tizen-builds/releases/latest | grep "name.*wgt"
```

### File Descriptor Error

If you get `library initialization failed - unable to allocate file descriptor table`:

Edit `docker-compose.yml` and add to the base service:

```yaml
ulimits:
  nofile:
    soft: 1024
    hard: 65536
```

### Certificate Mismatch Error

Error: `install failed[118, -11], reason: Author certificate not match`

**Solution:** Uninstall the existing app from your TV, then run the installation again.

### TV Not Found

Error: `Unable to find the TV name`

**Check:**
1. TV is in Developer Mode
2. TV's "Host PC IP" is set to your computer's IP
3. TV and computer are on the same network
4. No firewall blocking the connection

### Invalid Certificate Chain

Error: `install failed[118, -12], reason: Check certificate error`

**Solution:** Your TV requires custom certificates. See the main README for instructions on creating certificates.

## Clean Up

Remove containers after installation:

```bash
docker compose down
```

## Advanced Usage

### Using Local Build

To use a local build instead of the published image:

1. Edit `docker-compose.yml`:
   ```yaml
   tizen-installer:
     build: .
     # image: ghcr.io/edivad1999/install-github-wgt-tizen:latest
   ```

2. Build and run:
   ```bash
   docker compose build
   docker compose up jellyfin
   ```

### Override All Settings Inline

```bash
TV_IP=192.168.0.10 \
REPO_URL=https://github.com/user/repo \
WGT_FILE=App.wgt \
VERSION=v1.0.0 \
CERT_PASSWORD=pass123 \
docker compose run --rm tizen-installer
```

### View Logs

```bash
docker compose logs
```

## Environment Variable Format

Configure apps in `.env` using three variables:

```env
# For Jellyfin service
JELLYFIN_REPO_URL=https://github.com/jeppevinkel/jellyfin-tizen-builds
JELLYFIN_WGT_FILE=Jellyfin.wgt
JELLYFIN_VERSION=2024-11-24-0431    # or leave empty for latest

# For Moonlight service
MOONLIGHT_REPO_URL=https://github.com/OneLiberty/moonlight-chrome-tizen
MOONLIGHT_WGT_FILE=Moonlight.wgt
MOONLIGHT_VERSION=                   # empty = latest

# For custom service
CUSTOM_REPO_URL=https://github.com/user/repo
CUSTOM_WGT_FILE=App.wgt
CUSTOM_VERSION=v1.0.0
```

## Tips

1. **Version pinning**: Set specific versions in `.env` for reproducible installations
2. **Latest releases**: Leave `VERSION` empty to always get the latest
3. **Multiple variants**: Use different WGT_FILE values for different app variants
4. **Certificate security**: Never commit `.p12` files to git
5. **TV compatibility**: Moonlight requires Tizen 5.5+
