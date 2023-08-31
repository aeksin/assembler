.286
;запрет на удаление файлов при запуске программы
;+--------------------------------------------------------------------------
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
start:
    jmp begin
;----------------------------------------------------------------------------

old_2Fh_vector  DD  ?
old_09h         DD  ?
old_21h			DD	?
PRINT       PROC FAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP
;----------------------------------------------------------------------------
flag        DB  0

;============================================================================
new_21h proc far                  ;новый обработчик прерывания 21h
	jmp internal_message
	yet_another_message	DB "deleting is forbidden",13,10,'$'
	internal_message:
	cmp AX, 71h           
	je forbid_deleting
	cmp AH, 13h
	je forbid_deleting   ;удаление файлов разными функциями
	cmp AH, 41h             
	je forbid_deleting
	
	jmp     dword ptr CS:[old_21h];если нет, то уходим в стандартный обработчик без возврата                   
	
	forbid_deleting:               
	pusha
	push cs
	pop ds
	mov dx,offset yet_another_message
	call print
	popa
		 
	iret
 
new_21h endp

;============================================================================
new_2Fh proc far
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
    
	mov     AX,3521h    ; Проверить вектор 21h
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
    cmp     BX, offset CS:new_2Fh
    jne     Not_remove
; ---------------------- Выгрузка программы из памяти ---------------------
;
    push    DS
;
    
	
	lds     DX, CS:old_21h   
    mov     AX,2521h        ; Заполнение вектора старым содержимым
    int     21h
;
    lds     DX, CS:old_2Fh_vector   
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
new_2Fh endp
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
	
    mov DX,offset new_2Fh           ;   получить смещение точки входа в новый
                                    ;   обработчик на DX
    mov AX,252Fh                    ;   функция установки прерывания
                                    ;   изменить вектор 2Fh
    int 21h  ; AL - номер прерыв. DS:DX - указатель программы обработки прер.
;============================================================================
    
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
;============================================================================

;;============================================================================
code_seg ends
         end start
