# Cockpit Package Manager - Debian Packaging

Debian packaging repository for cockpit-package-manager.

## Upstream Source

**Repository**: https://github.com/hatlabs/cockpit-package-manager

Cockpit-based package manager using PackageKit, inspired by Raspberry Pi's Add/Remove Software.

## Purpose

This repository contains only Debian packaging files for building .deb packages of cockpit-package-manager. The upstream source is maintained at [hatlabs/cockpit-package-manager](https://github.com/hatlabs/cockpit-package-manager).

## Structure

- `debian/` - Standard Debian packaging directory
  - `control` - Package metadata and dependencies
  - `rules` - Build instructions (builds with npm)
  - `changelog` - Version history in Debian format
  - `copyright` - License information (LGPL-2.1+)
  - `install` - File installation mappings
  - `compat` - Debhelper compatibility level (13)
  - `source/format` - Source package format (3.0 native)

## Building

The build process expects the upstream source to be available as `cockpit-package-manager/` (either a symlink or cloned repository):

```bash
# Clone the upstream repository (if not already present)
git clone https://github.com/hatlabs/cockpit-package-manager.git

# Or create a symlink to an existing checkout
# ln -s ../cockpit-package-manager cockpit-package-manager

# Build using Docker (recommended)
./run package:deb:docker

# Or build natively (requires Debian/Ubuntu with build dependencies)
dpkg-buildpackage -us -uc -b

# Package will be created in parent directory
ls ../*.deb
```

## Build Dependencies

- debhelper-compat (= 13)
- nodejs (>= 18)
- npm

## Package Details

- **Package name**: cockpit-package-manager
- **Architecture**: all (JavaScript/TypeScript, platform independent)
- **Dependencies**:
  - cockpit (>= 276)
  - packagekit
- **Installation path**: /usr/share/cockpit/packagemanager/

## Files Installed

- `index.html` - Main HTML entry point
- `manifest.json` - Cockpit manifest
- `packagemanager.js` - Bundled application JavaScript
- `packagemanager.js.map` - Source map for debugging
- `packagemanager.scss` - Styles (included in build)

## Versioning

Follow semantic versioning:
- **0.1.0**: Initial release
- **0.2.0**: First feature additions
- Use Debian revision -1 for initial packaging of each upstream version (e.g., 0.1.0-1)

## Testing the Package

```bash
# Install the package
sudo dpkg -i cockpit-package-manager_0.1.0-1_all.deb

# If dependencies are missing, fix with:
sudo apt-get install -f

# Test in Cockpit
# Open http://localhost:9090 and look for "Package Manager" in the menu

# Remove the package
sudo apt-get remove cockpit-package-manager
```

## Integration with HaLOS

This package is designed to be included in HaLOS images. To add to pi-gen builds:

1. Build the .deb package
2. Copy to the APT repository in `apt.hatlabs.fi/`
3. Update the repository index
4. Add to the package list in the appropriate pi-gen stage

## Maintainer

Matti Airas <matti.airas@hatlabs.fi>

## License

LGPL-2.1-or-later (same as Cockpit and upstream source)
