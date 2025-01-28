BITS 16
ORG 0x100

WIDTH EQU 320
HEIGHT EQU 200

section .data
colors: db 0x13, 0x4D, 0x28
worldMap: db 	 1, 1, 1, 1, 1, 1,
					db   1, 0, 0, 1, 0, 1,
					db	 1, 0, 0, 0, 0, 1,
					db	 1, 0, 0, 0, 0, 1,
					db	 1, 0, 0, 0, 0, 1,
					db	 1, 1, 1, 1, 1, 1
playerX: dd 1.0
playerY: dd 1.0
playerDirX: dd 1.0
playerDirY: dd 0.0
onef: dd 1.0

theta: dd 0.05
sintheta: dd 0.05
costheta: dd 1.0

result: dd 0.0

section .text
start: 
	call initVideo
	
	mov cx, REFRESH_RATE * WAIT_SECS

.gameLoop:

	call waitFrame
	
	mov ax, 0x9000 		
	mov es, ax 				; -- POINTS ES TO THE BACK BUFFER.
	call drawBG

	call swapBuffers	; -- ES IS THEN POINTED TO THE VGA BUFFER IN THIS FUNCTION

	dec cx
	jnz .gameLoop
	call restoreVideo

	jmp .exit

.exit:
	mov ah, 0x4C
	mov al, 0x0
	int 0x21

;di - vector X (vector Y is always 2 after vector X)
;stores result in ds:result
getVectorLength:							;ST(0) ST(1)
	FLD DWORD PTR [ds:di] 			;
	FMUL st(0), st(0)						;	x2
	
	FLD DWORD PTR [ds:di+2]			; y 		x2
	FMUL st(0), st(0)						; y2    x2

	FADD st(0), st(1)						;y2+x2	x2
	FSQRT												; len		x2
	FSTP DWORD [ds:result]			; x2
	fstp st(0)									; 
	ret

;ds:result - length of vector
;di - vector X
vectorNormalize:
	FLD DWORD PTR [ds:result]		; r
	FLD DWORD PTR [ds:di]				; x			r
	FDIV st(0), st(1)						; x/r		r
	FSTP DWORD [ds:di]					; r
	FLD DWORD PTR [ds:di + 2]   ; y     r
	FDIV st(0), st(1)						; y/r   r
	FSTP DWORD [ds:di + 2]			; r
	FSTP st(0)									;

;ds:theta - turn sens (for now it is fixed at 0.05rad)
;di - vector X
vectorRotate:
	
	FLD DWORD PTR [ds:costheta] ; cos
	FLD DWORD PTR [ds:di]				; x    cos
	FMUL st(1), st(0)						; cos  xcos
	FSTP st(0)									; xcos 
	
	FLD DWORD PTR [ds:sintheta]	; sin	 xcos
	FLD DWORD PTR [ds:di + 2]		; y		 sin	xcos
	FMUL st(1), st(0)						; y		 ysin xcos
	FSTP st(0)									; ysin xcos

	FLD DWORD PTR [ds:di]				; x		 ysin xcos
	FADD st(0), st(2)
	FSUB st(0), st(1)
	FSTP DWORD [ds:di]					; X RESULT STORED
	FLD DWORD PTR [ds:di+2] 	
	FADD st(0), st(1)
	FADD st(0), st(2)
	FSTP DWORD [ds:di+2]				; Y RESULT STORED
	FSTP st(0)
	FSTP st(0)
	ret

drawCrossHair:
	mov bx, 95
	mov ch, [ds:colors + 2]
	mov dx, 160
	mov cl,	105
	call drawVerticalLine
	ret

drawPixel:
	mov si, ax
	mov [es:si], ch
	ret

;
;	DRAWLINE FUNCTION TAKES PARAMS:
; BX - START Y
;	CH - COLOR
; DX - X POSITION
;	CL - END Y

drawVerticalLine:
	push bx
.lineloop:
	mov ax, bx
	push dx
	mov dx, WIDTH
	mul dx
	pop dx
	add ax, dx
	call drawPixel
	inc bx
	cmp bl, cl
	jne .lineloop
	pop bx
	ret

drawBG:

	mov bx, HEIGHT / 2
	mov dx, 0
	mov cl, HEIGHT
	mov ch, [ds:colors + 0]
	call .drawloop

	mov bx, 0
	mov dx, 0
	mov cl, HEIGHT / 2
	mov ch, [ds:colors + 1]
	call .drawloop
	ret
	
.drawloop:
	call drawVerticalLine
	inc dx
	cmp dx, 320
	jne .drawloop
	ret


; VIDEO BOILERPLATE

REFRESH_RATE EQU 70
WAIT_SECS EQU 5

;SWAP BUFFERS FUNCTION:
;	COPIES BUFFER AT 0X9000 INTO 0XA000
; IMPORTANT NOT TO CALL ANY .DATA MEMBERS IN THIS FUNCTION, AS DS IS ALTERED

swapBuffers:
	push ds
	mov ax, 0x9000
	mov ds, ax
	xor si, si

	mov ax, 0xA000
	mov es, ax
	xor di, di

	mov cx, 64000
	rep movsb
	pop ds

waitFrame:
	push dx
	mov dx, 0x03DA
.waitRetrace:
	in al, dx
	test al, 0x08
	jnz .waitRetrace
.endRefresh:
	in al, dx
	test al, 0x08
	jz .endRefresh
	pop dx
	ret

initVideo:
	mov ax, 0x13
	int 0x10

	mov ax, 0x9000
	mov es, ax
	xor di, di
	mov cx, 64000
	mov ax, 0x0
	rep stosb

	mov ax, 0xA000
	mov es, ax
	xor di, di

	ret

restoreVideo:
	mov ax, 0x03
	int 0x10
	ret

