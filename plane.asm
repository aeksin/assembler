;+--------------------------------------------------------------------------
;крутейший проект, надо управлять машиной, которая уворачивается от бомб, которые скидывают вылетающие в рандомный момент в рандомном месте с рандомной скоростью самолёты
;+--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
    jmp begin
;----------------------------------------------------------------------------
old_2Fh_vector  DD  ?
old_09h         DD  ?
flag 			DB	0
print_hex proc near
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
 print_reg_AX proc near
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
PRINT       PROC FAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP
;----------------------------------------------------------------------------
rand8	proc FAR
			cmp flag,0 ;чтобы генерировать seed только один раз
			jne generate_seed ;генерация случайного seed при помощи получения времени
				push dx 
				push ax
				xor dx,dx
				mov ah,2ch;получение времени для генерации случайного seed
				int 21h
				
				add dl,dh
				add dl,cl
				add dl,ch;складываю часы, минуты, секунды и сотые доли секунд для более случайного числа
				mov seed,dx
				pop ax
				pop dx
				inc flag
			generate_seed:
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
;============================================================================
new_09h proc far
	jmp param
	plane		DB	'\\======'
	bomb_numb	equ 800
	plane_numb	equ	200
	bombs_x		DB	bomb_numb dup	(0)
	bombs_y		DB	bomb_numb dup	(0)
	planes_x		DB	plane_numb dup	(0)
	planes_y		DB	plane_numb dup	(0)
	planes_speed	DB	plane_numb dup	(0)
	cur_plane_numb	DW	0
	cur_bomb_numb	DW	0
	left        equ     4bh ;скен-код клавиши влево
	right       equ     4dh ;скен-код клавиши вправо
	cur_dir db      't'
	wait_time dw    0
	div_100	DB 100
	div_80 DB 80 ;константы для деления на 80, 12 и 2 для того чтобы не выйти за границы
	div_12 DB 12 ;и не пойти вниз при генерации позиции мячика и направления
	div_2  DB 2
	div_4  DB 4
	high_Y      DB  00	; координаты окна
	left_X      DB  00	; координаты окна
	near_low_y	DB	23
	low_Y       DB  24	; координаты окна
	right_X     DB  79	; координаты окна
	left_pos DB 38 ; координаты ракетки
	middle_minus DB 39
	middle_pos DB 40
	middle_plus DB 41
	right_pos DB 42
	;
	page_num    DB  0
	coord_Y     DB  11	; Y координата сообщения в окне
	coord_X     DB  35	; X координата сообщения в окне
	bufSIZE		DW	9 ;длина сооющения о конце игры
	BUFFER			DB	'GAME OVER'	; сообщение о конце игры
	param:
;
	;добавляет флаги в стек
    pushf
	push    AX
	;ввод с клавиатуры, регистр и номер порта
    in      AL,60h      ; ввод скен-кода
    cmp     AL,57h      ;  скен-код <F11>
    je      hotkey       
    pop     AX           
	popf
    jmp     dword ptr CS:[old_09h]  ; В системный обработчик без возврата
hotkey:
	
    sti                 ; Не будем мешать таймеру
    in      AL,61h      ; Введем содержимое порта B
    or      AL,80h      ; Установим старший бит
    out     61h,AL      ; и вернем в порт B.
    and     AL,7Fh      ; Снова разрешим работу клавиатуры,
    out     61h,AL      ; сбросив старший бит порта B.
;
;-------------------- Вывод окна средствами BIOS ---------------------------
;
            push    BX	; сохранение используемых регистров в стеке
            push    CX	; сохранение используемых регистров в стеке
            push    DX	; сохранение используемых регистров в стеке
			push	DS	; сохранение используемых регистров в стеке
			;
			push	CS	;	настройка DS
			pop		DS	;				на наш сегмент, т.е DS=CS
;----------------------------------------------------------------------------
        cli
		mov     AL, 20h      
		out     20h,AL       
		mov     AX, 0600h		; Задание окна
        mov     BH, 012h        
		;80 по х и 25 по y
        mov     CH, high_Y     ; Координаты окна, в данном случае весь экран
        mov     CL, left_X     ;    
        mov     DH, low_Y      ;      
        mov     DL, right_X    ;         
        int 10h
		
;----------------------------------------------------------------------------
        ; чтобы ракетка при перезапуске игры генерировалась посередине
		mov left_pos,38
		mov middle_minus,39
		mov middle_pos,40
		mov middle_plus,41
		mov right_pos,42
		; прячем курсор
		mov     ah, 1
		mov     ch, 2bh
		mov     cl, 0bh
		int     10h
		;инициализируем бомбы и самолёты
		mov cx,bomb_numb
		mov si,0
		init_bombs:
			mov bombs_x[si],0
			mov bombs_y[si],0
			inc si
		loop init_bombs
		mov cx,plane_numb
		mov si,0
		init_planes:
			mov planes_x[si],0
			mov planes_y[si],0
			inc si
		loop init_planes
		mov cur_plane_numb,0
		mov cur_bomb_numb,0
		;ставим ракетку
		mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:low_y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
				mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:near_low_y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h         
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_minus   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_pos   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_plus  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:right_pos  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:low_y   
				mov     DL,CS:right_pos  
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
		;ставим мячик         
		mov ah, 00h ; ожидание нажатия любой клавиши для начала игры
		int 16h
		game_loop: ;для того, чтобы не проиграть, когда мячик сразу появился внизу, двигаем его в начале цикла
			mov cur_dir,100
			;удаляем самолёты с предыдущего шага
			mov cx,plane_numb
			mov di,0
			mov si,cur_plane_numb
			deleting_planes:
						
				cmp planes_y[di],0
				je delete_it
					push cx
					push si
					mov cx,8
					mov si,0
					deleting:
						mov     AH,02h          ; Функция позиционирования
						mov     BH,CS:page_num  ; Видеостраница
						mov     DH,CS:planes_y[di]   ; Строка
						mov     DL,CS:planes_x[di]   ; Столбец
						add		dx,si
						int     10h
						mov     AH,0Eh
						mov al,' '
						int 10h
						inc si
					loop deleting
					pop si
					pop cx
					dec si
				delete_it:
				inc di
				cmp si,0
				je endloop_deleting
			loop deleting_planes
			endloop_deleting:
			;двигаем существующие самолёты
			mov cx,plane_numb
			mov di,0
			mov si,cur_plane_numb
			iterating_planes:
				cmp planes_y[di],0
				je move_it
					mov al,planes_speed[di]
					add planes_x[di],al
					cmp planes_x[di],79
					jb all_is_good
						mov planes_x[di],0
						mov planes_y[di],0
						mov planes_speed[di],0
						dec cur_plane_numb
					all_is_good:
					dec si
				move_it:
				inc di
				cmp si,0
				je endloop
			loop iterating_planes
			endloop:
			;генерация самолёта с шансом 20%
			xor ax,ax
			call rand8
			div div_100
			mov di,0
			cmp ah,20
			ja generate_new_plane
				metka_plane:
				
				cmp planes_y[di],0
				jne generated_plane
					xor ax,ax
					mov planes_x[di],0
					call rand8
					div div_12
					mov planes_y[di],ah
					call rand8
					div div_4
					add ah,1 ;чтобы не было скорости равной нулю
					mov planes_speed[di],ah
					inc cur_plane_numb
					jmp generate_new_plane
				generated_plane:
				inc di
				jmp metka_plane
			generate_new_plane:
			;отрисовываем самолёты
			mov cx,plane_numb
			mov di,0
			mov si,cur_plane_numb
			drawing_planes:
				cmp planes_y[di],0
				je draw_it
					push cx
					push si
					mov cx,2
					xor ax,ax
					mov si,0
					drawing_edge:
						mov     AH,02h          ; Функция позиционирования
						mov     BH,CS:page_num  ; Видеостраница
						mov     DH,CS:planes_y[di]   ; Строка
						mov     DL,CS:planes_x[di]  ; Столбец
						add dx,si
						int     10h
						mov     AH,0Eh
						mov al,'\'
						int 10h
						inc si
					loop drawing_edge
					mov cx,6
					mov bh,planes_x[di]+2
					drawing_equ:
						mov     AH,02h          ; Функция позиционирования
						mov     BH,CS:page_num  ; Видеостраница
						mov     DH,CS:planes_y[di]   ; Строка
						mov     DL,cs:planes_x[di]   ; Столбец
						add dx,si
						int     10h
						mov     AH,0Eh
						mov al,'='
						int 10h
						inc si
					loop drawing_equ
					pop si
					pop cx
					dec si
				draw_it:
				inc di
				cmp si,0
				je endloop_drawing
			loop drawing_planes
			endloop_drawing:
			
			;а теперь то же самое для бомб
			;удаляем бомбы с предыдущего шага
			mov cx,bomb_numb
			mov di,0
			mov si,cur_bomb_numb
			deleting_bombs:
						
				cmp bombs_y[di],0
				je delete_it_bombs
					
					
					mov     AH,02h          ; Функция позиционирования
					mov     BH,CS:page_num  ; Видеостраница
					mov     DH,CS:bombs_y[di]   ; Строка
					mov     DL,CS:bombs_x[di]   ; Столбец
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					dec si
				delete_it_bombs:
				inc di
				cmp si,0
				je endloop_deleting_bombs
			loop deleting_bombs
			endloop_deleting_bombs:
			;двигаем существующие бомбы
			mov cx,bomb_numb
			mov di,0
			mov si,cur_bomb_numb
			iterating_bombs:
				cmp bombs_y[di],0
				je move_it_bomb
					add bombs_y[di],1
					cmp bombs_y[di],25
					jb all_is_good_bombs
						mov bombs_x[di],0
						mov bombs_y[di],0
						dec cur_bomb_numb
					all_is_good_bombs:
					dec si
				move_it_bomb:
				inc di
				cmp si,0
				je endloop_bomb
			loop iterating_bombs
			endloop_bomb:
			;генерация бомбы с шансом 10%
			mov cx,plane_numb
			mov di,0
			mov si,cur_plane_numb
			generate_bombs:
				cmp planes_y[di],0
				je next_plane
					cmp planes_x[di],0
					je next_plane
					xor ax,ax
					call rand8
					div div_100
					cmp ah,10
					ja generating_bomb
						cmp planes_x[di],79
						je generating_bomb
						push ax
						push di
						push si
						mov si,di
						mov di,0
						metka_bomb:
						cmp bombs_y[di],0
						jne generated_bomb
							xor ax,ax
							mov al,planes_x[si]
							mov bombs_x[di],al
							mov al,planes_y[si]
							mov bombs_y[di],al
							add bombs_y[di],1
							inc cur_bomb_numb
							jmp ennd
						generated_bomb:
						inc di
						jmp metka_bomb
						ennd:
						pop si
						pop di
						pop ax
					generating_bomb:
					dec si
				next_plane:
				inc di
				cmp si,0
				je endloop_generating
			loop generate_bombs
			endloop_generating:
			;отрисовываем бомбы
			mov cx,bomb_numb
			mov di,0
			mov si,cur_bomb_numb
			drawing_bombs:
				cmp bombs_y[di],0
				je draw_it_bomb
					mov     AH,02h          ; Функция позиционирования
					mov     BH,CS:page_num  ; Видеостраница
					mov     DH,CS:bombs_y[di]   ; Строка
					mov     DL,CS:bombs_x[di]   ; Столбец
					int     10h
					mov     AH,0Eh
					mov al,'0'
					int 10h
					dec si
				draw_it_bomb:
				inc di
				cmp si,0
				je endloop_drawing_bomb
			loop drawing_bombs
			endloop_drawing_bomb:
			
			mov cx,bomb_numb
			mov di,0
			check_over:
				cmp bombs_y[di],23
				jb checkk
					mov al,left_pos
					cmp bombs_x[di],al
					jb smaller
						mov al,right_pos
						cmp bombs_x[di],al
						ja greater
							mov     ah, 1
							mov     ch, 0bh
							mov     cl, 0bh
							int     10h
							
							mov     AH,02h          ; Функция позиционирования
							mov     BH,CS:page_num  ; Видеостраница
							mov     DH,CS:coord_Y   ; Строка
							mov     DL,CS:coord_X   ; Столбец
							int 10h
							mov     CX,	CS:bufSIZE
							mov     BX, offset CS:BUFFER ;выводим game over по середине экрана
							mov     AH,0Eh              ; выводим по одному символу
							next_sym2:
								mov     AL,CS:[BX]          ; Символ в AL
								inc     BX                  ; Сдвиг по строке
								int     10h                 ;
							loop    next_sym2            ; Цикл по строке
							
							pop		DS	; восстановление регистров из стека в порядке LIFO
							pop     DX
							pop     CX
							pop     BX
							cli
							mov     AL, 20h      
							out     20h,AL       
							pop     AX
							popf
							iret
						greater:
					smaller:
				checkk:
				inc di
			loop check_over
;----------------------------------------------	
			check_for_key:
			; проверка нажатий клавиш
			mov     ah, 01h
			int     16h
			jz      no_key ;если ничего не нажато

			mov     ah, 00h
			int     16h

			cmp     al, 1bh    ; завершение игры по нажатию esc
			jne      stop_game  ;
			
				mov     ah, 1
				mov     ch, 0bh
				mov     cl, 0bh
				int     10h
				pop		DS	; восстановление регистров из стека в порядке LIFO
				pop     DX
				pop     CX
				pop     BX
				cli
				mov     AL, 20h      
				
				out     20h,AL      
			;
				pop     AX
				popf
				iret
			stop_game:
			
			;заносим в cur_dir нажатую клавишу
			
			mov     cur_dir, ah
			
			no_key:
			;таймер
			mov     ah, 00h
			int     1ah
			cmp     dx, wait_time
			jb      check_for_key
			add     dx, 4
			mov     wait_time, dx
;-----------------------------------------------
			cmp cur_dir, right ;идем вправо, если это скен-код кнопки стрелки направо
			je ping_righttt
			jmp ping_right
			ping_righttt:
				cmp right_pos,78 ; если дошли до конца вправо, то не двигаемся
				je metka ;иначе заменяем на пробел самую левую часть ракетки
					mov     AH,02h          ; Функция позиционирования
					mov     BH,CS:page_num  ; Видеостраница
					mov     DH,CS:near_low_y  ; Строка
					mov     DL,CS:left_pos   ; Столбец
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					mov     AH,02h          ; Функция позиционирования
					mov     BH,CS:page_num  ; Видеостраница
					mov     DH,CS:low_y  ; Строка
					mov     DL,CS:left_pos   ; Столбец
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					mov     AH,02h          ; Функция позиционирования
					mov     BH,CS:page_num  ; Видеостраница
					mov     DH,CS:low_y  ; Строка
					mov     DL,CS:right_pos   ; Столбец
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					inc left_pos
					inc middle_minus
					inc middle_pos
					inc middle_plus
					inc right_pos
				metka:
				mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:low_y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
				mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:near_low_y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h         
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_minus   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				ping_right: ; для расширения действия jne
				cmp cur_dir, right
				jne ping_right2
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_pos   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:middle_plus  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:right_pos  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:low_y   
				mov     DL,CS:right_pos  
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
			ping_right2:
			cmp cur_dir, left ;идем влево, если это скен-код кнопки стрелки налево
			je ping_lefttt
			jmp ping_left
			ping_lefttt:
				cmp left_pos,0 ;дошли влево до конца, ничего не делаем
				je metka2
					mov     AH,02h          ; иначе убираем самую правую точку ракетки
					mov     BH,CS:page_num  
					mov     DH,CS:near_low_y   
					mov     DL,CS:right_pos  
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					mov     AH,02h          ; иначе убираем самую правую точку ракетки
					mov     BH,CS:page_num  
					mov     DH,CS:low_Y   
					mov     DL,CS:right_pos  
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					mov     AH,02h          ; иначе убираем самую правую точку ракетки
					mov     BH,CS:page_num  
					mov     DH,CS:low_Y   
					mov     DL,CS:left_pos  
					int     10h
					mov     AH,0Eh
					mov al,' '
					int 10h
					dec left_pos ;и сдвигаем всю ракетку влево
					dec middle_minus
					dec middle_pos
					dec middle_plus
					dec right_pos
				metka2: ;отрисовка ракетки
				mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:low_Y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
				mov     AH,02h          ; Функция позиционирования
				mov     BH,CS:page_num  ; Видеостраница
				mov     DH,CS:near_low_y   ; Строка
				mov     DL,CS:left_pos   ; Столбец
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y  
				mov     DL,CS:middle_minus  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				ping_left: ;просто метка, чтобы расширить действие jne
				cmp cur_dir, left
				jne ping_left2
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y  
				mov     DL,CS:middle_pos  
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y  
				mov     DL,CS:middle_plus   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:near_low_y   
				mov     DL,CS:right_pos   
				int     10h
				mov     AH,0Eh
				mov al,'='
				int 10h
				mov     AH,02h          
				mov     BH,CS:page_num  
				mov     DH,CS:low_y   
				mov     DL,CS:right_pos   
				int     10h
				mov     AH,0Eh
				mov al,'0'
				int 10h
			ping_left2:
			; цикл игры:
			jmp     game_loop
;---------------------------------------------------------------------------
    cli
    mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
    out     20h,AL       ; приказ END OF INTERRUPT (EOF)
;
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
    jmp dword PTR CS:[old_2Fh_vector]
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
;
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
    lds     DX, CS:old_09h  

    mov     AX,2509h        ; Заполнение вектора старым содержимым
    int     21h
;
    lds     DX, CS:old_2Fh_vector   ; 

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
	
    mov word ptr old_2Fh_vector,BX    ;   ES:BX - вектор
    mov word ptr old_2Fh_vector+2,ES  ;
;
	
	;установка вектора
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
;----------------------------------------------------------------------------

seed	dw ? ;ключ для генерации случайных чисел

key         DB  '/off'
flag_off    DB  0
msg         DB  'already '
msg1        DB  'installed',13,10,'$'
msg4        DB  'just '
msg3        DB  'not '
msg2        DB  'uninstalled',13,10,'$'
;============================================================================

;;============================================================================
code_seg ends
         end start