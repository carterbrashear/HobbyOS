use32

;; Prints C-style strings to serial console
;; INPUT:
;;  BX = String
serial_print_pm:
    pushad					; Saves the register state
@@:							; Start of character print loop
    mov al, [bx]			; Load the character from the string
    cmp al, END_STRING		; Check if we are at the end of the string
    je  @f					; If we are then return from the function
    call serial_print_char_pm	; Actually print the character
    inc bx					; Move pointer to next character
    jmp @b					; Loop to print the next character
@@:							; Return jump point
    popad					; Returns register state
    ret						; Return to serial_print caller

;; Function that prints '0x' to the console
serial_print_hex_prefix_pm:
    push eax
    mov al, '0'
    call serial_print_char_pm
    mov al, 'x'
    call serial_print_char_pm
    pop eax
    ret

serial_print_hex8_pm:
    pushad
    call serial_print_hex_prefix_pm
    mov bx, 0x02 		   ; Loop counter (2 nibbles per byte)
    mov cl, 0x04		   ; Shift ammount (requiredfor 8086)
    jmp serial_hex_next_nibble_pm

serial_print_hex16_pm:
    pushad
    call serial_print_hex_prefix_pm
    mov bx, 0x04           ; Loop counter (4 nibbles in a word)
    mov cl, 0x04           ; Shift amount (required for 8086)
    jmp serial_hex_next_nibble_pm

serial_hex_next_nibble_pm:
    rol ax, cl             ; Rotate AX left by 4 (Top nibble moves to bottom)
    push ax                ; Save the rotated state
    and al, 0x0f           ; Isolate the bottom nibble (0-15)
    cmp al, 10
    jl serial_hex_is_digit_pm
    add al, 'A' - 10       ; Convert 10-15 to 'A'-'F'
    jmp serial_hex_send_pm
serial_hex_is_digit_pm:
    add al, '0'            ; Convert 0-9 to '0'-'9'
serial_hex_send_pm:
    ; Ensure DX is set here if your macro/function requires it
    ; mov dx, 0            ; COM1
    call serial_print_char_pm ; Send the character in AL
    pop ax                 ; Restore the rotated AX for the next iteration
    dec bx                 ; Decrement counter
    jnz serial_hex_next_nibble_pm       ; Loop 4 times
    popad
    ret

;; Function that prints the newline and carrage return to the serial console
serial_print_new_line_pm:
    push eax
    mov al, 0x0a
    call serial_print_char_pm
    mov al, 0x0d
    call serial_print_char_pm
    pop eax
    ret

;; Must be in AL!
serial_print_char_pm:
    ;; Saving internal registers
    push edx                 ; Save state of dx
    push eax                 ; Save state of ax (for getting AL later)
    ;; See if the device is ready for a message
    mov dx, SERIAL_PORT + 5 ; Line status register for serial port 1
@@:                         ; Point to jump when serial port is not yet ready
    in al, dx
    test al, 0x20			; Check the status of the serial device
    jz @b					; Run check again if device is not ready
    mov bp, sp
    mov al, [bp]            ; AX was the last thing pushed, so AL is at [sp]
    ;; Sending the character to the serial device
    mov dx, SERIAL_PORT     ; IO port for serial port 1 send
    out dx, al              ; Write the character to the console
    ;; Returning internal registers 
    pop eax                  ; Return the state of al
    pop edx                  ; Return state of dx
	ret
