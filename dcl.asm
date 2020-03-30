SYS_WRITE equ 1
SYS_EXIT  equ 60
STDOUT    equ 1
MAX_LINE  equ 45
BUFF_SIZE equ 131072
TAB_SIZE  equ 42
ASCII_1   equ 49
ASCII_Z   equ 90

global _start

section .bss

present  resb 3*TAB_SIZE
L_1:     resb TAB_SIZE     ; miejsce na zapis w tablicy znakow
R_1:     resb TAB_SIZE
LRT:     resb 24      ; miejsce na zapisanie adresu do tablicy   
buffer:  resb BUFF_SIZE

%macro next_arg 0
  add     rbp, 8           ; adres argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jz      ex_1    ; Napotkano zerowy wskaźnik, za malo argumentów.
%endmacro
  
%macro check_char 1
  sub     %1, ASCII_1
  cmp     %1, TAB_SIZE 
  jge      ex_1
%endmacro

%macro set_1 2
  mov     r9, %2        ; r9 to poczatek permutacji
  xor     r8d, r8d
  xor     r10d, r10d
set_1_loop_%1:
  mov     r10b, [r9]      ; r10 = znak z permutacji
  mov     byte [%1_1 + r10], r8b ; odwrocenie permutacji
  inc     r9            ; zwieksz wskaznik
  inc     r8d
  cmp     r8d, TAB_SIZE
  jne     set_1_loop_%1
%endmacro

%macro set_akt 2
  xor     %1d, %1d
  mov     %1b, [rsi + %2]     ; akt wartosci bebnow
  check_char %1b
%endmacro

%macro q_plus 3
  add     %1d, %2d
  cmp     %1d, TAB_SIZE
  jb      change_%3
  sub     %1d, TAB_SIZE
change_%3:
%endmacro

section .text

_start:
  lea     rbp, [rsp + 8]  ; adres args[0]
  xor     ebx, ebx          ; licznik na 0
  mov     r9, present       
  arg_loop:
    next_arg                ; zwieksza rbp i ustawia rsi na kolejny arg
    mov     ecx, MAX_LINE   ; Ogranicz przeszukiwanie do MAX_LINE znaków.
    mov     rdi, rsi        ; Ustaw adres, od którego rozpocząć szukanie.
    mov     [LRT + ebx*8], rsi    
    char_loop:
        mov     al, [rdi]      ; zapisz znak
        test    al, al       
        jz      check_count     ; koniec slowa
        dec     ecx
        jz      ex_1   ; za dlugi napis nie sprawdzam dalej
        check_char al
        mov     byte [rdi], al  ; zapisz spowrotem 
        mov     r8b, [r9 + rax]  ; patrze czy juz zajete miejsce
        test    r8b, r8b         
        jnz     ex_1      ; jesli juz sie pojawil taki znak 
        mov     byte [r9 + rax], 1 ; zajmij
        inc     rdi          ; przesuwam wskaznik
        jmp     char_loop
    check_count:
      sub     rdi, rsi        ; liczba bajtów w arg
      cmp     rdi, TAB_SIZE         ; 42 znaki w permutacji
      jne     ex_1   ; za duze/male argumenty
      add     r9, TAB_SIZE        ; przesuwam present
      inc     ebx             ; i++
      cmp     ebx, 3
      jne     arg_loop

  xor     r8, r8
  xor     ecx, ecx
check_perm_T:
  mov     al, [rsi + rcx]    ; al = znak
  mov     r8b, [rsi + rax] ; co jest na miejscu pierwotnym znaku w al
  cmp     al, r8b
  je      ex_1           ; cykl jednoelementowy
  cmp     ecx, r8d          ; czy miejsce pierwotne r8 to akt sprawdzane miejsce
  jne     ex_1      ; nie ma cyklu dwuelem  
  inc     ecx
  cmp     ecx, TAB_SIZE
  jne     check_perm_T 
  
  set_1 L, [LRT]                  ; ustaw perm odwrotna
  set_1 R, [LRT + 8]

  next_arg

  set_akt r14, 0
  set_akt r15, 1

  xor     r9d, r9d
  mov     r9b, [rsi + 2]    ; wychodzi jesli wiecej niz 2 znaki w kluczu
  test    r9d, r9d
  jnz     ex_1

  add     rbp, 8           ; adres argumentu 
  mov     rsi, [rbp]      ; adres kolejnego argumentu
  test    rsi, rsi
  jnz     ex_1        ; za duzo arg

  mov     r8, [LRT]         ; kazdy wskazuje poczatek czesci
  mov     r9, [LRT + 8]
  mov     r10, [LRT + 16]

read_loop:
  mov     edx, BUFF_SIZE
  mov     esi, buffer
  xor     edi, edi        ; STDIN     equ 0
  xor     eax, eax   ; SYS_READ  equ 0
  syscall             ; wczytaj dane

  test     eax, eax      ; end of input
  jz      ex_0
  xor     ecx, ecx    
coding_loop:          ; increase modulo R
  inc     r15d
  mov     edi, TAB_SIZE
  xor     edi, r15d
  jnz     no_oveflow_R 
  xor     r15d, TAB_SIZE
no_oveflow_R:
  mov     edi, 27
  xor     edi, r15d      ; check if increase L
  jz      move_L
  mov     edi, 33
  xor     edi, r15d      ; check if increase R
  jz      move_L
  mov     edi, 35
  xor     edi, r15d      ; check if increase L
  jz      move_L
  jmp     no_move_L
move_L:
  inc     r14d           ; increase modulo L
  mov     edi, TAB_SIZE
  xor     edi, r14d
  jnz     no_move_L 
  xor     r14d, r14d
no_move_L:

  mov     r12b, [buffer + rcx]   ; wczytaj znak
  check_char r12d

  mov     r11d, TAB_SIZE    ; -l
  sub     r11d, r14d

  mov     r13d, TAB_SIZE    ; -r
  sub     r13d, r15d
  
  q_plus r12, r15, Qr1      ; Qr

  mov     r12b, [r9 + r12]

  q_plus  r12, r13, Q_r1    ;Q-r

  q_plus r12, r14, Ql1      ; Ql
  
  mov     r12b, [r8 + r12]

  q_plus  r12, r11, Q_l1    ;Q-l

  mov     r12b, [r10 + r12]

  q_plus r12, r14, Ql2      ; Ql

  mov     r12b, [L_1 + r12]    ;L-1

  q_plus  r12, r11, Q_l2    ;Q-l

  q_plus r12, r15, Qr2      ; Qr

  mov     r12b, [R_1 + r12]   ;R-1

  q_plus  r12, r13, Q_r2    ;Q-r

  add     r12d, ASCII_1
  mov     byte [buffer + rcx], r12b
  inc     ecx
  cmp     ecx, eax
  jne     coding_loop

  mov     rdx, rax          ; print buffor
  mov     rsi, buffer
  mov     edi, STDOUT
  mov     rax, SYS_WRITE
  syscall
  jmp     read_loop

ex_0:
  mov     eax, SYS_EXIT
  xor     edi, edi        ; kod powrotu 0
  syscall

ex_1:
  mov     eax, SYS_EXIT   
  mov     edi, 1          ; kod powrotu 1
  syscall