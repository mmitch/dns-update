#!/bin/bash

setup_test()
{
    set -e

    TESTDIR=$(mktemp -d)
    trap "rm -r \"$TESTDIR\"" EXIT

    BINARY="$TESTDIR/update-client"

    # run from all possible subdirectory depths
    SOURCEDIR=.
    if [ ! -e "$SOURCEDIR/update-client" ]; then SOURCEDIR="../$SOURCEDIR"; fi
    if [ ! -e "$SOURCEDIR/update-client" ]; then SOURCEDIR="../$SOURCEDIR"; fi

    sed s:'^BASEDIR=/home/dns-update':"BASEDIR=\"$TESTDIR\"": < "$SOURCEDIR/update-client" > "$BINARY"
    chmod +x "$BINARY"

    mkdir "$TESTDIR"/{hosts,config,zones}
    
    cp "$SOURCEDIR"/config/zonefile.input "$TESTDIR"/config
    
    NSD_RELOADS="$TESTDIR/nsd_reloads"
    echo -n > "$NSD_RELOADS"
    export NSD_RELOADS

    ZONEFILE="$TESTDIR/zones/dynip.example.com.zone"
    export ZONEFILE
}

# $1 = client IP address from SSH connection
set_ssh_client_ip()
{
    export SSH_CONNECTION=$1
}

# $1 = hostname (second word of "command=" in .ssh/authorized_keys entry)
# $2 = ip address (passed to script, defaults to auto)
# $3 = script name (first word of "command=" in .ssh/authorized_keys entry, defaults to /home/dns-update/update-client)
script_under_test()
{
    export SSH_ORIGINAL_COMMAND="${3:-/home/dns-update/update-client} $2"
    "$BINARY" "$1"
}

# $1 = file to check
# $2 = expected content
assert_contains()
{
    local FILE="$1" FILENAME="${1##*/}" EXPECTED="$2"
    if [ ! -e "$FILE" ]; then
	echo "!!! file '$FILENAME' to be checked not found"
	exit 1
    fi
    if ! grep -E -q "$EXPECTED" "$FILE"; then
	echo "!!! $FILENAME does not contain '$EXPECTED' but:"
	echo "!!! -- START --"
	cat "$FILE"
	echo "!!! --- END ---"
	exit 1
    fi
}

# $1 = file to check
# $2 = expected content
assert_contains()
{
    local FILE="$1" FILENAME="${1##*/}" EXPECTED="$2"
    if [ ! -e "$FILE" ]; then
	echo "!!! file '$FILENAME' to be checked not found"
	exit 1
    fi
    if ! grep -E -q "$EXPECTED" "$FILE"; then
	echo "!!! $FILENAME does not contain '$EXPECTED' but should:"
	echo "!!! -- START --"
	cat "$FILE"
	echo "!!! --- END ---"
	exit 1
    fi
}

# $1 = file to check
# $2 = unexpected content
assert_contains_not()
{
    local FILE="$1" FILENAME="${1##*/}" EXPECTED="$2"
    if [ ! -e "$FILE" ]; then
	echo "!!! file '$FILENAME' to be checked not found"
	exit 1
    fi
    if grep -E -q "$EXPECTED" "$FILE"; then
	echo "!!! $FILENAME does contain '$EXPECTED' but should not:"
	echo "!!! -- START --"
	cat "$FILE"
	echo "!!! --- END ---"
	exit 1
    fi
}

# $* = command to execute
expect_error()
{
    if "$@"; then
	echo "!!! command finished successfully but was expected to fail"
	exit 1
    fi
}

# $1 = expected error message
# $* = command to execute
expect_error_message()
{
    local EXPECTED="$1"
    shift 1
    OUTPUT="$TESTDIR/output"
    if "$@" > "$OUTPUT"; then
	echo "$ERRMSG"
	exit 1
    fi
    assert_contains "$OUTPUT" "$EXPECTED"
    cat "$OUTPUT"
}

# intercept calls to sudo
sudo()
{
    if [ "$*" = "/bin/systemctl reload nsd" ]; then
	grep ';serial' "$ZONEFILE" >> "$NSD_RELOADS"
    else
	echo "!!! unexpected sudo call with '$*'"
	exit 1
    fi
}
export -f sudo

# $1 = expected reloads
assert_nsd_reloads()
{
    local EXPECTED="$1" ACTUAL=0
    while read -r ; do
	ACTUAL=$(( ACTUAL + 1 ))
    done < "$NSD_RELOADS"
    
    if [ "$ACTUAL" != "$EXPECTED" ]; then
	echo "!!! expected '$EXPECTED' nsd reloads but actually had '$ACTUAL'"
	exit 1
    fi
}

setup_test
