.model small
.stack 100h

.data
	dividend_input	db	"Enter the dividend$"
	divider_input	db	"Enter the divider$"

	result_output 		db 	"The result:$"
	remainder_output 	db 	"The remainder:$"

	buffer	db 7, 7 dup ('$')
 	endline db 13, 10, '$'

	zero_error 	 db "Error: dividing by zero$"

	base 	dw	10
	error 	dw 	0

.code

input proc 
	push 	bx
	push 	dx
	xor 	bx, bx
	xor 	cx, cx

input_loop:
	mov 	ah, 8
	int 	21h

	cmp 	al, 8
	je 		backspace

	cmp 	al, 27
	je 		escape

	cmp 	al, 13
	je 		enterr	

	call 	check_symbol
	cmp 	error, 666
	je 		input_loop

	cmp 	al, '0'
	jne 	label1
	cmp 	cx, 0
	je 		zeroo

label1:
	push 	bx
	push 	ax

	xor 	ah, ah
	xor 	dx, dx

	sub		al, '0'
	xchg 	ax, bx
	mul 	base
	add 	bx, ax
	jc		big
	cmp 	dx, 0
	jne 	big

	pop 	dx
	mov 	ah, 2
	int 	21h
	inc 	cx
	pop 	ax
	
	jmp 	input_loop

big:
	pop 	dx
	pop 	bx
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
	dec 	cx

	jmp 	input_loop

escape:
	mov 	cx, 7
escape_loop:
	call 	delete_char
	loop 	escape_loop

	xor 	bx, bx
	xor 	cx, cx
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

num_to_str proc 
	push 	dx
	push 	bx

	mov 	bx, 10	
	xor 	cx,cx	

	call 	clean_buffer
	lea 	di, buffer

loop1:	
	xor 	dx,dx       
	div 	bx		
	push 	dx		
	inc 	cx		
	cmp 	ax, 0	
	jnz 	loop1	

loop2:		
	pop 	ax		
	add 	al,'0'	
	mov 	[di], al
	inc 	di			
	loop 	loop2		
		
	pop 	bx
	pop 	dx
	ret
num_to_str endp

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
	call 	print_endline
	mov 	bx, ax

	lea 	dx, divider_input
	call 	print_str
	call 	print_endline

	xor 	cx, cx
	call 	input
	call 	print_endline

	cmp 	ax, 0
	je 		zero

	xchg	ax, bx
	xor 	dx, dx
	div 	bx
	mov 	bx, dx

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

	

