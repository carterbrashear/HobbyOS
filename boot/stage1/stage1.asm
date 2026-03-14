use16
org 0x7c00

define STAGE2_ADDR 0x7e00
define STAGE2_CODE 0x7e08
define STAGE2_SIG  29779

start:
  mov [drive_number], dl
  ;; Set video mode and clear screen
  xor ah, ah
  mov al, 0x03
  int 0x10
  ;; Load next sectors
  call disk_read
  mov ax, [STAGE2_ADDR]
  cmp ax, STAGE2_SIG
  jne error
  jmp STAGE2_CODE

error:
  mov bx, ERROR_MSG
  call print_string

ERROR_MSG: db "S1b error!", 0x0a, 0x0d, 0x00

include 'graphics.asm'
include 'disk_read.asm'
include 'disk_info.asm'

times 510-($-$$) db 0x00
dw 0xaa55
