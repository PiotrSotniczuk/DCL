SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1
MAX_LINE  equ 50

; Wykonanie programu zaczyna się od etykiety _start.
global _start

section .rodata

bad_char db "bad_char", 10
BAD_C_L  equ $ - bad_char
to_less_arg db "To less arg", 10
TO_L_ARG_L  equ $ - to_less_arg
debug db "debug", 10
DEBUG_L equ $ - debug

section .bss

present resb 42

%macro set_zeros 0     
  mov     r9, 42
zero_loop:                ; filling with zeros
  mov     byte [present + r9 - 1], 0
  dec     r9
  jnz     zero_loop
%endmacro

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
  set_zeros
char_loop:
  mov     r12b, [rdi]      ; zapisz znak
  test    r12b, r12b       
  jz      check_count     ; koniec slowa
  dec     ecx
  jz      exit_bad_char   ; za dlugi napis nie sprawdzam dalej
  cmp     r12b, 49       ; '1' = 49 ASCII
  jb      exit_bad_char
  cmp     r12b, 90       ; '90' = 'Z' 
  ja      exit_bad_char
  sub     r12, 49
  mov     r8b, [present + r12]  ; patrze czy juz zajete miejsce
  test    r8b, r8b         
  jnz     exit_bad_char      ; jesli juz sie pojawil taki znak 
  mov     byte [present + r12], 1 ; zajmij
  inc     rdi          ; przesuwam wskaznik
  jmp     char_loop
check_count:
  sub     rdi, rsi        ; liczba bajtów w arg
  cmp     rdi, 42         ; 42 znaki w permutacji
  jne     exit_bad_char   ; za duze/male argumenty
  dec     ebx             ; i--
  jnz     arg_loop
exit:
  mov     eax, SYS_EXIT
  xor     edi, edi        ; kod powrotu 0
  syscall


exit_bad_char:
  mov     rax, SYS_WRITE
  mov     edi, STDOUT
  mov     rsi, bad_char   ; Wypisz komunikat.
  mov     edx, BAD_C_L          
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