test_all:
	call test_scheme_pow
	call test_scheme_string_to_int
	call test_scheme_push_pop_word
	ret	

%macro assert_int_equal 2
	pusha

	mov cx, %1
	mov dx, %2

	cmp cx, dx
	je %%cont

	mov ax, __LINE__
	call os_print_4hex
	
	mov si, test_actual_msg
	call os_print_string
	mov ax, dx
	call os_print_4hex	

	mov si, test_expected_msg
	call os_print_string
	mov ax, cx
	call os_print_4hex
	call os_print_newline

	jmp $
	
        %%cont:
	mov si, test_succeeded
	call os_print_string
	popa
%endmacro	
	
;;; -------------------------------------------------------------
test_scheme_string_to_int:
%macro assert_scheme_string_to_int 2
	mov si, test_actual_msg
	call os_print_string
	mov ax, %%input
	call scheme_string_to_int
	mov cx, ax
	call os_print_4hex
	mov si, test_expected_msg
	call os_print_string
	mov ax, %2
	call os_print_4hex
	call os_print_newline
	cmp ax, cx
	je %%cont
	jmp $
	%%input db %1,0
        %%cont:	
%endmacro
	pusha
	mov si, .title
	call os_print_string
	
	assert_scheme_string_to_int "1", 1
	assert_scheme_string_to_int "2", 2
	assert_scheme_string_to_int "16", 16
	assert_scheme_string_to_int "32", 32
	assert_scheme_string_to_int "256", 256
	assert_scheme_string_to_int "512", 512
	assert_scheme_string_to_int "0", 0
	assert_scheme_string_to_int "1234", 1234
	
	popa
	ret
	.title db "testing scheme_string_to_int",0x0d, 0x0a,0
	
;;; -------------------------------------------------------------
test_scheme_pow:
%macro assert_scheme_pow 3
	mov ax, %1
	mov bx, %2
	call scheme_pow
	mov cx, ax
	mov si, test_actual_msg
	call os_print_string
	call os_print_4hex
	mov si, test_expected_msg
	call os_print_string
	mov ax, %3
	call os_print_4hex
	call os_print_newline
	cmp cx, ax
	je %%cont
	jmp $
        %%cont:	
%endmacro
	pusha
	mov si, .title
	call os_print_string

	assert_scheme_pow 2, 0, 1b
	assert_scheme_pow 2, 1, 10b
	assert_scheme_pow 2, 2, 100b
	assert_scheme_pow 2, 3, 1000b
	assert_scheme_pow 10, 2, 100
	
	popa
	ret
	.title db "testing scheme_pow:", 0x0d, 0x0a, 0

	
;;; -------------------------------------------------------------

test_scheme_push_pop_word:
	pusha
	mov si, .title
	call os_print_string
	mov word [scheme_code_sp], SCHEME_CODE_STACK_START ;reset code sp
	
	scheme_push_word 0xface
	assert_int_equal 0xface, [SCHEME_CODE_STACK_START]
	assert_int_equal SCHEME_CODE_STACK_START+2, [scheme_code_sp]
	
	scheme_push_word 0xbabe
	assert_int_equal 0xbabe, [SCHEME_CODE_STACK_START+2] 
	assert_int_equal SCHEME_CODE_STACK_START+4, [scheme_code_sp]

	mov ax, 0
	call scheme_pop_word
	assert_int_equal 0xbabe, ax
	assert_int_equal SCHEME_CODE_STACK_START+2, [scheme_code_sp]

	call scheme_pop_word
	assert_int_equal 0xface, ax
	assert_int_equal SCHEME_CODE_STACK_START, [scheme_code_sp]

	call os_print_newline
	
	popa
	ret
	.title db "testing scheme push pop word",0x0d,0x0a,0
	
;;; -------------------------------------------------------------
test_actual_msg db " - actual:",0
test_expected_msg db " expected:", 0
test_succeeded db ".",0	
