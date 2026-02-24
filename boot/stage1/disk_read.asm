use16

define SECTOR_COUNT 5
define SECTOR_COUNT_LBA SECTOR_COUNT + 1
define DEST_ADDR 0x7e00
define LBA_NUMBER 0x01
define PACKET_SIZE 0x10
define BIOS_LBA_LOAD 0x42
define BIOS_DISK_INTERRUPT 0x13
define MEMORY_ZERO_PAGE 0x00
define BIOS_CHS_LOAD 0x02
DRIVE_NUMBER: db 0x00

disk_read:
    ;; Try LBA load first
    pusha
    call lba_load
    jnc  disk_read_done
    call chs_load
    jc   disk_error
disk_read_done:
    popa
    ret

lba_load:
    mov si, DPACK
    mov ah, 0x42
    mov dl, [DRIVE_NUMBER]
    int BIOS_DISK_INTERRUPT
    ret

chs_load:
    mov ah, BIOS_CHS_LOAD
    mov al, 1
    xor ch, ch ; Cylinder 0
    xor dh, dh ; Head 0
    mov cl, 2 ; Sector start (1 is boot sector)
    mov dl, [DRIVE_NUMBER]
    xor bx, bx
    mov es, bx
    mov bx, DEST_ADDR
    int 0x13
    ret

disk_error:
    mov  bx, DISK_ERROR_MSG
    call print_string
    cli
    hlt

;; Disk address packet structure
DPACK:
        db PACKET_SIZE
        db 0x00
blkcnt: dw SECTOR_COUNT
db_add: dw DEST_ADDR
        dw MEMORY_ZERO_PAGE
d_lba:  dd LBA_NUMBER
        dd 0x00

DISK_ERROR_MSG: db "Error reading disk!", 0x0a, 0x0d, 0x00
