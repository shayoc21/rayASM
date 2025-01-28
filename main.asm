BITS 16
ORG 0x100

WIDTH EQU 320
HEIGHT EQU 200

section .data
colors: db 0x13, 0x4D, 0x28

section .text
start: 
	call initVideo
	
	mov cx, REFRESH_RATE * WAIT_SECS

.gameLoop:

	call waitFrame

	call drawBG
	call drawCrossHair
	call swapBuffers

	dec cx
	jnz .gameLoop
	call restoreVideo

	jmp .exit

.exit:
	mov ah, 0x4C
	mov al, 0x0
	int 0x21

drawCrossHair:
	mov bx, 95
	mov ch, 0x28
	mov dx, 160
	mov cl, 105
	call drawLine
	ret

drawPixel:
	mov si, ax
	mov [ds:si], ch
	ret

;
;	DRAWLINE FUNCTION TAKES PARAMS:
; BX - START Y
;	CH - COLOR
; DX - X POSITION
;	CL - END Y

drawLine:
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
	mov ax, 0x9000
	mov ds, ax

	mov bx, HEIGHT / 2
	mov dx, 0
	mov cl, HEIGHT
	mov ch, 0x13
	call .drawloop

	mov bx, 0
	mov dx, 0
	mov cl, HEIGHT / 2
	mov ch, 0x4D
	call .drawloop
	ret
	
.drawloop:
	call drawLine
	inc dx
	cmp dx, 320
	jne .drawloop
	ret


; VIDEO BOILERPLATE

REFRESH_RATE EQU 70
WAIT_SECS EQU 5

swapBuffers:
	mov ax, 0x9000
	mov ds, ax
	xor si, si

	mov ax, 0xA000
	mov es, ax
	xor di, di

	mov cx, 64000
	rep movsb

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

