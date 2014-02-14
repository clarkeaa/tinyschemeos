	BITS 16

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

loop:
	jmp loop

;//////////////////////////////////////////////////////////////////////////////////////
os_print_string:
	pusha
	mov ah, 0x0e			; int 10h teletype function
.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string
	int 0x10			; Otherwise, print it
	jmp .repeat			; And move on to next char
.done:
	popa
	ret
	
;//////////////////////////////////////////////////////////////////////////////////////

msg db "hello world!",0x0d, 0x0a, 0	

