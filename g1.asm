.model small
.stack 100h

.data
	color 	db 	?
	x 		dw 	?
	y 		dw 	?
	len 	dw 	4

	ghost_x 	dw 	70
	ghost_y 	dw 	80

	pumpkin_x	dw 	?
	pumpkin_y 	dw 	?						;0 - ничего
											;1 - призрак
	spider_x 	dw 	?						;2 - тыква
	spider_y 	dw 	?						;3 - паук
											
	kind 		db 	0
	field 		db 	64000 dup (0)

	speed 		db 	1
	time_last 	db 	0
	score		dw 	0

	string_game	db 12 dup(13, 10), "               GAME OVER", 7 dup(13, 10), '$'
	string_score 	db 	" YOUR SCORE: $"
	string_win 		db 11 dup(13,10), "                 WIN!!!$"
	string_pause 		db 11 dup(13,10), "                 PAUSE$"
	string_try	db 11 dup(13, 10), "              TRY AGAIN$"

	file_save 	db 	"save.txt", 0
	handle_save	dw 	?

	buffer	db 100 dup ('$')
	buffer_len 	dw 	0
 	endline db 13, 10, '$'

 	old_mode 	db 	?

.code
.486


str_to_num proc 
	push 	dx
	push 	bx
	xor 	dx, dx	
	mov 	bx, 10

stnloop:	
	xor 	ax,ax
	mov 	al, [si]
	inc 	si	

	cmp 	al,'$'
	je 		eexit
	
	sub 	ax,'0'
	
	push 	ax
	mov 	ax, dx
	mul 	bx
	pop 	dx
	add 	dx, ax
	jmp 	stnloop

eexit:
	mov 	ax, dx
	pop 	bx
	pop		dx
	ret

str_to_num endp 

num_to_str proc 

	push 	cx
	push 	bx
	mov 	bx,10	
	xor 	cx,cx	

.loop1:	
	xor 	dx,dx       
	div 	bx		
	push 	dx		
	inc 	cx		
	cmp 	ax, 0	
	jnz 	.loop1	

.loop2:		
	pop 	ax		
	add 	al,'0'	
	mov 	[di], al
	inc 	buffer_len
	inc 	di			
	loop 	.loop2		

	mov 	[di], byte ptr'$'
	inc 	di
	inc 	buffer_len
	pop 	bx
	pop 	cx

	ret
num_to_str endp

clean_buffer proc 
	push 	di
	push 	cx

	mov 	cx, 100

.looop:
	mov 	[di], byte ptr'$'
	inc 	di
	loop 	.looop

	pop 	cx
	pop 	di
	ret
clean_buffer endp

read_file proc 
	push ax
	push bx
	push cx
	push dx

	xor 	ax, ax
	xor 	cx, cx
	mov 	ah, 3Dh
	lea 	dx, file_save
	int 	21h
	mov 	handle_save, ax

	mov 	bx, ax 	
	lea		dx, buffer
	mov 	cx, 100
	xor 	ax, ax
	mov 	ah, 3Fh
	int 	21h

	xor 	ax, ax
	mov 	bx, [handle_save]
	mov 	ah, 3Eh
	int 	21h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
read_file endp

create_file proc 
	push ax
	push bx
	push cx
	push dx

	xor 	ax, ax
	xor 	cx, cx
	mov 	ah, 3Ch
	lea 	dx, file_save
	int 	21h
	mov 	handle_save, ax

	xor 	ax, ax
	mov 	bx, [handle_save]
	mov 	ah, 3Eh
	int 	21h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
create_file endp

write_file proc 
	push ax
	push bx
	push cx
	push dx

rfopen:
	xor 	cx, cx
	mov 	al, 2
	mov 	ah, 3Dh
	lea 	dx, file_save
	int 	21h
	mov 	[handle_save], ax
	jnc 	rfread

	call 	create_file
	jmp 	rfopen
rfread:

	mov 	bx, [handle_save]
	lea 	dx, buffer
	mov 	ah, 40h
	mov  	cx, buffer_len
	int 	21h

	xor 	ax, ax
	mov 	bx, [handle_save]
	mov 	ah, 3Eh
	int 	21h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
write_file endp

clear_screen proc 
	push 	ax
	push 	bx
	push 	cx
	push 	dx

	call 	clear_field
	mov 	ah, 6
	mov 	al, 0
	mov 	bh, 0
	mov 	cx, 0
	mov 	dx, 184Fh
	int 	10h

	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	ret
clear_screen endp


draw_point proc 				
	push 	ax
	push 	cx
	push 	dx

	mov 	ah, 0Ch
	mov 	al, color
	mov 	cx, x
	mov 	dx, y				 	
	int 	10h

	cmp 	kind, 1
	jne 	dplabel
	mov 	ax, 200
	mul 	y
	mov 	si, ax
	add 	si, x
	mov 	al, field[si]
	cmp 	al, 2
	je 		dp2
	cmp 	al, 3
	je 		dp3
	jmp 	dpexit	
dplabel:
	mov 	ax, 200
	mul 	y
	mov 	si, ax
	add 	si, x
	mov 	al, kind
	mov 	field[si], al
	jmp 	dpexit

dp2:
	call 	eat
	jmp 	dpexit

dp3:
	call 	game_over

dpexit:
	pop 	dx
	pop 	cx
	pop 	ax
	ret
draw_point endp

eat proc 
	push 	ax

	mov 	ax, 1000
	call 	random
	add 	score, ax
	call 	set_pumpkin

	pop 	ax
	ret
eat endp

listen proc 
	push 	ax
	push 	dx

	mov 	ah, 1
	int 	16h
	jz 		lexit

	mov 	ah, 0
	int 	16h

	cmp 	ah, 48h	
	je 		up

	cmp 	ah, 50h 	
	je 		down

	cmp 	ah, 1Fh
	je 		lsave

	cmp 	ah, 26h
	je 		lload

	cmp 	ah, 13h
	je 		restart

	cmp 	ah, 10h
	je 		quit

	cmp 	ah, 19h
	je 		lpause

	jmp 	wexit

lpause:
	call 	pause

quit:
	jmp 	exit

restart:
	jmp 	start

lload:
	call 	load

lsave:
	call 	save
	jmp 	lexit	

up:
	mov 	ax, ghost_y
	xor 	dx, dx
	div 	len
	cmp 	ax, 0
	je 		lexit
	mov 	ax, len
	sub 	ghost_y, ax
	jmp 	wexit

down:
	mov 	dx, 200
	sub 	dx, ghost_y
	push 	dx
	mov 	ax, 14
	mul 	len
	pop 	dx
	xchg 	ax, dx
	sub 	ax, dx
	xor 	dx, dx
	div 	len
	cmp 	ax, 0
	je 		lexit
	mov 	ax, len
	add 	ghost_y, ax
	jmp 	lexit

lexit:
	pop 	dx
	pop 	ax
	ret
listen endp

draw_square proc 
	push 	ax
	push 	cx
	push 	x
	push 	y

	mov 	cx, len
	add 	y, cx
	add 	x, cx
	mov 	ax, x 
sqloop1:
	push 	cx
	mov 	cx, len 
	mov 	x, ax
	sqloop2:
		call	draw_point
		dec 	x
		loop 	sqloop2 
	dec 	y
	pop 	cx
	loop	sqloop1

	pop 	y
	pop 	x
	pop 	cx
	pop 	ax
	ret
draw_square endp

draw_line proc 
	push 	dx
	mov 	dx, len
lloop:
	call   draw_square
	add		x, dx
	loop 	lloop

	pop 	dx
	ret
draw_line endp

draw_pumpkin proc 
	push 	y
	push 	x
	push 	ax
	push 	bx
	push 	cx
	push 	dx

	mov 	kind, 2
	mov 	ax, pumpkin_x
	mov 	bx, pumpkin_y
	mov 	x, ax
	mov  	y, bx
	mov 	dx, len

	add 	x, dx
	add		x, dx

	mov 	color, 2
	call 	draw_square
	add 	x, dx
	call 	draw_square

	add 	y, dx
	call 	draw_square

	add 	y, dx
	mov		x, ax
	add 	x, dx
	mov 	color, 12
	mov 	cx, 5
	call 	draw_line

	add 	y, dx	
	mov 	x, ax
	mov 	cx, 2
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, dx
	mov 	color, 12
	call 	draw_square
	add 	x, dx
	mov 	color, 0
	call 	draw_square
	mov 	color, 12
	add 	x, dx
	mov 	cx, 2
	call 	draw_line

	add 	y, dx
	mov 	x, ax
	mov 	cx, 7
	call 	draw_line

	add 	y, dx
	mov 	x, ax
	call 	draw_square
	add 	x, dx
	mov 	color, 0
	call 	draw_square
	add 	x, dx
	mov 	color, 12
	mov 	cx, 3
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	mov 	color, 12
	add 	x, dx
	call 	draw_square

	add 	y, dx
	mov 	x, ax
	mov 	cx, 2
	call 	draw_line
	mov 	color, 0
	mov 	cx, 3
	call 	draw_line
	mov 	color, 12
	mov 	cx, 2
	call 	draw_line

	add 	y, dx
	mov 	x, ax
	add 	x, dx
	mov 	cx, 5
	call draw_line

	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	pop 	x
	pop 	y
	ret
draw_pumpkin endp

draw_spider proc 
	push 	ax
	push 	bx
	push 	cx
	push 	dx
	push 	x
	push 	y

	mov 	kind, 3
	mov 	dx, spider_y
	mov 	bx, spider_x
	mov 	y, dx
	mov 	x, bx
	mov 	ax, len

	mov 	cx, 8
	mul 	cx
	add 	x, ax
	mov 	ax, len
	mov 	color, 5
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 7
	mul 	cx
	add 	x, ax
	mov 	ax, len
	mov 	cx, 4
	call 	draw_line


	add 	y, ax
	mov 	x, bx
	mov 	cx, 7
	mul 	cx
	add 	x, ax
	mov 	ax, len
	mov 	cx, 4
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 2
	call 	draw_line
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	;pop 	ax
	mov 	cx, 6
	call 	draw_line
	add 	x, ax
	mov 	cx, 2
	call 	draw_line
	mov 	ax, len

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	call 	draw_square
	add 	x, ax
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	mov 	cx, 6
	call 	draw_line
	add 	x, ax
	mov 	ax, len
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	mov 	cx, 2
	call 	draw_line
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	mov 	cx, 4
	call 	draw_line
	add 	x, ax
	mov 	ax, len
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	mov 	cx, 4
	call 	draw_line
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	add 	x, ax
	mov 	cx, 4
	call 	draw_line
	mov 	color, 4
	call 	draw_square
	add 	x, ax
	mov 	color, 5
	mov 	cx, 2
	call 	draw_line
	mov 	color, 4
	call 	draw_square
	add 	x, ax
	mov 	color, 5
	mov 	cx, 4
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	;push 	ax
	mov 	cx, 5
	mul 	cx
	add 	x, ax
	mov 	ax, len
	mov 	cx, 8
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	;push 	ax
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	mov 	ax, len
	call 	draw_square
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	mov 	cx, 2
	call 	draw_line
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square
	add 	x, ax
	add 	x, ax
	add 	x, ax
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	call 	draw_square
	;pop 	ax
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	call 	draw_square
	add 	x, ax
	push 	ax
	mov 	ax, len
	add 	x, ax
	call 	draw_square
	pop 	ax
	add 	x, ax
	call 	draw_square
	mov 	ax, len

	add 	y, ax
	mov 	x, bx
	mov 	cx, 6
	mul 	cx
	add 	x, ax
	mov 	ax, len
	call 	draw_square
	mov 	cx, 5
	mul 	cx
	add 	x, ax
	mov 	ax, len
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	mov 	cx, 7
	mul 	cx
	add 	x, ax
	mov 	ax, len
	call 	draw_square
	mov 	cx, 3
	mul 	cx
	add 	x, ax
	mov 	ax, len
	call 	draw_square

	pop 	y
	pop 	x
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	ret
draw_spider endp

draw_ghost proc 
	push 	ax
	push 	bx
	push 	cx
	push 	dx
	push 	x
	push 	y
	
	;mov 	len, 3
	mov 	kind, 1
	mov 	bx, ghost_x
	mov 	ax, len
	mov 	dx, ghost_y
	
	mov 	y, dx
	mov 	x, bx
	mov 	cx, 5
	mul 	cx
	add 	x, ax
	mov 	ax, len
	mov 	color, 15
	mov 	cx, 5
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	add 	x, ax
	mov 	cx, 9
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 2
	call 	draw_line
	add 	x, ax
	mov 	cx, 4
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 3
	call 	draw_line
	add 	x, ax
	mov 	cx, 3
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 14
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	mov 	color, 3
	call 	draw_square
	add 	x, ax
	mov 	cx, 4
	mov 	color, 15
	call 	draw_line
	mov 	color, 0
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 7
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	mov 	color, 3
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line
	mov 	color, 0
	mov 	cx, 2
	call 	draw_line
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line
	mov 	color, 0
	mov 	cx, 2
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 3
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	mov 	color, 3
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 3
	call 	draw_line
	mov 	color, 0
	mov 	cx, 4
	call 	draw_line
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	mov 	color, 3
	call 	draw_square
	add 	x, ax
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line
	mov 	color, 0
	mov 	cx, 3
	call 	draw_line
	mov 	color, 15
	mov 	cx, 5
	call 	draw_line
	
	add 	y, ax
	mov 	x, bx
	mov 	color, 3
	mov 	cx, 2
	call 	draw_line
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line
	mov 	color, 0
	mov 	cx, 3
	call 	draw_line
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line
	mov 	color, 3
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	mov 	color, 3
	mov 	cx, 2
	call 	draw_line
	mov 	color, 15
	mov 	cx, 5
	call 	draw_line
	mov 	color, 0
	mov 	cx, 3
	call 	draw_line
	mov 	color, 15
	mov 	cx, 2
	call 	draw_line
	mov 	color, 3
	call 	draw_square

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	mov 	color, 3
	mov 	cx, 2
	call 	draw_line
	mov 	color, 15
	mov 	cx, 8
	call 	draw_line
	mov 	color, 3
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	add 	x, ax
	add 	x, ax
	mov 	color, 3
	mov 	cx, 4
	call 	draw_line
	mov 	color, 15
	mov 	cx, 4
	call 	draw_line
	mov 	color, 3
	mov 	cx, 2
	call 	draw_line

	add 	y, ax
	mov 	x, bx
	mov 	cx, 4
	mul 	cx
	add 	x, ax
	mov 	color, 3
	mov 	cx, 6
	call 	draw_line
	
	pop 	y
	pop 	x
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	ax
	ret
draw_ghost endp

random proc 
	push 	bx
	push 	dx

	push 	ax
	xor 	ax, ax
	int 	1Ah
	mov 	ax, dx
	xor 	dx, dx
	pop 	bx
	div 	bx
	mov 	ax, dx

	pop 	dx
	pop 	bx
	ret
random endp

set_pumpkin proc 
	push 	ax
	push 	bx


	mov 	ax, 8
	mul 	len

	mov 	bx, 200
	sub 	bx, ax
	mov 	ax, bx
	call 	random
	mov 	pumpkin_y, ax

	mov 	ax, 7
	mul 	len
	mov 	bx, 320
	sub 	bx, ax
	mov 	ax, 14
	mul 	len
	sub 	bx, ax
	sub 	bx, ghost_x
	xchg 	ax, bx
	call 	random
	add		ax, ghost_x
	add 	ax, bx
	mov 	pumpkin_x, ax

	pop 	bx
	pop 	ax
	ret
set_pumpkin endp

set_spider proc 
	push 	ax
	push 	bx

	mov 	ax, 15
	mul 	len
	mov 	bx, 200
	sub 	bx, ax
	mov 	ax, bx
	call 	random
	mov 	spider_y, ax

	mov 	ax, 18
	mul 	len
	mov 	bx, 320
	sub 	bx, ax
	mov 	spider_x, bx

	pop 	bx
	pop 	ax
	ret
set_spider endp

display_score proc 
	push 	ax
	push 	bx
	push 	cx
	push 	dx

	mov 	ax, score
	mov 	bx, 10
	xor 	cx, cx

dspush:
	xor 	dx, dx
	div 	bx
	push 	dx
	inc 	cx
	cmp 	ax, 0
	jne 	dspush

	xor 	dx, dx
	xor 	bh, bh
	mov 	ah, 2
	int 10h

dspop:
	pop 	ax
	add 	ax, '0'
	mov 	dx, ax
	mov 	ah, 0Eh
	int 	10h
	loop	dspop

	pop 	dx
	pop 	bx
	pop 	cx
	pop 	ax

	ret
display_score endp

load proc 
	push 	ax

	call 	read_file
	lea 	si, buffer

	call 	str_to_num
	mov 	score, ax

	call 	str_to_num
	mov 	ghost_y, ax

	call 	str_to_num
	mov 	pumpkin_x, ax

	call 	str_to_num
	mov 	pumpkin_y, ax

	call 	str_to_num
	mov 	spider_x, ax

	call 	str_to_num
	mov 	spider_y, ax

	pop 	ax
	jmp 	timer
	ret
load endp
save proc 
	push 	ax

	lea 	di, buffer
	call 	clean_buffer
	mov 	buffer_len , 0

	mov 	ax, score
	call 	num_to_str

	mov 	ax, ghost_y
	call 	num_to_str


	mov 	ax, pumpkin_x
	call 	num_to_str

	mov 	ax, pumpkin_y
	call 	num_to_str

	mov 	ax, spider_x
	call 	num_to_str

	mov 	ax, spider_y
	call 	num_to_str

	call 	write_file
	pop 	ax
	ret
save endp

clear_field proc 
	push 	cx
	push 	bx

	mov 	cx, 200
	lea 	di, field
cfexternal:
	push 	cx
	mov 	cx, 320
	cfinternal:
		mov 	[di], byte ptr 0
		inc 	di
		loop 	cfinternal
	pop 	cx
	loop 	cfexternal

	pop 	bx
	pop 	cx
	ret
clear_field endp

pause proc 
	push 	ax
	push 	dx

	call 	clear_screen
	xor 	ax, ax
	lea 	dx, string_pause
	mov 	ah, 09h
	int 	21h

ploop:
	mov 	ah, 1
	int 	16h
	jz 		ploop

	mov 	ah, 0
	int 	16h

	cmp 	ah, 13h
	je 		prestart

	cmp 	ah, 10h
	je 		pquit

	cmp 	ah, 19h
	je 		ppause

	cmp 	ah, 1Fh
	je 		psave

	cmp 	ah, 26h
	je 		pload

	jmp 	ploop
psave:
	call 	save
	jmp 	ploop
pload:
	call 	load
ppause:
	jmp 	timer
pquit:
	jmp 	exit

prestart:
	jmp 	start	

pexit:
	pop 	dx
	pop 	ax
	ret
pause endp

win proc 
	push 	ax
	push 	dx

	call 	clear_screen
	xor 	ax, ax
	lea 	dx, string_win
	mov 	ah, 09h
	int 	21h

wloop:
	mov 	ah, 1
	int 	16h
	jz 		wloop

	mov 	ah, 0
	int 	16h

	cmp 	ah, 13h
	je 		wrestart

	cmp 	ah, 26h
	je 		wload

	cmp 	ah, 10h
	je 		wquit

	jmp 	wloop
wload:
	call 	load
wquit:
	jmp 	exit

wrestart:
	jmp 	start	

wexit:
	pop 	dx
	pop 	ax
	ret
win endp

game_over proc 
	push 	ax
	push 	dx

	cmp 	score, 0
	je 		gotry
	
	call 	clear_screen
	lea  	dx, string_game
	xor 	ax, ax
	mov 	ah, 09h
	int 	21h
	mov 	ax, score
	push 	ax
	xor 	ax, ax
	lea  	dx, string_score
	mov 	ah, 09h
	int 	21h
	pop 	ax


	lea 	di, buffer
	call 	clean_buffer
	call 	num_to_str
	
	xor 	ax, ax
	lea 	dx, buffer
	mov 	ah, 09h
	int 	21h
	jmp 	goloop

gotry:
	jmp 	start

goloop:
	mov 	ah, 1
	int 	16h
	jz 		goloop

	mov 	ah, 0
	int 	16h

	cmp 	ah, 13h
	je 		gorestart

	cmp 	ah, 10h
	je 		goquit

	cmp 	ah, 26h
	je 		goload

	jmp 	goloop
goload:
	call 	load
goquit:
	jmp 	exit

gorestart:
	jmp 	start	

goexit:
	pop 	dx
	pop		ax
	ret
game_over endp
game proc 
	xor 	ax, ax
	mov 	ah, 0Fh
	int 	10h
	mov 	old_mode, al
	mov 	ax, 13h
	int 	10h

start:

	mov 	ghost_y, 80
	mov 	ghost_x, 60
	mov 	time_last, 0
	mov 	score, 0
	call 	set_pumpkin
	call 	set_spider

timer:
	mov 	ah, 2Ch
	int 	21h

	mov 	bl, speed
	xor 	ax, ax
	mov 	al, dl
	div 	bl
	cmp 	al, time_last
	je 		timer

	mov 	time_last, al

	mov 	ax, 60000
	cmp 	ax, score
	ja 		label2
	call 	win
label2:
	mov 	ax, len
	sub 	spider_x, ax
	sub 	pumpkin_x, ax
	call 	clear_screen
	;call 	clear_field
	xor 	dx, dx
	mov 	ax, spider_x
	div 	len
	cmp 	ax, 0
	jne 	label1
	call 	set_spider
label1:
	mov 	ax, pumpkin_x
	div 	len
	cmp 	ax, 0
	jne 	label3
	call 	set_pumpkin
label3:
	call 	listen
	call 	draw_pumpkin
	call 	draw_spider
	call 	draw_ghost
	inc 	score
	call 	display_score
	jmp 	timer
exit:
	call 	clear_screen

	xor 	ax, ax
	mov 	al, old_mode
	int 	10h

	mov 	ax, 4C00h
	int 	21h
	ret
game endp

main:
	mov 	ax, @data
	mov 	ds, ax

 	call 	game
end	main
