bits 16
org 0

mov ax,0x8000               ;Set the data segment
mov ds,ax
mov es,ax
mov bx,0x0000
push bx
	 mov ax,0x9000
	 mov ss,ax      ;Setup stack
	 mov sp,0x1FFF  ;8 kb
	 sti            ;Turn interupts back on

	 mov [bootdrive],dl
	 call clear_screen
	
	 call reset_drive
	 jnc reset_ok

	 mov si,driveerr
	 call print_string
	 call reboot
reset_ok:                    ;Display the banner
	 push es
	 mov ax,0xb800
	 mov es,ax
	 mov si,banner
	 mov di,0x00
bstart:
	 lodsw
	 cmp ax,0x00
	 jz bend
	 mov [es:di],ax
	 add di,2
	 jmp bstart
bend:
	 pop es
	 mov ah,0x02
	 mov bh,0x0
	 mov dh,0x04
	 mov dl,0x0
	 int 0x10            ;move cursor to line 4
check_486:
	 pushfd
	 pushfd
	 pop eax
	 xor eax,0x00040000  ;change bit 21 of eflags
	 push eax
	 popfd
	 pushfd
	 pop ebx
	 popfd
	 cmp ebx,eax
	 mov si,msg486
	 je enable_A20
	 mov si,no486        ;No 486 exit.
	 call print_string
	 call reboot
enable_A20:
	 call print_string
	 cli
	 call a20wait
	 mov al,0xd1
	 out 0x64,al
	 call a20wait
	 mov al,0xdf
	 out 0x60,al
	 call a20wait
	 sti
test_A20:
	 xor ax,ax
	 mov fs,ax
	 dec ax
	 mov gs,ax
	 mov al,byte[fs:0]        ;get a byte from low memory
	 mov ah,al
	 not al
	 xchg al,byte[gs:10h]     ;put byte at ffff:0010
	 cmp ah,byte[fs:0]
	 mov [gs:10h],al
	 mov si,a20ok
	 jz a20_done
	 mov si,noa20
a20_done:call print_string

;   Try for flat real mode.
cli                          ;Kill the interrupt
push ds
push es
xor eax,eax
mov ax,ds
shl eax,4
add [GDT+2], eax
lgdt [GDT]                   ;Load the GDT
mov eax,cr0                  ;Swithc to pmode
inc ax
mov cr0, eax
mov bx,flat_data             ;Only pmode selector
mov es,bx
mov fs,bx                    ;Install 4gb limit
mov gs,bx
dec ax
mov cr0,eax                  ;switch back to real mode
pop es
pop ds
sti
mov ah,0x16
mov ecx, 8                   ;number of letters to print
mov si,flatmsg
mov edi,0x0b83c0             ;Address of video B800:05a0
Another:
mov eax,dword[si]            ;Get a dword from SI into eax
mov [fs:edi],eax             ;Put dword to fs:edi
add si,4
add edi,4
loop Another

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
	mov bx,0x0400                   ;copy root dir above bootcode
	call ReadSectors

;***
; Browse root dir for binary image
;***
	mov cx,WORD [MaxRootEntries]    ;load loop counter
	mov di,0x0400                   ;locate first root entry
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
	call print_string
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
		
	mov bx,0x1400                   ;copy FAT above bootcode
	call ReadSectors

;***
; Read image file into memory (0050:0000)
;***
	mov si,msgCRLF
	call print_string
	mov ax,0x0050
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
	mov bx,0x1400                   ;location of FAT in memory
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
	call print_string
	push WORD 0x0050
	push WORD 0x0000
	
	retf
	
FAILURE:
	mov si,msgFailure
	call print_string
	mov ah,0x00
	int 0x16                        ;wait for a key press
	int 0x19                        ;warm boot


print_string:

arround: lodsb
	 cmp al,0
	 jz .done
	 mov ah,0x0E
	 int 0x10
	 jmp arround
.done:
	 ret

clear_screen:
	 mov al,0x03
	 mov ah,0x00
	 int 0x10
	 ret
write_hex:
	 push cx
	 push dx
	 push bx
	 mov dh,0x0a
	 mov bx,0x0000
	 mov cx,0x0001
	 push ax
	 aam
	 or ax,0x3030
	 xchg al,ah
	 xchg ah,dh
	 int 0x10
	 xchg al,dh
	 int 0x10
	 pop ax
	 pop bx
	 pop dx
	 pop cx
	 ret

reset_drive:
	 mov ah,0
	 int 0x13
	 ret

kbdw0:   jmp short $+2
	 in al,0x60
a20wait: jmp short $+2
	 in al,0x64
	 test al,1
	 jnz kbdw0
	 test al,2
	 jnz a20wait
	 ret

reboot:
	 mov si,presskey
	 call print_string
	 mov ah,0
	 int 0x16
	 jmp 0xFFFF:0x0000        ;reboot
	
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
	mov si,tmsg                    ;msgProgress
	call print_string
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


flatmsg   db 0x46,0x1f,0x6c,0x1f,0x61,0x1f,0x74,0x1f,0x20,0x1f,0x6d,0x1f,0x6f,0x1f,0x64,0x1f,0x65,0x1f,0x20,0x1f,0x73,0x1f,0x65,0x1f,0x74,0x1f,0x75,0x1f,0x70,0x1f,0x21,0x1f
presskey  db 13,10,'Remove disk and press any key to reboot.',13,10,0
GDT       dw 0xF,GDT,0,0,0xFFFF,0,0x9200,0x8F
flat_data equ 8
tmsg     db 'a',0
noa20    db 'A20 failed.',13,10,0
a20ok    db 'A20 line set OK.',13,10,10,0
driveerr db 'Drive error.',13,10,0
msg486   db 'Found a 486 or greater cpu.',13,10,0
no486    db 'Need atleast a 486 to run Amateur OS.',13,10,0
bootdrive dw 0x0000

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
absoluteSector  db 0x00
absoluteHead    db 0x00
absoluteTrack   db 0x00
datasector      dw 0x0000
cluster         dw 0x0000
ImageName       db "AMATEUR COM"
msgCRLF         db 0x0D,0x0A,0x00
msgProgress     db ".",0x00
msgFailure      db "ERROR! Press any key to reboot..",0x00

; HEX Binary to HEX converter 
; by  Scott Billingsley 
; Input file :boot.img  Output file :boot.hex

banner  DB 0XC9,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XBB,0X1F
	DB 0XBA,0X1F,0X20,0X1F,0X20,0X1F,0X20,0X1F
	DB 0X20,0X1F,0X20,0X1F,0X20,0X1F,0X20,0X1F
	DB 0X20,0X1F,0X41,0X1F,0X4D,0X1F,0X41,0X1F
	DB 0X54,0X1F,0X45,0X1F,0X55,0X1F,0X52,0X1F
	DB 0X20,0X1F,0X4F,0X1F,0X53,0X1F,0X20,0X1F
	DB 0X57,0X1F,0X72,0X1F,0X69,0X1F,0X74,0X1F
	DB 0X65,0X1F,0X6E,0X1F,0X20,0X1F,0X62,0X1F
	DB 0X79,0X1F,0X20,0X1F,0X53,0X1F,0X63,0X1F
	DB 0X6F,0X1F,0X74,0X1F,0X74,0X1F,0X20,0X1F
	DB 0X42,0X1F,0X69,0X1F,0X6C,0X1F,0X6C,0X1F
	DB 0X69,0X1F,0X6E,0X1F,0X67,0X1F,0X73,0X1F
	DB 0X6C,0X1F,0X65,0X1F,0X79,0X1F,0X20,0X1F
	DB 0X69,0X1F,0X6E,0X1F,0X20,0X1F,0X53,0X1F
	DB 0X70,0X1F,0X68,0X1F,0X69,0X1F,0X6E,0X1F
	DB 0X78,0X1F,0X20,0X1F,0X43,0X1F,0X2D,0X1F
	DB 0X2D,0X1F,0X20,0X1F,0X61,0X1F,0X6E,0X1F
	DB 0X64,0X1F,0X20,0X1F,0X4E,0X1F,0X41,0X1F
	DB 0X53,0X1F,0X4D,0X1F,0X20,0X1F,0X20,0X1F
	DB 0X20,0X1F,0X20,0X1F,0X20,0X1F,0X20,0X1F
	DB 0X20,0X1F,0X20,0X1F,0X20,0X1F,0XBA,0X1F
	DB 0XC8,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XCD,0X1F
	DB 0XCD,0X1F,0XCD,0X1F,0XCD,0X1F,0XBC,0X1F
	DB 0X00,0X00,0X00,0X00,0X00,0X00,0X00,0X00
	DB 0X00,0X00,0X00,0X00,0X00,0X00,0X00,0X00
	DB 0X00,0X00,0X00,0X00,0X00,0X00,0X00,0X00
	DB 0X00,0X00,0X00,0X00,0X00,0X00,0X00,0X00
       

