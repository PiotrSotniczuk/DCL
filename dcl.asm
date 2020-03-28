SYS_WRITE equ 1
SYS_READ  equ 0
STDIN     equ 0
SYS_EXIT  equ 60
STDOUT    equ 1
MAX_LINE  equ 50
BUFF_SIZE equ 100
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
LRT:     resb 24      ; miejsce na zapisanie adresu do tablicy   
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

%macro set_1 1
  mov     r11, %1_1
  mov     r8b, 0
  mov     r10d, 0
set_1_loop_%1:
  mov     r10b, [r9]      ; r10 = znak z permutacji
  mov     byte [r11 + r10], r8b ; odwrocenie permutacji
  inc     r9
  inc     r8b
  cmp     r8b, TAB_SIZE
  jne     set_1_loop_%1
%endmacro

%macro q_plus 3
  mov     r13b, %1
  add     r13b, %2
  cmp     r13b, 42
  jb      change_%3
  sub     r13b, 42
change_%3:
  mov     r12b, r13b
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
    mov     [LRT + ebx*8], rsi
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

;cmp rsi, [LRT + 16]assertion
 ; je exit_debug  

  mov     r9, [LRT]        ; r9 = poczatek stringu permutacji
  set_1 L 

  mov     r9, [LRT + 8]        ; r9 = poczatek stringu permutacji
  set_1 P

  next_arg
  xor     r14, r14
  mov     r14b, [rsi]     ; akt wartosci bebnow
  check_char r14b
  sub     r14b, 49
  
  xor     r15, r15
  mov     r15b, [rsi + 1]
  check_char r15b
  sub     r15b, 49

  add     rbp, 8           ; adres argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jnz     exit_arg        ; za duzo arg

read_loop:
  mov     rdx, BUFF_SIZE
  mov     rsi, buffer
  mov     rdi, STDIN
  mov     rax, SYS_READ
  syscall

  cmp     eax, 0      ; end of input
  je      exit

  xor     rcx, rcx
  mov     r8d, 0
coding_loop:          ; increase modulo R
  inc     r15b
  cmp     r15b, 42
  jne     no_oveflow_R 
  sub     r15, 42
no_oveflow_R:
  cmp     r15b, 27      ; check if increase L
  je      move_L
  cmp     r15b, 33      ; R
  je      move_L
  cmp     r15b, 35      ; T
  je      move_L
  jmp     no_move_L
move_L:
  inc     r14b           ; increase modulo L
  cmp     r14b, 42
  jne     no_move_L
  sub     r14b, 42
no_move_L:

  mov     r12b, [buffer + r8]
  check_char r12b
  sub     r12b, 49  
  
  xor     r13, r13

  q_plus r12b, r15b, Qr1      ; Qr

  mov     r9, [LRT + 8]     ;R
  mov     r12b, [r9 + r13]

  mov     r11b, 42
  sub     r11b, r15b
  q_plus  r12b, r11b, Q_r1    ;Q-r

  q_plus r12b, r14b, Ql1      ; Ql
  
  mov     r9, [LRT]     ;L
  mov     r12b, [r9 + r13]

  mov     r11b, 42
  sub     r11b, r14b
  q_plus  r12b, r11b, Q_l1    ;Q-l

  mov     r9, [LRT + 16]     ;T
  mov     r12b, [r9 + r13]

  q_plus r12b, r14b, Ql2      ; Ql

  mov     r12b, [L_1 + r13]    ;L-1

  mov     r11b, 42
  sub     r11b, r14b
  q_plus  r12b, r11b, Q_l2    ;Q-l

  q_plus r12b, r15b, Qr2      ; Qr

  mov     r12b, [P_1 + r13]

  mov     r11b, 42
  sub     r11b, r15b
  q_plus  r12b, r11b, Q_r2    ;Q-r
  

  add     r12b, 49
  mov     byte [buffer + r8], r12b
  inc     r8d
  cmp     r8d, eax
  jne     coding_loop

  mov     rdx, rax          ; print
  mov     rsi, buffer
  mov     edi, STDOUT
  mov     rax, SYS_WRITE
  syscall
  jmp     read_loop



exit:
  mov     eax, SYS_EXIT
  xor     edi, edi        ; kod powrotu 0
  syscall


exit_bad_char:
  mov     eax, SYS_EXIT   
  mov     rdi, 1
  syscall
exit_arg:
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
