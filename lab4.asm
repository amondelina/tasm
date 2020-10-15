
.model small
.stack 100h

.data 
	string 	db 	100 dup(?)

.code 
input proc near
	push 	ax
	push 	dx

	lea 	bx, string
	xor  	si, si

char_input:
	xor 	dx, dx
	mov 	ah, 8
	int 	21h

	cmp 	al, 13
	je 		input_exit

	cmp 	al, 10
	je 		input_exit

	mov 	string[si], al
	inc 	si

	;mov 	dl, al
	;mov 	ah, 2
	;int 	21h
	jmp 	char_input


input_exit:
	mov 	string[si], '$'
	dec 	si
	mov 	bx, si

	pop 	dx
	pop 	ax
	ret
input endp

output proc 
	push 	ax
	push 	dx

	xor 	ax, ax
	xor 	dx, dx
	lea  	dx, string
	mov 	ah, 9
	int 	21h

	pop 	dx
	pop 	ax
	ret
output endp
swap proc 
	push	ax

	lea 	bx, string
	mov 	al, string[si]
	mov 	ah, string[di]
	mov 	string[si], ah
	mov 	string[di], al

	pop 	ax
	ret
swap endp
partition proc
	push 	cx
	push 	dx

	mov 	di, ax
	dec 	di
	mov		cx, bx
	sub 	cx, ax
	mov 	si, bx

	xor 	bx, bx
	lea 	bx, string
	
	mov 	dl, string[si]
	mov 	si, di
	jmp 	partition_loop
part:
	dec  	cx
	cmp 	cx, 0
	je 		part_exit
partition_loop:
	inc 	di
	cmp 	string[di], dl
	ja 		part
	inc 	si
	call 	swap
	loop 	partition_loop
part_exit:
	inc 	si
	inc 	di
	call 	swap
	mov 	bx, si

	pop 	dx
	pop 	cx
	ret
partition endp

quick_sort proc 	
	push 	ax
	push 	bx

	cmp 	bx, -1
	je 		sort_exit
	cmp 	ax, bx
	jnb 	sort_exit
	push 	bx
	call 	partition
	dec 	bx
	call	quick_sort
	mov 	ax, bx
	add 	ax, 2
	pop 	bx
	call 	quick_sort  	

sort_exit:
	pop 	bx
	pop 	ax
	ret
quick_sort endp

main:
	mov 	ax, @data
	mov 	ds, ax
	xor 	ax, ax

	call 	input
	call 	quick_sort
	call 	output

exit:
	mov 	ax, 4c00h
	int 	21h
end main