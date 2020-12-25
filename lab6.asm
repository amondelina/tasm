
.model small
.stack 100h
.data 

	k 	dw 	?
	key db 	26 dup ('$')
	key_len dw ?
	wrong_arguments_text 	db "Wrong arguments$"
	alphabet db "abcdefghijklmnopqrstuvwxyz$"
	new_alphabet db 26 dup('0'), '$'
	old_handler 	dd 00
	flag 	db 	0

.code
.486

read_arguments proc 
	pusha
	xor 	ax, ax
	mov 	cl, es:80h
	dec 	cl
	mov 	si, 82h
	xor 	ax, ax

ra_k_loop:
	mov 	al, es:[si]
	inc 	si
	dec 	cx
	cmp 	al, ' '
	je 		ra_k

	cmp 	al, '0'
	jb 		wrong_arguments

	cmp 	al, '9'
	ja 		wrong_arguments

	sub 	al, '0'
	xchg 	bx, ax
	mov 	dx, 10
	mul 	dx
	jo 		wrong_arguments
	add 	bx, ax
	jo 		wrong_arguments
	jmp 	ra_k_loop
		
ra_k:
	cmp 	bx, 26
	jnb 	wrong_arguments

	mov 	k, 	bx
	mov 	key_len, cx
	lea		di, key

ra_key_loop:
	mov 	al, es:[si]
	inc 	si 	
	cmp 	al, 'a'
	jb 		wrong_arguments

	cmp 	al, 'z'
	ja 		wrong_arguments

	mov 	[di], al 
	inc 	di	
	loop ra_key_loop

	jmp ra_exit

wrong_arguments:
	xor 	ax, ax
	mov 	ah, 9
	lea 	dx, wrong_arguments_text
	int 	21h
	jmp 	exit

ra_exit:
	popa
	ret
read_arguments endp

delete_symbol proc near
	pusha 
	
	cmp 	cx, 0
	je 		ds_label
ds_loop:
	mov  	al, [di+1]
	mov  	[di], al
	inc 	di
	loop 	ds_loop

ds_label:
	mov 	[di], byte ptr '$'

	popa
	ret
delete_symbol endp

check_key proc near
	pusha

	mov 	cx, key_len
	lea 	si, key

ck_loop:
	mov 	al, [si]
	inc 	si
	mov 	di, si
	mov 	bx, cx
	dec 	cx
	cmp 	cx, 0
	je 		ck_exit
	ck_loop2:
		cmp 	al, [di]
		je 		ck_del
		inc 	di
		loop 	ck_loop2
ck_label:
	mov 	cx, bx
	loop 	ck_loop	

	jmp 	ck_exit

ck_del:
	dec  	cx
	dec 	bx
	call 	delete_symbol
	dec 	key_len
	cmp 	cx, 0
	je 		ck_label
	jmp 	ck_loop2

ck_exit:
	popa
	ret
check_key endp
set_new_alphabet proc near
	pusha

	lea 	di, new_alphabet
	add 	di, k
	lea 	si, key
	mov 	cx, key_len
	mov 	bx, 26

snb_loop:
	mov 	al, [si]
	push 	di
	push 	cx
	mov 	cx, bx
	lea 	di, alphabet
	snb_find:
		cmp 	al, [di]
		je 		snb_del
		inc 	di
		loop 	snb_find
	pop 	cx
	pop 	di
	mov 	[di], al
	inc 	di
	inc 	si
	loop 	snb_loop

	lea 	si, alphabet
	mov 	cx, 26
	sub 	cx, k
	sub 	cx, key_len
	cmp 	cx, 0
	je 	snb_label

snb_loop1:
	mov 	al, [si]
	mov 	[di], al
	inc 	si
	inc 	di
	loop 	snb_loop1

snb_label:
	mov 	cx, k
	lea 	di, new_alphabet
snb_loop2:
	mov 	al, [si]
	mov 	[di], al
	inc 	si
	inc 	di
	loop 	snb_loop2


	popa
	ret	

snb_del:
	dec 	cx
	dec 	bx
	call 	delete_symbol
	jmp 	snb_find	
	
set_new_alphabet endp


install_handler proc near
	pusha

	push 	ds
	mov 	ax, 2509h
	mov 	dx, @code
	mov 	ds, dx
	mov 	dx, offset new_handler
	int 	21h
	pop 	ds

	mov 	flag, 1
	popa
	ret
install_handler endp
delete_handler proc near
	pusha

	push 	ds
	mov 	ax, 2509h
	mov 	ds, word ptr old_handler+2
	mov 	dx, word ptr cs:old_handler
	int 	21h
	pop 	ds

	mov 	flag, 0
	popa
	ret
delete_handler endp
new_handler proc near
	pusha 

	in 		al, 60h

	cmp 	al, 0Eh
	je 		bcs

	cmp 	al, 1Eh
	mov 	di, 0
	je 		new

	cmp 	al, 30h
	mov 	di, 1
	je 		new

	cmp 	al, 2Eh
	mov 	di, 2
	je 		new

	cmp 	al, 20h
	mov 	di, 3
	je 		new

	cmp 	al, 12h
	mov 	di, 4
	je 		new

	cmp 	al, 21h
	mov 	di, 5
	je 		new

	cmp 	al, 22h
	mov 	di, 6
	je 		new

	cmp 	al, 23h
	mov 	di, 7
	je 		new

	cmp 	al, 17h
	mov 	di, 8
	je 		new

	cmp 	al, 24h
	mov 	di, 9
	je 		new

	cmp 	al, 25h
	mov 	di, 10
	je 		new

	cmp 	al, 26h
	mov 	di, 11
	je 		new

	cmp 	al, 32h
	mov 	di, 12
	je 		new

	cmp 	al, 31h
	mov 	di, 13
	je 		new

	cmp 	al, 18h
	mov 	di, 14
	je 		new

	cmp 	al, 19h
	mov 	di, 15
	je 		new

	cmp 	al, 10h
	mov 	di, 16
	je 		new

	cmp 	al, 13h
	mov 	di, 17
	je 		new

	cmp 	al, 1Fh
	mov 	di, 18
	je 		new

	cmp 	al, 14h
	mov 	di, 19
	je 		new

	cmp 	al, 16h
	mov 	di, 20
	je 		new

	cmp 	al, 2Fh
	mov 	di, 21
	je 		new

	cmp 	al, 11h
	mov 	di, 22
	je 		new

	cmp 	al, 2Dh
	mov 	di, 23
	je 		new

	cmp 	al, 15h
	mov 	di, 24
	je 		new

	cmp 	al, 2Ch
	mov 	di, 25
	je 		new

old:	
	popa
	jmp 	dword ptr cs:[old_handler]
	iret

new:
	mov 	dl, [new_alphabet+di]
	mov 	ah, 02h
	int 	21h
	jmp 	nh_exit

bcs:
	mov 	dl, 8
	mov 	ah, 2
	int 	21h
	mov 	ah, 2
	mov 	dl, ' '
	int 	21h
	mov 	dl, 8
	mov 	ah, 2
	int 	21h

nh_exit:
	xor 	ax, ax
    mov 	al, 20h
    out 	20h, al 
    popa
	iret
new_handler endp

main:
	mov 	ax, @data 
	mov 	ds, ax
	xor 	ax, ax


	call 	read_arguments
	call 	check_key
	call 	set_new_alphabet

	mov 	ax, 3509h
	int 	21h
	mov 	word ptr old_handler, bx
	mov 	word ptr old_handler+2, es

	call 	install_handler


listen:
	xor 	ax, ax
	mov 	ah, 01h
	int 	21h

	cmp 	al, '`'
	je 		switch

	cmp 	al, 1Bh
	je 		exit

	jmp 	listen

switch:
	cmp 	flag, 0
	je 		sw
	call 	delete_handler
	jmp 	listen
sw:
	call 	install_handler
	jmp		listen

exit:
	cmp 	flag, 1
	jne 	label1
	call 	delete_handler
label1:
	mov 	ax, 4C00h
	int 	21h
end main