org 0x7C00
bits 16

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

  ; print msg 
  mov si, msg_hello
  call puts

  hlt

.halt:
  jmp .halt

msg_hello: db "Hello World!", 0

times 510-($-$$) db 0
dw 0AA55h
