;*******************
; Boot.asm 
; Bootloader writen by Scott Billingsley
; using part of Mathew Vea's tutorial and source...
; http://www.geocities.com/mvea/bootstrap.htm
; Compile to binary using NASM
; NASM -O boot.bin boot.asm
;
;********************
        BITS 16
        ORG 0x0             ;Tells nasm the first byte will be here..
;***        
;Setup to use the DOS file system...
;***
jmp begin_boot          ;Jump over the data area...

OEM_ID                  db 'AMATEUR0'           ;OEM identification
BytesPerSector          dw 0x0200               ;Bytes per sector
SectorsPerCluster       db 0x01                 ;Sectors per cluster
ReservedSectors         dw 0x0001               ;Number of reserved sectors
TotalFATs               db 0x02                 ;Number of FATs
MaxRootEntries          dw 0x0E0                ;Number of dirs in root
TotalSectorsSmall       dw 0x0B40               ;Number of sectors in volume
MediaDescriptor         db 0x0F0                ;Media descriptor
SectorsPerFAT           dw 0x0009               ;Number of sectors per FAT
SectorsPerTrack         dw 0x0012               ;Number of sectors per track
NumHeads                dw 0x0002               ;Number of read/write heads
HiddenSectors           dd 0x00000000           ;Number of hidden sectors
TotalSectorsLarge       dd 0x00000000           ;Total Sectors large
DriveNumber             db 0x00                 ;Drive number
Flags                   db 0x00                 ;Flags
Signature               db 0x29                 ;Signature
VolumeID                dd 0xffffffff           ;Volume ID
VolumeLabel             db "AMATEUR BOOT"        ;Volume Label
SystemID                db "FAT12   "           ;SystemID
;***
; Disk should still be able to work on DOS...
;***
;***        
; Data area...
;***
bootmsg         db 'Booting Amateur OS',13,10,0
absoluteSector  db 0x00
absoluteHead    db 0x00
absoluteTrack   db 0x00
datasector      dw 0x0000
cluster         dw 0x0000
ImageName       db "LOADER  BIN"
msgCRLF         db 0x0D,0x0A,0x00
msgProgress     db ".",0x00
msgFailure      db "ERROR! Press any key to reboot..",0x00

;***
; procedure message
; Display ASCII string at ds:si via BIOS
;***
message:
        lodsb                   ;Load the next character
        or al,al                ;Test for a NUL charactor
        jz FINISHED                ;
        mov ah,0x0E             ;BIOS Teletype
        mov bx,0x0007           ;White on black
        int 0x10                ;Put it on the screen..
        jmp message
FINISHED:
        ret
;***
; Prcedure ReadSectors
; read cx sectors from disk starting at ax into memory location es:bx
;***
ReadSectors:
.MAIN
        mov di,0x0005           ;five retries for error
.SECTORLOOP
        push ax
        push bx
        push cx
        call LBACHS
        mov ah,0x02                     ;BIOS read sector
        mov al,0x01                     ;read one sector
        mov ch,BYTE[absoluteTrack]      ;track
        mov cl,BYTE[absoluteSector]     ;sector
        mov dh,BYTE[absoluteHead]       ;head
        mov dl,BYTE[DriveNumber]        ;drive
        int 0x13                        ;invoke BIOS
        jnc .SUCCESS                    ;test for read error
        xor ax,ax                       ;BIOS reset disk
        int 0x13                        ;invoke BIOS
        dec di
        pop cx
        pop bx
        pop ax
        jnz .SECTORLOOP                 ;attempt to read again
        int 0x18
.SUCCESS
        mov si,msgProgress
        call message
        pop cx
        pop bx
        pop ax
        add bx,WORD[BytesPerSector]     ;queue next buffer
        inc ax                          ;queue next sector
        loop .MAIN
        ret
;***
; Procedure ClusterLBA
; convert FAT cluster into LBA addressing scheme
; LBA=(cluster-2)*sectors per cluster
;***
ClusterLBA:
        sub ax,0x0002                   ;zero base cluster number
        xor cx,cx
        mov cl,BYTE[SectorsPerCluster]  ;convert byte to word
        mul cx
        add ax,WORD[datasector]         ;base data sector
        ret
;***
; Procedure LBACHS
; convert ax LBA addressing scheme to CHS addressing scheme
; absolute sector=(logical sector/sectors per track)+1
; absolute head=(logical sector/sectors per track)MOD number of heads
; absolute track=logical sector/(sectors per track * number of heads)
;***
LBACHS:
        xor dx,dx                       ;prepare dx:ax for operation
        div WORD[SectorsPerTrack]
        inc dl                          ;adjust for sector 0
        mov BYTE[absoluteSector],dl
        xor dx,dx
        div WORD[NumHeads]
        mov BYTE[absoluteHead],dl
        mov BYTE[absoluteTrack],al
        ret

;***                                           
; Start the main code...
;***
begin_boot:
        cli                     ;Turn off interupts while we set things up
        mov ax,0x7C0            ;Set the offset to 0:07C00h
        mov ds,ax               ;And set the DS
        mov es,ax
        mov fs,ax
        mov gs,ax
;***
; Create a stack...
;***
        mov ax,0x0000
        mov ss,ax
        mov sp,0xFFFF
        sti                     ;Turn the interupts back on...
;***    Post the boot message..
        mov si,bootmsg                              
        call message
;***
; Compute the size of the root dir and store in cx
;***
        xor cx,cx
        xor dx,dx
        mov ax,0x0020                   ;32 byte dir entry
        mul WORD [MaxRootEntries]       ;total size of dir
        div WORD [BytesPerSector]       ;sectors used by dir
        xchg ax,cx
;***
; Compute the location of root dir and store in ax
;***
        mov al,BYTE [TotalFATs]         ;number of FATs
        mul WORD [SectorsPerFAT]        ;sectors used by FATs
        add ax, WORD [ReservedSectors]  ;adjust for bootsector
        mov WORD [datasector],ax        ;base of root dir
        add WORD [datasector],cx
;***
; Read root dir for binary image
;***
        mov bx,0x0200                   ;copy root dir above bootcode
        call ReadSectors
;***
; Browse root dir for binary image
;***
        mov cx,WORD [MaxRootEntries]    ;load loop counter
        mov di,0x0200                   ;locate first root entry
.LOOP:
        push cx                         
        mov cx,0x000B                   ;eleven character name
        mov si,ImageName                ;image name to find
        push di
rep cmpsb                               ;test for entry match
        pop di
        je LOAD_FAT
        pop cx
        add di,0x0020                   ;queue next dir entry
        loop .LOOP
        jmp FAILURE
LOAD_FAT:
;***
; Save starting cluster of boot image
;***
        mov si,msgCRLF
        call message
        mov dx, WORD[di+0x001A]
        mov WORD[cluster],dx            ;file's first cluster
;***
; Compute size of FAT and store in cx
;***
        xor ax,ax
        mov al,BYTE[TotalFATs]          ;Number of FATs
        mul WORD[SectorsPerFAT]         ;sectors used by FATs
        mov cx,ax
;***
; Compute location of FAT and store in ax
;***
        mov ax,WORD[ReservedSectors]    ;adjust for bootsector
;***
; Read FAT into memory (7C00:0200)
;***
        mov bx,0x0200                   ;copy FAT above bootcode
        call ReadSectors
;***
; Read image file into memory (8000:0000)
;***
        mov si,msgCRLF
        call message
        mov ax,0x8000
        mov es,ax                       ;destination for image
        mov bx,0x0000                   ;destination for image
        push bx
LOAD_IMAGE:
        mov ax,WORD[cluster]            ;cluster to read
        pop bx                          ;buffer to read into
        call ClusterLBA                 ;convert cluster to LBA
        xor cx,cx
        mov cl,BYTE[SectorsPerCluster]  ;sectors to read
        call ReadSectors
        push bx
;***
; Compute next cluster
;***
        mov ax,WORD[cluster]            ;identify current cluster
        mov cx,ax                       ;copy current cluster
        mov dx,ax                       ;copy current cluster
        shr dx,0x0001                   ;divide by two
        add cx,dx                       ;sum for (3/2)
        mov bx,0x0200                   ;location of FAT in memory
        add bx,cx                       ;index of FAT
        mov dx,WORD[bx]                 ;read two byte from FAT
        test ax,0x0001
        jnz .ODD_CLUSTER
.EVEN_CLUSTER:
        and dx,0000111111111111b        ;take low twelve bits
        jmp .DONE
.ODD_CLUSTER:
        shr dx,0x0004                   ;take high twelve bits
.DONE
        mov WORD[cluster],dx            ;store new cluster
        cmp dx,0x0FF0
        jb LOAD_IMAGE
DONE:
        mov si,msgCRLF
        call message
        push WORD 0x8000
        push WORD 0x0000
        retf
FAILURE:
        mov si,msgFailure
        call message
        mov ah,0x00
        int 0x16                        ;wait for a key press
        int 0x19                        ;warm boot

        
        times 510-($-$$) db 0
        dw 0xAA55
                 
