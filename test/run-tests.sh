#!/bin/bash

set -e

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
