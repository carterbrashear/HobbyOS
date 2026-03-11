use16

;; COLOR DEFINITIONS (when not in text mode)
BLACK 			= 0x00
BLUE 			= 0x01
GREEN 			= 0x02
CYAN 			= 0x03
RED 			= 0x04
MAGENTA 		= 0x05
BROWN 			= 0x06
LIGHT_GREY 		= 0x07
DARK_GREY 		= 0x08
LIGHT_BLUE 		= 0x09
LIGHT_GREEN 	= 0x0a
LIGHT_CYAN 		= 0x0b
LIGHT_RED 		= 0x0c
LIGHT_MAGENTA 	= 0x0d
YELLOW 			= 0x0e
WHITE 			= 0x0f

NEWLINE           = 0x000a ; ASCII code for newline character
CARRIAGE_RETURN   = 0x000d ; ASCII code for carriage return character
VBE_BLOCK_INFO    = 0x7c00 ; Write the block info over stage 1 of the boot sector (we don't need it anymore)
VBE_DEVICE_INFO   = 0x0500 ; Using 256 bytes from the beginning of free memory (the stack is not this high so we're fine)
GET_MODES_ID      = 0x4F00 ; AX for BIOS interrupt
GET_MODE_INFO_ID  = 0x4F01 ; AX for BIOS interrupt
SWITCH_VBE_MODE   = 0x4F02 ; AX for BIOS interrupt
VBE_SUCCESS       = 0x004F ; AX after BIOS interrupt
VIDEO_INTERRUPT   = 0x0010 ; BIOS interrupt
SET_VIDEO_MODE_ID = 0x0000 ; AH for BIOS interrupt
TEXT_MODE_ID      = 0x0003 ; AL for BIOS interrupt
VIDEO_LIST_END    = 0xffff ; End marker in video mode list memory structure

;; Redefinitions for using video mode data
define VRAM 		[BEST_VIDEO_MODE_ADDR]
define VIDEO_MODE 	[BEST_VIDEO_MODE]
define XRES 		[BEST_VIDEO_MODEX]
define YRES 		[BEST_VIDEO_MODEY]

macro print_fast string {
    local .loop             ; Mark .loop as local to this macro
    local .done             ; Mark .done as local to this macro
    push bx                 ; Save state of BX (needed to store string pointer)
    push ax                 ; Save state of AX (need for BIOS interrupt)
    mov bx, string          ; Store address of string
    mov ah, 0x0e            ; BIOS interrupt code to print character
    .loop:                  ; Character print loop
    mov al, [bx]            ; Set al to the character BX points to
    cmp al, END_STRING      ; If we are at the end of the string:
    je .done                ; Then return
    int VIDEO_INTERRUPT     ; Else: Print the character
    inc bx                  ; Point bx to next character in the string
    jmp .loop               ; Jump to the start of the character print loop
    .done:                  ; Return marker
    pop ax                  ; Return AX to origional state
    pop bx                  ; Return BX to origional state
}

macro println string {
    print string    ; Print the string 
    push ax         ; Save the state of AX
    mov ah, 0x0e    ; Tell BIOS we are printing to the screen again
    mov al, 0x0a    ; Prep newline character to be printed
    int 0x10        ; Print the newline character
    mov al, 0x0d    ; Prep the carrage return to be printed
    int 0x10        ; Print the carrage return character
    pop ax          ; Return the state of AX
}

;; Returns the video card's device codes
;; OUTPUT:
;;  BL = device code for active video card
;;  BH = device code for inactive video card
macro get_video_card_type {
    mov ah, 0x13
    xor al, al
    int VIDEO_INTERRUPT
}

;; Returns if active card has VGA support
;; OUTPUT:
;;  AL = VGA supprt (1 for supported)
macro vga_supported {
    mov ah, 0x13
    xor al, al
    int VIDEO_INTERRUPT
}

;; Run this to hide the text mode cursor (EGA and VGA)
;; OUTPUT: NONE
macro hide_cursor {
    mov ch, 0x20
    mov ah, 0x01
    int VIDEO_INTERRUPT
}

;; Run this to show the standard text mode cursor (EGA and VGA)
;; OUTPUT: NONE
macro show_standard_cursor {
    mov ch, 0x06
    mov cl, 0x07
    mov ah, 0x01
    int VIDEO_INTERRUPT
}

;; Run this to show the boxed text mode cursor (EGA and VGA)
;; OUTPUT: NONE
macro show_box_cursor {
    xor ch, ch
    mov cl, 0x07
    mov ah, 0x01
    int VIDEO_INTERRUPT
}

;; Get cursor position and size (EGA and VGA)
;; OUTPUT:
;;  DH = row    ; position info
;;  DL = column ; position info
;;  CH = cursor start line  ; size info
;;  CL = cursor bottom line ; size info
macro set_cursor_position row,column,page {
    mov dh, row
    mov dl, column
    mov bh, page
    int VIDEO_INTERRUPT
}

;; Get cursor position and size (EGA and VGA)
;; OUTPUT:
;;  DH = row    ; position info
;;  DL = column ; position info
;;  CH = cursor start line  ; size info
;;  CL = cursor bottom line ; size info
macro get_cursor page_number {
    mov bh, page_number
    mov ah, 0x03
    int VIDEO_INTERRUPT
}

;; Select the active video page (EGA and VGA)
;; OUTPUT: NONE
macro select_video_page page_number {
    mov ah, 0x05
    mov al, page_number
    int VIDEO_INTERRUPT
}

;; Read character and attribute at cursor position (EGA and VGA)
;; OUTPUT:
;;  AH = attribute
;;  AL = character
macro read_character_at_cursor page_number {
    mov bh, page_number
    mov ah, 0x08
    int VIDEO_INTERRUPT
}

;; Write character and attribute at cursor position (EGA and VGA)
;; OUTPUT: NONE
macro write_character_at_cursor character,page_number,attribute,times_to_write {
    mov ah, 0x09
    mov al, character
    mov bh, page_number
    mov bl, attribute
    mov cx, times_to_write
    int VIDEO_INTERRUPT
}

;; Set border/background color (EGA and VGA)
;; Only call in 320x200 or 640x200 graphic mode
;; OUPUT: NONE
macro select_background_color color {
    mov ah, 0x0b
    mov bh, 0x00
    mov bl, color
    int VIDEO_INTERRUPT
}

;; Select color pallette (EGA and VGA)
;; Only call for 320x200 graphic mode
;; OUTPUT: NONE
macro set_color_palette color_palette_number {
    mov ah, 0x0b
    mov bh, 0x01
    mov bl, color_palette_number
    int VIDEO_INTERRUPT
}

;; Write pixel (EGA and VGA)
;; OUTPUT: NONE
macro write_pixel video_page,screen_line,screen_column,color_value {
    mov bh, video_page
    mov dx, screen_line
    mov cx, screen_column
    mov al, color_value
    mov ah, 0x0c
    int VIDEO_INTERRUPT
}

;; Read pixel (EGA and VGA)
;; OUTPUT:
;;  AL = color value
macro read_pixel video_page,screen_line,screen_column,color {
    mov ah, 0x0d
    mov al, color
    mov bh, video_page
    mov dx, screen_line
    mov cx, screen_column
    int VIDEO_INTERRUPT
}

;; Write character (EGA and VGA)
;; OUTPUT: NONE
macro write_character character, foreground_color {
    mov ah, 0x0e
    mov al, character
    mov bl, foreground_color
    int VIDEO_INTERRUPT
}

;; Get current display mode (EGA and VGA)
;; OUTPUT:
;;  AL = video mode
;;  AH = number of characters per line
;;  BH = number of current display page
macro get_curr_display_mode {
    mov ah, 0x0f
    int VIDEO_INTERRUPT
}

;; Enable blinking (EGA and VGA)
;; Text mode only
;; Bit 7 of character attributes contain blink info
;; OUTPUT: NONE
macro enable_blinking blink_enable {
    mov ah, 0x10
    mov al, 0x00
    mov bl, blink_enable
    int VIDEO_INTERRUPT
}

