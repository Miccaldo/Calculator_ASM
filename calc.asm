; Author: Miccaldo
; Created: 17.05.2019

data SEGMENT
	calculatorTxt db "         *** CALCULATOR *** ", 0, "$" 
	infoTxt db " Input: A+B (max 2B) ", 0, "$" 
	funcTxt db " Functions: +, -, *, /, ^, #(root 2 deg.) ", 0, "$" 
	endInfoTxt db " End program - k ", 0, "$" 
	endTxt db " End program", 0, "$" 
	separatorTxt db " ----- ", 0, "$" 
	
	counter dw 0
	floating dw 0
	value db 11 dup (?)
	valueConvert dw 0
	valueBuf dw 0
	dividerPrint dw 10
	enterSign db 13
	multipleCnt db 0
	
	valueAdd_1 dw 0
	valueAdd_2 dw 0
	
	valueSub_1 dw 0
	valueSub_2 dw 0
	
	valueMul dw 0
	multiplier dw 0
	
	valueDiv dw 0
	divider dw 0
	
	valuePow dw 0
	powIndex db 0
	powBuf dw 0	
	
	valueRoot dw 0
	rootDeg db 2
	rootBuf dw 0
	rootEstimate dw 0
	rootDigits dw 0
	rootSteps db 20
		
	a dw 0
	b dw 0
	a_cnt dw 0
	b_cnt dw 0
	_b db 0
	
	operator db 0
	operator_buf db 6 dup (?)
	operatorVal db 0
	operatorCnt db 0
	
	si_buf dw 0
	
	plusSign db 43	; +
	minusSign db 45	; -
	mulSign db 42	; *
	divSign db 47	; /
	powSign db 94	; ^
	rootSign db 35 	; #	(root 2 deg.)
	
	splitCnt dw 0
	
	result dw 0
	digits db 5 dup (?)
	digitCnt db 0
	convertCnt db 0
	
	connectValCnt db 0
	printValCnt db 0
	multiplierConvert dw 0
	mov si, 0
	
data ENDS


order SEGMENT
ASSUME cs:order, ds:data	
	
	INIT PROC near				; Initialize function
		mov ax, SEG data
		mov ds, ax 
		
		mov dl, plusSign
		mov operator_buf[0],dl 
		mov dl, minusSign
		mov operator_buf[1],dl 
		mov dl, mulSign
		mov operator_buf[2],dl 
		mov dl, divSign
		mov operator_buf[3],dl 
		mov dl, powSign
		mov operator_buf[4],dl
		mov dl, rootSign	
		mov operator_buf[5],dl
	INIT ENDP
		
	MAIN PROC near
		mov ax, 0
		call PRINT_START
		jmp READ				
		jmp END_PROGRAM
	MAIN ENDP
	
	
	READ PROC near				; Read input data
		mov ah, 01h
		int 21h
		cmp al, 'k'
		je END_PROGRAM
		cmp al, enterSign		; If you press enter, go next
		je SPLIT
				
		mov ah, 0				
	
		cmp al, plusSign
		je GO_NEXT
		cmp al, minusSign
		je GO_NEXT
		cmp al, mulSign
		je GO_NEXT
		cmp al, divSign
		je GO_NEXT
		cmp al, powSign
		je GO_NEXT
		cmp al, rootSign
		je GO_NEXT
		
		sub ax, 48	
		GO_NEXT:
		
		mov value[si], al
		inc si
		
		jmp READ
	READ ENDP
	
	
	SPLIT PROC near				; Function is splitting two input values between operator
		mov dx, 0
		mov dx, si
		mov counter, dx
		mov cl, dl
		mov dl, cl
		mov si, 0
		mov operatorCnt, 0
		
		splitLoop_val_a:		; Add digits while to moment when not will be operator
			mov dl, plusSign
			cmp value[si], dl
			je _PLUS
			mov dl, minusSign
			cmp value[si], dl
			je _MINUS
			mov dl, mulSign
			cmp value[si], dl
			je _MUL
			mov dl, divSign
			cmp value[si], dl
			je _DIV
			mov dl, powSign
			cmp value[si], dl
			je _POW
			mov dl, rootSign
			cmp value[si], dl
			je _ROOT
			
			mov dl, value[si]
			mov digits[si], dl		
			inc si
		loop splitLoop_val_a
		
		BACK_OPERATOR:
		
		mov a_cnt, si
		mov dx, a_cnt
		mov ah, 0
		
		mov convertCnt, dl
		call CONVERT_TO_INTEGER
		mov dx, valueConvert
		mov a, dx
		
		mov dx, a_cnt
		mov si, dx
		inc si
		sub counter, 1		
		mov dl,convertCnt 
		sub counter, dx
		mov dx, cx
		mov si_buf, si
		mov dx, si
		mov dx, 0
		
		splitLoop_val_b:		; Add other digits to second array
			mov dx, si_buf
			mov si, dx
			mov dl, value[si]
			mov _b, dl	
			mov dx, splitCnt
			mov si, dx
			mov dl, _b
			mov digits[si], dl
			mov dx, si_buf
			mov si, dx
			add splitCnt, 1
			inc si
			mov dx, si
			mov si_buf, dx
			mov dx, counter
			cmp splitCnt, dx
		jb splitLoop_val_b		
			
		mov dx, splitCnt
		mov b_cnt, dx
		
		mov dh, 0
		mov dx, b_cnt
		mov convertCnt, dl
		mov dl, convertCnt
		
		call CONVERT_TO_INTEGER
		mov dx, valueConvert
		mov b, dx
		
		jmp CALCULATOR
	
	SPLIT ENDP
	
	_PLUS:
		mov operator, '+'
		jmp BACK_OPERATOR
	_MINUS:
		mov operator, '-'
		jmp BACK_OPERATOR
	_MUL:
		mov operator, '*'
		jmp BACK_OPERATOR
	_DIV:
		mov operator, '/'
		jmp BACK_OPERATOR
	_POW:
		mov operator, '^'
		jmp BACK_OPERATOR
	_ROOT:
		mov operator, '#'
		jmp BACK_OPERATOR
	
	
	CALCULATOR PROC near		; Performs basic arithmetic operations
		
		mov dl, plusSign
		cmp operator, dl
		je CALC_ADD
		
		mov dl, minusSign
		cmp operator, dl
		je CALC_SUB
		
		mov dl, mulSign
		cmp operator, dl
		je CALC_MUL
		
		mov dl, divSign
		cmp operator, dl
		je CALC_DIV
		
		mov dl, powSign
		cmp operator, dl
		je CALC_POW
		
		mov dl, rootSign
		cmp operator, dl
		je CALC_ROOT
		
		CALC_BACK:
		
		call WRITE_RESULT
		
		jmp READ
	CALCULATOR ENDP
	
	
	CALC_ADD PROC near
		mov dx, a
		mov valueAdd_1, dx
		mov dx, b
		mov valueAdd_2, dx
		call ADDITION
		jmp CALC_BACK
	CALC_ADD ENDP
	
	CALC_SUB PROC near
		mov dx, a
		mov valueSub_1, dx
		mov dx, b
		mov valueSub_2, dx
		call SUBTRACTION
		jmp CALC_BACK
	CALC_SUB ENDP
	
	CALC_MUL PROC near
		mov dx, a
		mov valueMul, dx
		mov dx, b
		mov multiplier, dx
		call MULTIPLICATION
		jmp CALC_BACK
	CALC_MUL ENDP
	
	CALC_DIV PROC near
		mov dx, a
		mov valueDiv, dx
		mov dx, b
		mov divider, dx
		call DIVISION
		jmp CALC_BACK
	CALC_DIV ENDP
	
	CALC_POW PROC near
		mov dx, a
		mov valuePow, dx
		mov dx, b
		mov powIndex, dl
		call POWER
		jmp CALC_BACK
	CALC_POW ENDP
	
	CALC_ROOT PROC near
		mov dx, a
		mov valueRoot, dx
		mov dx, b
		mov rootDeg, dl
		call ROOT
		jmp CALC_BACK
	CALC_ROOT ENDP
	
	
	WRITE_RESULT PROC near
		mov dl, ' '
		sub dl, 48
		call PRINT
		mov dl, '='
		sub dl, 48
		call PRINT
		mov dx, result
		call PRINT_VALUE
		call ENDL
		mov dx, offset separatorTxt 
		call PRINT_TXT
		call ENDL
		mov dl, ' '
		sub dl, 48
		call PRINT
			
		mov si, 0		; musi byc
		mov splitCnt, 0	
		ret		
	WRITE_RESULT ENDP
		
		
	DIGITS_VALUE:			; Calculate count of input digits
		cmp dx, 9
		ja moreThan10		
		jmp lessThan10		
		backLessThan10:
		backLessThan100:
		backLessThan1000:
		backLessThan10000:
		backLessThan65535:
		ret
		
		lessThan10:				
			mov digitCnt, 1		
			jmp backLessThan10
		moreThan10:
			cmp dx, 99
			ja moreThan100
			jmp lessThan100		
		lessThan100:
			mov digitCnt, 2
			jmp backLessThan100
		moreThan100:
			cmp dx, 999
			ja moreThan1000
			jmp lessThan1000		
		lessThan1000:
			mov digitCnt, 3
			jmp backLessThan1000
		moreThan1000:
			cmp dx, 9999
			ja moreThan10000
			jmp lessThan10000		
		lessThan10000:
			mov digitCnt, 4
			jmp backLessThan10000
		moreThan10000:
			cmp dx, 65535 
			ja moreThan65535
			jmp lessThan65535		
		lessThan65535:
			mov digitCnt, 5
			jmp backLessThan65535
		moreThan65535:
			jmp END_PROGRAM

	PRINT_VALUE PROC near			; Print full value
		mov valueBuf, dx	
		call DIGITS_VALUE
		mov cl, digitCnt    
		
		divLoop:					
			mov ax, valueBuf
			mov dx, 0
			mov bx, dividerPrint
			div bx		
			mov floating, dx
			mov valueBuf, ax
			
			mov dx, floating
			push dx					
			mov ax, 0				
		loop divLoop
		
		mov cl, digitCnt		
		reverseLoop:				
			pop dx
			
			cmp cl, digitCnt		
			call PRINT			
		loop reverseLoop
		
		mov ax, 0
		mov valueBuf, 0	
		ret
	PRINT_VALUE ENDP
		
		
	ADDITION PROC near		
		mov dx, valueAdd_1
		add valueAdd_2, dx
		mov dx, valueAdd_2
		mov result, dx
		ret
	ADDITION ENDP
	
	SUBTRACTION PROC near		
		mov dx, valueSub_1
		sub dx, valueSub_2
		mov result, dx
		ret
	SUBTRACTION ENDP
	
	MULTIPLICATION PROC near		
		mov ax, multiplier
		mov cx, valueMul
		mul cx
		mov result, ax
		ret
	MULTIPLICATION ENDP
	
	DIVISION PROC near		
		mov ax, valueDiv
		mov dx, 0
		mov bx, divider
		div bx		
		mov result, ax
		mov dx, 0
		mov ax, 0
		ret
	DIVISION ENDP
	
	POWER PROC near
		cmp powIndex, 0
		je POW_ZERO
		cmp powIndex, 1
		je FIRST_POW		
		sub powIndex, 1
		mov cl, powIndex
		mov dx, valuePow
		mov powBuf, dx
		powerLoop:
			mov ax, powBuf
			mov bx, valuePow
			mul bx
			mov valuePow, ax
		loop powerLoop
		
		FIRST_POW:			
		mov dx, valuePow
		mov result, dx
		BACK_POW_ZERO:
		ret
	POWER ENDP
	
	POW_ZERO PROC near
		mov result, 1
		jmp BACK_POW_ZERO
	POW_ZERO ENDP
		
		
	ROOT PROC near				; Calculate root by Babylonian method
		mov dx, valueRoot
		call DIGITS_VALUE
		mov dl, digitCnt
		mov dh, 0
		mov rootDigits, dx		
		
		mov valuePow, 10		
		mov dl, rootDeg
		mov powIndex, dl		
		
		call POWER				
		
		mov dx, result			
		mov valueMul, dx
		mov dx, rootDigits
		mov multiplier, dx
		call MULTIPLICATION
		
		mov dx, result			
		mov rootBuf, dx			
		
		mov cl, rootSteps				
		rootLoop:	
			mov dx, valueRoot			
			mov valueDiv, dx
			mov dx, rootBuf
			mov divider, dx
			
			call DIVISION
			
			mov dx, result			
			mov valueAdd_1, dx
			mov dx, rootBuf
			mov valueAdd_2, dx		
			
			call ADDITION
			
			mov dx, result			
			mov valueDiv, dx
			mov divider, 2
			call DIVISION
			
			mov dx, result
			mov rootBuf, dx
		loop rootLoop
		
		mov dx, rootBuf
		mov result, dx
		ret	
	ROOT ENDP

				
	CONVERT_TO_INTEGER PROC near		; Convert from array to one integer value
		mov cl, convertCnt
		mov si, 0
		mov ax, 0
		mov dx, 0
		mov valueConvert, 0
			
		mov dl, convertCnt
		mov connectValCnt, dl
		mov multipleCnt, dl
		mov printValCnt, dl
		
		connectValLoop:
			
			cmp connectValCnt, 1		
			je ONE_DIGIT
				
			mov ax, 10			
			mov cx, 10
			backOneDigit:
			
			mov dl, connectValCnt	
			mov multipleCnt, dl		
			sub multipleCnt, 2		
			
			multiplierLoop:
				cmp multipleCnt, 0 
				jle outMultiplerLoop	
				mul cx
				sub multipleCnt, 1
				cmp multipleCnt, 0
			jnbe multiplierLoop
			
			outMultiplerLoop:
			
			mov dx, ax
			mov multiplierConvert, dx
			mov dx, multiplierConvert
			
			mov dx, 0
			mov dl, digits[si]
			cmp digits[si], 9
			
			mov ax, multiplierConvert
			mov cx, dx
			mul cx
			add valueConvert, ax
			mov dx, valueConvert

			inc si
			
			sub connectValCnt, 1			
			cmp connectValCnt, 0
			jne connectValLoop					
		ret
	CONVERT_TO_INTEGER ENDP
		
	ONE_DIGIT PROC near
		mov ax, 1	
		mov cx, 1
		jmp backOneDigit
	ONE_DIGIT ENDP
		
	
	PRINT PROC near
		add dl, 48
		mov ah, 02h
		int 21h	
		mov ax, 0
		ret
	PRINT ENDP
		
	PRINT_TXT PROC near
		mov ah, 09h
		int 21h 
		mov ax, 0
		ret
	PRINT_TXT ENDP
		
	PRINT_START PROC near				; Print start text
		call ENDL
		mov dx, offset calculatorTxt 
		call PRINT_TXT
		call ENDL
		call ENDL
		mov dx, offset infoTxt 
		call PRINT_TXT
		call ENDL
		mov dx, offset funcTxt 
		call PRINT_TXT
		call ENDL
		mov dx, offset endInfoTxt 
		call PRINT_TXT
		call ENDL
		call ENDL
		mov dl, ' '
		sub dl, 48
		call PRINT
		ret
	PRINT_START ENDP
				
	ENDL PROC near
		mov dl, 10
		mov ah, 02h
		int 21h	
		mov ax, 0
		ret
	ENDL ENDP
		
	END_PROGRAM PROC near
		call ENDL
		call ENDL
		mov dx, offset endTxt 
		call PRINT_TXT
		mov ah, 4Ch
		int 21h  
	END_PROGRAM ENDP
		
order ENDS 

appStack SEGMENT stack 		; Stack segment
	dw 128 dup (?)
appStack ENDS


		
END INIT