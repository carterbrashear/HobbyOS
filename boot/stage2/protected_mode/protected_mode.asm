use16

check_processor:
    if defined DEBUG
        mov bx, CPU_PM_CHECK_MSG
        call serial_print
    end if
    pushf
    xor ah, ah
    push ax
    popf
    pushf
    pop ax
    and ah, 0xf0
    cmp ah, 0xf0
    je no_protected_mode
    mov ah, 0x70
    push ax
    popf
    pushf
    pop ax
    and ah, 0x70
    jz no_protected_mode
    popf
    if defined DEBUG
        mov bx, PASS_MSG
        call serial_print
    end if
    ret
no_protected_mode:
    if defined DEBUG
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

