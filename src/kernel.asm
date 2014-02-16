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

	call test_all
	call scheme_repl
	jmp $
	
;//////////////////////////////////////////////////////////////////////////////////////
	%include "mikeos.asm"
	%include "disk.asm"
	%include "scheme.asm"
	%include "test.asm"

msg db "welcome to tinyschemeos",0x0d, 0x0a, 0	
