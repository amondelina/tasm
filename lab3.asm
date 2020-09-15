
.model small
.stack 100h

.data
	a 	dw 	?
	b 	dw 	?
	sign 	dw	?
	one 	dw 	?
	error 	dw 	0


	base 	dw  10	

	buffer	db 7, 7 dup ('$')
	endline db 13, 10, '$'

	dividend_input	db	"Enter the dividend$"
	divider_input	db	"Enter the divider$"

	result_output 		db 	"The result:$"
	remainder_output 	db 	"The remainder:$"

	zero_error 	 db "Error: dividing by zero$"

.code
input proc 
	push 	bx
	push 	dx
	xor 	bx, bx
	xor 	cx, cx
	mov 	sign, 0
	mov 	one, 1

input_loop:
	mov 	ah, 8
	int 	21h
	cmp 	sign, 1
	je 		label6
	cmp 	cx, 0
	jne 	label6

	cmp 	al, '+'
	je 		plus1

	cmp 	al, '-'
	je 		minus1
label6:
	cmp 	cx, 0
	jz 		label4

	cmp 	al, 13
	je 		enterr1	
label4:
	cmp 	al, 8
	je 		backspace1

	cmp 	al, 27
	je 		escape1

	cmp 	al, '0'
	jne 	label5
	cmp 	cx, 0
	je 		zeroo1

label5:
	call 	check_symbol
	cmp 	error, 666
	je 		input_loop
label1:
	push 	bx
	push 	ax

	xor 	ah, ah
	xor 	dx, dx

	sub		al, '0'
	imul 	one

	xchg 	ax, bx
	imul 	base
	;jc 		big
	jo		big
	add 	bx, ax
	;jc 		big
	jo		big
	cmp 	one, 1
	jne 	cmp_neg

	test	bx, 1000000000000000b
	jnz 	big
	cmp 	dx, 0
	jne		big
	jmp 	label3
cmp_neg:
	cmp 	dx, 0
	je 		label3 	
	cmp 	dx, 1111111111111111b
	jne 	big

label3:
	pop 	dx
	mov 	ah, 2
	int 	21h
	inc 	cx
	pop 	ax
	
	jmp 	input_loop

zeroo1:
	jmp 	zeroo
minus1:
	jmp 	minus
plus1:
	jmp 	plus
backspace1:
	jmp 	backspace
escape1:
	add 	cx, sign
	jmp 	escape
enterr1:
	jmp 	enterr
big:
	pop 	dx
	pop 	bx
	jmp 	input_loop

minus:
	mov 	dl, '-'
	mov 	one, -1
	jmp 	label7
plus:
	mov 	dl, '+'
label7:
	mov 	ah, 2
	int 	21h
	mov 	sign, 1
	jmp 	input_loop


zeroo:
	inc 	cx
	mov 	dl, al
	mov 	ah, 2
	int 	21h

label2:
	mov 	ah, 8
	int 	21h

	cmp 	al, 13
	je 		enterr	

	cmp 	al, 8
	je 		backspace

	cmp 	al, 27
	je 		escape

	jmp 	label2

backspace:
	mov 	dl, 8
	mov 	ah, 2
	int 	21h
	mov 	ah, 2
	mov 	dl, ' '
	int 	21h
	xor 	dx, dx 
	mov 	ax, bx
	div 	base
	mov 	bx, ax
	call 	delete_char
	cmp 	cx, 0
	je 		sign_delete
	dec 	cx
	jmp 	input_loop
sign_delete:
	mov 	sign, 0
	mov  	one, 1
	jmp 	input_loop

escape:
	call 	delete_char
	loop 	escape

	xor 	bx, bx
	xor 	cx, cx
	mov 	sign, 0
	jmp 	input_loop

enterr:
	mov 	ax, bx

input_exit:
	pop 	dx
	pop 	bx
	ret
input endp

delete_char proc near
	push 	ax
	push 	dx
	xor 	ax, ax
	xor 	dx, dx
	mov 	ah, 2
	mov 	dl, 8
	int 	21h
	mov 	dl, ' '
	int 	21h
	mov 	dl, 8
	int 	21h
	pop 	dx
	pop 	ax
	ret
delete_char endp

check_symbol proc
	mov 	error, 0

	cmp 	al, '0'
	jb 		error_symbol

	cmp 	al, '9'
	ja 		error_symbol

	ret

error_symbol:
	mov 	error, 666
	ret
check_symbol endp
print_str proc 
	push 	ax

	mov 	ah, 9
	int 	21h

	call 	clean_buffer
	pop 	ax
	ret
print_str endp 

print_endline proc 
	lea 	dx, endline
	call	print_str
	ret
print_endline endp
clean_buffer proc 
	push 	di
	push 	cx
	xor 	cx, cx

	lea 	di, buffer
	mov 	byte ptr [di], 7
	inc 	di
	mov 	cx, 6

looop:
	mov 	byte ptr [di], '$'
	inc 	di
	loop 	looop

	pop 	cx
	pop 	di
	ret
clean_buffer endp
num_to_str proc 
	push 	dx
	xor 	cx,cx	

	call 	clean_buffer
	lea 	di, buffer
	test 	ax, ax
	jns 	.loop1
	mov 	byte ptr [di], '-'
	inc 	di
	neg 	ax

.loop1:	
	xor 	dx,dx       
	div 	base		
	push 	dx		
	inc 	cx		
	cmp 	ax, 0	
	jnz 	.loop1	

.loop2:		
	pop 	ax		
	add 	al,'0'	
	mov 	[di], al
	inc 	di			
	loop 	.loop2		
		
	pop 	dx
	ret
num_to_str endp

main:
	mov 	ax, @data
	mov 	ds, ax
	xor 	ax, ax

	lea 	dx, dividend_input
	xor 	ax, ax
	call 	print_str
	call 	print_endline

	xor 	cx, cx
	call 	input
	mov 	a, ax
	call 	print_endline

	mov 	bx, ax

	lea 	dx, divider_input
	call 	print_str
	call 	print_endline

	xor 	cx, cx
	call 	input
	mov 	b, ax
	call 	print_endline

	cmp 	b, 0
	je 		zero

	mov 	ax, a
	cwd
	idiv 	b
	mov 	bx, dx

	cmp 	dx, 0
	je 		output

	mov 	dx, a
	test 	dx, dx
	jns 	output

	mov 	dx, b
	test 	dx, dx
	js 		neg_b
	dec 	ax
	add		bx, b
	jmp 	output

neg_b:
	neg 	b
	inc 	ax
	add		bx, b

output:
	lea 	dx, result_output
	call 	print_str
	call 	print_endline
	call 	num_to_str
	lea 	dx, buffer
	call 	print_str
	call 	print_endline

	lea 	dx, remainder_output
	call 	print_str
	call 	print_endline
	mov 	ax, bx
	call 	num_to_str
	lea 	dx, buffer
	call 	print_str

	jmp 	exit

zero: 
	lea 	dx, zero_error
	call 	print_str

exit:
	mov 	ax, 4c00h
	int 	21h
end main

	

