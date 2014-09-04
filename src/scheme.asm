%define SCHEME_TYPE_ERROR 0x0
%define SCHEME_TYPE_INT 0x1
%define SCHEME_TYPE_STRING 0x2
%define SCHEME_TYPE_LIST 0x3
%define SCHEME_TYPE_ATOM 0x4

%define SCHEME_CODE_STACK_START 0x1000	

;//////////////////////////////////////////////////////////////////////////////////////

scheme_prompt db ">",0
scheme_error db "* unknown scheme error",0x0d,0x0a,0
scheme_paren_mismatch_error db "error: parameter mismatch",0x0d,0x0a,0
scheme_code_sp dw SCHEME_CODE_STACK_START

%macro scheme_debug_4hex 2
	pusha
	mov si, %%msg
	call os_print_string
	mov ax, %2
	call os_print_4hex
	call os_print_newline	
	popa
	jmp %%exit
	%%msg db %1,0
%%exit:	
%endmacro

%macro scheme_debug_mem 1
	pusha
	mov si, %%prefix
	call os_print_string
	mov ax, %1
	call os_print_4hex
	mov si, %%colon
	call os_print_string
	mov ax, [%1]
	call os_print_4hex
	call os_print_newline	
	popa
	jmp %%exit
	%%prefix db "0x",0
	%%colon db ":",0
%%exit:	
%endmacro
        
;;; -------------------------------
;;; IN AX - word to push
_scheme_push_word:	
	pusha
	mov bx, [scheme_code_sp] 	;get address
	mov [bx], ax			;write to address
	add bx, 2
	mov word [scheme_code_sp], bx	
	popa
	ret

%macro scheme_push_word 1
  pusha        
	mov ax, %1
	call _scheme_push_word
  popa
%endmacro

;;; -------------------------------
;;; OUT AX - word removed from stack
scheme_pop_word:	
	pusha
	mov bx, [scheme_code_sp]
	sub bx, 2
	mov ax, [bx]
	mov [.answer], ax
	mov word [scheme_code_sp], bx
	popa
	mov ax, [.answer]
	ret
	.answer dw 0
	
;//////////////////////////////////////////////////////////////////////////////////////
	
scheme_repl:		
	mov word [scheme_code_sp], SCHEME_CODE_STACK_START ;reset code sp
	
	mov si, scheme_prompt           ;print prompt
	call os_print_string

	mov ax, .input_buffer		; input sexp
	call os_input_string
	mov si, ax	
	call os_print_newline
	
	call scheme_read		; read
	cmp ax, 0x0
	jne scheme_repl

	mov ax, SCHEME_CODE_STACK_START ; eval
	call scheme_eval
	cmp ax, 0x0
	jne scheme_repl

	mov ax, SCHEME_CODE_STACK_START ;print
	call scheme_print
	
	jmp scheme_repl			; repeat

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
	scheme_push_word SCHEME_TYPE_LIST
	inc cx
	jmp .loop

;;; -----
.read_string:
	scheme_push_word SCHEME_TYPE_STRING
	jmp .loop

;;; -----
.read_atom:
	scheme_push_word SCHEME_TYPE_ATOM
	jmp .loop

;;; -----
.read_number:
	scheme_push_word SCHEME_TYPE_INT
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
	scheme_push_word ax	; put number on stack
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
; IN: AX = location in memory to eval
; OUT: AX = err code
scheme_eval:	
	pusha
  mov bx, ax
  scheme_debug_4hex "stack start:", SCHEME_CODE_STACK_START
  scheme_debug_4hex "stack ptr:", bx
  scheme_debug_4hex "stack sp:", [scheme_code_sp]
  cmp bx, scheme_code_sp
  je .return
.loop:        
  scheme_debug_mem bx
  add bx, 2
	cmp bx, [scheme_code_sp]
	jl .loop
.return:
	popa
	mov ax, 0x0
	ret
  

; -----------------------------------------------------
; IN: AX = memory location of value
scheme_print:	
	pusha	

	mov bx, ax		;bx = meta address
	mov ax, [bx]		;deref bx

	cmp ax, SCHEME_TYPE_ERROR
	je .exit
	cmp ax, SCHEME_TYPE_INT
	je .print_int
	cmp ax, SCHEME_TYPE_STRING
	je .print_string
	cmp ax, SCHEME_TYPE_LIST
	je .print_list
	jmp .exit
	
.print_int:		
	mov ax, [bx+2]
	call os_print_4hex
	jmp .exit
.print_string:
	jmp .exit
.print_list:
	jmp .exit
.exit:
	call os_print_newline
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
	mov dl, al		;dx = number for digit
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
	
