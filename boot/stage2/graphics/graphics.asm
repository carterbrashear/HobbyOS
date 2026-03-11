use16

;; Prints a null terminated string held in bx
;; Must be called in text mode and 16-bit real mode
print:
    push bx				; Save state of BX (needed to store string pointer)
    push ax				; Save state of AX (need for BIOS interrupt)
    mov ah, 0x0e		; BIOS interrupt code to print character
@@:						; Character print loop
    mov al, [bx]		; Set al to the character BX points to
    cmp al, END_STRING	; If we are at the end of the string:
    je @f				; Then return
    int VIDEO_INTERRUPT	; Else: Print the character
    inc bx				; Point bx to next character in the string
    jmp @b				; Jump to the start of the character print loop
@@:						; Return marker
    pop ax				; Return AX to origional state
    pop bx				; Return BX to origional state
    ret					; Return to print caller

NUM_VIDEO_MODES:      dw 0x00
BEST_VIDEO_MODE:      dw 0x00
BEST_VIDEO_MODEX:     dw 0x00
BEST_VIDEO_MODEY:     dw 0x00
BEST_VIDEO_MODE_ADDR: dd 0x00
TEMP_MODE:            dw 0x00
;; BOOT SECTOR WILL BE WRITTEN OVER BY THIS FUNCTION
;; Get's all supported video modes and saves the highest resolution 1 byte pixel video mode in 0x7c00 (16-bits)
get_video_modes:
    pusha							; Save state of the registers
	;; Attempt to get a list of video modes
    mov ax, GET_MODES_ID			; Set video interrupt to get modes
    mov di, VBE_BLOCK_INFO			; Give it the pointer to store the data
    int VIDEO_INTERRUPT				; Call interrupt and actually get the block
    ;; Check errors from the interrupt call
	cmp ax, VBE_SUCCESS		; Check for interrupt success
    jne vbe_not_supported			; On fail, VBE is not supported so jump to error handling
    ;; Load the info for the first video mode
	mov si, [VBE_BLOCK_INFO+0x0E]	; Load Offset into SI
    mov ax, [VBE_BLOCK_INFO+0x10]	; Load Segment into AX
    mov fs, ax                     	; Move Segment to FS register
next_mode:
    mov cx, [fs:si]                	; Get the next mode number from the list
    cmp cx, VIDEO_LIST_END      	; Check for end of list marker
    je end_of_list
	;; B
    mov ax, GET_MODE_INFO_ID    	; Get VBE Mode Information
    mov di, VBE_DEVICE_INFO     	; Buffer location for device info
    int VIDEO_INTERRUPT         	; CX contains the mode number

    cmp ax, VBE_SUCCESS    	; Check for success
    jne skip_mode               	; On fail, skip entry

    inc word [NUM_VIDEO_MODES]  	; Incrament video mode count

    if defined DEBUG_VIDEO
        mov bx, MODE_ID_MSG
        call serial_print
    end if
    mov ax, cx                   	; Current video mode
    mov [TEMP_MODE], ax
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
    
    if defined DEBUG_VIDEO
        mov bx, X_RES_MSG
        call serial_print
    end if
    mov ax, [VBE_DEVICE_INFO+0x12]	; Get X resolution
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
    
    if defined DEBUG_VIDEO
        mov bx, Y_RES_MSG
        call serial_print
    end if
    mov ax, [VBE_DEVICE_INFO+0x14]	; Get Y resolution
    if defined DEBUG_VIDEO
        call serial_print_hex16
    end if
	
    if defined DEBUG_VIDEO
        mov bx, BITS_PER_PIXEL_MSG
        call serial_print
    end if
    mov ah, [VBE_DEVICE_INFO+0x19]	; Get bits per pixel
    if defined DEBUG_VIDEO
        call serial_print_hex8
        call serial_print_new_line
    end if
    cmp ah, 0x08
    je  check_valid_mode
skip_mode:
    add si, 2                   	; Make si point to next video mode entry
    jmp next_mode               	; loop
end_of_list:
    mov ax, [BEST_VIDEO_MODE]   	;
    mov [0x7c00], ax            	; Save the best video mode in 0x7c00 (16-bits)
    cmp ax, 0x00                	;
    je no_supported_modes_error 	; If so then error
    popa                        	; Retrun registers to before get_video_modes was called
    ret                         	; Return to get_video_modes caller
;; Here we're checking if the video mode has a higher resolution than the current best
check_valid_mode:
    mov ax, [VBE_DEVICE_INFO+0x12]	; Grab the resolution of the current video mode
    cmp ax, [BEST_VIDEO_MODEX]		; See if it's bigger than the resolution of the current best video mode
    jg  save_mode					; If it has a higher resolution, save it
    jmp skip_mode					; Otherwise go read the next one on the list
save_mode:
    mov ax, [TEMP_MODE]				; Grab the id of the current video mode
    mov [BEST_VIDEO_MODE], ax		; Save it as the best video mode
    mov ax, [VBE_DEVICE_INFO+0x12]	; Grab the video mode's x resolution
    mov [BEST_VIDEO_MODEX], ax		; Save it
	mov ax, [VBE_DEVICE_INFO+40]	; Grab lower part of memory address
	mov [BEST_VIDEO_MODE_ADDR], ax	; Save it
	mov ax, [VBE_DEVICE_INFO+42]	; Grab upper part of memory address
	mov [BEST_VIDEO_MODE_ADDR+2], ax; Save it
    jmp skip_mode					; Go read the next video mode on the list
;; Error handling point jumped to when we can't get the VBE block info
vbe_not_supported:
    mov ah, SET_VIDEO_MODE_ID		; Set the video mode,
    mov al, TEXT_MODE_ID			; to a basic always supported text mode.
    int VIDEO_INTERRUPT				; Switch the video mode (also clears the screen)
	;; Print a message saying "VBE Not Supported!" if we have debug statements enabled
    if defined DEBUG_VIDEO
        mov bx, VBE_NOT_SUPPORTED_MSG
        call serial_print
		call print
    end if
    ;; We have reached a critical unrecoverable error so just freeze the system
    cli
    hlt
.end:
    popa                            ; Pushed after get_video_modes is called
	mov ax, [BEST_VIDEO_MODE]		; Return the best video mode in ax
    ret                             ; Return to get_video_modes caller
.save_error:
    ;; FIXME: Handle this error
    cli
    hlt
no_supported_modes_error:
    ;; FIXME: Handle this error
    cli
    hlt

;; This function switchest to the found video mode
;; Must call get_video_modes first
set_video_mode:
	push ax
	push bx
	;; Load video mode
	mov bx, [BEST_VIDEO_MODE]	; Grab the id of the best video mode
	;; Check for special case
	cmp bx, 0x13				; Check for non-VBE video mode
	je .set_mode_13h			; If so, then call switch normally
	;; Switch mode
	mov ax, SWITCH_VBE_MODE		; Tell BIOS we are switching to a VBE video mode
	int VIDEO_INTERRUPT			; BIOS interrupt to switch video mode
	;; Check for errrors
	cmp ax, VBE_SUCCESS			; Check if interrupt returned a success
	jne .mode_selection_error	; If not, then handle error
	;; Return
	jmp @f						; Return to set_video_mode caller
.set_mode_13h:
	mov ah, SET_VIDEO_MODE_ID	; Use old video mode setting function
	mov al, 0x13				; Select video mode 0x13 (the special case)
	int VIDEO_INTERRUPT			; Switch mode
@@: ; Return point
	pop bx
	pop ax
	ret
.mode_selection_error:
	;; Print error message if debug is enabled
    if defined DEBUG_VIDEO
        mov bx, MODE_SELECTION_ERR_MSG
        call serial_print
		call print
    end if
	;; Hang the system
	cli
	hlt

if defined DEBUG_VIDEO
    VBE_NOT_SUPPORTED_MSG: db "VBE Not Supported!", 0x00
    X_RES_MSG:             db " X Resolution: ", 0x00
    Y_RES_MSG:             db " Y Resolution: ", 0x00
    BITS_PER_PIXEL_MSG:    db " Bits per pixel: ", 0x00
    MODE_ID_MSG:           db "Video mode: ", 0x00
	MODE_SELECTION_ERR_MSG db "Error selecting video mode ", 0x00
end if
