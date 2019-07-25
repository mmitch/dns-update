#!/bin/bash

setup_test()
{
    set -e

    TESTDIR=$(mktemp -d)
    trap "rm -r \"$TESTDIR\"" EXIT

    BINARY="$TESTDIR/update-client"

    # run from all possible subdirectory depths
    SOURCE=update-client
    if [ ! -e "$SOURCE" ]; then SOURCE="../$SOURCE"; fi
    if [ ! -e "$SOURCE" ]; then SOURCE="../$SOURCE"; fi

    sed s:'^BASEDIR=/home/dns-update':"BASEDIR=\"$TESTDIR\"": < "$SOURCE" > "$BINARY"
    chmod +x "$BINARY"
}

setup_test
