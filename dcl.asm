SYS_WRITE	equ 1
SYS_EXIT	equ 60
STDOUT		equ 1
MAX_LINE	equ 45
BUFF_SIZE	equ 3862
TAB_SIZE	equ 42
ASCII_1		equ 49

global _start

section .bss

present	resb 3*TAB_SIZE	; miejsce na
L_1:		resb TAB_SIZE		; tablica trzymajaca L^(-1)
R_1:		resb TAB_SIZE
LRT:		resb 24					; miejsce na zapisanie adresu do tablic w nazwie
buffer:	resb BUFF_SIZE		; do wczytania i wypisania danych

%macro get_arg 1				 
	mov			rsi, [rbp + %1*8 + 8] ; adres kolejnego argumentu
	test		rsi, rsi
	jz			ex_1						; napotkano zerowy wskaźnik, za malo argumentów.
%endmacro
	
%macro check_char 1
	sub			%1, ASCII_1			; jesli liczba < ASCII_1 to overflow i duza liczba
	cmp			%1, TAB_SIZE		; jesli miedzy 0 a 41 to przejdzie
	jge			ex_1
%endmacro

%macro set_1 2
	mov			r9, %2					; r9 to poczatek permutacji
	xor			r8d, r8d
	xor			r10d, r10d
set_1_loop_%1:
	mov			r10b, [r9]			; r10 = znak z permutacji
	mov			byte [%1_1 + r10], r8b ; odwrocenie permutacji
	inc			r9
	inc			r8d
	cmp			r8d, TAB_SIZE
	jne			set_1_loop_%1
%endmacro

%macro set_akt 2
	xor			%1d, %1d
	mov			%1b, [rsi + %2] ; akt wartosci bebnow
	check_char %1b
%endmacro

%macro q_plus 2
	add			%1d, %2d				; tyle powinno sie przesunac
	mov			edi, %1d				; na wszelki wypadek zapamietac
	sub			%1d, TAB_SIZE		; zakladam ze przekroczylem 41 
	cmovs		%1d, edi				; jesli overflov to zle zalozenie wiec cofam
%endmacro

section .text

_start:
	lea			rbp, [rsp + 8]	; adres args[0]
	xor			ebx, ebx				; licznik na 0
	mov			r9, present			; wskaznik na tablice zer
arg_loop:
	get_arg rbx							; ustawia rsi na kolejny arg
	mov			ecx, MAX_LINE		; ogranicz przeszukiwanie do MAX_LINE znaków.
	mov			rdi, rsi				; ustaw adres, od którego rozpocząć szukanie.
	mov			[LRT + ebx*8], rsi ; zapamietaj adres argumentu w tablicy LRT
char_loop:
	mov			al, [rdi]				; zapisz znak
	test		al, al				
	jz			check_count			; koniec danego arg
	dec			ecx
	jz			ex_1						; za dlugi napis nie sprawdzam dalej
	check_char al
	mov			byte [rdi], al	; zapisz spowrotem ale juz pomniejszone o ASCII_1
	mov			r8b, [r9 + rax] ; patrze czy juz zajete miejsce
	test		r8b, r8b				 
	jnz			ex_1						; jesli juz sie pojawil taki znak
	mov			byte [r9 + rax], 1 ; zajmij
	inc			rdi							
	jmp			char_loop
check_count:
	sub			rdi, rsi				; liczba bajtów w arg
	cmp			rdi, TAB_SIZE		; 42 znaki w permutacji
	jne			ex_1						; za duze/male argumenty
	add			r9, TAB_SIZE		; przesuwam na kolejne 42 niezajete miejsca
	inc			ebx
	cmp			ebx, 3
	jne			arg_loop

	xor			r8d, r8d
	xor			ecx, ecx
check_perm_T:
	mov			al, [rsi + rcx] ; al = znak
	mov			r8b, [rsi + rax]; co jest na miejscu pierwotnym znaku w al
	cmp			al, r8b
	je			ex_1						; jesli to samo to cykl jednoelementowy
	cmp			ecx, r8d				; czy miejsce pierwotne r8 to akt sprawdzane miejsce
	jne			ex_1						; nie ma cyklu dwuelem
	inc			ecx
	cmp			ecx, TAB_SIZE
	jne			check_perm_T
	
	set_1		L, [LRT]				; ustaw perm odwrotna czyli tablice L_1 R_1
	set_1		R, [LRT + 8]

	get_arg 3								; rsi na nastepny argument

	set_akt r14, 0					; ustaw akt wartosci bebnow
	set_akt r15, 1

	xor			r9d, r9d
	mov			r9b, [rsi + 2]	; wychodzi jesli wiecej niz 2 znaki w kluczu
	test		r9d, r9d
	jnz			ex_1

	mov			rsi, [rbp + 5*8] ; adres kolejnego argumentu
	test		rsi, rsi
	jnz			ex_1						; za duzo arg

	mov			r8, [LRT]				; kazdy wskazuje poczatek kolejno L, R, T
	mov			r9, [LRT + 8]
	mov			r10, [LRT + 16]
	xor			ebx, ebx

read_loop:
	mov			edx, BUFF_SIZE
	mov			esi, buffer
	xor			edi, edi				; STDIN			equ 0
	xor			eax, eax				; SYS_READ	equ 0
	syscall									; wczytaj dane

	test			eax, eax			 
	jz			ex_0						; koniec inputu
	js			ex_1						; blad
	xor			ecx, ecx
coding_loop:
	inc			r15d
	cmp			r15d, TAB_SIZE
	cmovge	r15d, ebx				; ebx = 0, operacja modulo TAB_SIZE
	
	cmp			r15d, 27				; sprawdz czy zwiekszyc L (L=27, R=33, T=35)
	je			move_L
	cmp			r15d, 33
	je			move_L
	cmp			r15d, 35
	je			move_L
no_move_L:
	mov			r12b, [buffer + rcx] ; wczytaj znak
	check_char r12d

	mov			r11d, TAB_SIZE
	sub			r11d, r14d			; operacje Q^(-1)x mozna zastapic przez Qy y=42-x

	mov			r13d, TAB_SIZE
	sub			r13d, r15d
	
	q_plus	r12, r15				; Qr

	mov			r12b, [r9 + r12] ; R

	q_plus	r12, r13,				; Q-r

	q_plus	r12, r14,				; Ql
	
	mov			r12b, [r8 + r12] ; L

	q_plus	r12, r11,				; Q-l

	mov			r12b, [r10 + r12] ; T

	q_plus	r12, r14,				; Ql

	mov			r12b, [L_1 + r12] ; L-1

	q_plus	r12, r11,				; Q-l

	q_plus	r12, r15,				; Qr

	mov			r12b, [R_1 + r12] ; R-1

	q_plus	r12, r13,				; Q-r

	add			r12d, ASCII_1
	mov			byte [buffer + rcx], r12b ; zapisz znak
	inc			ecx
	cmp			ecx, eax
	jne			coding_loop

	mov			rdx, rax				; wypisz buffor
	mov			rsi, buffer
	mov			edi, STDOUT
	mov			rax, SYS_WRITE
	syscall
	test		rax, rax				; blad wypisywania
	js			ex_1
	jmp			read_loop

move_L:
	inc			r14d						; dodaj jeden mod TAB_SIZE
	cmp			r14d, TAB_SIZE
	cmovge	r14d, ebx
	jmp			no_move_L

ex_0:
	mov			eax, SYS_EXIT
	xor			edi, edi				; kod powrotu 0
	syscall

ex_1:
	mov			eax, SYS_EXIT
	xor			edi, edi				; kod powrotu 1
	inc			edi
	syscall