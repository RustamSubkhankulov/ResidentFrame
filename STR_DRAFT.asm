;--------------------RITOA-----------------------
; 
; Description: 
;
; Entry: DS - points to the segment, where string
;             will be stored
;        SI - points tot the start of memory 
;             where string will be stored
;        CL - base of the numeral syste
;        Note: CL can be value only from 2 to 10
;
;        BX - number to be translated
;
; Exit : SI - points to the first symbol in 
;             string
; Destr: AX, CX
;------------------------------------------------

ritoa   proc

        mov ch, 1               ; lenght at least is 1
        mov ax, bx              

    ritoaCountLoop:             ; counting number of digits 
        div cl                  ; in number to get offset
                                
        cmp al, 0
        je ritoaStopCount

        inc ch
        cbw
        jmp ritoaCountLoop

    ritoaStopCount:
        mov al, ch
        cbw
        add si, ax
        dec si                  ; si points to the last symb

        mov ax, bx

    ritoaLoop:
        div cl
        add ah, '0'             ; converting symbol code
        mov ds:[si], ah         ; store symbol in string

        cmp al, 0
        je ritoaRet
        cbw
        dec si                  ; going from end to start of string
        jmp ritoaLoop

    ritoaRet:
        ret

ritoa   endp

;--------------------RHTOA------------------------
;
; Description: Translates hexadecimal number into 
;              string
; Entry:       DS - points to the segment, where
;                   string will be stored
;              SI - points to the address of the
;                   first symbol in string
;              BX - number to be translated (less than 200)
; Exit:        SI remains it value
; Destr:       AX, CX, DI, BX, DL
;------------------------------------------------

rhtoa proc

        mov ch, 1               ; lenght at least is 1
        mov ax, bx              

        ;
        mov cl, 16d
        ;

    rhtoaCountLoop:             ; counting number of digits 
        div cl                  ; in number to get offset
                                
        cmp al, 0
        je rhtoaStopCount

        inc ch
        cbw
        jmp rhtoaCountLoop

    rhtoaStopCount:
        mov al, ch
        cbw
        add si, ax
        dec si                  ; si points to the last symb

        mov ax, bx

    lea di, SYMB_TABLE
    xor bh, bh

    rhtoaLoop:
        div cl
        mov bl, ah
        ;add ah, '0'             ; converting symbol code and
        ;mov ds:[si], [bx + di]   ; store symbol in string
        mov dl, [bx+di]
        mov ds:[si], dl

        cmp al, 0
        je rhtoaRet
        cbw
        dec si                  ; going from end to start of string
        jmp rhtoaLoop

    rhtoaRet:
        ret

rhtoa   endp


SYMB_TABLE db '0123456789ABCDEF' 


;--------------------SITOA-----------------------
; 
; Description: 
;
; Entry: first  - points to the segment, where 
;                string will be stored
;        second - points tot the start of memory 
;                 where string will be stored
;        third  - base of the numeral system
;
;        Note: CL can be value only from 2 to 10
;        fourth - number to be converted
;
; Exit : SI - points to the first symbol in 
;             string
; Destr: AX, CX, DS
;------------------------------------------------

sitoa   proc

        push bp                 ; prologue
        mov  bp, sp

        mov cx, [bp + 6 ]       ; getting args
        mov si, [bp + 8 ]
        mov ds, [bp + 10]

        mov ch, 1
        mov ax, [bp + 4]

    sitoaCountLoop:
        div cl

        cmp al, 0
        je sitoaStopCount

        inc ch
        cbw
        jmp sitoaCountLoop

    sitoaStopCount:
        mov al, ch
        cbw
        add si, ax
        dec si 

        mov ax, [bp + 4]

    sitoaLoop:
        div cl
        add ah, '0'
        mov ds:[si], ah

        cmp al, 0
        je sitoaRet
        cbw
        dec si
        jmp sitoaLoop

    sitoaRet:
        pop bp                  ; epilogue
        ret

sitoa   endp

