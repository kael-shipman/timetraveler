#!/bin/bash

if [ ! -d "$1" ] || [ ! -d "$2" ]; then
    >&2 echo "You must supply a source directory and backup directory"
    exit 1
fi

src="$1"
bakdir="$2"

bakname="$(basename "$src").$(date +%F_%H-%M-%S)"

src="$(readlink -f "$src")"
dest="$(readlink -f "$bakdir")/$bakname"

if [ -e "$bakdir/latest" ]; then
    linkdest="$(readlink -f "$bakdir/latest")"
    rsync -aHAXx --link-dest="$linkdest" "$src/" "$dest"
else
    rsync -aHAXx "$src/" "$dest"
fi

ln -snf "$bakname" "$bakdir/latest"

