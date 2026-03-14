use16

;; Stores wether A20 line is enbaled in A20_ENABLED
;; Use if needed in 16 bit real mode
;; INPUTS: NONE
;; OUTPUTS:
;;  AX = A20 Status (0 = disabled, 1 = enabled)
check_A20_rm:
    pushf
	push ax
    push ds
    push es
    push di
    push si

    cli						; Interrupts are not re-enabled after this

    xor ax, ax				; ax = 0
    mov es, ax

    not ax					; ax = 0xFFFF
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je @f

    mov ax, 1
@@:
    pop si
    pop di
    pop es
    pop ds
	pop ax
    popf
    ret

;; Call to set A20 line if it is disabled
;; INPUTS: NONE
;; OUTPUTS: NONE
set_A20:
	push ax			; Save state of ax
	;; Check if interrupt is supported
	mov ax, 0x2403	; Check if interrupt is supported
	int 0x15		; Check if interrupt is supported
	jc @f			; On fail method is not supported
	test ah, ah		; Check for fail another way
	jc @f			; On fail method is not supported
	;; Check current status of A20
	mov ax, 0x2402	; Get A20 status
	int 0x15		; Get A20 status
	jc @f			; On fail, method is not supported
	test ah, ah		; Check for fail another way
	jnz @f			; On fail, method is not supported
	test al, al		; Check if already activated
	jnz .a20_ok		; Success because it is already enabled
	;; Activate A20
	mov ax, 0x2401	; Enable A20
	int 0x15		; Enable A20
	jc @f			; On fail, method is not supported
	test ah, ah		; Check for fail
	jnz @f			; On fail, method is not supported
	;; A20 line is now enabled so let's return
	jmp .a20_ok
@@:	;; BIOS interrupt method not supported
	;; Check if line is somehow enabled
	call check_A20_rm	; Check A20
	cmp ax, 0x01		; See if it is enabled
	je .a20_ok			; If so then return
	;; Enable with keyboard
	call keyboard_a20_enable
	;; Check again
	call check_A20_rm	; Check A20
	cmp ax, 0x01		; See if it is enabled
	je .a20_ok			; If so then return
	;; As a last resort, attempt fast a20 gate method
	call fast_a20
	;; Check one final time
	call check_A20_rm	; Check A20
	cmp ax, 0x00		; See if it is disabled
	je .a20_error		; If so then error
;; set_A20 return
.a20_ok:
	;; Print pass message if debug is enabled
	;; Commented out because it prints after video mode has been changed
	; if defined DEBUG
		; mov bx, A20_PASS_MSG
		; call serial_print
		; call print
	; end if
	pop ax
	ret
.a20_error:
	pop ax
	;; Print error message if debug is enabled
	if defined DEBUG
		mov bx, A20_ERR_MSG
		call serial_print
		call print
	end if
	;; Fatal error so hang the machine
	cli
	hlt

;; Only called by set_A20 if BIOS interrupt 0x15 fails
keyboard_a20_enable:
	push ax
	cli
	;; Disable the kyboard
	call .wait1
	mov al, 0xad
	out 0x64, al
	;; Read controller output port
	call .wait1
	mov al, 0xd0
	out 0x64, al
	;; Save response byte
	call .wait2
	in al, 0x60
	push ax
	;; Write next byte into controller output port
	call .wait1
	mov al, 0xD1
	out 0x64, al
	;; Enable A20
	call .wait1
	pop ax
	or al, 2
	out 0x60, al
	;; Reactivate keyboard
	call .wait1
	mov al, 0xAE
	out 0x64, al
	;; Return to keyboard_a20_enable caller
	sti
	pop ax
	ret
;; Waits until input buffer is clear
.wait1:
	in al, 0x64
	test al, 2
	jnz .wait1
	ret
;; Wait until response byte has arrived
.wait2:
	in al, 0x64
	test al, 1
	jz .wait2
	ret

;; Last resort function called by set_A20 if keyboard and int 0x15 fail
fast_a20:
	push ax
	in al, 0x92
	or al, 2
	out 0x92, al
	pop ax
	ret

if defined DEBUG
	A20_PASS_MSG: db "A20: PASS", 0x0a, 0x0d, 0x00
	A20_ERR_MSG:  db "A20: FAIL", 0x00
end if
