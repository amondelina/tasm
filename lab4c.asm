
.model small
.stack 100h

.data 
	istring db 	100 dup(?)
	ostring db 	100 dup(?)
	buffer 	db 	256 dup(0)
	k 		dw 	256


.code 
input proc
	push 	ax
	push 	dx

	xor  	si, si

char_input:
	xor 	dx, dx
	mov 	ah, 8
	int 	21h

	cmp 	al, 13
	je 		input_exit

	cmp 	al, 10
	je 		input_exit

	mov 	istring[si], al
	inc 	si

	mov 	dl, al
	mov 	ah, 2
	int 	21h
	jmp 	char_input


input_exit:
	mov 	istring[si], '$'
	mov 	bx, si

	pop 	dx
	pop 	ax
	ret
input endp

output proc 
	push ax
	push bx

	xor 	ax, ax
	lea  	dx, ostring
	mov 	ah, 9
	int 	21h

	pop 	bx
	pop 	ax
	ret
output endp

counting_sort proc 
	push 	cx
	push 	ax
	push 	dx

	mov 	cx, bx				
	xor		ax, ax
	lea 	si, istring				
loop1:
	mov 	al, [si]
	mov 	di, ax		
	inc 	buffer[di]
	inc 	si
loop 	loop1

	mov 	cx, k
	dec 	cx
	xor		di, di
	lea 	si, ostring
loop3:
	cmp 	buffer[di], 0
	je 		zero
	loop4:
		xor 	dx, dx
		mov 	dx, di
		mov 	[si], byte ptr dl
		dec 	buffer[di]
		inc 	si
		jmp 	loop3
zero:
	inc 	di
	loop 	loop3

	mov 	ostring[bx], '$'

	pop 	dx
	pop 	cx
	pop 	ax
	ret
counting_sort endp
main:
	mov 	ax, @data
	mov 	ds, ax
	xor 	ax, ax

	call 	input
	call 	counting_sort
	call 	output


exit:
	mov 	ax, 4c00h
	int 	21h
end main