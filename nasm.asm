section .text
global _start
;программа на насме, выводит содержимое файла в консоль линукса, например может распечатать в консоль содержимое самого этого файла
_start:
	;вывод сообщения на экран
	mov eax, 4       ; SYS_WRITE
    mov ebx, 1
    mov ecx, print_open_file
    ;mov edx, eax
    mov edx, print_open_len
    int 0x80
	;вводим имя файла
	mov ebx, 0
	mov eax, 3 ;sys read filename
	mov ecx,buffer1 
	mov edx,1024
	int 0x80
	;цикл, чтобы поставить 0 вместо CR
	mov esi, buffer1
	metka:
		cmp  byte [esi],0xA
		jne metka2
			mov byte [esi], 0
			jmp end_metka
		metka2:
		inc si
	loop metka
	end_metka:
    ; открываем файл
    mov eax, 5       ; SYS_OPEN
    mov ebx, buffer1
    mov ecx, 0
    int 0x80
    mov ebx, eax     ; сохраняем дескриптор файла в EBX
	mov esi,handler ; и в переменную handler
	mov byte [esi],al
	inc si
	mov byte [esi],0xA ;добавляем перенос строки
	inc si
	mov byte [esi],0
    cmp ebx,2
	int 0x80
	
	add byte [handler],'0'
	mov eax, 4       ; SYS_WRITE
    mov ebx, 1
    mov ecx, handler
    ;mov edx, eax
    mov edx, 3
    int 0x80
	sub byte [handler],'0'

	mov bl,byte [handler]
	
    ; читаем файл
    mov eax, 3       ; SYS_READ
    mov ecx, buffer
    mov edx, 40960
    int 0x80
    ; закрываем файл
    mov eax, 6       ; SYS_CLOSE
    ;mov ebx, eax
    int 0x80
    ; выводим содержимое файла на экран
    mov eax, 4       ; SYS_WRITE
    mov ebx, 1
    mov ecx, buffer
    ;mov edx, eax
    mov edx, 40960
    int 0x80
	
    ; завершаем программу
    mov eax, 1       ; SYS_EXIT 
    xor ebx, ebx  
    int 0x80
section .data
filemode db 'r',0
format db "%d",0

print_open_file db "Please write a filename:",10
print_open_len equ $-print_open_file

section	.bss
buffer3	 resb 100
handler	 resb 3
buffer1	 resb 1024
buffer	 resb 40960
