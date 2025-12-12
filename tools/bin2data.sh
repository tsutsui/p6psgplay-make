#!/bin/sh
# bin2data.sh - generate BASIC "DATA" statements from binary data.
# usage: bin2data.sh binfile [size]

MAX_SIZE=8192

prog=${0##*/}

usage() {
    echo "usage: $prog binfile [size]" >&2
    exit 1
}

# od(1) awk(1) 存在チェック
for util in od awk; do
    if ! command -v "$util" >/dev/null 2>&1; then
        echo "$prog: $util(1) not found in PATH" >&2
        exit 1
    fi
done

# 引数チェック
case $# in
1|2) ;;
*)  usage ;;
esac

binfile=$1

# 入力ファイルチェック（C版の open() エラー相当）
if [ ! -r "$binfile" ]; then
    echo "$prog: can't open input file '$binfile'" >&2
    exit 1
fi

# size 指定（C版の strtoul(..., 0) 相当）
if [ $# -eq 2 ]; then
    # base 0 なので 10, 012, 0x10 などをそのまま解釈
    req_size=$(( $2 ))
else
    req_size=0
fi

# .awk の場所（デフォルトはこの .sh と同じディレクトリ）
AWK_SCRIPT=${BIN2DATA_AWK:-$(dirname "$0")/bin2data.awk}

# od で 1バイトごとの16進を吐かせて awk に渡す
# サイズチェックと整形はすべて awk 側で行う
od -An -tx1 -v "$binfile" 2>/dev/null | \
awk -f "$AWK_SCRIPT" \
    -v prog="$prog" \
    -v binfile="$binfile" \
    -v max="$MAX_SIZE" \
    -v req_size="$req_size"

exit $?
