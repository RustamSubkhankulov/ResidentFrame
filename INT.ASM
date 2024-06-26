.model tiny
.code
org 100h

;================REGISTERS=FRAME=================
;
; This is a simple program, that uses interrupts
; for showing current registers values in the 
; frame
;
; Using: F1 - turn on 
;        F2 - turn of 
;
; To release memory, use ALT + F5, choose 
;    'int.com' and press release
;
;==================MAIN=BODY=====================

Start:      ;cld                         ; DF = 0

            ;
            ;jmp DEBUG
            ;

            mov al, 08h                 ; int 08h
            lea di, Old08               
            lea dx, New08
            call ChngIntHandler

            mov al, 09h                 ; int 09h
            lea di, Old09
            lea dx, New09
            call ChngIntHandler

            lea dx, ProgEnd
            call TermNStay

;==================INCLUDES======================

include W:\FRAME\FRAME.ASM 

include W:\STRLIB\STRLIB.ASM 

;----------TERMINATE-AND-STAY-RESIDENT-----------
;
; Descr: Terminates program and stay resident
;
; Entry: DX - address of the end of program
; Exit : None
; Destr: AX, DX
;------------------------------------------------

TermNStay   proc

            mov ax, 3100h               ; TSR function code
            shr dx, 4
            inc dx                      ; size in 16-byte pages
            int 21h  

TermNStay   endp 

;--------------ChngIntHandler--------------------
;
; Description: Changes addres of the function
;              that handles interruption and
;              and loads address vector of 
;              original handler 
; Entry: AL - number of interrupt
;        DI -> address, where old handler's
;                   address will be stored
;        DX -> address of the new handler
; Exit : None
; Destr: AX, BX, ES
; Note:  Forbids interruption during process 
;        using cli and sti 
;        Expects DF = 0
;------------------------------------------------

ChngIntHandler  proc

                mov ah, 35h             ; get address
                int 21h                 ; of the old handler

                mov [di], bx            ; store it
                mov [di + 2], es

                mov ah, 25h             ; change address in
                int 21h                 ; IntrTable to new one
 
                ret 

ChngIntHandler  endp

;-------------------New08------------------------
;
; Descr: new int 08h handler
;        draws frame with registers in it if 
;        feature is on 
; Entry:
; Exit :
; Destr:
;------------------------------------------------

New08       proc                        ; at the start of int in stack are pushed FLAGS, CS, IP


            ;
            ;DEBUG:
            ;

            ;
            ;pushf 
            ;push cs 
            ;push cs
            ;

            push es ss ds  
            push sp bp di si
            push dx cx bx ax 

            cld 

            ;
            ;jmp DEB1
            ;

            cmp cs:IsTurnOn, 1
            jne TurnedOff               ; if IsTurnOn == 0 jmp to TurnedOff

            cmp cs:LstScnCode, 3Ch      ; else cmp last scan code and F2
            je TurnOffFrame             ; if last scan code == F2 turn off frame and restore vid mem
            jmp TurnedOn                ; else draw frame

        TurnedOff:
            cmp cs:LstScnCode, 3Bh      ; if last scan code != F1 and frame turned off
            jne ToOrigHandler           ; jmp to orig handler

            mov cs:IsTurnOn, 1          ; else turn on frame
                                        ; and draw it 

            ;
            ;
            ;DEB1:
            ;

            call LoadRegs               ; load reg values from stack to specialized array

            call FillBackBuf            ; draw frame in BackBuf
            call FillSaveBuf            ; load vid memory to SaveBuf

            jmp DrawRegistersFrame      ; jmp to drawing frame


        TurnedOn:
            call LoadRegs               ; saving reg names and values in array

            call FillSaveBuf            ; update SaveBuf
            call FillBackBuf            ; update BackBuf

        DrawRegistersFrame:
            mov si, VIDEOSEG
            mov es, si                  ; es = 0B800h

            call DrawRegFrame           ; draw frame with registers
            jmp  ToOrigHandler

        TurnOffFrame:
            mov cs:IsTurnOn, 0          ; turn on frame
            call RestoreVidMem          ; restore video memory behind frame

        ToOrigHandler:
            pop ax bx cx dx
            pop si di bp sp
            pop ds ss es

Jump08:     db 0EAh
Old08:      dd 0h

New08       endp 

;------------------LoadRegs----------------------
;
; Descr: saves reg name and value in array
;        ready to be printed
;        Registers: AX, BX, CX, DX, 
;                   SI, DI, BP, SP
; Entry: None
;        Expects DF == 0 
; Exit:  Saved names and values in array
; Destr: ES, BP, DI, DX, SI, BX, DS
;------------------------------------------------

LoadRegs    proc 

            push bp
            mov  bp, sp

            ;push sp bp di si dx cx bx ax 
                                        ; save reg values
            mov si, 4                   ; counter for arguments 

            push cs 
            pop  es                     ; es == cs 

            push cs 
            pop  ds                     ; ds == cs for proper 
                                        ; addressing

            lea bx, RegNames            ; bx -> registers names 
            lea di, SavedRegVal         ; di -> array for saved reg values
            mov dx, 0Fh                 ; mask for 16-base numeric
                                        ; system
            mov cl, 4                   ; 16 = 2 ^ 4

            mov ch, 13d                 ; counter = number of registers

        LoadLoop:
            inc di                      ; skip one space 

            mov ax, cs:[bx]             ; ax == name of the reg
            stosw                       ; di += 2;
            add bx, 2                   ; move si to next name

            add di, 3                   ; skip three spaces 

            mov ax, ss:[bp + si]        ; get saved reg value from stack
            add si, 2                   ; si -> next arg

            push si bx                  ; save si and bx values
            call rnumtoa2               ; write value in array as a string
            pop  bx si                  ; restore si and bx values 

            add di, 5                   ; move di to position for next iteration

            dec ch                      ; decrement counter
            cmp ch, 0               
            jne LoadLoop                ; repeat if counter != 0

            mov ax, ss:[bp + si]        ; get flags values as word
            call WriteFlags             ; write flag values in array

            pop bp 
            ret 

LoadRegs    endp

RegNames    db "AX","BX","CX","DX","SI","DI","BP","SP","DS","SS","ES","IP","CS"

;-----------------WriteFlags---------------------
;
; Descr: converts word from stack into flag 
;        values and writes it in array
; Entry: AX - flags as word from stack after PUSHF
;        DI -> line of frame, where flag values
;              will be printer (position in array)
;        DS == CS, ES == CS
; Exit : None
; Destr: DI, CX, SI, DX, BX
;------------------------------------------------

WriteFlags      proc

                mov si, offset FlagsTitle
                                        ; si->Title of the line
                mov cx, cs:FlagsTitleSize
                                        ; size of the title
                rep movsb               ; write title in array
                                        ; di += 3

                mov dx, 8               ; counter - number of flags
                mov si, 0               ; counter for masks
                                
            RegWriteLoop:
                mov bx, ax              ; get value of flags as word
                mov cx, cs:FlagOffs[si] ; get offset to bit
                inc si                  ; move to next flag
                shr bx, cl              ; move bit to the right
                and bx, 1               ; get value

                add bx, '0'             ; convert into symbol
                mov cs:[di], bx         ; store in array
                inc di                  ; move to next pos

                dec dx                  ; decrement counter
                cmp dx, 0           
                jne RegWriteLoop        ; repeat while counter != 0
                                        ; di += 8
                mov si, offset FlagNames
                mov cx, FlagNamesSize   ; get address and size of FlagNames string

                rep movsb               ; di += 11
                ret 
WriteFlags      endp

;                  CF   PF   AF   ZF   SF   IF    DF    OF      ; names 
FlagOffs        dw 0d,  2d,  4d,  6d,  7d,  9d,   10d,  11d     ; offset to move flag to right

FlagNames       db "NM:CPAZSIDO"                                ; names of flags
FlagNamesSize   dw 11d                                          ; lenght 

FlagsTitle      db "FL:"                                        ; title of line with flags
FlagsTitleSize  dw 3d                                           ; lenght

;-----------------DrawRegFrame-------------------
;
; Descr: used by our new INT 08h hadnlew to draw
;        frame with registers values in it
; Entry: ES -> segment, where frame will be 
;              drawn
; Exit : None
; Destr: SI, DI, CX, BX, DS=CS, AL
;------------------------------------------------

DrawRegFrame    proc

                push cs
                pop ds                  ; ds == cs for addressing

                mov byte ptr cs:FrameType, 2d              
                                        ; frame type
                                        
                call DrawFrame          ; draw empty frame

                lea si, RegFrameTitle   ; title of frame
                mov cx, 10d             ; lenght of title
                mov bx, 1d              ; write on first line 
                call WriteTextStr       ; write title in frame

                lea si, SavedRegVal     ; address of the array with saved
                                        ; registers values
                mov dx, 3d              ; start from the third line

            WriteRegLoop:
                mov bx, dx              ; number of the line

                cmp bx, 11d             ; if number of string == 11
                je HorLine              ; draw horizontal line

                cmp bx, 17d             ; same with 17th line
                je HorLine

                mov cx, 11d              ; write 9 symbols
                call WriteTextStr       ; on the particular line

                inc dx                  ; move to next line 
                cmp dx, 20d             ; stop after 8 lines
                jne WriteRegLoop        ; else repeat 

                jmp DrawRegFrameRet

            HorLine:
                push si                 ; save si value 
                call DrawHorLine       ; draw horizontal line
                inc  dx                 ; increment counter of lines
                pop  si                 ; restore si value

                jmp WriteRegLoop        ; return to the cycle 

            DrawRegFrameRet:
                ret 
DrawRegFrame    endp 

RegFrameTitle   db " REGISTERS"

;------------------SaveVidMem--------------------
;
; Descr: saves fragment of the video memory 
;        in array, that will be used for restoring
;        it 
; Entry: ES == CS
; Exit : None
; Destr: SI, DI, CX, BX 
; Warning: Array must be enough size
;          Expects DF == 0    
;------------------------------------------------

SaveVidMem  proc

            push ds                     ; save ds value
            mov  si, VIDEOSEG           
            mov  ds, si                 ; ds = 0B800h

            mov si, (StartLine * FRAME_LEN + StartColm) * 2
                                        ; si -> start of the frame

            ;
            push cs
            pop  es
            ;

            lea di, SaveBuf         ; di -> array for saving

            mov bx, WID                 ; global counter

        SaveVidMemLoop:
            mov cx, LEN                 ; local counter
            rep movsw                   ; move one line

            add si, (FRAME_LEN - LEN) * 2 
                                        ; si -> start of the next line

            dec bx                      ; decrement counter
            cmp bx, 0                   
            jne SaveVidMemLoop          ; if counter != 0 repeat

            pop ds                      ; restore DS value 
            ret 

SaveVidMem  endp 

;-----------------RestoreVidMem------------------
;
; Descr: restores video memory behind frame from
;        the array using data saved before
; Entry: ds == cs 
; Exit : None
; Destr: SI, DI, ES, BX, CX
;------------------------------------------------

RestoreVidMem   proc

                mov si, VIDEOSEG
                mov es, si              ; es -> video segment

                lea si, SaveBuf         ; array with saved data
                mov di, (StartLine * FRAME_LEN + StartColm) * 2
                                        ; di -> start of the frame 
                ;
                push cs
                pop  ds 
                ;

                mov bx, WID             ; global counter
            
            RestoreVidMemLoop:
                mov cx, LEN             ; local counter
                rep movsw               ; move one line

                add di, (FRAME_LEN - LEN) * 2 
                                        ; di -> start of the next line

                dec bx                  ; decrement global counter
                cmp bx, 0
                jne RestoreVidMemLoop   ; if counter != 0 repeat

                ret 

RestoreVidMem   endp

;------------------FillBackBuf-------------------
;
; Draws frame in ' BackBuf' array, that simulates 
; video memory by its  size
;
; Descr:
; Entry: None
; Exit : None
; Destr: 
;------------------------------------------------

FillBackBuf     proc

                mov si, cs:BackBufSeg
                mov es, si              ; get value from variable

                call DrawRegFrame

                ret 
FillBackBuf     endp

;-------------------FillSaveBuf------------------
;
; Descr:
; Entry:
; Exit:
; Destr: DS=VidSes, ES=SaveBufSeg, DI, SI, AX, BX
;------------------------------------------------

FillSaveBuf     proc

                mov si, VIDEOSEG
                mov ds, si              ; ds -> VIDEO SEG
                ;xor si, si              ; si -> start
                mov si, (StartLine * FRAME_LEN + StartColm) * 2


                mov di, cs:BackBufSeg
                mov es, di              ; es -> BackBufsegment

                mov di, offset SaveBuf
                                        ; cs:[di] -> SaveBuf

                mov bx, WID             ; global counter

            FillSaveBufCycle:
                mov cx, LEN             ; local counter

            SaveBufLineLoop:
                mov ax, ds:[si]         ; get word from videomem

                cmp ax, es:[si]         ; cmp with BackBuf
                je  NextIter            ; if video = back -> next iter
                mov cs:[di], ax         ; else save video to SaveBuf

            NextIter:
                add si, 2               
                add di, 2               ; to next word
                loop SaveBufLineLoop    ; repeat CX times

                dec bx                  ; decrement global counter
                cmp bx, 0               ; if bx == 0 stop 
                je FillSaveBufRet

                add si, (FRAME_LEN - LEN) * 2 
                                        ; move to next line
                jmp FillSaveBufCycle    ; and repeat cycle

            FillSaveBufRet:
                ret
FillSaveBuf     endp

;---------------------New09----------------------
;
; Descr: New int 09h interrupt handler
;        sets local vaiable '1' if F1 is pressed
;        and sets it '0' if F2 is pressed 
;        Then jumps to original hanled
; Entry: None
; Exit : Changes 'IsTurnOn' variable value
; Destr: None
;------------------------------------------------

New09       proc

            push ax                     ; save ax value

            in  al, 60h                 ; get  last scan code
            mov cs:LstScnCode, al       ; save last scan code  

            cmp cs:IsTurnOn, 1          
            jne IsNotTurnOn             ; jmp if is turned off

            cmp al, 3Ch                 ; is F2 pressed?
            jne ShortCut09              ; if it is not,
                                        ; jmp to original handler
            jmp IntEnding               ; else jmp to our ending

        IsNotTurnOn:                    
            cmp al, 03Bh                ; is F1 pressed?
            jne ShortCut09              ; if it is not,
                                        ; jmp to original handler

        IntEnding:                      ; else 
            in  al, 61h                 ; blink to the 61h port 
            mov ah, al
            or  al, 80h 
            out 61h, al 
            mov al, ah 
            out 61h, al 

            mov al, 20h                 ; Interrupt Controller
            out 20h, al

            pop ax
            iret 

    ShortCut09:
            pop ax                      ; restore ax value 

Jump09:     db 0EAh 
Old09:      dd 0h

New09       endp

;------------------------------------------------

IsTurnOn    db 0                        ; SwitchOn\Off variable
LstScnCode  db 0                        ; Last scanned code 

;BackBufSeg  dw 0b800h + (80d * 25d *2d) / 16d
BackBufSeg  dw 0B8FAh                    
                                        ; segment of BackBuf

;------------------------------------------------

SaveBuf db (LEN * WID * 2) dup (1h)    ; array where saved vid 
                                       ; memory will be saved

SavedRegVal db (14 * 11 + 2 * 11) dup (20h)  ; 14 registers, 2 bytes for name
                                                  ; 2 spaces and 4 bytes for value 
                                                  ; plus two lines each 11 bytes for flags

;------------------------------------------------

ProgEnd:                                ; Used for TSR (see 'TermNstay')

end Start                 



