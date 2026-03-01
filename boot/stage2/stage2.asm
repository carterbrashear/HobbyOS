use16
org 0x7e00 ; Location stage2 is loaded to
;; Signature (checked to see if sectors loaded correctly)
db "Stage 2", 0x00 ; 8 bytes

; DEBUG = 1
DEBUG_VIDEO = 1

include "serial/serial_console.inc"
include "graphics/graphics.inc"

start:
    mov bx, TEST_MSG
    mov ax, 0x10
    call serial_print_hex16
    call serial_print_new_line
    call print
    call serial_print
    call check_processor
    call get_video_modes
    ;; Set video mode
terminate:
    cli
    hlt

TEST_MSG: db "Hi!", 0x0a, 0x0d, 0x00

include "graphics/graphics.asm"
include "serial/serial_console.asm"
include "protected_mode/protected_mode.asm"
