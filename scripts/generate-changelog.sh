#!/usr/bin/env bash
#
# Generate debian/changelog and output the calculated package version.
# This script is used by both build.yml and draft-release.yml workflows.
#
# Prerequisites:
# - VERSION file must exist in project root
# - gh CLI must be available and authenticated
# - Must be run from project root directory
#
# Outputs:
# - Prints the calculated package version to stdout (e.g., "1.0.7-1")
# - Creates/updates debian/changelog file
#

set -euo pipefail

# Ensure we're in the project root
if [ ! -f "VERSION" ]; then
  echo "ERROR: VERSION file not found. Run this script from the project root." >&2
  exit 1
fi

# Read upstream version from VERSION file
UPSTREAM_VERSION=$(tr -d '[:space:]' < VERSION)
echo "Upstream version: $UPSTREAM_VERSION" >&2

# Find the next available revision number by checking existing releases
REVISION=1
while gh release view "v${UPSTREAM_VERSION}-${REVISION}" &>/dev/null; do
  echo "Release v${UPSTREAM_VERSION}-${REVISION} exists, trying next..." >&2
  REVISION=$((REVISION + 1))
done

PACKAGE_VERSION="${UPSTREAM_VERSION}-${REVISION}"
echo "Calculated package version: $PACKAGE_VERSION" >&2

# Generate debian/changelog entry
TIMESTAMP=$(date -R)
cat > debian/changelog << EOF
cockpit-package-manager ($PACKAGE_VERSION) trixie; urgency=medium

  * Automated release v$PACKAGE_VERSION
  * Cockpit Package Manager upstream version: v$UPSTREAM_VERSION
  * For detailed changes: https://github.com/\${GITHUB_REPOSITORY:-hatlabs/cockpit-package-manager-debian}/commits/main

 -- Hat Labs <info@hatlabs.fi>  $TIMESTAMP
EOF

echo "Generated debian/changelog" >&2

# Output the version to stdout for GitHub Actions to capture
echo "$PACKAGE_VERSION"
