test_scheme_string_to_int:
%macro assert_scheme_string_to_int 2
	mov si, test_actual_msg
	call os_print_string
	mov ax, %1
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
        %%cont:	
%endmacro
	pusha
	mov si, .title
	call os_print_string
	
	assert_scheme_string_to_int .test1, 1
	assert_scheme_string_to_int .test2, 2
	assert_scheme_string_to_int .test3, 16
	assert_scheme_string_to_int .test4, 32
	assert_scheme_string_to_int .test5, 256
	assert_scheme_string_to_int .test6, 512
	assert_scheme_string_to_int .test7, 0
	assert_scheme_string_to_int .test8, 1234
	
	popa
	ret
	.title db "testing scheme_string_to_int",0x0d, 0x0a,0
	.test1 db "1",0
	.test2 db "2",0
	.test3 db "16",0
	.test4 db "32",0
	.test5 db "256",0
	.test6 db "512",0
	.test7 db "0",0
	.test8 db "1234",0

	
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

test_actual_msg db "actual:",0
test_expected_msg db " expected:", 0
	
