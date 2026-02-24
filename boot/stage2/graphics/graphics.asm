use16

print:
    push bx                 ; Save state of BX (needed to store string pointer)
    push ax                 ; Save state of AX (need for BIOS interrupt)
    mov ah, 0x0e            ; BIOS interrupt code to print character
@@:                         ; Character print loop
    mov al, [bx]            ; Set al to the character BX points to
    cmp al, END_STRING      ; If we are at the end of the string:
    je @f                   ; Then return
    int VIDEO_INTERRUPT     ; Else: Print the character
    inc bx                  ; Point bx to next character in the string
    jmp @b                  ; Jump to the start of the character print loop
@@:                         ; Return marker
    pop ax                  ; Return AX to origional state
    pop bx                  ; Return BX to origional state
    ret                     ; Return to print caller

NUM_VIDEO_MODES:                dw 0x00
BEST_VIDEO_MODE:                dw 0x00
BEST_VIDEO_MODEX:               dw 0x00
BEST_VIDEO_MODE_BITS_PER_PIXEL: dw 0x00

get_video_modes:
    pusha
    mov ax, GET_MODES_ID
    mov di, VBE_BLOCK_INFO
    int VIDEO_INTERRUPT
    cmp ax, GET_MODE_SUCCESS
    jne vbe_not_supported
    mov si, [VBE_BLOCK_INFO + 0x0E]  ; Load Offset into SI
    mov ax, [VBE_BLOCK_INFO + 0x10]  ; Load Segment into AX
    mov fs, ax                       ; Move Segment to FS register
next_mode:
    mov cx, [fs:si]                ; Get the next mode number from the list
    cmp cx, VIDEO_LIST_END      ; Check for end of list marker
    je end_of_list

    mov ax, GET_MODE_INFO_ID    ; Get VBE Mode Information
    mov di, VBE_DEVICE_INFO     ; Buffer location for device info
    int VIDEO_INTERRUPT         ; CX contains the mode number

    cmp ax, GET_MODE_SUCCESS    ; Check for success
    jne skip_mode               ; On fail, skip entry

    inc word [NUM_VIDEO_MODES]  ; Incrament video mode count
    
    mov ax, cx                       ; Push the video mode id
    call serial_print_hex16
    mov bx, X_RES_MSG
    call serial_print
    mov ax, [VBE_DEVICE_INFO + 0x12] ; Get X resolution
    call serial_print_hex16
    mov bx, Y_RES_MSG
    call serial_print
    mov ax, [VBE_DEVICE_INFO + 0x14] ; Get Y resolution
    call serial_print_hex16
    mov bx, BITS_PER_PIXEL_MSG
    call serial_print
    mov ah, [VBE_DEVICE_INFO + 0x19] ; Get bits per pixel
    call serial_print_hex8
    call serial_print_new_line
skip_mode:
    add si, 2                   ; Make si point to next video mode entry
    jmp next_mode               ; loop
end_of_list:
    popa
    ret
save_mode:
    
vbe_not_supported:
    mov ah, SET_VIDEO_MODE_ID
    mov al, TEXT_MODE_ID
    int VIDEO_INTERRUPT
if defined DEBUG
    mov bx, VBE_NOT_SUPPORTED_MSG
    call serial_print
end if
    ; FIXME: Find alternate logic and remove hanging the system
    cli
    hlt
.end:
    popa                            ; Pushed after get_video_modes is called
    ret                             ; Return to get_video_modes caller
.save_error:
    ;; FIXME: Handle this error
    cli
    hlt

VBE_NOT_SUPPORTED_MSG: db "VBE Not Supported!", 0x0a, 0x0d, 0x00
X_RES_MSG:             db " X Resolution: ", 0x00
Y_RES_MSG:             db " Y Resolution: ", 0x00
BITS_PER_PIXEL_MSG:    db " Bits per pixel: ", 0x00
MODE_ID_MSG:           db "Video mode: ", 0x00

