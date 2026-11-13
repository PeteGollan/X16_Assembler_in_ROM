; *******************************************************************************************
;
;							Test assembly of address values/branches
;
; *******************************************************************************************

v1 = $1234
v2 = $ABCD

		* = $8000
start:
		adc 	start
		sta 	end
		lda 	v1
		jmp 	v2
		bcc 	end
		.word 	start
another_label		
		bra 	another_label
		beq 	start
		bra 	*
		bra 	*-2
		bra 	*+2
end:		