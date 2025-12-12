# bin2db.awk - core logic for bin2db.sh
#
# 入力 : od -An -tx1 -v の出力 (1バイトごとの16進)
# 変数 :
#   prog    プログラム名 (エラーメッセージ用)
#   binfile 入力ファイル名 (エラーメッセージ用)
#   max     最大サイズ

# 入力の od(1) 16進バイト列を data[] に読み込み
{
    for (i = 1; i <= NF; i++) {
        data[++n] = $i
    }
}

END {
    # n = 実際に読めたバイト数 (=ファイルサイズ相当)

    if (n == 0 || n > max) {
        printf "%s: invalid size of %s (%d)\n",
               prog, binfile, n > "/dev/stderr"
        exit 1
    }

    printf "\n"

    for (i = 1; i <= n; i++) {
        idx = i - 1   # 0-origin

        # 8バイト毎に行頭に "\tdb\t"
        if (idx % 8 == 0) {
            printf "\tdb\t"
        }

        printf "0%sh", toupper(data[i])

        if (i == n) {
            # 最後のバイト
            printf "\n"
            break
        }

        if (idx % 8 != 7) {
            # 行途中はカンマ区切り
            printf ","
        } else {
            # 行末はオフセットコメント "; 0x%04x" を付けて改行
            off = idx - (idx % 8)    # i & 0xfff8 相当
            printf "\t; 0x%04x\n", off
        }
    }
}
