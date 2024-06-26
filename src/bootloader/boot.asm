org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;Fat12 Header
jmp short start
nop

bdb_oem: db 'MSWIN4.1'
bdb_bytes_per_second: dw 512
bdb_sectors_per_cluster: db 1 
bdb_reserved_sectors: dw 1 
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors: dw 2880 ;2880*512 = 1.44MB
bdb_media_descriptor_type: db 0F0h
bdb_numbers_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2 
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; Extend Boot rec 
ebr_drive_number: db 0 
                  db 0 
ebr_signiture:    db 29h 
ebr_volume:       db 12h, 34h, 56h, 69h ; serial number (78h in tutorial Last val)
ebr_volume_lable: db 'HOBBYLOS OS' ; Must be padded with spaces, value doesnt matter
ebr_system_id:    db 'FAT12  '



start:
  jmp main

; prints a string to screen
; Parameters:
;   ds:si points to string
puts:
  ; registers who will modify 
  push si 
  push ax

.loop:
  lodsb   ; loads next charekter in al 
  or al, al
  jz .done
  ;jmp .loop

  mov ah, 0x0e  ; bios interupt
  mov bh,0
  int 0x10

  jmp .loop

.done:
  pop ax
  pop si 
  ret


main:

; setting up data segments
  mov ax, 0 
  mov ds, ax
  mov es, ax

;stack setup
  mov ss, ax
  mov sp, 0x7C00

  mov [ebr_drive_number], dl
  mov ax, 1 ;LBA set to 1, second disk sector
  mov cl, 1 
  mov bx, 0x7E00
  call disk_read

  ; print msg 
  mov si, msg_hello
  call puts
  cli
  hlt

floppy_err: 
  hlt
.halt:
  cli
  hlt 
; Disk Routines
;
; Converts LBH Adress to CHS Adress 
; params:
;   ax: LBA Adress
;  Returns:
;   cx [bits 0-5]: sector number
;   cx [bits 6-16]: cylinder
;   dh: Head 
lba_to_chs:

  push ax
  push dx 

  xor dx, dx ;0
  div word [bdb_sectors_per_track] ;ax = LBA
  inc dx ; dx = LBA 5 Sectors per track + 1 
  mov cx, dx

  xor dx, dx
  div word [bdb_heads]

  mov dh, dl
  mov ch, al
  shl ah, 6
  or cl, ah 

  pop ax
  mov dl, al
  pop ax 
  ret

; Read sectors from disk 
; Params:
;   ax: LBA adress
;   cl: num of sectors to Read
;   dl: drive number
;   es:bx: memory adress to store data
disk_read:

  push ax
  push bx
  push cx
  push dx
  push di

  push cx ;temp. save cl 
  call lba_to_chs
  pop ax

  mov ah, 02h
  mov di, 3 ; retry time
  

.retry:
  pusha ; save all registers
  stc   ; set carry flag
  int 13h ; carry flag cleard = it worked
  jnc .done
  ; read unsucessfull
  popa
  call disk_reset

  dec di
  test di, di
  jnz .retry

.fail:
  jmp floppy_err

.done: 
  popa

  pop di 
  pop dx 
  pop cx
  pop bx
  pop ax
  ret

; Reset disk controller
; di = driver num
disk_reset:
  pusha
  mov ah, 0 
  stc
  int 13h 
  jc floppy_err
  popa 
  ret

msg_hello: db "Hello World!", ENDL,0

times 510-($-$$) db 0
dw 0AA55h
