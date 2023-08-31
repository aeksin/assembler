.286
;вроде рисует рандомные прямоугольники рандомного цвета при нажатии пробела
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
JMP	BEGIN
CR	EQU	13
	LF	EQU	10
	div_80 DB 80
	div_25 DB 25
	div_10000 DB 100
;=============================macro=================================
 print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop		DX
	pop		AX
endm
;===================================================================
   print_mes	macro	message
   	local	msg, nxt
   	push	AX
   	push	DX
   	mov		DX,	offset msg
   	mov		AH,	09h
   	int	21h
   	pop		DX
    pop		AX
   	jmp nxt
msg	DB message,'$'
nxt:
 	endm
;===================================================================	
;===================================================================
BEGIN:
	mov ax,03
	int 10h;
	metka:
		pusha
		xor ax,ax;
		;mov bl,80
		;mov bh,25
		call	rand8
		div div_80
		mov x1,ah
		call	rand8
		div div_80
		mov x2,ah
		call	rand8
		div div_25
		mov y1,ah
		call	rand8
		div div_25
		mov y2,ah
		call rand8
		div div_10000
		mov color, ah
		popa 
		pusha
		mov ah,06h
		mov al,0
		mov bh,color
		mov ch,y1
		mov cl,x1
		mov dh,y2
		mov dl,x2
		int 10h
		popa
		mov ah, 01h
		int 21h
		cmp al,' '
		jne go_out
		jmp metka
	int 21h
	
	go_out:
	ret
	;
	; rand8
	; Возвращает случайное 8-битное число в AL.
	; Переменная seed должна быть инициализирована заранее,
	; например из области данных BIOS, как в примере для конгруэнтного генератора.
rand8	proc near
			mov	AX,		word ptr	seed
			mov	CX,		8	

newbit:	mov	BX,		AX
			and	BX,		002Dh
			xor	BH,	BL
			clc
			jpe	shift
			stc
shift:	rcr	AX,	1
		loop	newbit
		mov	word	ptr	seed,	AX
		mov	AH,	0
		ret
	rand8 endp
	seed	dw 1
x1 db ?
x2 db ?
y1 db ?
y2 db ?
color db ?
code_seg ends
         end start