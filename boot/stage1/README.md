# Bootloader Stage 1
This first stage of the bootloader's only job is to read the next few sectors of the disk (where the second stage is stored) and load it to 0x7e00 in memory. The goal is for both the code and data combined must be below 256 bytes so the remaining 255 bytes can be reserved for signatures. All assembly files must be optimized for space while keeping compatability assumptions to a minimum.

## stage1.asm
This mostly calls functions held in `graphics.asm` and `disk_read.asm`. The only goal of this is to load the next few sectors in to memory, check the signature and then jump to it.
