use16

BIOS_GET_DRIVE_PARAMETERS = 0x08

;; Global variables to hold drive information
drive_number:      db 0x00
sectors_per_track: db 0x00
total_heads:       db 0x00

get_drive_parameters:
	pusha ; TODO: REPLACE WITH 8086 COMPATIBLE CODE
	mov ah, BIOS_GET_DRIVE_PARAMETERS	; Tell the BIOS we want drive parameters
	mov dl, [drive_number]				; Grab the saved drive number
	xor di, di							; Set di = 0 (pleases old buggy BIOSes)
	mov es, di							; Set di = 0 (pleases old buggy BIOSes)
	int BIOS_DISK_INTERRUPT				; Ask the BIOS for the drive parameters
	jc @f								; On error jump to the error code
	mov al, cl							; AL = Sectors per track (almost)
	and al, 0x3f						; Mask the upper two bits
	mov [sectors_per_track], al			; Save the sectors per track for later use
	;; Read the total number of heads
	mov al, dh							; AL = number of heads - 1
	inc al								; AL = number of heads
	mov [total_heads], al				; Save total number of heads for later use
	popa ; TODO: REPLACE WITH 8086 COMPATIBLE CODE
	ret									; Return to get_drive_parameters caller
@@: ; Error Jump Point
	;; Print error message
    mov bx, DISK_ERROR_MSG
    call print_string
	;; Kill the system
    cli
    hlt
