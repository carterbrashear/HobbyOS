use16
org 0x7e00 ; Location stage2 is loaded to
;; Signature (checked to see if sectors loaded correctly)
db "Stage 2", 0x00 ; 8 bytes

DEBUG = 1
;DEBUG_VIDEO = 1
NUMBER_OF_SECTORS = 3

include "serial/serial_console.inc"
include "graphics/graphics.inc"

start:
    call check_processor		; Check for supported processor
    call get_video_modes		; Get all avalible video modes
	call set_video_mode			; Set the best one
	call set_A20				; Set A20 line so we can access all of our memory
	call jump_to_protected_mode	; Switch to 32-bit protected mode
use32
PModeMain:
	mov bx, TEST_MSG
	call serial_print_pm
	mov eax, 0x01
	mov ebx, 0x01
	mov ch, WHITE
	call draw
terminate:
    cli
    hlt

TEST_MSG: db "Protected Mode!", 0x0a, 0x0d, 0x00

include "graphics/graphics.asm"
include "graphics/draw.asm"
include "serial/serial_console.asm"
include "protected_mode/a20.asm"
include "protected_mode/protected_mode.asm"
include "pci/pci.asm"
include "serial/serial_console_pm.asm"

;; Pad the rest of the binary files with zero
times (NUMBER_OF_SECTORS*512)-($-$$) db 0x00
