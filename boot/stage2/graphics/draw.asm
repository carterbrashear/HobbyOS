;; This is a 32-bit video library using the VBE video mode from graphics.asm
use32

;; Draw function
;; Draws places a pixel at the desired location
;; INPUT:
;;  EAX = X position
;;  EBX = Y position
;;  CH = Color
;; OUTPUT: NONE
draw:
	push eax		; Preserve EAX
	push ebx		; Preserve EBX
	;; Position = (XResolution * YPosition) + XPosition
	;; eax = (XRES * EBX) + EAX
	push eax		; Save the X position
	xor eax, eax	; EAX = 0
	mov ax, XRES	; EAX = XResolution
	mul ebx			; EAX = XResolution * YPosition
	pop ebx			; EBX = XPosition
	add eax, ebx	; EAX = (XResolution * YPosition) + XPosition
	;; Destination address = VRAM + Position
	mov ebx, VRAM	; EBX = VRAM
	add eax, ebx	; EAX = (XResolution * YPosition) + XPosition + VRAM
	;; Draw pixel
	mov [eax], ch	; Write pixel to VRAM
	;; Return
	pop ebx			; Return EBX
	pop eax			; Return EAX
	ret				; Return to draw caller


;; FIXME: THIS FUNCTION DOES NOT WORK
;; INPUTS: AL = 8-bit color index
clear_screen:
    pushad
    mov edi, VRAM      ; Load the address of the Framebuffer
    mov ecx, XRES        
    imul ecx, YRES       ; ECX = Total number of pixels (1 byte each)
    
    mov ah, al           ; Copy color to AH
    shl eax, 16          ; Move to high word
    mov ax, [esp + 32]   ; Wait, simpler way:
    
    ; Re-do the EAX setup for rep stosd (faster than stosb)
    movzx eax, al        ; Clear upper bits of EAX
    mov ah, al           ; Fill EAX with 4 copies of the color
    mov ebx, eax
    shl eax, 16
    or eax, ebx          ; Now EAX = 0xYYYYYYYY (where Y is your color index)
    
    cld
    rep stosd            ; Write 4 pixels at a time
    popad
    ret
