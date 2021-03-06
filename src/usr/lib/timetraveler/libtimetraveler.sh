#!/bin/bash

set -e

function echo_usage() {
    {
        echo
        echo "SYNOPSIS"
        echo "      timetraveler [command] [command-options]"
        echo
        echo "COMMANDS"
        echo "      backup [profile]|all"
        echo "          Run the specified backup (or all backups if 'all' specified)"
        echo
        echo "      scan-config"
        echo "          Scan user configs and update systemd unit files accordingly"
        echo
        echo "      find [profile] [relative-path] [find-options]"
        echo "          Find instances of files or folders within the backups"
        echo
        echo "      search [profile] [relative-path] [regex]"
        echo "          Search files in [profile]/[relative-path] for [regex]"
        echo
        echo "GLOBAL OPTIONS"
        echo "      -h|--help"
        echo "          Show this help text. Note: you can also pass --help|-h to any subcommand"
        echo "          to see more information about each."
        echo
        echo "      --version"
        echo "          Display version information"
        echo
        echo
        echo
    }
}






# Config functions

function verify_config() {
    local cnf_home="$1"
    if [ -z "$cnf_home" ] || [ ! -d "$cnf_home" ]; then
        >&2 echo
        >&2 echo "E: You must pass a home directory as the only argument to this"
        >&2 echo "   function. (You passed '$cnf_home')"
        >&2 echo
        exit 11
    fi
    TT_CONF_DIR="$cnf_home/.config/timetraveler"
    TT_CONF_FILE="$TT_CONF_DIR/config"

    if [ ! -e "$TT_CONF_FILE" ]; then
        >&2 echo
        >&2 echo "E: You haven't created a config file yet!"
        >&2 echo
        >&2 echo "   Please create the file $TT_CONF_FILE and put your timetraveler config, including"
        >&2 echo "   backup profiles, in it. (See https://github.com/kael-shipman/timetraveler for"
        >&2 echo "   more information about config.)"
        >&2 echo
        exit 12
    else
        if ! jq="$(command -v jq)"; then
            >&2 echo
            >&2 echo "E: You must have \`jq\` installed on your machine to use timetraveler."
            >&2 echo
            exit 13
        fi

        if ! jq . "$TT_CONF_FILE" >/dev/null; then
            >&2 echo
            >&2 echo "E: Your config file has errors."
            >&2 echo
            exit 25
        fi
    fi
}

function parse_config() {
    local CNF="$1"
    if [ -z "$CNF" ]; then
        >&2 echo
        >&2 echo "E: You need to pass the config file path as an argument to the parse_config function."
        >&2 echo
        exit 14
    fi

    # Rsync command
    local val=
    if val="$(jq -ej '.["rsync-command"]' "$CNF")"; then
        RSYNC="$val"
    fi

    # Rsync options
    if val="$(jq -ej '.["rsync-options"]' "$CNF")"; then
        RSYNC_OPTIONS="$val"
    fi

    CNF_PRFS_SRCS=()
    CNF_PRFS_TRGS=()
    CNF_PRFS_FREQUENCIES=()
    CNF_PRFS_RETENTIONS=()
    CNF_PRFS_RSYNCS=()
    CNF_PRFS_RSYNC_OPTS=()
    CNF_PRFS=($(jq -j '.backups | keys | join(" ")' "$CNF"))

    for p in "${CNF_PRFS[@]}"; do
        if ! CNF_PRFS_SRCS[${#CNF_PRFS_SRCS[@]}]="$(jq -ej '.backups["'$p'"].source' "$CNF")"; then
            >&2 echo
            >&2 echo "E: Required value 'source' missing for backup profile '$p'"
            >&2 echo
            exit 15
        fi
        if ! CNF_PRFS_TRGS[${#CNF_PRFS_TRGS[@]}]="$(jq -ej '.backups["'$p'"].target' "$CNF")"; then
            >&2 echo
            >&2 echo "E: Required value 'target' missing for backup profile '$p'"
            >&2 echo
            exit 16
        fi
        CNF_PRFS_FREQUENCIES[${#CNF_PRFS_FREQUENCIES[@]}]="$(jq -j '.backups["'$p'"].frequency' "$CNF")"
        CNF_PRFS_RETENTIONS[${#CNF_PRFS_RETENTIONS[@]}]="$(jq -j '.backups["'$p'"].retention' "$CNF")"
        CNF_PRFS_RSYNCS[${#CNF_PRFS_RSYNCS[@]}]="$(jq -j '.backups["'$p'"]["rsync-command"]' "$CNF")"
        CNF_PRFS_RSYNC_OPTS[${#CNF_PRFS_RSYNC_OPTS[@]}]="$(jq -j '.backups["'$p'"]["rsync-options"]' "$CNF")"
    done
}






