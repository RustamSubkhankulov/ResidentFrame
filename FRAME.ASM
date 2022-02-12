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
FRAME_LEN   = 80            ; lenght of the video frame
FRAME_WID   = 25            ; width  of the video frame

CENTER_LINE = FRAME_WID / 2 ; center line   of the video frame
CENTER_COLM = FRAME_LEN / 2 ; center column of the video frame

START_LINE = CENTER_LINE - WID / 2
START_COLM = CENTER_COLM - LEN / 2

;--------------INTERRUPTION-CODES----------------

PUTS		equ 09h	    	; interrupt code for printing line		
STOP		equ 04Ch    	; interrupt code for terminating

;--------------FRAME-PARAMETERS------------------

WID	    	= 5d		    ; width  of the frame
LEN		    = 20d		    ; lenght of the frame
COLOR_ATTR  = 4Eh           ; color attribute for the frame
 
;===============ASCII-SYMBOL-CODES===============

;-----------------DOUBLE-FRAME-------------------

DFR_RT		= 187d  	    ; right top symbol    
DFR_RB		= 188d		    ; right bottom symbol 
DFR_LT		= 201d		    ; left top symbol     
DFR_LB		= 200d		    ; left bottom symbol  
DFR_VER		= 186d		    ; vertical symbol     
DFR_HOR		= 205d		    ; horizontal symbol   

;-----------------SINGLE-FRAME-------------------

SFR_RT		= 191d  	    ; right top symbol    
SFR_RB		= 217d		    ; right bottom symbol 
SFR_LT		= 218d		    ; left top symbol     
SFR_LB		= 192d		    ; left bottom symbol  
SFR_VER		= 179d		    ; vertical symbol     
SFR_HOR		= 196d		    ; horizontal symbol   

SPACE	 	= 020h		    ; srace symbol
NWLINE		= 0Ah		    ; \n
GACHI		= 0Bh		    ; GACHI SYMBOL for 300$ bucks

;===================MAIN=BODY====================

Start:      call GetFrmType

            call DrawFrame

            mov ah, STOP
            xor al, al
            int 21h         ; terminates process

;=============FUNCTIONS DEFINITIONS==============

locals RT

;------------------------------------------------
; GetFrameType
;
; Entry: none   
; Exit : AL - frame type
; Destr: AX
;------------------------------------------------

GetFrmType  proc

            mov bx, CMND_LN + 1
            mov al, [bx]
            sub al, '0'

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

            mov al, [si]
            inc si

            mov es:[di], ax
            add di, 2

            mov al, [si]
            inc si

            sub cx, 2
            jbe RTstopDrwLn 

        RTnextSymb:
            mov es:[di], ax
            add di, 2
            loop RTnextSymb

            mov al, [si]
            inc si          ;isn't needed

            mov es:[di], ax
            add di, 2       ;also isn't needed  

            jmp RTret        

        RTstopDrwLn:
            mov ah, 09h
            mov dx, offset DrwLnErrMsg
            int 21h

        RTret:
            ret 
            endp

DrwLnErrMsg     db 'Incorrect lenght of the frame$' 

;------------------------------------------------
;
; DrawFrame
;
; Entry: AL - frame type    
; Exit : None
; Destr:
;------------------------------------------------

DrawFrame   proc 
    ;First line of frame
            mov ah, 9
            mul ah
            xor ah, ah
            mov bx, ax

            lea si, FRAMES[bx]

            ;xor di, di
            ;
            mov di, (START_LINE * FRAME_LEN + START_COLM) * 2
            ;

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
            ;
            add al, START_LINE
            ;
            dec al
            mov ah, FRAME_LEN * 2
            mul ah
            ;
            add ax, START_COLM * 2
            ;

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
            ;mov di, (WID - 1) * FRAME_LEN * 2
            mov di, (START_LINE + WID - 1) * FRAME_LEN * 2 + START_COLM * 2

            call DrawLine

            .PAUSE
            jmp RTret

        RTstop:
            mov ah, 09h
            mov dx, offset DrwFrErrMsg
            int 21h 

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

SINGLE_FST  db SFR_LT , SFR_HOR, SFR_RT
SINGLE_MDL  db SFR_VER, SPACE  , SFR_VER
SINGLE_LSR  db SFR_LB , SFR_HOR, SFR_RB

;------------------DOUBLE-FRAME------------------
; TYPE 2

DOUBLE_FST  db DFR_LT , DFR_HOR, DFR_RT
DOUBLE_MDL  db DFR_VER, SPACE  , DFR_VER
DOUBLE_LST  db DFR_LB , DFR_HOR, DFR_RB

;----------------USER-STYLE-FRAME----------------
; TYPE 3

USER_FST    db 3 dup(?)
USER_MDL    db 3 dup(?)
USER_LST    db 3 dup(?)

;====================THE=END=====================

end Start