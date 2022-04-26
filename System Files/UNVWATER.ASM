; Information
; ßßßßßßßßßßß
;
;  Program Title : Unvwater.asm
;  External name : Unvwater.bin
;  Version       : 1.0
;  Start date    : 7/19/2001
;  Last update   : 
;  Author        : Universe and fULGORE
;  Copyright     : 
;  Description   : 100 byte water effect
;
;
;                  Ported to Amateur OS as a demo by Scott Billingley
;                  From source code found on internet


[BITS 16]                    ; Set 16 bit code generation
[ORG 0x0000]                 ; Set code start address to 00h (BIN file)
Start:
    mov ax,0xa000            ;Set video seg
    mov es,ax
    add ax,ax                ;ax=ax+ax segment is clear??
    mov ds,ax                ;set the ds
    mov ax,0x13
    int 0x10                 ;set mode 13

    mov dx,0x3c9             ;color palette port
aaa2:                        ;clear segment
    mov [di],ax              ;mov ax into ds:di
    dec di                   ;dec di, at the loop start di=0 so after first
    jnz aaa2                 ;dec di= 65535
ploop:                       ;palette loop
    xor ax,ax                ;clear ax
    out dx,al                ;lets write R to graphics port R=0
    out dx,al                ;lets write G to graphics port G=0
    mov al,bl
    shr al,2                 ;al=al/4
    out dx,al                ;lets write B to graphics port B=al
    inc bx                   ;bx=bx+1
    jnz ploop                ;fill the palette
main:                        ;main loop
    xor bx,bx                ;clear bx
    mov dx,3
    mov si,di
sux:                         ;matrix loop
    inc si
    mov al,byte[si-322]      ;matrix calculations
    add bx,ax
    mov al,byte[si+318]
    add bx,ax
    mov al,byte[si-2]
    add bx,ax
    dec dx
    jnz sux                  ;jmp to make matrix 3x3
    mov al,byte[di]          ;it's for out matrix
    sub bx,ax
    shl ax,2                 ;bx=bx-ax ax=ax*4 bx=bx-ax bx=bx/4 ax=bx
    sub bx,ax                ;ax=ax/128
    shr bx,2                 ;bx=bx-ax
    mov ax,bx
    shr ax,7                 ;b=bx a=ax so the way is
    sub bx,ax                ;b=(b-a*5)/4 a=b a=a/1128 bx=bx-ax
    mov [di],bl              ;moving our point to the memory
    inc di
    loop main
    
    dec cx                   ;cx=0 cx-1=65535
    rep movsb                ;moving our data to screen
    in al,0x60               ;check keyboard
    dec al                   ;if port 0x60<>1(esc) we will continue rendering
    jnz main
    mov al,0x03
    int 0x10                 ;text mode
    mov dh,0x00
    int 0x20                 ;exit
