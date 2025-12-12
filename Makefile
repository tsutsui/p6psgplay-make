# ----------------------------------------------------------------------
# Makefile to build PC-6001 BASIC + Z80 machine code set
# (1) Macroassembler AS で Z80アセンブラソースをアセンブル
# (2) BASIC DATA文での埋め込みローダー部を含む N60-BASICプログラム生成
# (3) エミュレータ用 P6 テープファイルと実機ロード用 wav ファイル生成
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# このバージョンは P6 PSG音源ドライバMML演奏テスト用サンプルとして以下も実施
# (0-a) PC-6001 PSG音源ドライバアセンブラソースにパッチ当て
# (0-b) PC-6001 PSG音源ドライバ用MMLソースを p6psgmmlc でコンパイル
# (0-c) 音源ドライバとMMLコンパイルデータを include するための db 文生成
# (0-d) 上記ドライバとデータを include する psgplay.asm を用意
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# ビルドプロジェクト設定
# ----------------------------------------------------------------------

# ターゲット および ソースファイル名
TARGET=		psgplay

# MML ソースファイル
MMLFILE?=	sample.mml

MMLDIR?=	./mml
MMLSRC?=	${MMLDIR}/${MMLFILE}

# BASIC プログラムベース (ローダ部 DATA 文以外の更新不要部分)
BAS_BASE=	${TARGET}-base.bas

# ----------------------------------------------------------------------
# 機械語データ配置情報 (現状はアセンブラやBASIC文記述と手動同期必要)
# ----------------------------------------------------------------------

# BASIC プログラム DATA文で埋め込むローダ部分の開始アドレス (16進)
LOADER_ADDR=	CA00

# BASIC プログラムから EXEC文で呼び出す機械語ルーチン部分の開始アドレス (16進)
# 現状は手動で同期必要
PROG_ADDR=	CB00

# 機械語部分 P6テープデータ先頭のヘッダデータバイト数
# 現状は手動で同期必要
P6HDRSIZE=	16

# ----------------------------------------------------------------------
# 必要なツール一式
# ----------------------------------------------------------------------

# Makefile中で使用するコマンド
AWK?=		awk
CAT?=		cat
CP?=		cp
ECHO?=		echo
DD?=		dd
GREP?=		grep
MKDIR?=		mkdir
MV?=		mv
PATCH?=		patch
RM?=		rm

# bin2db.sh と bin2data.sh のテキスト変換スクリプトで使用するコマンド
OD?=		od

CHECK_TOOLS_psgplay=	${AWK} ${CAT} ${CP}
#CHECK_TOOLS_psgplay+=	${ECHO}			# sh(1) ビルトイン
CHECK_TOOLS_psgplay+=	${DD} ${GREP} ${MKDIR} ${MV} ${PATCH} ${RM}

CHECK_TOOLS_psgplay+=	${OD}

# コマンドビルド用
CC?=		cc
#CC?=		clang

# txt2bas07.zip 取得と展開とビルドで使用するコマンド
WGET?=		wget
#WGET?=		ftp
UNZIP?=		unzip

CHECK_TOOLS_txt2bas=	${WGET}	${UNZIP} ${CC}

# p6psgmmlc や p6towav の git clone 用
GIT?=		git

CHECK_TOOLS_p6psgmmlc=	${GIT} ${CC}
CHECK_TOOLS_p6towav=	${GIT} ${CC}

# ----------------------------------------------------------------------
# 機械語バイナリ→テキスト変換スクリプトとそれらのディレクトリ
# ----------------------------------------------------------------------

TOP=		.
TOOLSDIR=	${TOP}/tools

# bin2db.sh: バイナリから Z80 asm db文列を生成
BIN2DB=		${TOOLSDIR}/bin2db.sh

# bin2data.sh: バイナリから BASIC DATA文列を生成
BIN2DATA=	${TOOLSDIR}/bin2data.sh

# ----------------------------------------------------------------------
# Z80アセンブル用 Macroassembler AS インストール場所とコマンド定義
# http://john.ccac.rwth-aachen.de:8000/as/
# ----------------------------------------------------------------------

# Macroassembler AS
#ASPATH?=	/usr/local/bin
#ASPATH?=	/usr/pkg/bin
ASL=		asl
ASLOPTS=	-cpu z80 -L
P2BIN=		p2bin
PLIST=		plist

CHECK_TOOLS_asl=	${ASL} ${P2BIN} ${PLIST}

# ----------------------------------------------------------------------
# テープP6ファイルおよび wavファイル作成までに使用する外部ツール
# ----------------------------------------------------------------------

## ---------------------------------------------------------------------
## txt2bas: BASICテキストファイルから P6ファイル生成
## http://retropc.net/isio/mysoft/#txt2bas
## ---------------------------------------------------------------------
TXT2BASZIP=	txt2bas07.zip
TXT2BASURL=	http://retropc.net/isio/mysoft/${TXT2BASZIP}
TXT2BASDIR=	${TOP}/txt2bas07
TXT2BAS=	${TXT2BASDIR}/source/txt2bas

## ---------------------------------------------------------------------
## p6psgmmlc: MMLソーステキストから P6 PSGドライバ用データをコンパイル
## ---------------------------------------------------------------------
P6PSGMMLCGITHUB= https://github.com/tsutsui/p6psgmmlc
P6PSGMMLCDIR=	${TOP}/p6psgmmlc
P6PSGMMLC=	${P6PSGMMLCDIR}/p6psgmmlc

## ---------------------------------------------------------------------
## p6towav: P6ファイルから wav ファイルを生成
## ---------------------------------------------------------------------
P6TOWAVGITHUB=	https://github.com/tsutsui/p6towav
P6TOWAVDIR=	${TOP}/p6towav
P6TOWAV=	${P6TOWAVDIR}/p6towav

# ----------------------------------------------------------------------
# PC-6001 PSG音源ドライバソース配置場所
# http://park10.wakwak.com/~yosh/p6/manual.html をどうにか持ってくる前提
# ----------------------------------------------------------------------
PSGDRVDIR=	${TOP}/psgdrv
PSGDRVSRCFILE=	psgdrv_asmsrc.TXT
PSGDRVSRC=	${PSGDRVDIR}/${PSGDRVSRCFILE}
PSGDRVPATCH=	${PSGDRVDIR}/${PSGDRVSRCFILE}.diff

# ----------------------------------------------------------------------
# ビルド生成ファイル
# ----------------------------------------------------------------------

# アセンブル結果
OBJ_P=		${TARGET}.p		# asl オブジェクトファイル
OBJ_LST=	${TARGET}.lst		# asl アセンブル後リストファイル
OBJ_BIN=	${TARGET}.bin		# rawバイナリ出力

# ローダ DATA 埋め込み済みの BASIC プログラム出力
BAS_PROG=	${TARGET}.bas

# テープファイル出力ディレクトリ
TAPEDIR=	${TOP}/tape

# テープファイル (.p6)
BAS_P6=		${TAPEDIR}/${TARGET}-bas.p6
DATA_P6=	${TAPEDIR}/${TARGET}-data.p6
ALL_P6=		${TAPEDIR}/${TARGET}.p6

# 実機ロード用 wav ファイル
BAS_WAV=	${TAPEDIR}/${TARGET}-bas.wav
DATA_WAV=	${TAPEDIR}/${TARGET}-data.wav

# ファイル別生成ターゲット定義
P6FILES=	${BAS_P6} ${DATA_P6} ${ALL_P6}
WAVFILES=	${BAS_WAV} ${DATA_WAV}

# ----------------------------------------------------------------------
# アセンブラソースファイル (include文で取り込むものを含む)
# ----------------------------------------------------------------------

ASMSRC=		${TARGET}.asm

ASMINCSRC=	psgdrv.asm
ASMINCSRC+=	psgdata.asm

# ----------------------------------------------------------------------
# ターゲット定義
# ----------------------------------------------------------------------
.PHONY: all p6files wavfiles

# デフォルトターゲットでは P6テープファイルと wav まで作成
all: p6files wavfiles

# エミュレータ用テープファイル一式 (.p6)
p6files: ${P6FILES}

# 実機ロード用 wav ファイル一式
wavfiles: ${WAVFILES}

# ----------------------------------------------------------------------
# 必要ツール存在チェック
# ----------------------------------------------------------------------

CHECK_TOOLS_SH=								\
	missing="";							\
	for tool in $$TOOLS; do						\
		case "$$tool" in					\
		""|-* )							\
			continue					\
			;;						\
		esac;							\
		if ! command -v "$$tool" > /dev/null 2>&1; then		\
			missing="$$missing $$tool";			\
		fi;							\
	done;								\
	if [ -n "$$missing" ]; then					\
		${ECHO} "$$TARGET のビルドに必要なコマンド"		\
		"$$missing がインストールされていません";		\
		exit 1;							\
	fi

CHECK_TOOLS_all=	${CHECK_TOOLS_psgplay}
CHECK_TOOLS_all+=	${CHECK_TOOLS_asl}
CHECK_TOOLS_all+=	${CHECK_TOOLS_txt2bas}
CHECK_TOOLS_all+=	${CHECK_TOOLS_p6psgmmlc}
CHECK_TOOLS_all+=	${CHECK_TOOLS_p6towav}

.PHONY: checktools

checktools:
	@TOOLS='${CHECK_TOOLS_all}' TARGET=psgplay;			\
	    ${CHECK_TOOLS_SH}
	@${ECHO} 'ビルドに必要なコマンドはインストールされています'

# ----------------------------------------------------------------------
# Macroassembler AS でビルドするファイルのサフィックスルール
# ----------------------------------------------------------------------

.SUFFIXES: .asm .p .bin

# アセンブル (オブジェクト生成)
.asm.p:
	@${ECHO} "==> $@ をアセンブル"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_asl}' TARGET=アセンブラバイナリ;		\
	    ${CHECK_TOOLS_SH}
	${ASL} ${ASLOPTS} $<

# rawバイナリ生成
.p.bin:
	@${ECHO} "==> $@ を出力"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_asl}' TARGET=アセンブラバイナリ;		\
	    ${CHECK_TOOLS_SH}
	${P2BIN} $<

# ----------------------------------------------------------------------
# p6psgmmlc を git clone で取得してビルド
# ----------------------------------------------------------------------
${P6PSGMMLC}:
	@${ECHO} "==> $@ を取得してビルド"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_p6psgmmlc}' TARGET=p6psgmmlc;		\
	    ${CHECK_TOOLS_SH}
	${RM} -rf ${P6PSGMMLCDIR}
	# 乱暴に git clone
	${GIT} clone ${P6PSGMMLCGITHUB}
	# ビルド
	(cd ${P6PSGMMLCDIR} && ${MAKE})

# ----------------------------------------------------------------------
# p6towav を git clone で取得してビルド
# ----------------------------------------------------------------------
${P6TOWAV}:
	@${ECHO} "==> $@ を取得してビルド"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_p6towav}' TARGET=p6towav;			\
	    ${CHECK_TOOLS_SH}
	# 乱暴に git clone
	${RM} -rf ${P6TOWAVDIR}
	# ビルド
	${GIT} clone ${P6TOWAVGITHUB}
	(cd ${P6TOWAVDIR} && ${MAKE})

# ----------------------------------------------------------------------
# txt2bas の zip アーカイブを取得してビルド
# ----------------------------------------------------------------------
${TXT2BAS}:
	@${ECHO} "==> $@ を取得してビルド"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_txt2bas}' TARGET=txt2bas;			\
	    ${CHECK_TOOLS_SH}
	# 乱暴に取得展開
	${RM} -rf ${TXT2BASDIR}
	${WGET} ${TXT2BASURL}
	${UNZIP} -o -x ${TXT2BASZIP}
	# ビルド
	(cd ${TXT2BASDIR}/source && ${MAKE})

# ----------------------------------------------------------------------
# PSG driver: オリジナルのPSGドライバソースにパッチを当てる
# ----------------------------------------------------------------------
${PSGDRVSRC}:
	@${ECHO} "${PSGDRVSRCFILE} を取得して ${PSGDRVDIR} にコピーしてください"
	@false

psgdrv.asm: ${PSGDRVSRC} ${PSGDRVPATCH}
	@${ECHO} "==> ${PSGDRVSRC} をパッチして $@ を生成"
	${CP} ${PSGDRVSRC} .
	${PATCH} -p0 < ${PSGDRVPATCH}
	${MV} ${PSGDRVSRCFILE} $@

CLEANFILES+=	psgdrv.asm ${PSGDRVSRCFILE} ${PSGDRVSRCFILE}.orig

# ----------------------------------------------------------------------
# PSG data: MMLコンパイルして db文 asmファイル生成
# ----------------------------------------------------------------------

psgdata.asm: ${MMLSRC} ${P6PSGMMLC}
	@${ECHO} "==> MMLファイル ${MMLSRC} をコンパイルして $@ を生成"
	${P6PSGMMLC} ${MMLSRC} psgdata.bin
	${BIN2DB} psgdata.bin > $@

CLEANFILES+=	psgdata.asm psgdata.bin

# ASL generates ${OBJ_LST} and ${OBJ_P}
${OBJ_P}: ${ASMSRC} ${ASMINCSRC} psgdata.asm

CLEANFILES+=	${OBJ_P} ${OBJ_LST}

# ----------------------------------------------------------------------
# BASIC: ローダ本体を DATA 文に変換して埋め込む
# ----------------------------------------------------------------------
# 1. .p のリンクアドレス情報から ${LOADER_ADDR} 部分のサイズを取得
# 2. そのバイト数のバイナリを bin2data で BASIC DATA 文に変換
# 3. BASIC プログラムベース部分に DATA を連結して BASIC プログラム全体を生成
# ----------------------------------------------------------------------

${BAS_PROG}: ${OBJ_BIN} ${BAS_BASE} ${OBJ_P}
	@${ECHO} "==> BASICプログラムテキスト $@ を生成"
	# 必要ツール存在チェック
	@TOOLS='${CHECK_TOOLS_psgplay}' TARGET=psgplay;			\
	    ${CHECK_TOOLS_SH}
	size_hex=$$(${PLIST} ${OBJ_P} | ${GREP} ${LOADER_ADDR} | \
	    ${AWK} '{print $$4}'); \
	size_dec=$$(( 0x$$size_hex )); \
	( ${CAT} ${BAS_BASE}; \
	  ${BIN2DATA} ${OBJ_BIN} $$size_dec ) > $@

CLEANFILES+=	${BAS_PROG}
CLEANFILES+=	${OBJ_BIN}

# ----------------------------------------------------------------------
# BASICプログラムから P6テープファイル生成
# ----------------------------------------------------------------------

${BAS_P6}: ${BAS_PROG} ${TXT2BAS}
	@${ECHO} "==> BASICプログラムP6ファイル $@ を生成"
	${MKDIR} -p ${TAPEDIR}
	${TXT2BAS} ${BAS_PROG} $@

# ----------------------------------------------------------------------
# 機械語部分（ヘッダ含む）から P6テープファイル生成
#   - (先頭のローダー部領域 - テープヘッダ分) をスキップ
# ----------------------------------------------------------------------

${DATA_P6}: ${OBJ_BIN}
	@${ECHO} "==> バイナリデータP6ファイル $@ を生成"
	${MKDIR} -p ${TAPEDIR}
	p6offset=$$(( 0x${PROG_ADDR} - 0x${LOADER_ADDR} - ${P6HDRSIZE} )); \
	    ${DD} if=${OBJ_BIN} of=$@ bs=1 skip=$$p6offset

# ----------------------------------------------------------------------
# BASIC 部分と本体データ部分を連結したエミュレータ用 P6テープファイル
# ----------------------------------------------------------------------

${ALL_P6}: ${BAS_P6} ${DATA_P6}
	@${ECHO} "==> 結合した $@ を生成"
	${CAT} ${BAS_P6} ${DATA_P6} > $@

# ----------------------------------------------------------------------
# p6towav で実機ロード用 wav 生成
# ----------------------------------------------------------------------

${BAS_WAV}: ${BAS_P6} ${P6TOWAV}
	@${ECHO} "==> P6ファイルから $@ を生成"
	${P6TOWAV} ${BAS_P6} $@

${DATA_WAV}: ${DATA_P6} ${P6TOWAV}
	@${ECHO} "==> P6ファイルから $@ を生成"
	${P6TOWAV} ${DATA_P6} $@

# ----------------------------------------------------------------------
# clean
# ----------------------------------------------------------------------
.PHONY: clean distclean

clean:
	${RM} -f ${CLEANFILES}
	${RM} -rf ${CLEANDIR}

distclean: clean
	${RM} -f ${TXT2BASZIP} ${TXT2BASZIP}.*
	${RM} -rf ${TXT2BASDIR}
	${RM} -rf ${P6PSGMMLCDIR}
	${RM} -rf ${P6TOWAVDIR}
