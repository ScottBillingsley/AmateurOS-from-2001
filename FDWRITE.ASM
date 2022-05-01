; Information
; ßßßßßßßßßßß
;
;  Program Title : FDWRITE
;  External name : FDWRITE.COM
;  Version       : 1.0
;  Start date    : 6/29/2001
;  Last update   : 6/29/2001
;  Author        : Scott Billingsley
;  Copyright     : freeware
;  Language	 : NASM 0.95
;  Description   : A program to write a file to drive A:
;                            ** 3.5 disk only **
;                  Writen in NASM-IDE 1.1 and NASM 0.95.
;                  User can choose Head,Cylinder and Sector
;                  Does not update FAT, Does check before write
;                  ** WARNING: This program will kill data!!! *****
;                  Use at your own risk..

[BITS 16]
[ORG 0x0100]
[SECTION .text]

START:   mov ah,0x09
         mov dx,message              ;Display the startup message
         int 0x21
         xor ah,ah
         int 0x16                     ;Get a key
         cmp al,0x79                  ;Is it a 'y'
         je CONT
         cmp al,0x59                  ;Is it a 'Y'
         je CONT
         ret                          ;If not exit
CONT:    mov dl,al
         mov ah,0x06
         int 0x21                     ;Print the letter

         mov ah,0x09
         mov dx,Infile                 ;Ask the file name
         int 0x21

         xor si,si                     ;Get the file name
INLOOP:  mov ah,0x01
         int 0x21                      ;Get a key
         cmp al,13                     ;Is it enter?
         je INDONE                     ;If so jump out
         mov byte [imgfile+si],al      ;Put the byte in the buffer
         inc si                        ;Next byte position
         jmp INLOOP                    ;Do it again
INDONE:  mov byte [imgfile+si],0       ;Put a zero at the end

         mov ax,0x3d00
         mov dx,imgfile
         int 0x21                     ;Open image file
         mov dx,ErrorS
         jc TOTALERROR

         mov [handle],ax              ;Save file handle

         mov ah,0x09
         mov dx,OSuccess
         int 0x21                     ;Show the file opened OK


         mov ah,0x3f                  ;Read from file
         mov bx,[handle]
         mov cx,0x1000            ;# of bytes
         mov dx,Buffer                ;where to put it
         int 0x21
         mov dx,RError
         jc TOTALERROR
         mov bx,[handle]
         mov ah,0x3e
         int 0x21                     ;close file

         xor ax,ax
         mov dl,0
         int 0x13                      ;reset the floppy
         mov dx,FError
         jc TOTALERROR
         mov ah,0x09
         mov dx,SuccessF
         int 0x21
HEAD0:
         mov ah,0x09
         mov dx,HInput
         int 0x21
         mov ah,0x0
         int 0x16                      ;Get a key
         mov ah,0x0e
         mov bh,0x0
         int 0x10                      ;Show it
         sub al,48
         cmp al,0
         jl badkey
         cmp al,1
         jg badkey
         mov byte [head],al
         jmp CYLINDER
TOTALERROR:
         jmp MERROR

badkey:  mov ah,0x09
         mov dx,HError
         int 0x21
         jmp HEAD0
CYLINDER:
         mov ah,0x09
         mov dx,CInput
         int 0x21
         mov ah,0x0
         int 0x16                      ;Get a key
         cmp al,13
         je Cbadkey
         mov ah,0x0e
         mov bh,0x0
         int 0x10                      ;Show it
         sub al,48
         cmp al,0
         jl Cbadkey
         cmp al,9
         jg Cbadkey
         mov byte [cylinder],al
         jmp CSECOND
Cbadkey:
         mov ah,0x09
         mov dx,CError
         int 0x21
         jmp CYLINDER
CSECOND:
         mov ah,0x0
         int 0x16                     ;Get a key
         xor bl,bl                    ;Clear bl incase of jump
         cmp al,13
         je CFOURTH                     ;If enter store number
         mov ah,0x0e
         mov bh,0x0
         int 0x10                      ;Show it
         sub al,48
         cmp al,0
         jl Cbadkey
         cmp al,9
         jg Cbadkey
         mov bl,al
CTHRID:
         mov al, byte [cylinder]
         mov cl,0xA
         mul cl                       ;Multiply cylinder by 10
         add al,bl                     ;Add the second number
         mov byte [cylinder],al
         mov ah,0x0
         int 0x16                     ;Get a key
         xor bl,bl                    ;Clear bl incase of jump
         cmp al,13
         je CFOURTH                     ;If enter store number
         mov ah,0x09
         mov dx,ZError
         int 0x21
         jmp CYLINDER             ;If # larger than 99, fuss and jump back
CFOURTH:
SECTOR:
         mov ah,0x09
         mov dx,SInput
         int 0x21
         mov ah,0x0
         int 0x16                      ;Get a key
         cmp al,13
         je Sbadkey
         mov ah,0x0e
         mov bh,0x0
         int 0x10                      ;Show it
         sub al,48
         cmp al,0
         jl Sbadkey
         cmp al,9
         jg Sbadkey
         mov byte [sector],al
         jmp SSECOND
Sbadkey:
         mov ah,0x09
         mov dx,CError
         int 0x21
         jmp SECTOR
SSECOND:
         mov ah,0x0
         int 0x16                     ;Get a key
         xor bl,bl                    ;Clear bl incase of jump
         cmp al,13
         je SFOURTH                     ;If enter store number
         mov ah,0x0e
         mov bh,0x0
         int 0x10                      ;Show it
         sub al,48
         cmp al,0
         jl Sbadkey
         cmp al,9
         jg Sbadkey
         mov bl,al
STHRID:
         mov al, byte [sector]
         mov cl,0xA
         mul cl                       ;Multiply cylinder by 10
         add al,bl                     ;Add the second number
         mov byte [sector],al
         mov ah,0x0
         int 0x16                     ;Get a key
         xor bl,bl                    ;Clear bl incase of jump
         cmp al,13
         je SFOURTH                     ;If enter store number
         mov ah,0x09
         mov dx,ZError
         int 0x21
         jmp SECTOR             ;If # larger than 99, fuss and jump back
SFOURTH:

LOOP1:   mov ah,0
         mov dl,0
         int 0x13                      ;reset floppy
         mov al,8                      ;write 4 sectors
         mov ah,3
         mov ch,byte [cylinder]
         mov cl,byte [sector]
         mov dh,byte [head]
         mov dl,0x0
         mov bx,Buffer
         int 0x13
         jnc WRITEOK
         dec byte [count]
         jz MERROR
         jmp LOOP1

WRITEOK: mov ah,0x09
         mov dx,SuccessS
         int 0x21


         pop bx                       ;clean the stack
         mov dx,MErrorS
         jc MERROR
         mov dx,SuccessZ
MERROR:  mov al,0x09
         int 0x21
         mov al,1
         mov ah,0x4c
         int 0x21

[SECTION .data]
message   db '                  FDWrite Kernel Installer',13,10,13,10
          db '             This program will write a file to',13,10
          db '             floppy disk in drive A: Make sure',13,10
          db '             that the file is in the current',13,10
          db '             directory. Size is linited to 4k.',13,10,10
          db '**** Warning: This program can kill data!!! *****',13,10,10
          db 'Continue? [Y/N] ',0x24
Infile   db 13,10,'Name of file to write                : ',0x24
OSuccess db 13,10,'*****   File opened successfully *****',0x24
CError   db 13,10,'*****   Numbers 0 thru 99 only   *****',0x24
ErrorS   db 13,10,'*****   Error opening file       *****',0x24
FError   db 13,10,'*****   Floppy reset ERROR       *****',0x24
HError   db 13,10,'***     Only head 0 and 1 supported. *',0x24
MErrorS  db 13,10,'*****   ERROR writing to disk   ******',0x24
OError   db 13,10,'*** ERROR File too large for buffer **',0x24
RError   db 13,10,'*****   ERROR reading file      ******',0x24
ZError   db 13,10,'**  Only numbers up to 99 supported. *',0x024
SuccessF db 13,10,'**  Floppy initialised successfully! *',0x24
SuccessS db 13,10,'*****    File writen to disk.    *****',0x24
SuccessZ db 13,10,'Success...Thanks for using FDWrite....',13,10,0x24
HInput   db 13,10,'Input head to write to               : ',0x24
CInput   db 13,10,'Input cylinder to write              : ',0x24
SInput   db 13,10,'Input sector to write                : ',0x24
count    db 3
head     db 0
cylinder db 0
sector   db 0
imgfile: resb 80
handle:  resb 1
filesize: resb 10
Buffer: times 4608 db 0
