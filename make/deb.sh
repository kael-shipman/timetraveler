#!/bin/bash

set -e

if [ "$(whoami)" != "root" ]; then
    >&2 echo
    >&2 echo "E: You must run this command with sudo so that package permissions"
    >&2 echo "   may be set accordingly."
    >&2 echo
    exit 1
fi

if [ -z "$KSUTILS_PATH" ]; then
    KSUTILS_PATH=/usr/share/kael-shipman
fi
if [ ! -e "$KSUTILS_PATH/dpkg-build-utils.sh" ]; then
    >&2 echo
    >&2 echo "E: Your system doesn't appear to have ks-utils installed. (Looking for"
    >&2 echo "   library 'dpkg-build-utils.sh' in $KSUTILS_PATH. To define a different"
    >&2 echo "   place to look for this file, just export the 'KSUTILS_PATH' environment"
    >&2 echo "   variable.)"
    >&2 echo
    exit 2
else
    . "$KSUTILS_PATH/dpkg-build-utils.sh"
fi

if ! command -v dpkg &>/dev/null; then
    >&2 echo
    >&2 echo "E: Your system doesn't appear to have dpkg installed. Dpkg is required"
    >&2 echo "   for creating debian packages."
    >&2 echo
    exit 3
fi

builddir=build
pkgdir=build/deb

rm -Rf "$pkgdir" 2>/dev/null
mkdir -p "$pkgdir"

cp -R --preserve=mode pkg-src/DEBIAN "$pkgdir/"





# Copy files over

libdir="$pkgdir/usr/share/timetraveler"
mkdir -p "$libdir"
cp src/timetraveler.lib.sh "$libdir/"

bindir="$pkgdir/usr/bin"
mkdir -p "$bindir"
cp src/{timetraveler,timetraveler-scan-config,timetraveler-backup} "$bindir/"

sysddir="$pkgdir/lib/systemd/system"
mkdir -p "$sysddir"
cp peripherals/timetraveler-scan-config.{service,timer} "$sysddir/"



# Replace version with current version
sed -i "s/::VERSION::/$(cat VERSION)/" "$bindir/timetraveler"



# Build deb package

ksdpkg_update_pkg_version "$pkgdir" "$(cat VERSION)"
ksdpkg_update_pkg_size "$pkgdir"
ksdpkg_update_md5s "$pkgdir"

dpkg --build "$pkgdir" "$builddir"

rm -Rf "$pkgdir"

echo "Done."

