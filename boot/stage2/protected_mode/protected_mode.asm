use16

check_processor:
	;; FIXME: Explodes when I uncomment this
    if defined DEBUG
		pusha
        mov bx, CPU_PM_CHECK_MSG
        call serial_print
		popa
    end if
	;; Save flags for check
    pushf					; stack = 2 bytes
	;; Check for 8086/8088
	xor ah, ah
    push ax					; stack = 4 bytes
    popf					; stack = 2 bytes
    pushf					; stack = 4 bytes
    pop ax					; stack = 2 bytes
    and ah, 0xf0
    cmp ah, 0xf0
    je no_protected_mode
	;; Check for i286
    mov ah, 0x70
    push ax					; stack = 4 bytes
    popf					; stack = 2 bytes
    pushf					; stack = 4 bytes
    pop ax					; stack = 2 bytes
    and ah, 0x70
    jz no_protected_mode
	;; Return flags after check
    popf					; stack = 0 bytes

	;; FIXME: Explodes when I uncomment this
    ; if defined DEBUG
		; pusha
        ; mov bx, PASS_MSG
        ; call serial_print
		; popa
    ; end if
    ret
no_protected_mode:
	popf					; Stack = 0
    if defined DEBUG
		mov bx, CPU_PM_CHECK_MSG
		call serial_print
        mov bx, FAIL_MSG
        call serial_print
    end if
    ;; Critical error so hang the system
    cli
    hlt

jump_to_protected_mode:
    cli
    lgdt [gdt]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 08h:PModeMain

use32
PModeMain:
    

;; TODO: Create global descriptor table
gdt:
gdt_null:
    dq 0x0000
gdt_code:
    dw 0xffff
    dw 0x0000

if defined DEBUG
    CPU_PM_CHECK_MSG: db "PM_CHECK: ", 0x00
    FAIL_MSG: db "FAIL", 0x0a, 0x0d, 0x00
    PASS_MSG: db "PASS", 0x0a, 0x0d, 0x00
end if

