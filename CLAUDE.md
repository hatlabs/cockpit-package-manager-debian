# Cockpit Package Manager - Debian Packaging

Debian packaging repository for cockpit-package-manager.

## Purpose

This repository contains only Debian packaging files for building .deb packages. The actual source code is in the sibling `cockpit-package-manager/` directory in the halos-distro workspace.

## Structure

Standard Debian packaging layout following Debian policy and best practices.

## Building

```bash
cd cockpit-package-manager-debian
dpkg-buildpackage -us -uc -b
```

This will:
1. Run `npm install` in cockpit-package-manager/
2. Run `npm run build` to create the bundled JavaScript
3. Install files to debian package staging area
4. Create .deb package in parent directory

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
packagemanager/packagemanager.scss → /usr/share/cockpit/packagemanager/
```

## Version Management

Update `debian/changelog` for each release:

```bash
# Use dch to add new entries
dch -v 0.2.0-1 "New upstream release"
dch "Added feature X"
dch "Fixed bug Y"
dch -r ""
```

Follow conventional format:
- Major.Minor.Patch-DebianRevision
- 0.1.0-1: Initial release
- 0.1.0-2: Packaging fix, same upstream
- 0.2.0-1: New upstream version

## Testing

After building, test the package:

```bash
# Install in a test environment
sudo dpkg -i ../cockpit-packagemanager_*.deb
sudo apt-get install -f  # Fix any dependency issues

# Verify files
dpkg -L cockpit-packagemanager

# Test functionality in Cockpit
# http://localhost:9090

# Check for errors
journalctl -u cockpit.service -f
```

## Git Workflow

**IMPORTANT**: Always ask before committing, pushing, or tagging.

This repository should be managed independently from cockpit-package-manager source but kept in sync with the workspace structure.

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
