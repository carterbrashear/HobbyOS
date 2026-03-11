use16

if defined DEBUG
    CPU_PM_CHECK_MSG: db "PM_CHECK: ", 0x00
    FAIL_MSG: db "FAIL", 0x0a, 0x0d, 0x00
    PASS_MSG: db "PASS", 0x0a, 0x0d, 0x00
end if

check_processor:
	;; FIXME: Explodes when I uncomment this
    if defined DEBUG
		pusha
        mov bx, CPU_PM_CHECK_MSG
        call serial_print
		call print
		popa
    end if
	;; Save flags for check
    pushf					; stack = 2 bytes
	;; Check for 8086/8088 (hopefully not because we have been using pusha and popa)
	xor ah, ah				; AH = 0x00
    push ax					; stack = 4 bytes
    popf					; stack = 2 bytes
    pushf					; stack = 4 bytes
    pop ax					; stack = 2 bytes
    and ah, 0xf0
    cmp ah, 0xf0
    je no_protected_mode
	;; Check for i286 (only other invalid option I think)
    mov ah, 0x70
    push ax					; stack = 4 bytes
    popf					; stack = 2 bytes
    pushf					; stack = 4 bytes
    pop ax					; stack = 2 bytes
    and ah, 0x70
    jz no_protected_mode
	;; Return flags after check
    popf					; stack = 0 bytes
	;; Print "PASS" if debug statements are enabled
    if defined DEBUG
		pusha
        mov bx, PASS_MSG
        call serial_print
		call print
		popa
    end if
    ret
no_protected_mode:
	popf					; Stack = 0
	;; Print "FAIL" if debug statements are enabled
    if defined DEBUG
		mov bx, CPU_PM_CHECK_MSG
		call serial_print
		call print
        mov bx, FAIL_MSG
        call serial_print
		call print
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

;; Completely flat global descriptor table
gdt_start:
gdt_null:
    ;; The CPU requires the first entry to be exactly 8 bytes of zeroes.
    dq 0x0000000000000000
gdt_code:
    ;; 32-bit Code Segment (Base: 0x00000000, Limit: 4GB)
    dw 0xFFFF       ; Limit (bits 0-15)
    dw 0x0000       ; Base (bits 0-15)
    db 0x00         ; Base (bits 16-23)
    db 10011010b    ; Access Byte (Present, Ring 0, Code, Exec/Read)
    db 11001111b    ; Flags (4KB Granularity, 32-bit) + Limit (bits 16-19)
    db 0x00         ; Base (bits 24-31)
gdt_data:
    ;; 32-bit Data Segment (Base: 0x00000000, Limit: 4GB)
    dw 0xFFFF       ; Limit (bits 0-15)
    dw 0x0000       ; Base (bits 0-15)
    db 0x00         ; Base (bits 16-23)
    db 10010010b    ; Access Byte (Present, Ring 0, Data, Read/Write)
    db 11001111b    ; Flags (4KB Granularity, 32-bit) + Limit (bits 16-19)
    db 0x00         ; Base (bits 24-31)
gdt_end:
gdt:
    dw gdt_end - gdt_start - 1  ; 16-bit Limit (Size of GDT minus 1)
    dd gdt_start