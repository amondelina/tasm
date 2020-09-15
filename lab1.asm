.model small
.stack 100h

	.data 
	a	dw	3
	b	dw	4
	c	dw	7
	d 	dw	1

.code
main:
	mov		ax, @data
	mov 	ds, ax

	mov 	ax, a
	add 	ax, b
	jc 		else1

	mov		bx, c
	or 		bx, d

	cmp 	ax, bx
	jne		else1

true1:
	mov		bx, c
	xor 	bx, d

	and 	ax, bx

	jmp		exit

else1:
	mov		ax, b
	xor 	ax, c

	mov 	bx, a
	or 		bx, d

	cmp 	ax, bx
	jne 	else2

true2:
	mov		ax, b
	xor 	ax, c

	mov 	bx, a
	or 		bx, d

	and 	ax, bx

	jmp 	exit

else2:
	mov 	ax, a
	xor 	ax, b

	mov 	bx, c
	xor 	bx, d

	or 		ax, bx

exit:
	mov 	ah, 04Ch
	mov 	al, 0
	int		21h
end	main


