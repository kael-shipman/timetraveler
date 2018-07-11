#!/bin/bash

inc=libtimetraveler.sh
if [ ! -e "$inc" ]; then
    inc="timetraveler/$inc"
    if [ ! -e "$inc" ]; then
        inc="lib/$inc"
        if [ ! -e "$inc" ]; then
            inc="usr/$inc"
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
        fi
    fi
fi

. "$inc"

function todo_test_verify_config() {
    assert_fail
}

function todo_test_parse_config() {
    assert_fail
}
