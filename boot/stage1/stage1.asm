use16
org 0x7c00

define STAGE2_ADDR 0x7e00
define STAGE2_CODE 0x7e08
define STAGE2_SIG  29779

start:
  mov [drive_number], dl	; We start with the boot drive's number in dl so save it for later
  ;; Set video mode and clear screen
  xor ah, ah				; AH = 0, tells BIOS we are changing the video mode
  mov al, 0x03				; Video Mode = 3 (80 x 25 text mode)
  int 0x10					; Request video mode change from the BIOS
  ;; Load next sectors
  call disk_read			; Load the next sectors of the boot drive
  mov ax, [STAGE2_ADDR]		; Load the signature at the start of sector 2
  cmp ax, STAGE2_SIG		; Check to see if sector two loaded correctly
  jne @f					; If it did not then will jump to our error code
  jmp STAGE2_CODE			; Runs the code on the next sector of the disk
@@: ; Error jump point
  mov bx, ERROR_MSG			; Loads error message string
  call print_string			; Prints the error message to the screen

ERROR_MSG: db "S1b error!", 0x0a, 0x0d, 0x00

include 'graphics.asm'
include 'disk_read.asm'
include 'disk_info.asm'

times 510-($-$$) db 0x00
dw 0xaa55
