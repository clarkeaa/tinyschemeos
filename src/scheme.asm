%define SCHEME_TYPE_ERROR 0x0
%define SCHEME_TYPE_INT 0x1
%define SCHEME_TYPE_STRING 0x2
%define SCHEME_TYPE_LIST 0x3
%define SCHEME_TYPE_ATOM 0x4


;//////////////////////////////////////////////////////////////////////////////////////
	
scheme_repl:	
	mov si, scheme_prompt
	call os_print_string

	mov ax, .input_buffer
	call os_input_string
	mov si, ax	
	call os_print_newline
	
	call scheme_read
	cmp ax, 0x0
	jne scheme_repl
	
	call scheme_eval
	cmp ax, 0x0
	je scheme_repl
	
	call scheme_print
		
	jmp scheme_repl

	.input_buffer times 255 db 0
	
; -----------------------------------------------------
; IN: SI = location of sexp
; OUT: AX = 0 error code
scheme_read:
	pusha
	mov word [.answer], 0
	mov cx, 0
.loop:	
	lodsb

.loop_decide:
	cmp al, 0x0		;exit at null char
	je .exit
	cmp al, ' '		;ignore whitespace
	jb .loop		
	cmp al, '('		;start list
	je .read_list
	cmp al, ')'		;stray close paren
	je .paren_close
	cmp al, 0x22		;start string "
	je .read_string
	cmp al, '0'		;start atom
	jb .read_atom
	cmp al, '9'		;start number
	jbe .read_number
	jmp .read_atom		;start atom
		
;;; -----
.read_list:
	push 0x3000
	inc cx
	jmp .loop

;;; -----
.read_string:
	push 0x2000
	jmp .loop

;;; -----
.read_atom:
	push 0x4000
	jmp .loop

;;; -----
.read_number:
	push 0x1000
	mov di, .read_buffer	; start writing to read_buffer
.read_number_loop:
	stosb

	lodsb

	cmp al, '0'		; stop reading if not digit
	jb .read_number_end	
	cmp al, '9'		
	jg .read_number_end
	jmp .read_number_loop	

.read_number_end:
	mov dl, al		; store read character to dl
	mov al, 0		; add null to string
	stosb
	mov ax, .read_buffer
	call scheme_string_to_int ;ax = int, bx = err
	cmp bx, 0		; exit on error
	jne .read_error		
	push ax			; put number on stack
	mov al, dl		; restore read character
	jmp .loop_decide

;;; -----
.paren_close:
	dec cx
	jmp .loop


;;; -----
.read_error:
	mov word [.answer], 2
	jmp .exit_no_err
	
;;; -----
.exit:
	cmp cx, 0
	je .exit_no_err
	mov word [.answer], 1

.exit_no_err:
	popa
	mov ax, [.answer]	
	ret
	.answer dw 0
	.read_buffer times 255 db 0

; -----------------------------------------------------
; IN: none, reads off stack
; OUT: AX = result meta, BX = result
scheme_eval:	
	pusha
	popa
	ret

; -----------------------------------------------------
; IN: AX = result meta, BX = result
scheme_print:	
	pusha
	popa
	ret

; --------------------------------------------------
; IN: AX ptr to string
; OUT: AX number, BX err code
scheme_string_to_int:
	pusha
	mov word [.err_code], 0	;err_code = 0
	mov si, ax		;string to read from = ax
	call os_string_length	
	mov cx, ax		;cx = string length
	mov word [.answer], 0	;answer = 0

.loop:
	cmp cx, 0		;exit on last digit
	je .exit	
	lodsb
	sub al, '0'		;al = number of digit
	mov dl, al		;dl = number for digit
	mov dh, 0		
	mov bx, cx		;bx = count
	dec bx			;bx-=1
	mov ax, 10		;ax = 10
	call scheme_pow		;ax = 10^bx
	mul dx			;ax = number of digit * 10^loc
	mov bx, [.answer]
	add ax, bx
	mov [.answer], ax
	dec cx
	jmp .loop

.exit:
	popa
	mov ax, [.answer]
	mov bx, [.err_code]	;bx = err_code
	ret
	.answer dw 0
	.err_code dw 0

;;; --------------------------------------
;;; IN: ax number, bx power
;;; OUT: ax power
scheme_pow:
	pusha
	mov cx, ax
	mov ax, 1
.loop:	
	cmp bx, 0
	je .exit
	mul cx
	dec bx
	jmp .loop
	
.exit:
	mov [.answer], ax
	popa
	mov ax, [.answer]
	ret
	.answer dw 0
	
;//////////////////////////////////////////////////////////////////////////////////////
	
scheme_prompt db ">",0
scheme_error db "* unknown scheme error",0x0d,0x0a,0
scheme_paren_mismatch_error db "error: parameter mismatch",0x0d,0x0a,0
