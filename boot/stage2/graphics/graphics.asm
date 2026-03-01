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

NUM_VIDEO_MODES:  dw 0x00
BEST_VIDEO_MODE:  dw 0x00
BEST_VIDEO_MODEX: dw 0x00
BEST_VIDEO_MODEY: dw 0x00
TEMP_MODE:        dw 0x00
;; BOOT SECTOR WILL BE WRITTEN OVER BY THIS FUNCTION
;; Get's all supported video modes and saves the highest resolution 1 byte pixel video mode in 0x7c00 (16-bits)
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

    if defined DEBUG_VIDEO
        mov bx, MODE_ID_MSG
        call serial_print
    end if
    mov ax, cx                   ; Current video mode
    mov [TEMP_MODE], ax
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
    
    if defined DEBUG_VIDEO
        mov bx, X_RES_MSG
        call serial_print
    end if
    mov ax, [VBE_DEVICE_INFO + 0x12] ; Get X resolution
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
    
    if defined DEBUG_VIDEO
        mov bx, Y_RES_MSG
        call serial_print
    end if
    mov ax, [VBE_DEVICE_INFO + 0x14] ; Get Y resolution
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
    
    if defined DEBUG_VIDEO
        mov bx, BITS_PER_PIXEL_MSG
        call serial_print
    end if
    mov ah, [VBE_DEVICE_INFO + 0x19] ; Get bits per pixel
    if defined DEBUG_VIDEO
        call serial_print_hex8
        call serial_print_new_line
    end if
    
    cmp ah, 0x08
    je  check_valid_mode
skip_mode:
    add si, 2                   ; Make si point to next video mode entry
    jmp next_mode               ; loop
end_of_list:
    mov ax, [BEST_VIDEO_MODE]   ;
    mov [0x7c00], ax            ; Save the best video mode in 0x7c00 (16-bits)
    cmp ax, 0x00                ;
    je no_supported_modes_error ; If so then error
    popa                        ; Retrun registers to before get_video_modes was called
    ret                         ; Return to get_video_modes caller
check_valid_mode:
    mov ax, [VBE_DEVICE_INFO + 0x12]
    cmp ax, [BEST_VIDEO_MODEX]
    jg  save_mode
    jmp skip_mode
save_mode:
    mov ax, [TEMP_MODE]
    mov [BEST_VIDEO_MODE], ax
    mov ax, [VBE_DEVICE_INFO + 0x12]
    mov [BEST_VIDEO_MODEX], ax
    jmp skip_mode
vbe_not_supported:
    mov ah, SET_VIDEO_MODE_ID
    mov al, TEXT_MODE_ID
    int VIDEO_INTERRUPT
    if defined DEBUG_VIDEO
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
no_supported_modes_error:
    ;; FIXME: Handle this error
    cli
    hlt

if defined DEBUG_VIDEO
    VBE_NOT_SUPPORTED_MSG: db "VBE Not Supported!", 0x0a, 0x0d, 0x00
    X_RES_MSG:             db " X Resolution: ", 0x00
    Y_RES_MSG:             db " Y Resolution: ", 0x00
    BITS_PER_PIXEL_MSG:    db " Bits per pixel: ", 0x00
    MODE_ID_MSG:           db "Video mode: ", 0x00
end if
