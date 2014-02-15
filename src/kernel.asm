	BITS 16

	; This is the location in RAM for kernel disk operations, 24K
	; after the point where the kernel has loaded; it's 8K in size,
	; because external programs load after it at the 32K point:

	disk_buffer	equ	24576

;//////////////////////////////////////////////////////////////////////////////////////
os_main:
	cli				; Clear interrupts
	mov ax, 0
	mov ss, ax			; Set stack segment and pointer
	mov sp, 0FFFFh
	sti				; Restore interrupts

	cld				; The default direction for string operations
					; will be 'up' - incrementing address in RAM

	mov ax, 2000h			; Set all segments to match where kernel is loaded
	mov ds, ax			; After this, we don't need to bother with
	mov es, ax			; segments ever again, as MikeOS and its programs
	mov fs, ax			; live entirely in 64K
	mov gs, ax

;//////////////////////////////////////////////////////////////////////////////////////
	
	mov si, msg
	call os_print_string

repl:	
	mov si, prompt
	call os_print_string

	mov ax, .input_buffer
	call os_input_string
	mov si, ax	
	call os_print_newline
	
	call scheme_read
	cmp ax, 0x0
	je repl
	
	call scheme_eval
	cmp ax, 0x0
	je repl
	
	call scheme_print
		
	jmp repl

	.input_buffer times 255 db 0
;//////////////////////////////////////////////////////////////////////////////////////

%define SCHEME_TYPE_ERROR 0x0
%define SCHEME_TYPE_INT 0x1
%define SCHEME_TYPE_STRING 0x2
%define SCHEME_TYPE_LIST 0x3
	
; -----------------------------------------------------
; IN: SI = location of sexp
; OUT: AX = 0 on error, otherwise we are good
scheme_read:
	pusha
	mov ax, 0
	mov cx, 0
.loop:	
	lodsb

	cmp ax, 0x0
	je .check_parens	
	cmp ax, '('
	je .open_paren
	cmp ax, ')'
	je .close_paren

	jmp .loop
	
.open_paren:
	inc cx
	jmp .loop
.close_paren:
	dec cx
	jmp .loop

.check_parens:
	mov word [.answer], 1
	cmp cx, 0
	je .exit

	mov word [.answer], 0
	mov si, paren_mismatch_error
	call os_print_string
.exit:	
	popa
	mov ax, [.answer]	
	ret
	.answer dw 0

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
	
;//////////////////////////////////////////////////////////////////////////////////////
	%include "mikeos.asm"
	%include "disk.asm"
	
;//////////////////////////////////////////////////////////////////////////////////////

msg db "welcome to tinyschemeos",0x0d, 0x0a, 0	
prompt db ">",0
scheme_error db "* unknown scheme error",0x0d,0x0a,0
paren_mismatch_error db "error: parameter mismatch",0x0d,0x0a,0
