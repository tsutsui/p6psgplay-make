;
; PC-6001 音源ドライバテスト演奏プログラム
;
; 以下を含む
; (1) BASICのDATA文とREAD文で書き込んで EXEC文で呼び出すテープロードルーチン
; (2) テープからロードされた後に BASICから EXEC文で呼び出されるメインのアプリ
;

	ORG	0CA00H

; BASIC ROM内ルーチン
OPENTAPE	EQU	1A61H
READTAPE	EQU	1A70H
CLOSETAPE	EQU	1AAAH

; テープにセーブするバイナリデータのヘッダマーク (値に特に意味はない)
TAPEMARK	EQU	0C9H

; テープからバイナリをロードするルーチン EXEC文エントリ
LOADBIN:
	CALL	OPENTAPE
	LD	HL,DATATOP
	LD	BC,DATAEND-DATATOP

LOADBIN1:
	; マークデータが出てくるまで読み飛ばし
	CALL	READTAPE
	CP	TAPEMARK
	JR	NZ,LOADBIN1
LOADBIN2:
	; マークデータが以外が出てくるまで読み飛ばし
	CALL	READTAPE
	CP	TAPEMARK
	JR	Z,LOADBIN
LOADBIN3:
	; 指定したアドレス (HL) に指定した長さ (BC) 読み出し
	CALL	READTAPE
	LD	(HL),A
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,LOADBIN3
	CALL	CLOSETAPE

	; これで準備完了
	RET

; テープロード用データに切り出せるようにマークを書いておく
; 5バイトくらいでいいはずだが、見やすいように 16バイトにしておく。

	ORG 0CAF0H

	DB TAPEMARK 		; 0
	DB TAPEMARK 		; 1
	DB TAPEMARK 		; 2
	DB TAPEMARK 		; 3
	DB TAPEMARK 		; 4
	DB TAPEMARK 		; 5
	DB TAPEMARK 		; 6
	DB TAPEMARK 		; 7
	DB TAPEMARK 		; 8
	DB TAPEMARK 		; 9
	DB TAPEMARK 		; A
	DB TAPEMARK 		; B
	DB TAPEMARK 		; C
	DB TAPEMARK 		; D
	DB TAPEMARK 		; E
	DB 0	 		; F

	ORG 0CB00H

DATATOP:
; ここからテープから読み出すバイナリデータ

; PSG音源ドライバ
;  START: EXEC &HxC00
;  STOP:  EXEC &HxC03
	include "psgdrv.asm"

; PSG音源ドライバ演奏データ
OBJSAD:
	include "psgdata.asm"

DATAEND:
	END
