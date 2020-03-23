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
;chars    db "12k3456789:m<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"
;CHARS_L  equ $ - chars

section .text

_start:
  mov     rax, SYS_WRITE
  mov     edi, STDOUT
  mov     rsi, hello   ; Wypisz hello i linii.
  mov     edx, 6          ; Wypisz 6 bajt.
  syscall
  lea     rbp, [rsp + 8]  ; adres args[0]
  mov     ebx, 3          ;licznik
arg_loop:
  add     rbp, 8           ; adres pierwszego argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jz      exit_less_arg    ; Napotkano zerowy wskaźnik, za malo argumentów.
  cld                     ; Zwiększaj indeks przy przeszukiwaniu napisu.
  xor     al, al          ; Szukaj zera.
  mov     ecx, MAX_LINE   ; Ogranicz przeszukiwanie do MAX_LINE znaków.
  mov     rdi, rsi        ; Ustaw adres, od którego rozpocząć szukanie.
  repne \
  scasb                   ; Szukaj bajtu o wartości zero rdi rosnie
  sub     rdi, rsi        ; liczba bajtów w arg
  cmp     rdi, 43         ; 42 znaki plus \0
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
  mov     edi, 1
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
