use32

PCI_CONFIG_ADDR = 0xCF8
PCI_DATA		= 0xCFC

pci_scan_devices:

pci_check_device:
	pushad
	;; Get the vendor id
	;; check if vendor id is 0xffff
	;; if so then it is invalid
	;; Check the device functions
	;; Get the header type
	;; Check if it is a multi-function device
	;; if os then get the remaining functions
	popad
	ret

;; INPUTS:
;;  EAX = bus
;;  EBX = slot
;;  ECX = func
;;  EDX = offset (e.g., 0x00, 0x02, 0x04)
;; OUTPUTS:
;;  EAX = pci word (16 bits)
pci_read_word:
    push ebx
    push ecx
    push edx
    
    ; EDX contains the original offset. We need to align it for the DWORD read.
    mov ecx, edx            ; Save original offset in ECX
    and edx, 0xFFFFFFFC     ; Clear the low 2 bits to get the DWORD-aligned offset

    shl eax, 16             ; bus
    shl ebx, 11             ; slot
    shl ecx, 8              ; func (this clobbers our saved offset, so let's use the stack)
    
    pop edx                 ; Get original offset off the stack
    push edx                ; Put it back for later
    
    pop ecx                 ; Original func
    shl ecx, 8              ; func << 8
    
    ; Combine bus, slot, func, and aligned offset.
    or eax, ebx
    or eax, ecx
    or eax, edx             ; OR with the aligned offset
    or eax, 0x80000000      ; Set enable bit
    
    mov dx, PCI_CONFIG_ADDR
    out dx, eax             ; Write the address
    
    mov dx, PCI_DATA
    in eax, dx              ; Read the 32-bit data into EAX

    pop edx                 ; Retrieve original offset
    
    test dl, 2              ; Check bit 1 of the original offset
    jz @f                   ; If it's 0, we want the low word (no shift needed)
    shr eax, 16             ; If it's 1, we want the high word, so shift right by 16
@@:
    and eax, 0xFFFF         ; Keep only the desired 16-bit word
    pop ecx
    pop ebx
    ret
