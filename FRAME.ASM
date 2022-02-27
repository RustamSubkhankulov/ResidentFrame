;.model tiny
;.code 
;org 100h

;===================USING========================
;
; If you want to print text in the frame,
; write text after 'frame.com' in command line
; quarded by '$' on the both sides.
; Maximum lenght of the text = LEN - 2
;
; If you don't want to print text, just write down
; type of the frame - 0, 1, 2 or 3 after space
;
; Frame types:
;       0 - frame made of '+' and '-'
;       1 - single-lined frame
;       2 - double-lined frame
;       3 - user's style of the frame

; Note: after 3 must be written 9 symbols,
;       that will be used as left-top corner, 
;       horizontal symbol in first line,
;       right-top corner, vertical symbol on the 
;       left side, background symbol, vertical
;       symbol on the right symbol, left-bottom
;       corner, horizontal symbol on the last line
;       and rigth-bottom corner
;
;       Symbols of user's style frame must be 
;       printed without spaces between
;
; Constant frame parameters:
;       COLOR_ATTR - color attribute for frame
;       WID - width  of the frame
;       LEN - lenght of the frame
;       FRAME_LEN and FRAME_WID - video frame
;                                 parameters
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

StartLine   = 0             ; first line   of the frame
StartColm   = 0            ; first column of the frame

;CENTER_LINE = FRAME_WID / 2 ; center line   of the video frame
;CENTER_COLM = FRAME_LEN / 2 ; center column of the video frame

;START_LINE = CENTER_LINE - WID / 2
;START_COLM = CENTER_COLM - LEN / 2

;--------------INT-21H-FUNCTIONS-----------------

PUTS		equ 09h	    	; interrupt code for printing line		
STOP		equ 04Ch    	; interrupt code for terminating

;--------------FRAME-PARAMETERS------------------

WID	    	= 20d		    ; width  of the frame
LEN		    = 13d		    ; lenght of the frame
COLOR_ATTR  = 4Eh           ; color attribute for the frame
                            ;
                            ; this default color attribute
                            ; prints yellow symbols on the right
                            ; background 

SGNTBLLEN   = 09d           ; lenght of the sign table
 
;===============ASCII-SYMBOL-CODES===============

SPACE	 	= 020h		    ; space symbol

;===================MAIN=BODY====================

;Start:      cld

            ;call ParseCmndLine
            ;call DrawFrame
            ;.PAUSE

            ;cmp word ptr TextLen, 0
            ;je Terminate


            ;mov bx, 3               ; first string
            ;lea si, FRAME_TEXT      ; address of the string 
            ;mov cl, TextLen
            ;xor ch, ch              ; cx = number of the symbols in string
            ;mov ah, COLOR_ATTR      ; color attribute

            ;call WriteTextStr
            ;.PAUSE

        Terminate:
            mov ah, STOP
            xor al, al
            int 21h         ; terminates process

;=============FUNCTIONS DEFINITIONS==============

locals RT

;--------------DrawHorLine-----------------------
;
; Descr: draw horizontal line in frame on 
;        particular line
;
; Entry: ES -> segment, where frame printed
;        AH - color attribute
;        BX - number of line 
;        cs:FrameType - type of the frame (0 - 2)
;                       (function cannot be used 
;                        with users style of frame)
; Exit:  NONE
; Desrt: AL, SI, DI, BX, CX
;------------------------------------------------

DrawHorLine     proc

                mov di, (StartLine * FRAME_LEN + StartColm)
                                        ; di == start position of text

                shl bx, 4
                add di, bx 
                shl bx, 2
                add di, bx              ; add offset to the string

                shl di, 1               ; di *= 2

                mov si, word ptr cs:FrameType 
                shl si, 1
                add si, word ptr cs:FrameType    
                                        ; si = type * 3

                lea si, cs:HOR_LINES[si]
                                        ; get offset to the symbols
                mov cx, LEN             ; lenght of the frame

                call DrawLine 

                ret 
DrawHorLine     endp

;--------------WriteTextStr----------------------
;
; Descr: writes text on the particular line of
;        the frame, string will be centered
;        in the frame
;
; Warning: function is not secure for the number
;          of the line, user must use correct 
;          number
;
; Entry: ES -> 0B800h
;        DS:SI -> string to be printed
;        CX = number of symbols in string
;        AH = color attribute 
;        BX - number of the line 
; Destr: SI = SI + CX, DI, BX
;------------------------------------------------

WriteTextStr    proc

                mov di, (StartLine * FRAME_LEN + StartColm)
                                                ; di == start position of text
                
                shl bx, 4                       ; bx = bx * 16
                add di, bx                            
                shl bx, 2                       ; bx = bx * 64
                add di, bx                      ; di -> start of the choosed line 

                shl di, 1                       ; di = di * 2

                mov bx, LEN
                sub bx, cx  
                shr bx, 1                       ; correcting addres (divides by 2)
                shl bx, 1
                add di, bx                      ; centering text in the frame
 
            RTLoop:
                lodsb                           ; write text
                stosw 
                loop RTLoop

                ret 
WriteTextStr    endp

;------------------------------------------------
; WriteText
;
; Entry: expects DF == 0
;        AH == color attribute
; Exit : None
; Destr: AL, CX, SI, DI
;------------------------------------------------

WriteText       proc

                mov di, ((StartLine + WID/2) * FRAME_LEN + StartColm) * 2
                                                ; di == start position of text
                mov si, LEN
                sub si, word ptr TextLen
                shr si ,1                       ; correcting addres (divides by 2)
                shl si, 1
                add di, si                      ; centering text in the frame

                lea si, FRAME_TEXT              ; si -> address of the text array
                mov cx, word ptr TextLen        ; cx is counter
                mov ah, COLOR_ATTR              ; color attribute

            RTloop:
                lodsb                           
                stosw
                loop RTloop

                ret
                endp   

;------------------------------------------------
;
; ParseCmndLine
;
; Entry: expects DF == 0
; Exit : FrameType variable - frame type, 
;        TextLen variable - number of symbols in note
;
; Destr: AX, SI, CX, DI
;------------------------------------------------

ParseCmndLine   proc

                mov si, CMND_LN + 1         ; si points to the first symbol 
                mov dl, [si]                ; in cmnd line
                
                cmp dl, '$'                 ; if *si != '$' -> no text
                jne RTnoText

                inc si                      ; else si++ and get text
                call GetFrameText

            RTnoText:
                call GetFrameType           ; get type of the frame

            RTret:
                ret
                endp

;------------------------------------------------
;
; GetFrameText
;
; Entry: SI - address of the first symbol of text in cmnd line
;        expects DF == 0
; Exit : TextLen - number of symbols read 
; Destr: AX, BX, CX, DX
;------------------------------------------------

GetFrameText    proc

                xor ah, ah                  ; reset number of symbols

                mov cx, ds                  ; es = ds
                mov es, cx

                lea di, FRAME_TEXT          ; bx points to the array
                                            ; where text will be stored 
                mov cx, LEN - 2             ; max lenght of the text

            RTloop:
                lodsb                       ; al = ds:[si]; si++;
                cmp al, '$'                 ; if al == $ -> end of text
                je RTisSpace                ; next symb after $ must be SPACE

                stosb                       ; store symbol in FRAME_TEXT
                inc ah                      ; increment counter of symbols

                loop RTloop

            RTis$:
                lodsb                       ; load next symbol
                mov dl, '$'                 ; comparing symbol
                inc si                      ; si -> FrameTypeNumber
                jmp RTcompare

            RTisSpace:
                lodsb                       ; al = ds:[si]; si++
                mov dl, ' '                 ; comparing symbol
                jmp RTcompare

            RTcompare:
                cmp dl, al                  ; compare with expected symbol
                jne RTinputErr              ; if NE -> Incorrect Format of Input
                jmp RTret

            RTinputErr:                     ; print error msg and stop
                mov ah, 09h
                mov dx, offset InputErrMsg
                int 21h
                jmp Terminate

            RTret:
                mov byte ptr TextLen, ah
                ret
                endp

InputErrMsg db 'Incorrect format of the input$'

;------------------------------------------------
; GetFrameType
;
; Entry: SI - address of the frame type symbol in cmnd line
;        expects DF == 0
; Exit : FrameType variable = number of frame type ( from 0 to 3)
; Destr: AL, SI
;------------------------------------------------

GetFrameType    proc

                lodsb                       ; al = ds:[si++];
                                            ; expects si -> numbet of type
                sub al, '0'                 ; code -> number

                cmp al, 3                   ; if NOT User Style of frame
                jne RTret                   ; jmp to return

                inc si                      ; skip one more symbols 
                call GetUserFrame           ; get symbols for uset style of frame

            RTret:
                mov byte ptr FrameType, al  ; save frame type in variable
                ret 
                endp

;------------------------------------------------
; 
; GetUserFrame
;
; Entry: SI points to the first symbol of user frame symbols
;        ES must be equal DS
;        expects DF == 0
; Exit : None
; Destr: AL, DI, SI, CX
;------------------------------------------------

GetUserFrame    proc

                lea di, UserFrame           ; array for uset style symbols
                mov cx, SGNTBLLEN           ; cx == SGNTBLLEN, number of symbols expected

                rep movsb                   ; ds:[si++] -> es:[di++]

                ret
                endp

;------------------------------------------------
; DrawLine
;
; Entry: AH - color attribute, CX - lenght 
;        SI - address of symbol string
;        DI - destination address
;        ES - destination segment
; Exit : None   
; Desrt: AL, SI, DI
; After process: SI := SI + 3
;                DI := DI + 2 * LEN
;------------------------------------------------

DrawLine    proc

            push cx             ; save cx value

            lodsb               ; al = ds:[si++]; first symb of line
            stosw               ; es:[di] = ax; di += 2;

            lodsb               ; al = next - middle - symbol of line

            sub cx, 2           ; number of middle symbols to be printed
            jbe RTstopDrwLn     ; Incorrect lenght of line

            rep stosw           ; es:[di] = ax; di += 2; cx times

            lodsb               ; al = last symbol of line; si++;
            stosw               ; es:[di] = ax; di += 2; 

            jmp RTret

        RTstopDrwLn:            ; print error msg 
            mov ah, 09h
            mov dx, offset DrwLnErrMsg
            int 21h
            jmp Terminate          

        RTret:
            pop cx              ; restore cx value

            ret
            endp    

DrwLnErrMsg     db 'Incorrect lenght of the frame$' 

;------------------------------------------------
;
; DrawFrame
;
; Entry: ES -> segment, where frame will be drawn
; Exit : None
; Destr: AL, BX, CX, DI, SI
;------------------------------------------------

DrawFrame   proc 

            ;mov si, VIDEOSEG                            ; ES as parameter 
            ;mov es, si           ; es == 0B800h         ; offset / 16 + ds 
                                                        ; db offset $ OFh dup 
            mov si, word ptr cs:FrameType
            shl si, 3
            add si, word ptr cs:FrameType    
                                 ; si == SGNTNLLEN * FrameType   
            lea si, cs:FRAMES[si]   
                                 ; si == address of the Frame Symbols

            mov ah, COLOR_ATTR   ; ah == color attribute
            mov di, (StartLine * FRAME_LEN + StartColm) * 2
                                 ; mov di to the start of the first line
            mov cx, LEN          ; cx = lenght of the frame

            call DrawLine        ; draw first line

            mov bx, WID - 2      ; number of the middle lines on frame
            add di, (FRAME_LEN - LEN) * 2
                                 ; di -> start of the next line

        MiddleLines:              ; middle lines cycle
            call DrawLine        ; print line
            add di, (FRAME_LEN - LEN) * 2
            sub si, 3            ; si -> first symbol for the middle line
                                 ; di -> start of the mext line
            dec bx               ; decremenint counter
            cmp bx, 0            
            jne MiddleLines      ; if counter != 0 repeat

            add si, 3            ; si -> first symbol for the last line
            call DrawLine        ; print last line
            jmp RTret            ; jmp to return

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

TextLen     db 0, 0
FrameType   db 0, 0

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

;-----------------HORIZONTAL-LINES---------------

HOR_LINES:

SIGN_LINE   db 195d, '-' , 180d
SG_LINE     db 195d, 196d, 180d
DB_LINE     db 204d, 205d, 185d

;----------------IN-FRAME-TEXT-ARRAY-------------

FRAME_TEXT  db (LEN - 2) dup (?)

;====================THE=END=====================

;end Start