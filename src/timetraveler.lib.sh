#!/bin/bash

set -e

function echo_usage() {
    {
        echo
        echo "USAGE"
        echo
        echo " $(basename "$0") [command] [command-options]"
        echo
        echo " COMMANDS"
        echo
        echo "    backup [profile]|all                           Run the specified backup (or all backups if 'all' specified)"
        echo "    scan-config                                    Scan user configs and update systemd unit files accordingly"
        echo "    find [profile] [relative-path] [find-options]  Find instances of files or folders within the backups"
        echo "    search [profile] [relative-path] [regex]       Search files in [profile]/[relative-path] for [regex]"
        echo
        echo
        echo " GLOBAL OPTIONS"
        echo
        echo "    -h|--help                                      Show this help text. Note: you can also pass --help|-h to"
        echo "                                                   any subcommand to see more information about each."
        echo "       --version                                   Display version information"
        echo
        echo
        echo " BACKUP OPTIONS"
        echo
        echo
        echo
        echo " FIND OPTIONS"
        echo
        echo "    (This command is a pass-through for \`find\`. See \`find\` command man page for options)"
        echo
        echo
    }
}

function parse_config() {
    local CNF="$1"
    if [ -z "$CNF" ]; then
        >&2 echo
        >&2 echo "E: You need to pass the config file path as an argument to the parse_config function."
        >&2 echo
        exit 5
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

    declare -ga CNF_PRFS
    declare -ga CNF_PRFS_SRCS
    declare -ga CNF_PRFS_TRGS
    declare -ga CNF_PRFS_FREQUENCIES
    declare -ga CNF_PRFS_RETENTIONS
    declare -ga CNF_PRFS_RSYNCS
    declare -ga CNF_PRFS_RSYNC_OPTS
    CNF_PRFS=($(jq -j '.backups | keys | join(" ")' "$CNF"))

    for p in "${CNF_PRFS[@]}"; do
        if ! CNF_PRFS_SRCS[${#CNF_PRFS_SRCS[@]}]="$(jq -ej '.backups["'$p'"].source' "$CNF")"; then
            >&2 echo
            >&2 echo "E: Required value 'source' missing for backup profile '$p'"
            >&2 echo
            exit 6
        fi
        if ! CNF_PRFS_TRGS[${#CNF_PRFS_TRGS[@]}]="$(jq -ej '.backups["'$p'"].target' "$CNF")"; then
            >&2 echo
            >&2 echo "E: Required value 'target' missing for backup profile '$p'"
            >&2 echo
            exit 6
        fi
        CNF_PRFS_FREQUENCIES[${#CNF_PRFS_FREQUENCIES[@]}]="$(jq -j '.backups["'$p'"].frequency' "$CNF")"
        CNF_PRFS_RETENTIONS[${#CNF_PRFS_RETENTIONS[@]}]="$(jq -j '.backups["'$p'"].retention' "$CNF")"
        CNF_PRFS_RSYNCS[${#CNF_PRFS_RSYNCS[@]}]="$(jq -j '.backups["'$p'"]["rsync-command"]' "$CNF")"
        CNF_PRFS_RSYNC_OPTS[${#CNF_PRFS_RSYNC_OPTS[@]}]="$(jq -j '.backups["'$p'"]["rsync-options"]' "$CNF")"
    done
}


