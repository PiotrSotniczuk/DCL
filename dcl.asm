SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1
MAX_LINE  equ 50
BUFF_SIZE equ 10
TAB_SIZE  equ 42

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

present resb TAB_SIZE
L_1:     resb TAB_SIZE     ; miejsce na zapis w tablicy znakow
P_1:     resb TAB_SIZE
LPT:     resb 24      ; miejsce na zapisanie adresu do tablicy   
buffer:  resb BUFF_SIZE

%macro set_zeros 1     
  mov     r9, TAB_SIZE
zero_loop:                ; filling with zeros
  mov     byte [%1 + r9 - 1], 0
  dec     r9
  jnz     zero_loop
%endmacro

%macro next_arg 0
  add     rbp, 8           ; adres argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jz      exit_arg    ; Napotkano zerowy wskaźnik, za malo argumentów.
%endmacro
  
%macro check_char 1
  cmp     %1, 49       ; '1' = 49 ASCII
  jb      exit_bad_char
  cmp     %1, 90       ; '90' = 'Z' 
  ja      exit_bad_char
%endmacro

%macro find_akt 2
  check_char %1
  sub     %1, 49
  cld
  mov     al, %1
  mov     ecx, TAB_SIZE
  mov     rdi, %2
  repne \
  scasb
  dec     rdi
%endmacro

section .text

_start:
  lea     rbp, [rsp + 8]  ; adres args[0]
  mov     ebx, 0          ;licznik
  mov     r12d, 0
  arg_loop:
    next_arg
    mov     ecx, MAX_LINE   ; Ogranicz przeszukiwanie do MAX_LINE znaków.
    mov     rdi, rsi        ; Ustaw adres, od którego rozpocząć szukanie.
    mov     [LPT + ebx*8], rsi
    set_zeros present
      char_loop:
        mov     r12b, [rdi]      ; zapisz znak
        test    r12b, r12b       
        jz      check_count     ; koniec slowa
        dec     ecx
        jz      exit_bad_char   ; za dlugi napis nie sprawdzam dalej
        check_char r12b
        sub     r12b, 49
        mov     byte [rdi], r12b  ; odejmij 49 
        mov     r8b, [present + r12]  ; patrze czy juz zajete miejsce
        test    r8b, r8b         
        jnz     exit_bad_char      ; jesli juz sie pojawil taki znak 
        mov     byte [present + r12], 1 ; zajmij
        inc     rdi          ; przesuwam wskaznik
        jmp     char_loop
    check_count:
      sub     rdi, rsi        ; liczba bajtów w arg
      cmp     rdi, TAB_SIZE         ; 42 znaki w permutacji
      jne     exit_bad_char   ; za duze/male argumenty
      inc     ebx             ; i++
      cmp     ebx, 3
      jne     arg_loop


  mov     r9, 0
check_perm_T:
  mov     r12b, [rsi + r9]    ; r12 = znak
  mov     r8b, [rsi + r12] ; co jest na miejscu pierwotnym znaku w r12
  cmp     r12b, r8b
  je      exit_bad_char           ; cykl jednoelementowy
  cmp     r9, r8          ; czy miejsce pierwotne r8 to akt sprawdzane miejsce
  jne     exit_bad_char      ; nie ma cyklu dwuelem  
  inc     r9
  cmp     r9, TAB_SIZE
  jne     check_perm_T 

;cmp rsi, [LPT + 16]assertion
 ; je exit_debug  

  mov     r9, [LPT]        ; r9 = poczatek stringu permutacji
  mov     r11, L_1
  call    near set_1

  mov     r9, [LPT + 8]        ; r9 = poczatek stringu permutacji
  mov     r11, P_1
  call    near set_1

  next_arg
  mov     r14b, [rsi]     ; akt wartosci bebnow
  find_akt r14b, [LPT]
  mov     r14, rdi        ; adres akt wartoosci bebna L

  mov     r15b, [rsi + 1]
  find_akt r15b, [LPT + 8]
  mov     r15, rdi

  add     rbp, 8           ; adres argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jnz     exit_arg        ; za duzo arg


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
exit_arg:
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
  mov     rdi, r12
  syscall

set_1:
  mov     r8b, 0
  mov     r10d, 0
set_1_loop:
  mov     r10b, [r9]      ; r10 = znak z permutacji
  mov     byte [r11 + r10], r8b ; odwrocenie permutacji
  inc     r9
  inc     r8b
  cmp     r8b, TAB_SIZE
  jne     set_1_loop
  ret
  