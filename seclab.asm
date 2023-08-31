;+--------------------------------------------------------------------------
;вводишь пароль, и до правильного ввода заново запрещается перезагрузка
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
flag		DB	0
key         DB  '/off'
flag_off    DB  0
msg         DB  'already '
msg1        DB  'installed',13,10,'$'
msg4        DB  'just '
msg3        DB  'not '
msg2        DB  'uninstalled',13,10,'$'
msg5		DB 'Please enter a password:',13,10,'$'
msg6		DB 'Please create a password:',13,10,'$'
msg7		DB 'reboot',13,10,'$'
real_password 			DB 30,0,30 dup (0)
written_password		DB 30,0,30 dup (0)
;----------------------------------------------------------------------------
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
 PRINT       PROC FAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP

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


;============================================================================
new_09h proc far
;	
	push DX
    ;mov DX,offset msg1  ; Сообщение об установке
    ;call    print
	pop DX
	;добавляет флаги в стек
    pushf
	push    AX
	push cs
	pop ds
	;ввод с клавиатуры, регистр и номер порта
    in      AL,60h      ; Введем scan-code - клавиатура 
    cmp     AL,53h      ; Это скен-код <delete>, практически порядковый номер клавиши
	jne not_p
    MOV AX,0    
    MOV ES,AX          ; Чтение флагов состояния  
    MOV AL,ES:[417h]   ; клавиатуры в регистр AL и 
    AND AL,00001100b   ; определение нажаты ли клавиши 
    CMP AL,00001100b   ; Ctrl-Alt, если нет, то 
	je      hotkey      ; Yes
	not_p:
    pop     AX          ; No. Восстановим AX
	popf
    jmp     dword ptr CS:[old_09h]  ; В системный обработчик без возврата
hotkey:
	
	; сброс клавиатуры, мастхэв. прочитать про 55 порт(55 микросхему)
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
			push cs
			pop es
;----------------------------------------------------------------------------
			cmp flag,1
			jne reboot
				;int 19h
				mov dx, offset msg7
				call print
			reboot:
			
			cmp flag,0
			jne recieve_password
				mov dx,offset msg5
				call print
				mov AH, 0Ah ;вводим пароль
				mov DX, offset written_password
				int 21h
				xor Bx, Bx
				mov BL, written_password[1]
				mov written_password[BX+2], 0
				PRINT_CRLF
				;сравниваем, если равны, меняем флаг
				;перезагружаем прерыванием int 19h
				cmp real_password[1],bl
				jne wrong_password
					mov cx,bx
					mov di,2
					metka:
						mov bl,written_password[di]
						cmp real_password[di],bl
						jne wrong_password
						inc di
					loop metka
					inc flag
			wrong_password:
			recieve_password:
			
			pop		DS	; восстановление регистров из стека в порядке LIFO
            pop     DX
            pop     CX
            pop     BX
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
    lds     DX, CS:old_09h   ; Эта команда эквивалентна следующим двум
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
				mov dx,offset msg6
				call print
				mov AH, 0Ah ;ввод реального пароля
				mov DX, offset real_password
				int 21h
				xor Bx, Bx
				mov BL, real_password[1]
				mov real_password[BX+2], 0
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

;============================================================================

;;============================================================================
code_seg ends
         end start
