use32
;; INPUTS: NONE
;; OUTPUTS:
;;  EAX = Enabled (0 = disabled, 1 = enabled)
check_A20_pm:
	pushad				; Save registers
	mov edi, 0x112345	; Load odd megabyte address
	mov esi, 0x012345	; Load even megabyte address
	mov [esi], esi		; Make sure addresses are different
	mov [edi], edi		; Make sure addresses are different
	cmpsd				; Check if addresses are the same
	popad				; Done with registers so return them
	jne a20_set			; A20 line is set so return 1
	xor eax, eax		; Return 0
	ret					; Return
.a20_set:
	mov eax, 0x01		; Return 1
	ret
