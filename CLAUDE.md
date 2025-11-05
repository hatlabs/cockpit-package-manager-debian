⚠️ **THESE RULES ONLY APPLY TO FILES IN /cockpit-package-manager-debian/** ⚠️

# Cockpit Package Manager - Debian Packaging

Debian packaging repository for cockpit-package-manager.

**Local Instructions**: For environment-specific instructions and configurations, see @CLAUDE.local.md (not committed to version control).

## Purpose

This repository contains only Debian packaging files for building .deb packages. The actual source code is in the sibling `cockpit-package-manager/` directory in the halos-distro workspace.

## Structure

Standard Debian packaging layout following Debian policy and best practices.

### Source Layout

This packaging repo expects the source code to be available via a symlink:
```
cockpit-package-manager-debian/
├── cockpit-package-manager -> ../cockpit-package-manager  (symlink)
├── debian/                   (packaging files)
├── docker/                   (Docker build infrastructure)
└── run                       (build automation script)
```

The Docker compose configuration mounts the parent workspace directory to enable symlink resolution.

### Docker Infrastructure

- `docker/Dockerfile.debtools` - Debian Trixie with build tools and Node.js
- `docker/docker-compose.debtools.yml` - Compose configuration
  - Mounts parent workspace (`../..:/workspace`) to resolve symlinks
  - Sets working directory to `/workspace/cockpit-package-manager-debian`

## Git Workflow Policy

**IMPORTANT:** Always ask before pushing, creating/pushing tags, or running destructive git operations that affect remote repositories. Local commits and branch operations are fine.

**Branch Workflow:** Never push to main directly - always use feature branches and PRs.

## Building

```bash
# Build using Docker (recommended)
./run package:deb:docker

# Build for CI
./run package:deb:docker:ci
```

**All build and inspection commands use Docker** - no native Debian tools required on macOS.

## Available Commands

Run `./run help` to see all commands. Key commands:

**Package Management:**
- `./run package:deb:docker` - Build Debian package
- `./run package:inspect` - List package contents
- `./run package:info` - Show package metadata
- `./run package:extract` - Extract package to /tmp for inspection
- `./run package:clean` - Clean build artifacts

**Development:**
- `./run debtools:shell` - Open interactive shell in container
- `./run setup:check` - Verify source directory symlink

**Examples:**
```bash
# Build and inspect package
./run package:deb:docker
./run package:inspect | grep packagemanager.css

# Debug CSS issue
./run package:extract
./run debtools:shell
# In shell: wc -l /tmp/cockpit-package-manager-extract/usr/share/cockpit/packagemanager/packagemanager.css

# Clean everything
./run package:clean
```

## Build Requirements

- Node.js >= 18 (for building TypeScript/React)
- npm (for dependency management)
- debhelper-compat 13

## Runtime Dependencies

- **cockpit >= 276**: Web management interface
- **packagekit**: System package management backend

## File Mapping

The `debian/install` file maps build outputs to system locations:

```
packagemanager/index.html → /usr/share/cockpit/packagemanager/
packagemanager/manifest.json → /usr/share/cockpit/packagemanager/
packagemanager/packagemanager.js → /usr/share/cockpit/packagemanager/
packagemanager/packagemanager.js.map → /usr/share/cockpit/packagemanager/
packagemanager/packagemanager.css → /usr/share/cockpit/packagemanager/
packagemanager/*.woff2 → /usr/share/cockpit/packagemanager/
```

## Architecture

- **Package**: Debian package for all architectures (pure JavaScript)
- **Frontend**: React + TypeScript + PatternFly UI
- **Backend**: PackageKit D-Bus API (via cockpit.js)
- **Build**: esbuild bundles JS, copies PatternFly CSS + fonts
- **Installation path**: `/usr/share/cockpit/packagemanager/`

## Version Management

Update `debian/changelog` manually for each release:

**Version format:** `X.Y.Z-N` where X.Y.Z is cockpit-package-manager version, N is packaging revision.

- 0.1.0-1: Initial release
- 0.1.0-2: Packaging fix, same upstream
- 0.2.0-1: New upstream version

## Package Inspection

Use the `./run` script to inspect built packages (all commands use Docker internally):

```bash
# List package contents
./run package:inspect

# Show package metadata
./run package:info

# Extract package to /tmp for detailed inspection
./run package:extract

# Open interactive shell in debtools container
./run debtools:shell
```

**Example: Verify CSS file in package**
```bash
./run package:extract
# Then in another terminal:
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "wc -l /tmp/cockpit-package-manager-extract/usr/share/cockpit/packagemanager/packagemanager.css"
```

## Testing Locally

See [CLAUDE.local.md](CLAUDE.local.md) for remote testing procedures.

**Local debugging:**
```bash
ssh pi@halos.local
# Check installed files
ls -la /usr/share/cockpit/packagemanager/
# Check Cockpit logs
sudo journalctl -u cockpit.service -f
```

## Common Issues

### CSS Not Loading / No Styling

**Symptom:** Package Manager loads but appears completely unstyled (no colors, cards, or layout).

**Cause:** PatternFly v6 splits CSS into two files:
- `patternfly-base.css` - Token definitions (`--pf-t--global--*`)
- `patternfly.css` - Component styles that reference those tokens

If only `patternfly.css` is included, all `var(--pf-t--global-*)` references have no values.

**Solution:** The `esbuild.config.js` combines both files:
```javascript
const baseCSS = fs.readFileSync('node_modules/@patternfly/patternfly/patternfly-base.css', 'utf8');
const mainCSS = fs.readFileSync('node_modules/@patternfly/patternfly/patternfly.css', 'utf8');
const combinedCSS = baseCSS + '\n\n' + mainCSS;
fs.writeFileSync('packagemanager/packagemanager.css', combinedCSS);
```

**Verify:** Check that `packagemanager.css` contains ~45,000 lines with token definitions:
```bash
./run package:extract
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "grep -c 'pf-t--global--font--size--100:' /tmp/cockpit-package-manager-extract/usr/share/cockpit/packagemanager/packagemanager.css"
# Should return 4 (not 0)
```

### Docker for Mac Bind Mount Caching

**Symptom:** Build reports writing large CSS file (45k lines), but package contains small/old CSS (23k lines).

**Cause:** Docker for Mac bind mounts cache file reads. When esbuild writes the combined CSS inside the container, the file is created correctly. However, when `dpkg-buildpackage` later reads the file to copy it into the package, it may read a cached/stale version from the bind mount instead of the freshly written file.

**Solution:** Write to `/tmp` (outside bind mount) inside container, then explicitly copy back:
```bash
# In esbuild.config.js - write to both locations
fs.writeFileSync('packagemanager/packagemanager.css', combinedCSS);  // bind mount (may be cached)
fs.writeFileSync('/tmp/packagemanager.css', combinedCSS);            // outside bind mount

# In debian/rules - force overwrite from /tmp
cp /tmp/packagemanager.css cockpit-package-manager/packagemanager/packagemanager.css
```

This workaround is **only needed on macOS**. Linux builds don't have this issue.

**How to verify the issue:**
```bash
# Build will show correct size being written
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "cd /workspace/cockpit-package-manager && npm run build"
# Output: "Combined CSS: 2092499 bytes, 45216 lines"

# But file read from bind mount shows old size
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "wc -l /workspace/cockpit-package-manager/packagemanager/packagemanager.css"
# Output: "23271" (wrong!)

# File from /tmp has correct size
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "wc -l /tmp/packagemanager.css"
# Output: "45215" (correct!)
```

### Other Common Issues

- **Module not found**: Verify packagemanager.js exists and is readable
- **Blank page**: Check browser console (F12) for JavaScript errors
- **Permission errors**: Check file ownership in /usr/share/cockpit/packagemanager/

## Troubleshooting Workflow

If you encounter issues after building and installing the package, follow this workflow:

### 1. Verify Package Contents

```bash
# Extract and check what's actually in the package
./run package:extract

# Check CSS file size
./run debtools:shell
wc -l /tmp/cockpit-package-manager-extract/usr/share/cockpit/packagemanager/packagemanager.css
# Expected: ~45,000 lines

# Check for token definitions
grep -c 'pf-t--global--font--size--100:' /tmp/cockpit-package-manager-extract/usr/share/cockpit/packagemanager/packagemanager.css
# Expected: 4 (not 0)
```

### 2. Verify Installed Files

```bash
# Check deployed files on server
ssh pi@halos.local "ls -lah /usr/share/cockpit/packagemanager/"

# Check CSS on server
ssh pi@halos.local "wc -l /usr/share/cockpit/packagemanager/packagemanager.css"

# Verify tokens are present
ssh pi@halos.local "grep -c 'pf-t--global--font--size--100:' /usr/share/cockpit/packagemanager/packagemanager.css"
```

### 3. Check Browser

```bash
# Use Playwright to inspect actual browser state
cd ../cockpit-package-manager
npx playwright test test-css-loading-frontend.spec.ts

# Check screenshot
open test-results/*/test-failed-1.png
```

### 4. Check Build Process

```bash
# Verify source CSS is being built correctly
cd ../cockpit-package-manager
npm run build

# Check build output
wc -l packagemanager/packagemanager.css
# Expected: ~45,000 lines (not ~23,000)

# If incorrect, check esbuild.config.js console output for:
# "Combined CSS: 2092499 bytes, 45216 lines"
```

### 5. Debug Docker Volume Mounts

If build says correct size but package has wrong size:

```bash
# Build and immediately check inside container
docker compose -f docker/docker-compose.debtools.yml run --rm debtools bash -c \
  "cd /workspace/cockpit-package-manager && npm run build && wc -l packagemanager/packagemanager.css"

# Compare with host file
wc -l packagemanager/packagemanager.css

# If different, Docker volume mount has sync issues - verify /tmp workaround in debian/rules
```

## Integration with HaLOS

To add to HaLOS builds:

1. Build .deb package
2. Add to apt.hatlabs.fi repository
3. Update repository indices
4. Add package to pi-gen stage package lists

## References

- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- cockpit-dockermanager-debian/ for similar packaging example
