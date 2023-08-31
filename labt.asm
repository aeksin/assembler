.286
;выводим имена удалённых с момента запуска программы файлов на экран
;+--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
    jmp begin
;----------------------------------------------------------------------------
int_2Fh_vector  DD  ?
old_09h         DD  ?
old_21h			DD	?
PRINT       PROC FAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP
;----------------------------------------------------------------------------
flag        DB  0
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
;============================================================================
new_21h proc far                  ;новый обработчик прерывания 21h
	

	cmp AH, 41h             ;разные функции удаление файлов
	je add_to_deleted             
	cmp AX, 71h           
	je add_to_deleted 
	cmp AH, 13h
	je add_to_deleted

	jmp     dword ptr CS:[old_21h];если нет, то уходим в стандартный обработчик                    
	 
	add_to_deleted:               
		 pushf 
		 pusha
		 push cs
		 pop ds
		 push cs
		 pop es
	 
		 mov SI,DX                    ;копируем DX в SI, теперь в DS:SI содержится
									  ;адрес ASCIIZ-строки с именем файла
		 pushf
		 call     dword ptr CS:[old_21h]  ;возвращаемся в старый обработчик
		 cmp ah,0 ;если файла нет 
		 je not_open
		 nextsymbol:                  ;ищем конец имени удаляемого файла
			  mov AL,DS:SI
			  mov di,del_len
			  mov deleted_files[di],al
			  
			  inc del_len
			  inc si
			  cmp AL,0                ;это нулевой байт 
			  jne nextsymbol          ;если нет, то переходим к следующему символу
			 dec SI                       ;теперь в DS:SI содержит адрес последнего 
										  ;символа расширения файла
			 dec del_len ; так как занесли ноль и увеличили после этого
			 dec del_len
			 mov di,del_len
			 mov deleted_files[di],13
			 inc di
			 inc del_len
			 mov deleted_files[di],10
			 inc di
			 inc del_len
			 mov deleted_files[di],' '
			 
		 not_open:
		 
		 popa
		 popf
		 
	iret
 
new_21h endp
;============================================================================
new_09h proc far ;новый обработчик прерывания от клавиатуры
;
	jmp perem
	msg5		DB	'list of deleted files',13,10,'$'
	msg6		DB	'that is all',13,10,'$'
	msg7		DB	'Write name of file to delete:',13,10,'$'
	
	perem:
	;добавляет флаги в стек
    pushf
	push    AX
	;ввод с клавиатуры, регистр и номер порта
    in      AL,60h      ; Введем scan-code - клавиатура 
    cmp     AL,58h      ; Это скен-код <F12>, практически порядковый номер клавиши
    je      hotkey      
	cmp 	AL,57h		; Это скен-код <F11>, практически порядковый номер клавиши
	je 		another_hotkey
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
            push    BX	; сохранение используемых регистров в стеке
            push    CX	; сохранение используемых регистров в стеке
            push    DX	; сохранение используемых регистров в стеке
			push	DS	; сохранение используемых регистров в стеке
			;
			push	CS	;	настройка DS
			pop		DS	;				на наш сегмент, т.е DS=CS
			mov DX,offset msg5 ;сообщение о списке удалённых файлов
			call print
			cmp del_len,0
			je not_going
			mov cx,del_len
			mov si,0
			mov ah,02h ;посимвольно выводим список удалённых файлов
			metka:
				mov dl,deleted_files[si]
				inc si
				int	21h			
			loop metka
			not_going:
			mov DX,offset msg6 ;выводим, что всё вывели
			call print
			pop		DS	; восстановление регистров из стека в порядке LIFO
            pop     DX
            pop     CX
            pop     BX
    cli
    mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
    out     20h,AL       ; приказ END OF INTERRUPT (EOF)
    pop     AX
	popf
    iret
	jmp endd
another_hotkey:
	sti                 ; Не будем мешать таймеру
    in      AL,61h      ; Введем содержимое порта B
    or      AL,80h      ; Установим старший бит
    out     61h,AL      ; и вернем в порт B.
    and     AL,7Fh      ; Снова разрешим работу клавиатуры,
    out     61h,AL      ; сбросив старший бит порта B.
            push    BX	; сохранение используемых регистров в стеке
            push    CX	; сохранение используемых регистров в стеке
            push    DX	; сохранение используемых регистров в стеке
			push	DS	; сохранение используемых регистров в стеке
			;
			push	CS	;	настройка DS
			pop		DS	;				на наш сегмент, т.е DS=CS
			cli
			mov     AL, 20h      ; Пошлем
			;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
			out     20h,AL       ; приказ END OF INTERRUPT (EOF)
			mov DX,offset msg7 
			call print
			mov AH, 0Ah ;ввод строки
			mov DX, offset FileName ;в буфер filename
			int 21h
			PRINT_CRLF
			xor Bx, Bx
			mov BL, FileName[1]
			mov FileName[BX+2], '0'
			mov dx,offset FileName+2 
			mov ah,41h ;передаём название файла для его удаления
			int 21h
			pop		DS	; восстановление регистров из стека в порядке LIFO
            pop     DX
            pop     CX
            pop     BX
    cli
    mov     AL, 20h      ; Пошлем
	;сброс происходит для того, чтобы могли выполнятся прерывания с меньшим приоритетом
    out     20h,AL       ; приказ END OF INTERRUPT (EOF)
    pop     AX
	popf
    iret
	endd:
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
	mov     AX,3521h    ; Проверить вектор 09h
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_21h
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
	
	lds     DX, CS:old_21h   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr old_09h
;    mov     DS, word ptr old_09h+2
    mov     AX,2509h        ; Заполнение вектора старым содержимым
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
	mov AX,3521h                        ;   получить
										;   вектор
    int 21h                             ;   прерывания  21h
    mov word ptr old_21h,BX    ;   ES:BX - вектор
    mov word ptr old_21h+2,ES  ;
    mov DX,offset new_21h           ;   получить смещение точки входа в новый
;                                   ;   обработчик на DX
    mov AX,2521h                        ;   функция установки прерывания
                                        ;   изменить вектор 21h
    
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
FileName DB 30,0,30 dup (0)
	deleted_files DB 20480 dup (0) ; размер буфера 20 Кб
	del_len DW 0
;============================================================================

;;============================================================================
code_seg ends
         end start
