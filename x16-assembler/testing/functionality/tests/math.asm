; *******************************************************************************************
;
;							Test assembly of address arithmetic
;
;	(Note: there is a fuller testing of the arithmetic in the Makefile, this is a 
;	 compatibilty test more than an accuracy test.)
;
; *******************************************************************************************

v1 = $1234
v2 = $ABCD

		* = $8000
start:
	lda 	#5+19
	lda 	#19-4
	lda 	#2*3
	lda 	#12/2
	lda 	#13/2
	lda 	#>v1
	lda 	#<v1
	lda 	#v2 >> 8
	lda 	#v2 & $FF
	lda 	#(2+3)*4
	lda 	#2+3*4
	lda 	#-4+44
end:		