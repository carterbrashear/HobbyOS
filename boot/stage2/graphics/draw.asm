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
