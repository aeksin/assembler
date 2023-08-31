.286
;имба, часики!!!!
;+--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
    jmp begin
;----------------------------------------------------------------------------
;заменить
int_2Fh_vector  DD  ?
old_09h         DD  ?
old_1ch			DD	?
PRINT       PROC FAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP
;----------------------------------------------------------------------------
flag        DB  0
print_hex proc FAR
and DL,0Fh
add DL,30h
cmp DL,3Ah
jl $print
add DL,07h
$print:
int 21H
 ret
print_hex endp
PRINT_CRLF macro 
	 push AX
	 push DX
	 mov DL,13
	 mov AH,02
	 int 21h ; print CR
	 mov DL,10
	 mov AH,02
	 int 21h ; print LF
	 pop DX
	 pop AX
 ENDm
 print_reg_AX proc FAR
	push AX
	push BX
	push CX
	push DX
	;
	mov BX, AX
	mov AH,02
	 mov DL,BH
	rcr DL,4
	call print_hex
	 mov DL,BH
	call print_hex
	mov DL,BL
	rcr DL,4
	call print_hex
	mov DL,BL
	call print_hex
	pop DX
	pop CX
	pop BX
	pop AX
	ret
	print_reg_AX endp
;============================================================================
new_1ch proc far                  ;новый обработчик прерывания 21h
	sti                 ; Не будем мешать таймеру
    in      AL,61h      ; Введем содержимое порта B
    or      AL,80h      ; Установим старший бит
    out     61h,AL      ; и вернем в порт B.
    and     AL,7Fh      ; Снова разрешим работу клавиатуры,
    out     61h,AL      ; сбросив старший бит порта B.
	cli
	mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
	out     20h,AL       ; приказ END OF INTERRUPT (EOF)
	pushf
	pusha
	push cs
	pop ds
	jmp perem
	page_num    DB  0
	div_12	DB	12
	div_5	DB	5
	str1			DB	201,205,205,205,205,205,205,205,205,205,187,'$'
	str2			DB	186,'11 12  1 ',186,'$'
	str3 			DB	186,'10     2 ',186,'$'
	str4			DB	186,' 9  *  3 ',186,'$'
	str5			DB	186,' 8     4 ',186,'$'
	str6			DB	186,' 7  6  5 ',186,'$'
	str7			DB	200,205,205,205,205,205,205,205,205,205,188,'$'
	y				DB	00
	x				DB	48
	clocks_here		DB	0	
	perem:
	cmp flag,1
	je not_showing
	jmp installed
	not_showing:
		push ax
		mov ah,0Fh
		int 10h
		mov ah,03h
		int 10h
		push dx
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str1
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str2
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str3
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str4
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str5
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str6
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str7
		int 21h
		inc y
		;div div_12
		
		
		
		mov ah,2ch
		int 21h
		xor ax,ax
		mov al,ch
		div div_12
		;call print_reg_AX
		mov y,0
		
		cmp ah,0
		jne null
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,5
			int     10h
			mov ah,02h
			mov dl,'|'
			int 21h
			jmp finish
		null:
		cmp ah,1
		jne one
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,6
			int     10h
			mov ah,02h
			mov dl,'/'
			int 21h
			jmp finish
		one:
		cmp ah,2
		jne two
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,6
			int     10h
			mov ah,02h
			mov dl,218
			int 21h
			jmp finish
		two:
		cmp ah,3
		jne three
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,3
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,'-'
			int 21h
			jmp finish
		three:
		cmp ah,4
		jne four
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,192
			int 21h
			jmp finish
		four:
		cmp ah,5
		jne five
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,'\'
			int 21h
			jmp finish
		five:
		cmp ah,6
		jne six
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,5
			int     10h
			mov ah,02h
			mov dl,'|'
			int 21h
			jmp finish
		six:
		cmp ah,7
		jne seven
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'/'
			int 21h
			jmp finish
		seven:
		cmp ah,8
		jne eight
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,217
			int 21h
			jmp finish
		eight:
		cmp ah,9
		jne nine
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,3
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'-'
			int 21h
			jmp finish
		nine:
		cmp ah,10
		jne ten
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,191
			int 21h
			jmp finish
		ten:
		cmp ah,11
		jne eleven
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'\'
			int 21h
			jmp finish
		eleven:
		finish:
		pop dx
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		int     10h
		add x,12
		mov y,0
		
		
		
		
		mov ah,0Fh
		int 10h
		mov ah,03h
		int 10h
		push dx
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str1
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str2
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str3
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str4
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str5
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str6
		int 21h
		inc y
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		mov     DH,CS:y   ; Строка
		mov     DL,CS:x   ; Столбец
		int     10h
		mov ah,09h
		mov dx,offset str7
		int 21h
		inc y
		;div div_12
		
		
		
		mov ah,2ch
		int 21h
		xor ax,ax
		
		mov al,cl
		;call print_reg_AX
		div div_5
		;call print_reg_AX
		mov y,0
		
		cmp al,0
		jne null2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,5
			int     10h
			mov ah,02h
			mov dl,'|'
			int 21h
			jmp finish2
		null2:
		cmp al,1
		jne one2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,6
			int     10h
			mov ah,02h
			mov dl,'/'
			int 21h
			jmp finish2
		one2:
		cmp al,2
		jne two2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,6
			int     10h
			mov ah,02h
			mov dl,218
			int 21h
			jmp finish2
		two2:
		cmp al,3
		jne three2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,3
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,'-'
			int 21h
			jmp finish2
		three2:
		cmp al,4
		jne four2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,192
			int 21h
			jmp finish2
		four2:
		cmp al,5
		jne five2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,7
			int     10h
			mov ah,02h
			mov dl,'\'
			int 21h
			jmp finish2
		five2:
		cmp al,6
		jne six2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,5
			int     10h
			mov ah,02h
			mov dl,'|'
			int 21h
			jmp finish2
		six2:
		cmp al,7
		jne seven2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'/'
			int 21h
			jmp finish2
		seven2:
		cmp al,8
		jne eight2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,4
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,217
			int 21h
			jmp finish2
		eight2:
		cmp al,9
		jne nine2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,3
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'-'
			int 21h
			jmp finish2
		nine2:
		cmp al,10
		jne ten2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,191
			int 21h
			jmp finish2
		ten2:
		cmp al,11
		jne eleven2
			mov     AH,02h          ; Функция позиционирования
			mov     BH,CS:page_num  ; Видеостраница
			mov     DH,CS:y   ; Строка
			add dh,2
			mov     DL,CS:x   ; Столбец
			add dl,4
			int     10h
			mov ah,02h
			mov dl,'\'
			int 21h
			jmp finish2
		eleven2:
		finish2:
		pop dx
		mov     AH,02h          ; Функция позиционирования
		mov     BH,CS:page_num  ; Видеостраница
		int     10h
		mov clocks_here,0
		mov y,0
		mov x,48
		pop ax
	installed:
	;mov ah,09h
	;mov dx,offset messager
	;int 21h
	
	popa
	popf
	jmp     dword ptr CS:[old_1ch]
	iret
 
new_1ch endp
;============================================================================
new_09h proc far
	
;
	;добавляет флаги в стек
    pushf
	push    AX
	;ввод с клавиатуры, регистр и номер порта
    in      AL,60h      ; Введем scan-code - клавиатура 
    cmp     AL,58h      ; Это скен-код <F12>, практически порядковый номер клавиши
	je      hotkey      ; Yes
	
    pop     AX          ; No. Восстановим AX
	popf
    jmp     dword ptr CS:[old_09h]  ; В системный обработчик без возврата
hotkey:
	sti                 ; Не будем мешать таймеру
    in      AL,61h      ; Введем содержимое порта B
    or      AL,80h      ; Установим старший бит
    out     61h,AL      ; и вернем в порт B.
    and     AL,7Fh      ; Снова разрешим работу клавиатуры,
    out     61h,AL      ; сбросив старший бит порта B.
	cli
	mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
	out     20h,AL       ; приказ END OF INTERRUPT (EOF)
	pushf
	pusha
		push cs
		pop ds
		push cs
		pop es
		
		cmp flag,0
		jne metka
			
			inc flag
			
			cld                 			;Сброс флага df - направление вперед
			mov  	cx,		12*80          	;Счетчик на размер экрана (кол-во слов)
			lea  	di,		buffer     		;Адрес области куда схранить экран   	
			xor		si,		si				;Адрес области "откуда" от начала экрана (смещение относительно B800h)
			mov 	ax,		0B800h			;начало видеобуфера
			mov 	ds,		ax				;DS-> на видеобуфер; DS на строку 0 видеобуфера
			rep 	movsw							;Пересылаем весь экран в буфер DS:[si] --> es:[di]
			
			;mov cx,7
			;mov ax,0B800h;начало видеобуфера
			;xor		si,		si				;Адрес области "откуда" от начала экрана (смещение относительно B800h)	
			;cycle:
			;	push cx
			;	cld                 			;Сброс флага df - направление вперед
			;	mov  	cx,		23          	;Счетчик на размер экрана (кол-во слов)
			;	lea  	di,		buffer     		;Адрес области куда схранить экран   	
			;		
			;	mov 	ds,		ax				;DS-> на видеобуфер; DS на строку 0 видеобуфера
			;	rep 	movsw							;Пересылаем весь экран в буфер DS:[si] --> es:[di]
			;	pop cx
			;	add ax,80
			;loop cycle
			push cs
			pop ds
			popa
			popf
			sti
			mov     AL, 20h      ; Пошлем
			;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
			out     20h,AL       ; приказ END OF INTERRUPT (EOF)
			sti
			pop     AX
			popf
			iret
  
		metka:
		cmp flag,1
		jne to_end
			dec flag
			push cs
			pop ds
			xor bx,bx
			xor dx,dx
			xor ax,ax
			xor cx,cx
	;------------------  восстанавливаем экран  ---------------------------------------------   				
			mov cx,7
			mov ax,0B806h;начало видеобуфера
			xor di,di
			mov bx,48*2
			cycle2:
				push cx
				mov  	cx,		24				;
				lea  	si,		buffer[bx]     		;Адрес области откуда ds:[si] --> es:[di]
				;xor 	di,		di				;
				mov 	es,		ax				;es-> на видеобуфер; es на строку 0 видеобуфера
				rep 	movsw							;Переслать данные
				add ax,07
				pop cx
				add bx,80*2
			loop cycle2
			
;----------------------------------------------------------------------------------------
	to_end:
	push cs
	pop ds
	popa
	popf
	sti
	mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
	out     20h,AL       ; приказ END OF INTERRUPT (EOF)
	sti
    pop     AX
	popf
    iret
new_09h     endp
;============================================================================
;============================================================================
int_2Fh proc far
    cmp     AH,0C7h         ; Наш номер?
    jne     Pass_2Fh        ; Нет, на выход
    cmp     AL,00h          ; Подфункция проверки на повторную установку?
    je      inst            ; Программа уже установлена
    cmp     AL,01h          ; Подфункция выгрузки?
    je      unins           ; Да, на выгрузку
    jmp     short Pass_2Fh  ; Неизвестная подфункция - на выход
inst:
    mov     AL,0FFh         ; Сообщим о невозможности повторной установки
    iret
Pass_2Fh:
    jmp dword PTR CS:[int_2Fh_vector]
;
; -------------- Проверка - возможна ли выгрузка программы из памяти ? ------
unins:
    push    BX
    push    CX
    push    DX
    push    ES
;
    mov     CX,CS   ; Пригодится для сравнения, т.к. с CS сравнивать нельзя
    mov     AX,3509h    ; Проверить вектор 09h
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_09h
    jne     Not_remove
	mov     AX,351Ch    ; Проверить вектор 1Ch
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_1ch
    jne     Not_remove
    mov     AX,352Fh    ; Проверить вектор 2Fh
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:int_2Fh
    jne     Not_remove
; ---------------------- Выгрузка программы из памяти ---------------------
;
    push    DS
;
    lds     DX, CS:old_09h   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr old_09h
;    mov     DS, word ptr old_09h+2
    mov     AX,2509h        ; Заполнение вектора старым содержимым
    int     21h
	
	lds     DX, CS:old_1ch   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr old_09h
;    mov     DS, word ptr old_09h+2
    mov     AX,251Ch        ; Заполнение вектора старым содержимым
    int     21h
;
    lds     DX, CS:int_2Fh_vector   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr int_2Fh_vector
;    mov     DS, word ptr int_2Fh_vector+2
    mov     AX,252Fh
    int     21h
;
    pop     DS
;
    mov     ES,CS:2Ch       ; ES -> окружение
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AX, CS
    mov     ES, AX          ; ES -> PSP выгрузим саму программу
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AL,0Fh          ; Признак успешной выгрузки
    jmp     short pop_ret
Not_remove:
    mov     AL,0F0h          ; Признак - выгружать нельзя
pop_ret:
    pop     ES
    pop     DX
    pop     CX
    pop     BX
;
    iret
int_2Fh endp
;============================================================================
begin:
;инициализирующая часть
        mov CL,ES:80h       ; Длина хвоста в PSP
		;начиная с 81 находится хвост, в котором параметры
        cmp CL,0            ; Длина хвоста=0?
        je  check_install   ; Да, программа запущена без параметров,
                            ; попробуем установить
        xor CH,CH       ; CX=CL= длина хвоста
        cld             ; DF=0 - флаг направления вперед
        mov DI, 81h     ; ES:DI-> начало хвоста в PSP
        mov SI,offset key   ; DS:SI-> поле key
        mov AL,' '          ; Уберем пробелы из начала хвоста
repe    scasb   ; Сканируем хвост пока пробелы
                ; AL - (ES:DI) -> флаги процессора
                ; повторять пока элементы равны
        dec DI          ; DI-> на первый символ после пробелов
        mov CX, 4       ; ожидаемая длина команды
repe    cmpsb   ; Сравниваем введенный хвост с ожидаемым
                ; (DS:DI)-(ES:DI) -> флаги процессора
        jne check_install ; Неизвестная команда - попробуем установить
        inc flag_off
; Проверим, не установлена ли уже эта программа
check_install:
        mov AX,0C700h   ; AH=0C7h номер процесса C7h
		;; выбрали номер C7, он закреплен за нашей программой
                        ; AL=00h -дать статус установки процесса
						;; для проверки, есть ли в памяти
        int 2Fh         ; мультиплексное прерывание
		;;проходит через все обработчики C7 -пользовательский номер
        cmp AL,0FFh
		; проверяет, установлена ли уже
        je  already_ins ; возвращает AL=0FFh если установлена
;----------------------------------------------------------------------------
    cmp flag_off,1
    je  xm_stranno
;----------------------------------------------------------------------------
    ; штатная установка программы
	
	;получение вектора
	mov AX,352Fh                      ;   получить с помощью 35 функции в АН и 2Ф в АЛ
                                      ;   вектор
    int 21h                           ;   прерывания  2Fh
	; заменить на old_2Fh_vector!!!!!!!!!!!!!!!!! Для красоты, важно
    mov word ptr int_2Fh_vector,BX    ;   ES:BX - вектор
    mov word ptr int_2Fh_vector+2,ES  ;
;
	
	;установка вектора
	;заменить на new_2Fh
    mov DX,offset int_2Fh           ;   получить смещение точки входа в новый
                                    ;   обработчик на DX
    mov AX,252Fh                    ;   функция установки прерывания
                                    ;   изменить вектор 2Fh
    int 21h  ; AL - номер прерыв. DS:DX - указатель программы обработки прер.
;============================================================================
    mov AX,3509h                        ;   получить
                                        ;   вектор
    int 21h                             ;   прерывания  09h
    mov word ptr old_09h,BX    ;   ES:BX - вектор
    mov word ptr old_09h+2,ES  ;
    mov DX,offset new_09h           ;   получить смещение точки входа в новый
;                                   ;   обработчик на DX
    mov AX,2509h                        ;   функция установки прерывания
                                        ;   изменить вектор 09h
    int 21h ;   AL - номер прерыв. DS:DX - указатель программы обработки прер.
;
	mov AX,351Ch                        ;   получить
										;   вектор
    int 21h                             ;   прерывания  1Ch
    mov word ptr old_1ch,BX    ;   ES:BX - вектор
    mov word ptr old_1ch+2,ES  ;
    mov DX,offset new_1ch           ;   получить смещение точки входа в новый
;                                   ;   обработчик на DX
    mov AX,251Ch                        ;   функция установки прерывания
                                        ;   изменить вектор 1Ch
    
	int 21h ;   AL - номер прерыв. DS:DX - указатель программы обработки прер.
	
    mov DX,offset msg1  ; Сообщение об установке
    call    print
;----------------------------------------------------------------------------
    mov DX,offset   begin           ;   оставить программу ...
    int 27h                         ;   ... резидентной и выйти
;============================================================================
already_ins:
        cmp flag_off,1      ; Запрос на выгрузку установлен?
        je  uninstall       ; Да, на выгрузку
        lea DX,msg          ; Вывод на экран сообщения: already installed!
        call    print
        int 20h
; ------------------ Выгрузка -----------------------------------------------
 uninstall:
        mov AX,0C701h  ; AH=0C7h номер процесса C7h, подфункция 01h-выгрузка
        int 2Fh             ; мультиплексное прерывание
        cmp AL,0F0h
        je  not_sucsess
        cmp AL,0Fh
        jne not_sucsess
        mov DX,offset msg2  ; Сообщение о выгрузке
        call    print
        int 20h
not_sucsess:
        mov DX,offset msg3  ; Сообщение, что выгрузка невозможна
        call    print
        int 20h
xm_stranno:
        mov DX,offset msg4  ; Сообщение, программы нет, а пользователь
        call    print       ; дает команду выгрузки
        int 20h
;----------------------------------------------------------------------------
key         DB  '/off'
flag_off    DB  0
msg         DB  'already '
msg1        DB  'installed',13,10,'$'
msg4        DB  'just '
msg3        DB  'not '
msg2        DB  'uninstalled',13,10,'$'
buffer		DW	23*7 dup(?)
;============================================================================

;;============================================================================
code_seg ends
         end start
