use16

SECTOR_COUNT =          5
SECTOR_COUNT_LBA =      SECTOR_COUNT + 1
DEST_ADDR =             0x7e00
LBA_NUMBER =            0x01
PACKET_SIZE =           0x10
BIOS_LBA_LOAD =         0x42
BIOS_DISK_INTERRUPT =   0x13
MEMORY_ZERO_PAGE =      0x00
BIOS_CHS_LOAD =         0x02

DRIVE_NUMBER: db 0x00

disk_read:
    pusha
chs_load:
    mov ah, BIOS_CHS_LOAD
    mov al, 9  ; Sectors to read
    xor ch, ch ; Cylinder 0
    xor dh, dh ; Head 0
    mov cl, 2  ; Sector start (1 is boot sector)
    mov dl, [DRIVE_NUMBER]
    xor bx, bx
    mov es, bx
    mov bx, DEST_ADDR
    int 0x13
    popa
    ret

disk_error:
    mov  bx, DISK_ERROR_MSG
    call print_string
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

DISK_ERROR_MSG: db "Error reading disk!", 0x0a, 0x0d, 0x00
