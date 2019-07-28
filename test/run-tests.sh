#!/bin/bash

#
# runtest.sh - test script for update-client
# Copyright (C) 2019  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 (or later)
#
# This file is part of:
#  dns-update - small dynamic DNS suite using SSH
#  https://github.com/mmitch/dns-update
#

set -e

# run in autowatch mode with "--watch"
if [ "$1" = "--watch" ]; then
    ./run-tests.sh || true
    while inotifywait -e modify -e move -e move_self -e create -e delete -e delete_self tests tests/* test-functions.sh run-tests.sh ../update-client; do
	./run-tests.sh || true
    done
    exit 0
fi

# single run mode from here on
OK=0
FAILED=0
for TESTSCRIPT in tests/*.test; do

    TESTNAME=${TESTSCRIPT%.test}
    TESTNAME=${TESTNAME#tests/}
    
    echo ">>> running test $TESTNAME:"
    if bash -e "$TESTSCRIPT"; then
	echo "<<< test ok"
	OK=$(( OK + 1 ))
    else
	echo "<<< TEST FAILED"
	FAILED=$(( FAILED + 1 ))
    fi

    echo
    
done

echo "result:"
printf "%3d successful tests\n" $OK
printf "%3d failed tests\n" $FAILED

if [ $FAILED -gt 0 ]; then
    exit 1
fi
exit 0
