.model tiny
.code 
org 100h

;===================MACRO========================

.PAUSE		macro           ; getchar();
		    nop
		    xor ah, ah
		    int 16h
		    nop
		    endm
    
;=================CONSTANTS======================

CMND_LN     equ 081h        ; start of the command 
                            ; line address

;----------------VIDEO-MEMORY--------------------

VIDEOSEG    equ 0B800h      ; address of video memory segment
FRAME_LEN   = 80           ; lenght of the video frame
FRAME_WID   = 25            ; width  of the video frame

CENTER_LINE = FRAME_WID / 2 ; center line   of the video frame
CENTER_COLM = FRAME_LEN / 2 ; center column of the video frame

START_LINE = CENTER_LINE - WID / 2
START_COLM = CENTER_COLM - LEN / 2

;--------------INTERRUPTION-CODES----------------

PUTS		equ 09h	    	; interrupt code for printing line		
STOP		equ 04Ch    	; interrupt code for terminating

;--------------FRAME-PARAMETERS------------------

WID	    	= 3d		    ; width  of the frame
LEN		    = 5d		    ; lenght of the frame
COLOR_ATTR  = 4Eh           ; color attribute for the frame
 
;===============ASCII-SYMBOL-CODES===============

SPACE	 	= 020h		    ; srace symbol
NWLINE		= 0Ah		    ; \n
GACHI		= 0Bh		    ; GACHI SYMBOL for 300$ bucks

;===================MAIN=BODY====================

Start:      call GetTypeAndText
            call DrawFrame

            cmp dh, 0
            je Terminate

            call WriteText
            .PAUSE

        Terminate:
            mov ah, STOP
            xor al, al
            int 21h         ; terminates process

;=============FUNCTIONS DEFINITIONS==============

locals RT

;------------------------------------------------
;
; WriteText
;
; Entry: DH - number of symbols are to be printed
; Exit : None
; Destr:
;------------------------------------------------

WriteText       proc

                mov al, dh
                cbw
                mov cx, ax

                lea si, FRAME_TEXT
                shr dh, 1
                mov bh, CENTER_COLM
                sub bh, dh

                xor bl, bl
                xchg bl, bh
                
                add bx, CENTER_LINE  * FRAME_LEN
                shl bx, 1
                mov di, bx

                mov ah, COLOR_ATTR

            RTloop:
                lodsb
                stosw
                loop RTloop

                ret
                endp   

;------------------------------------------------
;
; GetTypeAndText
;
; Entry: None
; Exit : DL - frame type, DH - number of symbols in note
; Destr: AX, BX, SI, Cx, DI
;------------------------------------------------

GetTypeAndText  proc

                xor dh, dh
                mov si, CMND_LN + 1
                mov dl, [si]
                
                cmp dl, '$'
                jne RTnoText

                inc si
                call GetFrameText

            RTnoText:
                call GetFrameType

            RTret:
                ret
                endp

;------------------------------------------------
;
; GetFrameText
;
; Entry: BX - address of the first symbol after '$' int frame text
; Exit:
; Destr: AX, BX, CX, SI
;------------------------------------------------

GetFrameText    proc

                lea bx, FRAME_TEXT
                mov cx, LEN - 2

            RTloop:
                lodsb
                cmp al, '$'
                je RTisSpace

                mov [bx], al
                inc bx
                inc dh

                loop RTloop

            RTis$:
                lodsb
                mov dl, '$'
                inc si
                jmp RTcompare

            RTisSpace:
                lodsb
                mov dl, ' '
                jmp RTcompare

            RTcompare:
                cmp dl, al
                jne RTinputErr
                jmp RTret

            RTinputErr:
                mov ah, 09h
                mov dx, offset InputErrMsg
                int 21h
                jmp Terminate

            RTret:
                ret
                endp

InputErrMsg db 'Incorrect format of the input$'

;------------------------------------------------
; GetFrameType
;
; Entry: SI - address of the frame type symbol in cmnd line
; Exit : DL - frame type
; Destr: AX, BX, SI, DL
;------------------------------------------------

GetFrameType    proc

                mov dl, [si]
                sub dl, '0'

                cmp dl, 3
                jne RTret

                add si, 2
                call GetUserFrame

            RTret:
                ret 
                endp

;------------------------------------------------
; 
; GetUserFrame
;
; Entry: SI points to the first symbol of user frame symbols
; Exit : None
; Destr: AX, BX, SI
;------------------------------------------------

GetUserFrame    proc

                xor ah, ah
                lea bx, UserFrame

                mov cx, 9

            RTloop:
                lodsb                     

                mov [bx], al
                inc bx

                loop RTloop

                ret
                endp

;------------------------------------------------
; DrawLine
;
; Entry: AH - color attribute, CX - lenght 
;        SI - address of symbol string
;        DI - destination address
; Exit : None   
; Desrt: AX, CX, SI, DI
; After process: SI:=SI + 3
;------------------------------------------------

DrawLine    proc

            lodsb
            stosw

            lodsb
            sub cx, 2
            jbe RTstopDrwLn 
            rep stosw

            lodsb
            stosw 

            jmp RTret

        RTstopDrwLn:
            mov ah, 09h
            mov dx, offset DrwLnErrMsg
            int 21h
            jmp Terminate

        RTret:
            ret
            endp    

DrwLnErrMsg     db 'Incorrect lenght of the frame$' 

;------------------------------------------------
;
; DrawFrame
;
; Entry: DL - frame type    
; Exit : None
; Destr: AX, BX, CX, DI, SI
;------------------------------------------------

DrawFrame   proc 
    ;First line of frame
            mov al, dl
            mov ah, 9
            mul ah
            xor ah, ah
            mov bx, ax

            lea si, FRAMES[bx]
            mov di, (START_LINE * FRAME_LEN + START_COLM) * 2
            
            mov ah, COLOR_ATTR
            mov cx, LEN

            mov bx, VIDEOSEG
            mov es, bx

            call DrawLine

    ; Middle lines of frame
            mov bx, WID - 1
            cmp bx, 0
            JBE RTstop

        RTmiddleLines:
            mov cx, LEN

            mov al, bl
            add al, START_LINE - 1
            mov ah, FRAME_LEN * 2
            mul ah
            add ax, START_COLM * 2
            mov di, ax

            mov ah, COLOR_ATTR

            call DrawLine

            dec bx
            cmp bx, 1
            je RToutLoop

            sub si, 3
            jmp RTmiddleLines

        RToutLoop:

    ; Last line of frame

            mov cx, LEN
            mov di, (START_LINE + WID - 1) * FRAME_LEN * 2 + START_COLM * 2

            call DrawLine
            jmp RTret

        RTstop:
            mov ah, 09h
            mov dx, offset DrwFrErrMsg
            int 21h 
            jmp Terminate

        RTret:
            ret
            endp

DrwFrErrMsg db 'Incorrect width of the frame$'

;================GLOBAL=VARIABLES================

FRAMES:     

;--------------SIGN-(PLUS-MINUS)-FRAME-----------
; TYPE '0'

SIGN_FST    db '+', '-', '+'
SIGN_MDL    db '|', ' ', '|'
SIGN_LST    db '+', '-', '+'

;------------------SINGLE-FRAME------------------
; TYPE 1

SINGLE_FST  db 218d, 196d , 191d
SINGLE_MDL  db 179d, SPACE, 179d
SINGLE_LSR  db 192d, 196d , 217d

;------------------DOUBLE-FRAME------------------
; TYPE 2

DOUBLE_FST  db 201d, 205d , 187d
DOUBLE_MDL  db 186d, SPACE, 186d
DOUBLE_LST  db 200d, 205d , 188d

;----------------USER-STYLE-FRAME----------------
; TYPE 3

UserFrame:

USER_FST    db 3 dup(?)
USER_MDL    db 3 dup(?)
USER_LST    db 3 dup(?)

;----------------IN-FRAME-TEXT-ARRAY-------------

FRAME_TEXT  db (LEN - 2) dup (?)

;====================THE=END=====================

end Start