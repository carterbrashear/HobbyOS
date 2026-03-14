# Hobby OS

---

## Bootloader Stage 1
Stage 1 of the bootloader is mostly complete. The only thing it does is load the next few sectors of the disk and runs it.
You must change number of sectors depending on the length of the code.
### TODO
* Make disk reading code take into account loaded sectors per track so we can increase capacity

## Bootloader Stage 2
### Video
The video driver in the stage 2 code uses the BIOS while we have it to find the best video mode that supports 8 bit colors and switches to it
### Protected Mode
The stage 2 bootloader also switches from 16-bit real mode to 32-bit protected mode.
In the process it loads a flat global descriptor table. By that I mean all memory is segmented for both code and data.

## Assumptions
Without any of the following items, the computer will not be able to run the bootloader properly

* Drive number is loaded into DL on boot by the BIOS
* BIOS has VBE support
* Video mode 0x13 or other mode with a greater resolution and uses 8-bit colors exists
* BIOS interrupt 0x12 and 0x13 are supported
* Enabling A20 by BIOS or by keyboard controller is supported
