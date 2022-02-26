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

Start:      cld                         ; DF = 0

            ;jmp DEBUG

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

New08       proc            

            cmp cs:IsTurnOn, 1          ; if drawing frame turned off
            jne Jump08                  ; jmp to original int handler

            push ax bx cx dx 
            push si di bp
            push es ds                  ; saving registers values 

        DEBUG:
            cld
            call LoadRegs               ; saving reg names and values in array
            call SaveVidMem             ; save video memory

            call DrawRegFrame           ; draw frame with registers

            push cx 
            mov cx, 0FFFFh
        DelayLoop:
            nop

            loop DelayLoop
            pop cx

            call RestoreVidMem         ; restore video memory

            pop ds es         
            pop bp di si 
            pop dx cx bx ax             ; restore registers values  

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
; Destr: ES, BP, DI, DX
;------------------------------------------------

LoadRegs    proc 

            push sp bp di si dx cx bx ax 
                                        ; save reg values

            push cs 
            pop  es                     ; es == cs 

            push cs 
            pop  ds                     ; ds == cs for proper 
                                        ; addressing

            lea bp, RegNames            ; bp -> registers names 
            lea di, SavedRegVal         ; di -> array for saved reg values
            mov dx, 0Fh                 ; mask for 16-base numeric
                                        ; system
            mov cl, 4                   ; 16 = 2 ^ 4

            mov ch, 8d                  ; counter = number of registers

        LoadLoop:
            mov ax, cs:[bp]             ; ax == name of the reg
            stosw                       ; di += 2;
            add bp, 2                   ; move bp to next name

            add di, 2                   ; skip two spaces 

            pop ax                      ; get saved reg value from stack
            call rnumtoa2               ; write value in array as a string

            add di, 4                   ; move di to position for next iteration

            dec ch                      ; decrement counter
            cmp ch, 0               
            jne LoadLoop                ; repeat if counter != 0

            ret 

LoadRegs    endp

RegNames    db "AX","BX","CX","DX","SI","DI","BP","SP"

;-----------------DrawRegFrame-------------------
;
; Descr: used by our new INT 08h hadnlew to draw
;        frame with registers values in it
; Entry: None
; Exit : None
; Destr:
;------------------------------------------------

DrawRegFrame    proc

                mov byte ptr cs:FrameType, 2d              
                                        ; frame type
                call DrawFrame          ; draw empty frame

                lea si, RegFrameTitle   ; title of frame
                mov cx, 9d              ; lenght of title
                mov bx, 1d              ; write on first line 
                call WriteTextStr       ; write title in frame

                lea si, SavedRegVal     ; address of the array with saved
                                        ; registers values
                mov dx, 3d              ; start from the third line

                push cs
                pop ds 

            WriteRegLoop:
                mov cx, 8d              ; write 8 symbols
                mov bx, dx              ; number of the line
                call WriteTextStr       ; on the particular line

                inc dx                  ; move to next line 
                cmp dx, 11d             ; stop after 8 lines
                jne WriteRegLoop        ; else repeat 

                ret 
DrawRegFrame    endp 

RegFrameTitle   db "REGISTERS"

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

            lea di, SavedVidMem         ; di -> array for saving

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

                lea si, SavedVidMem     ; array with saved data
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
            mov cs:IsTurnOn, 0          ; else turn off frame
            jmp IntEnding               ; and jmp to ending

        IsNotTurnOn:                    
            cmp al, 03Bh                ; is F1 pressed?
            jne ShortCut09              ; if it is not,
                                        ; jmp to original handler
            mov cs:IsTurnOn, 1          ; else turn on

        IntEnding:
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

;------------------------------------------------

SavedVidMem db (LEN * WID * 2) dup (20h); array where saved vid 
                                        ; memory will be saved

SavedRegVal db (8 * (4 + 4)) dup (20h)  ; 8 registers, 2 bytes for name
                                        ; 2 sapces and 4 bytes for value 

;------------------------------------------------

ProgEnd:                                ; Used for TSR (see 'TermNstay')

end Start                               