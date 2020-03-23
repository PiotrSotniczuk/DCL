SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1
MAX_LINE  equ 50

; Wykonanie programu zaczyna się od etykiety _start.
global _start

section .rodata

; znak nowej linii
new_line db `\n`
hello    db "Hello", 10
ill_char db "bad_char", 10
ILL_C_L  equ $ - ill_char
to_less_arg db "To less arg", 10
TO_L_ARG_L  equ $ - to_less_arg
debug db "debug", 10
DEBUG_L equ $ - debug
;chars    db "12k3456789:m<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"
;CHARS_L  equ $ - chars

section .text

_start:
  lea     rbp, [rsp + 8]  ; adres args[0]
  mov     ebx, 3          ;licznik
arg_loop:
  add     rbp, 8           ; adres pierwszego argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jz      exit_less_arg    ; Napotkano zerowy wskaźnik, za malo argumentów.
  mov     ecx, MAX_LINE   ; Ogranicz przeszukiwanie do MAX_LINE znaków.
  mov     rdi, rsi        ; Ustaw adres, od którego rozpocząć szukanie.
char_loop:
  mov     r12b, [rdi]      ; zapisz znak
  test    r12, r12       
  jz      check_count     ; koniec slowa
  dec     ecx
  jz      exit_debug   ; za dlugi napis nie sprawdzam dalej
  cmp     r12, 49       ; '1' = 49 ASCII
  jb      exit_debug
  cmp     r12, 90       ; '90' = 'Z' 
  ja      exit_debug
  inc     rdi          ; przesuwam wskaznik
  jmp     char_loop
check_count:
  sub     rdi, rsi        ; liczba bajtów w arg
  cmp     rdi, 42         ; 42 znaki w permutacji
  jne     exit_ill_char   ; za duze/male argumenty
  dec     ebx             ; i--
  jnz     arg_loop
exit:
  mov     eax, SYS_EXIT
  xor     edi, edi        ; kod powrotu 0
  syscall
exit_ill_char:
  mov     rax, SYS_WRITE
  mov     edi, STDOUT
  mov     rsi, ill_char   ; Wypisz komunikat.
  mov     edx, ILL_C_L          
  syscall
  mov     eax, SYS_EXIT   
  mov     rdi, 1
  syscall
exit_less_arg:
  mov     rax, SYS_WRITE
  mov     edi, STDOUT
  mov     rsi, to_less_arg   ; Wypisz komunikat.
  mov     edx, TO_L_ARG_L          
  syscall
  mov     eax, SYS_EXIT  
  mov     edi, 1
  syscall
exit_debug:
  mov     rax, SYS_WRITE
  mov     edi, STDOUT
  mov     rsi, debug   ; Wypisz komunikat.
  mov     edx, DEBUG_L          
  syscall
  mov     eax, SYS_EXIT  
  mov     rdi, 1
  syscall