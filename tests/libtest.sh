#!/bin/bash

inc=timetraveler.lib.sh
if [ ! -e "$inc" ]; then
    inc="src/$inc"
    if [ ! -e "$inc" ]; then
        inc="../$inc"
        if [ ! -e "$inc" ]; then
            >&2 echo
            >&2 echo "E: Can't find library. Please run this command from repo root"
            >&2 echo
            exit 1
        fi
    fi
fi

. "$inc"

n=1

path="kael@kaelshipman.me:/some/path"
if path_is_remote "$path"; then
    echo "$n. PASSED: remote path '$path' detected"
else
    echo "$n. **FAILED**: remote path '$path' not detected"
fi
((n++))

path="/some/crazy:delim/localpath"
if ! path_is_remote "$path"; then
    echo "$n. PASSED: local path '$path' detected"
else
    echo "$n. **FAILED**: local path '$path' not detected"
fi
((n++))

path=/tmp
if path_exists "$path"; then
    echo "$n. PASSED: local path '$path' existence confirmed"
else
    echo "$n. **FAILED**: local path '$path' should have been found"
fi
((n++))

path=/nonexistent
if ! path_exists "$path"; then
    echo "$n. PASSED: local nonexistent path '$path' confirmed not to exist"
else
    echo "$n. **FAILED**: local nonexistent path '$path' shouldn't have been found"
fi
((n++))

path="kaelshipman.me:/tmp"
if path_exists "$path"; then
    echo "$n. PASSED: remote path '$path' confirmed to exist"
else
    echo "$n. **FAILED**: remote path '$path' not correctly detected"
fi
((n++))

path="kaelshipman.me:Documents"
if path_exists "$path"; then
    echo "$n. PASSED: remote path '$path' confirmed to exist"
else
    echo "$n. **FAILED**: remote path '$path' not correctly detected"
fi
((n++))

path="kaelshipman.me:nope"
if ! path_exists "$path"; then
    echo "$n. PASSED: remote path '$path' correctly not found"
else
    echo "$n. **FAILED**: remote path '$path' incorrectly detected"
fi
((n++))

path="kaelshipman.me:/path/to/nowhere"
if ! path_exists "$path"; then
    echo "$n. PASSED: remote path '$path' correctly not found"
else
    echo "$n. **FAILED**: remote path '$path' incorrectly detected"
fi
((n++))

path="/tmp/some/long/path"
tt_cmd "$path" 'mkdir -p "::path::"'
if [ -e "$path" ]; then
    echo "$n. PASSED: local path '$path' created"
    rm -Rf /tmp/some
else
    echo "$n. **FAILED**: local path '$path' not created"
fi
((n++))

path="kaelshipman.me:/tmp/some/long/path"
tt_cmd "$path" 'mkdir -p "::path::"'
if path_exists $path; then
    echo "$n. PASSED: remote path '$path' created"
    ssh "kaelshipman.me" "rm -Rf /tmp/some"
else
    echo "$n. **FAILED**: remote path '$path' not created"
fi
((n++))

toPath="/tmp/test"
fromPath="$toPath.partial"
tt_cmd "$fromPath" 'mkdir -p "'$fromPath'"'
tt_cmd "$fromPath" 'mv "'$fromPath'" "'$toPath'"'
if path_exists "$toPath"; then
    echo "$n. PASSED: local path '$fromPath' moved to '$toPath'"
    rm -Rf "$toPath"
else
    echo "$n. **FAILED**: local path '$fromPath' not moved to '$toPath'"
fi
((n++))

toPath="kaelshipman.me:/tmp/test"
fromPath="$toPath.partial"
tt_cmd "$fromPath" 'mkdir -p "'$fromPath'"'
tt_cmd "$fromPath" 'mv "'$fromPath'" "'$toPath'"'
if path_exists "$toPath"; then
    echo "$n. PASSED: remote path '$fromPath' moved to '$toPath'"
    rm -Rf "$toPath"
else
    echo "$n. **FAILED**: remote path '$fromPath' not moved to '$toPath'"
fi
((n++))

