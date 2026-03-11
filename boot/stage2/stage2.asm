use16
org 0x7e00 ; Location stage2 is loaded to
;; Signature (checked to see if sectors loaded correctly)
db "Stage 2", 0x00 ; 8 bytes

DEBUG = 1
DEBUG_VIDEO = 1
NUMBER_OF_SECTORS = 2

include "serial/serial_console.inc"
include "graphics/graphics.inc"

start:
    mov bx, TEST_MSG
    call print
    call serial_print
    call check_processor
    call get_video_modes
	call set_video_mode
	call jump_to_protected_mode
use32
PModeMain:
	mov eax, 0x01
	mov ebx, 0x01
	mov ch, WHITE
	call draw
terminate:
    cli
    hlt

TEST_MSG: db "Starting...", 0x0a, 0x0d, 0x00

include "graphics/graphics.asm"
include "graphics/draw.asm"
include "serial/serial_console.asm"
include "protected_mode/protected_mode.asm"

;; Pad the rest of the binary files with zero
times (NUMBER_OF_SECTORS*512)-($-$$) db 0x00
