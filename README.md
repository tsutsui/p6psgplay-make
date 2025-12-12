# p6psgplay-make

PC-6001 用 BASIC + Z80 機械語ローダ／テープファイル一式を生成する Makefile

## これはなに？

このディレクトリの `Makefile` は、PC-6001 用の

- N60-BASIC ローダープログラム
- Z80 機械語本体（PSG ドライバ＋MMLデータ＋テスト再生コード）

をまとめてビルドし、以下のファイルを生成するためのものです。

- エミュレータ用 P6 テープファイル
  - `tape/psgplay-bas.p6`（BASIC 部分）
  - `tape/psgplay-data.p6`（機械語部分）
  - `tape/psgplay.p6`（BASIC + 機械語連結済み）
- 実機ロード用 WAV ファイル
  - `tape/psgplay-bas.wav`
  - `tape/psgplay-data.wav`

さらに、このサンプルでは PSG 音源ドライバの MML 演奏テスト用サンプルとして、
以下も自動的に行います。

1. PC-6001 PSG 音源ドライバ・アセンブラソースにパッチを当てる
2. PSG ドライバ用 MML を `p6psgmmlc` でコンパイルする
3. コンパイル結果バイナリから `db` 文アセンブラソースを生成する
4. 上記ドライバ＋データを `include` する `psgplay.asm` をアセンブルする

## 想定手順

PC6001VX などのエミュレータで以下のようにすれば MMLソースの演奏確認ができます。
（ビルド方法などの詳細については後述）

1. MMLファイルを `./mml/sample.mml` としてセーブ
2. このディレクトリで `make`
3. PC6001VX 等のエミュレータを起動しテープデータとして `tape/psgplay.p6` を指定
4. エミュレータ上で `CLOAD`
5. エミュレータ上で `RUN`
6. ロードが完了したらなにかキーを押す

PC-6001 実機でも以下のようにすれば MMLソースの演奏確認ができます。

1. MMLファイルを `./mml/sample.mml` としてセーブ
2. このディレクトリで `make`
3. PC-6001 実機を起動して CMT ケーブルの白をヘッドホン出力などに接続
4. PC-6001 実機で `CLOAD` して PC 側で `tape/psgplay-bas.wav` を再生
5. PC-6001 実機で `RUN` して PC 側で `tape/psgplay-data.wav` を再生
6. ロードが完了したらなにかキーを押す

BASIC プログラムのベース部分や機械語ソースを修正することで
[一千光年 feat. PC-6001](https://tsutsui.hatenablog.com/entry/1000kounen-p6)
のようなデモも作成可能です。

---

## ディレクトリ構成およびファイル構成

トップディレクトリ（この `README.md` と `Makefile` がある場所）を `.` として、
ざっくり以下のような構成です。

- `./Makefile`  
  この README 対応の Makefile 本体

- `./psgplay.asm`  
  テスト用 PSG データロードと再生コード
  （ビルドで生成される `psgdrv.asm` と `psgdata.asm` を `include` する構成）

- `./psgplay-base.bas`  
  BASIC プログラムの「ベース部分」  
  （ローダー機械語部の `DATA` 文以外。`DATA` 文は `Makefile` が生成して連結）

- `./mml/`  
  PSG ドライバ用 MML ソースディレクトリ
  - `sample.mml`（テスト用のサンプル MML ソース。`MMLFILE` で変更可能）

- `./psgdrv/`  
  PSG ドライバオリジナルソースとパッチ
  - `psgdrv_asmsrc.TXT`  
    オリジナル PSG 音源ドライバソース（ユーザーが別途入手して配置）
  - `psgdrv_asmsrc.TXT.diff`  
    上記に適用するパッチ（本リポジトリ側で用意）

- `./tools/`  
  バイナリ→テキスト変換スクリプト
  - `bin2data.sh`, `bin2data.awk`  
    バイナリ → BASIC 行番号 + `DATA` 文列に変換
  - `bin2db.sh`, `bin2db.awk`  
    バイナリ → `db 0xxh, ...` 形式に変換（Macroassembler AS 用）
- `./tape/`  
  生成された `.p6` / `.wav` の出力先（`Makefile` が自動で作成）

ビルド時に自動的に追加されるディレクトリ／ファイル:

- `./txt2bas07/`  
  `txt2bas` の展開・ビルドディレクトリ
- `./p6psgmmlc/`  
  MML コンパイラ `p6psgmmlc` の `git clone` + ビルド結果
- `./p6towav/`  
  P6ファイルから音声wav生成するツール `p6towav` の `git clone` + ビルド結果

---

## 必要なツール

### 1. Unix の基本コマンド

以下は NetBSD / Ubuntu / Arch Linux などの通常インストールならほぼ標準で入っています。

- `awk`
- `cat`
- `cp`
- `dd`
- `grep`
- `mkdir`
- `mv`
- `rm`
- `od`
- `patch`（※ 最低限これだけは無い環境もあり得る）

Makefile 内では変数経由で利用しています。

```make
AWK?=   awk
CAT?=   cat
CP?=    cp
DD?=    dd
GREP?=  grep
MKDIR?= mkdir
MV?=    mv
PATCH?= patch
RM?=    rm
OD?=    od
```

足りないコマンドがある場合、`make` 実行時に

> psgplay のビルドに必要なコマンド xxx がインストールされていません

といったエラーが出ます。その場合は該当コマンドをインストールしてください。

### 2. Macroassembler AS

Z80 アセンブラとして [Macroassembler AS](http://john.ccac.rwth-aachen.de:8000/as/) を使用します。

* 必要なコマンド

  * `asl`
  * `p2bin`
  * `plist`

Makefile では以下のように定義されています。

```make
ASL=    asl
ASLOPTS= -cpu z80 -L
P2BIN=  p2bin
PLIST=  plist
```

インストール済みの環境であれば PATH に通っていることを確認してください。

### 3. C コンパイラ

外部ツール（`p6psgmmlc` / `p6towav` / `txt2bas`）をビルドするために C コンパイラが必要です。

* デフォルト: `cc`
* 必要に応じて `CC=clang` のように上書き可能

```make
CC?= cc
```

### 4. ネットワークと展開ツール

以下は「初回に外部ツールを自動取得・ビルドする」のに使います。

* `wget` または `ftp`（Makefile ではデフォルト `wget`）
* `unzip`
* `git`

Makefile 上の定義:

```make
WGET?=  wget      # 必要なら ftp に差し替え可
#WGET?=  ftp
UNZIP?= unzip
GIT?=   git
```

URL にアクセスできるネットワーク環境が前提です。

---

## 自動取得される外部ツール

### 1. txt2bas

* 役割: BASIC テキスト (`psgplay.bas`) → P6 テープファイル (`psgplay-bas.p6`) 変換
* 取得先: `http://retropc.net/isio/mysoft/txt2bas07.zip`
* 展開先: `./txt2bas07`
* 実行ファイル: `./txt2bas07/source/txt2bas`

`txt2bas` がまだ存在しない状態で `make` すると、
自動的に zip をダウンロード／展開／ビルドします。

### 2. p6psgmmlc

* 役割: PSG ドライバ用 MML (`mml/sample.mml` 等) → PSG データバイナリ (`psgdata.bin`) 変換
* 取得元: GitHub `https://github.com/tsutsui/p6psgmmlc`
* 展開先: `./p6psgmmlc`
* 実行ファイル: `./p6psgmmlc/p6psgmmlc`

`p6psgmmlc` が無い状態で `psgdata.asm` を作ろうとすると、
自動的に `git clone` + `make` が走ります。

### 3. p6towav

* 役割: P6 ファイル → WAV ファイル変換
* 取得元: GitHub `https://github.com/tsutsui/p6towav`
* 展開先: `./p6towav`
* 実行ファイル: `./p6towav/p6towav`

`.wav` 生成ターゲットを叩いたときに `p6towav` が無ければ、
自動的に `git clone` + `make` が走ります。

---

## PSG ドライバオリジナルソースの配置

PSG ドライバそのもののソースは自動取得していません。
以下は **ユーザーが事前に用意する必要があります**。

1. オリジナルソース `psgdrv_asmsrc.TXT` をミラーサイトなどから取得
2. `psgdrv/` ディレクトリに取得した `psgdrv_asmsrc.TXT` をコピー

Makefile は `psgdrv.asm` を作る際に

* `psgdrv/psgdrv_asmsrc.TXT` をカレントディレクトリにコピー
* `psgdrv_asmsrc.TXT.diff` を `patch` で適用
* 結果を `psgdrv.asm` にリネーム

という手順を実行します。

`psgdrv/psgdrv_asmsrc.TXT` が存在しない場合、`make` 実行時に

> psgdrv_asmsrc.TXT を取得して psgdrv にコピーしてください

とメッセージを出して停止するので、前述の説明に従って配置してください。

---

## 使い方とビルドについて

### 1. 最低限の準備

1. `psgdrv/psgdrv_asmsrc.TXT` を所定の場所に配置
2. `mml/sample.mml` に PSG ドライバ用 MML を用意（デフォルトのサンプルでもOK）
3. 必要ツール（`asl` / `p2bin` / `plist` / `git` / `wget` / `unzip` / `cc` など）が
   PATH 上にあることを確認

ツール類が揃っているか事前に確認したい場合は：

```sh
make checktools
```

で

> ビルドに必要なコマンドはインストールされています

と出れば OK です。

### 2. まとめてビルド（デフォルト）

このディレクトリで

```sh
make
```

または

```sh
make all
```

を実行すると、

* `psgplay-bas.p6`, `psgplay-data.p6`, `psgplay.p6` のエミュレータ用P6ファイル
* `psgplay-bas.wav`, `psgplay-data.wav` の実機CLOAD用 wavファイル

まで一気に生成されます。

途中でツールが足りない場合や PSG ドライバソースが無い場合には、
エラーメッセージが出て止まるので、その内容に従って環境を整えてください。

---

## ビルドフローの詳細

ざっくりとした流れは以下のとおりです。

### 0. PSG ドライバと MML データの準備

1. `psgdrv_asmsrc.TXT` + パッチ → `psgdrv.asm` を生成
2. `p6psgmmlc` で MML (`mml/sample.mml` 等) → `psgdata.bin`
3. `bin2db.sh` で `psgdata.bin` → `psgdata.asm` (`db 0xxh` 列)

`psgplay.asm` は `psgdrv.asm` と `psgdata.asm` を `include` して、
PSG ドライバ・データ込みの Z80 プログラムを構成します。

### 1. Macroassembler AS によるアセンブル

* `psgplay.asm`（+ include される asm ファイル）を `asl` でアセンブルし、
* `.p`（オブジェクト）と `.lst` を生成
* `p2bin` で `.p` から `.bin` を生成

### 2. ローダ部分を BASIC DATA 文に変換

`plist` の出力から BASIC文部分で必要な `LOADER_ADDR` に対応するサイズを取得し、
そのバイト数だけ `.bin` から読み取って BASICの 行番号 + `DATA` 文に変換します。

* ローダ開始アドレス（16進）: `LOADER_ADDR=CA00`
* EXEC される本体開始アドレス: `PROG_ADDR=CB00`
* テープヘッダ長: `P6HDRSIZE=16` バイト

これらはアセンブラ側および BASIC プログラムと **手動同期が必要** なパラメータです。
変更するときは `psgplay.asm` / `psgplay-base.bas` と合わせて変更してください。

変換処理:

1. `.p` を `plist` して `LOADER_ADDR` 部分のサイズ（16進）を取得
2. そのサイズ分 `.bin` から読み出し `bin2data.sh` で `DATA` 文列に変換
3. `psgplay-base.bas` の末尾に `DATA` 文を連結 → `psgplay.bas` 完成

### 3. BASIC / 機械語の P6 化と WAV 化

* `psgplay.bas` → `txt2bas` → `psgplay-bas.p6`
* `psgplay.bin` からローダ部分をスキップして本体データを切り出し → `psgplay-data.p6`
* 両者を連結して `psgplay.p6` を作成
* `p6towav` で `*.p6` → `*.wav` を生成

---

## カスタマイズ

### ターゲット名の変更

`psgplay` 以外の名前でビルドしたい場合、Makefile 冒頭の

```make
TARGET= psgplay
```

を変更すると、

* `*.asm` / `*.bas`
* `tape/` 以下のファイル一式

の名前が一括で切り替わります。

### MML ファイルの変更

`mml/` 以下の MML ファイル名を指定するには、

* Makefile 内を直接書き換える場合:

  ```make
  MMLFILE?= sample.mml
  ```

  を他のファイル名に変更。

* 実行時に差し替える場合:

  ```sh
  make MMLFILE=foo.mml
  ```

### 配置アドレスやヘッダサイズの変更

以下の 3 つはアセンブラコードと BASIC プログラムに依存する値です。

```make
LOADER_ADDR= CA00
PROG_ADDR=   CB00
P6HDRSIZE=   16
```

意味:

* `LOADER_ADDR`: ローダ本体の配置開始アドレス（16進）
* `PROG_ADDR`: EXEC される本体の配置開始アドレス（16進）
* `P6HDRSIZE`: 機械語部分 P6 データ先頭ヘッダのバイト数

これらを変更するときは、

* `psgplay.asm` 側の ORG / ローダの参照アドレス
* BASIC 側の EXEC 先アドレス
* 実際の P6 ヘッダ長

と必ず整合を取ってください。

---

## エラーと対処

### 「psgdrv_asmsrc.TXT を取得して psgdrv にコピーしてください」

* PSG ドライバのオリジナルソースが見つからない状態です。
* `psgdrv/psgdrv_asmsrc.TXT` を用意し、再度 `make` してください。

### 「psgplay のビルドに必要なコマンド xxx がインストールされていません」

* 使用するツールのインストールチェックに引っかかった状態です。
* 表示されたコマンド（`asl`, `p2bin`, `plist`, `git`, `wget`, `unzip`, `cc` など）
をインストールしてから再度 `make` してください。

### 「アセンブラバイナリ のビルドに必要なコマンド xxx がインストールされていません」

* Macroassembler AS 関連 (`asl`, `p2bin`, `plist`) のいずれかが PATH から見えていません。
* AS 一式のインストールと PATH 設定を確認してください。

---

## `make clean`

* 一時ファイルや生成された asm / bin / bas などを消す場合:

  ```sh
  make clean
  ```

* それに加えて `txt2bas07` / `p6psgmmlc` / `p6towav` の取得物や zip も含めて消す場合:

  ```sh
  make distclean
  ```

再取得・再ビルドも含めてやり直したいときは `make distclean` を使ってください。
