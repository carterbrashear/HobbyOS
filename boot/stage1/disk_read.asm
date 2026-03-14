use16

SECTOR_COUNT =          3
SECTOR_COUNT_LBA =      SECTOR_COUNT + 1
DEST_ADDR =             0x7e00
LBA_NUMBER =            0x01
PACKET_SIZE =           0x10
BIOS_LBA_LOAD =         0x42
BIOS_DISK_INTERRUPT =   0x13
MEMORY_ZERO_PAGE =      0x00
BIOS_CHS_LOAD =         0x02
STARTING_SECTOR =		0x02

disk_read:
    pusha					; Save registers
	xor bx, bx				; BX = 0
	mov es, bx				; ES = 0
    mov dl, [drive_number]	; Load saved drive number (needed for int 0x13)
	mov ax, SECTOR_COUNT	; needed for int 0x13
	mov cl, STARTING_SECTOR	; needed for int 0x13
	mov bx, DEST_ADDR		; needed for int 0x13
@@: ; READ LOOP
	cmp ax, 0x00			; Check if we are done reading
	je  @f					; If so, then return
    call chs_load			; Load the data
	inc cl					; Point cl to the next sector
	add bx, 0x200			; Point memory address to next 512 bytes
	dec ax					; Decrement the sector count
	jmp @b					; Load the next sector
@@: ; END LOOP
    popa					; Return registers
    ret						; Return to disk_read caller
;; Called by disk_read only
chs_load:
    push ax					; Save AX
    mov ah, BIOS_CHS_LOAD	; AH = 0x02
    mov al, 1				; Read 1 sector
    xor ch, ch				; Cylinder 0
    xor dh, dh				; Head 0
    int BIOS_DISK_INTERRUPT	; Ask the BIOS to read the sector
    jc  @f		         	; Exit on error
    pop ax                 	; Restore AX
    ret
@@: ; Error jump point
	pop ax					; Restore stack (not needed here)
	;; Print error message
    mov bx, DISK_ERROR_MSG
    call print_string
	;; Kill the system
    cli
    hlt

;; Disk address packet structure
; DPACK:
;         db PACKET_SIZE
;         db 0x00
; blkcnt: dw SECTOR_COUNT
; db_add: dw DEST_ADDR
;         dw MEMORY_ZERO_PAGE
; d_lba:  dd LBA_NUMBER
;         dd 0x00

DBG1: db "1: ", 0x00
DBG2: db "2: ", 0x00
DISK_ERROR_MSG: db "Error reading disk!", 0x0a, 0x0d, 0x00
