#!/bin/sh
# bin2db.sh - convert binary file to Macroassembler AS "db" statements.
# usage: bin2db.sh binfile

MAX_SIZE=8192

prog=${0##*/}

usage() {
    echo "usage: $prog binfile" >&2
    exit 1
}

# od(1) awk(1) 存在チェック
for util in od awk; do
    if ! command -v "$util" >/dev/null 2>&1; then
        echo "$prog: $util(1) not found in PATH" >&2
        exit 1
    fi
done

if [ "$#" -ne 1 ]; then
    usage
fi

binfile=$1

if [ ! -r "$binfile" ]; then
    echo "$prog: can't open input file '$binfile'" >&2
    exit 1
fi

AWK_SCRIPT=${BIN2DB_AWK:-$(dirname "$0")/bin2db.awk}

od -An -tx1 -v "$binfile" 2>/dev/null | \
awk -f "$AWK_SCRIPT" \
    -v prog="$prog" \
    -v binfile="$binfile" \
    -v max="$MAX_SIZE"

exit $?
