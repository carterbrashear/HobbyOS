use16

SERIAL_PORT = 0x3f8
END_STRING  = 0x00

macro serial_print_char_fast char {
    ;; Saving internal registers
    push dx                 ; Save state of dx
    push ax                 ; Save state of ax

    ;; See if the device is ready for a message
    mov dx, SERIAL_PORT + 5 ; Line status register for serial port 1
@@:                         ; Point to jump when serial port is not yet ready
    in al, dx
    test al, 0x20
    jz @b

    if char eq al
        ; If the user passed AL, get the original value back from the stack
        mov bp, sp
        mov al, [bp]        ; AX was the last thing pushed, so AL is at [sp]
    else
        mov al, char        ; If it's a constant or another register, just move it
    end if

    ;; Sending the character to the serial device
    mov dx, SERIAL_PORT     ; IO port for serial port 1 send
    mov al, char            ; Load the character to al from wherever
    out dx, al              ; Write the character to the console
    
    ;; Returning internal registers 
    pop ax                  ; Return the state of al
    pop dx                  ; Return state of dx
}

;; This does not see if the port is ready
macro serial_print_fast string {
    pusha
    mov bx, string
    mov dx, SERIAL_PORT
@@:
    mov al, [bx]
    cmp al, END_STRING
    je  @f
    out dx, al
    inc bx
    jmp @b
@@:
    popa
}

