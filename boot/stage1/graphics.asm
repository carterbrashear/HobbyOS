use16
define TEXT_MODE          0x03
define VGA_MODE           0x13
define VGA_LOCATION       0xa0000
define VGA_WIDTH          320
define VGA_HEIGHT         200
define GRAPHICS_INTERRUPT 0x10
define END_STRING         0x00

;; void(void)
set_text_mode:
  xor ah, ah
  mov al, TEXT_MODE
  int GRAPHICS_INTERRUPT
  ret

;; void(string : bx)
;; Must be in text mode
print_string:
  pusha
  mov ah, 0x0e
print_string_loop:
  mov al, [bx]
  cmp al, END_STRING
  je  print_string_done
  int GRAPHICS_INTERRUPT
  inc bx
  jmp print_string_loop
print_string_done:
  popa
  ret
