# bin2data.awk - core logic for bin2data.sh
#
# 入力 : od -An -tx1 -v の出力 (1バイトごとの16進)
# 変数 :
#   prog       プログラム名 (エラーメッセージ用)
#   binfile    入力ファイル名 (エラーメッセージ用)
#   max        最大サイズ
#   req_size   変換するサイズ (0 の場合は入力全体)

# 入力の od(1) 16進バイト列を data[] に読み込み
{
    for (i = 1; i <= NF; i++) {
        data[++n] = $i
    }
}

END {

    # DATA文開始行番号
    line = 1000
    # 1行あたり16バイト
    perline = 16

    # n = 実際に読めたバイト数 (=入力ファイルサイズ)
    size = req_size + 0  # 数値化

    # サイズ指定がなければ全体
    if (size == 0)
        size = n

    # サイズチェック
    if (size <= 0 || size > max) {
        printf "%s: invalid size of %s (%d)\n",
               prog, binfile, n > "/dev/stderr"
        exit 1
    }

    # 入力サイズチェック
    if (size > n) {
        printf "%s: failed to read input file\n", prog > "/dev/stderr"
        exit 1
    }

    if (size == 0)
        exit 0

    for (i = 1; i <= size; i++) {
        if ((i - 1) % perline == 0) {
            # 行頭に行番号と DATA文
            printf "%d DATA ", line
        }

        # od の16進バイトを大文字化
        printf "%s", toupper(data[i])

        if (i == size) {
            # 最後のバイトであれば DATA文用の終端を書いて終了
            printf ",END\n"
            break
        }

        if (i % perline == 0) {
            # 行末 (16バイト目) で改行して次の行番号
            printf "\n"
            line += 10
        } else {
            # 行途中はコンマ区切り
            printf ","
        }
    }
}
