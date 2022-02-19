.model tiny
.code
org 100h

;=============STRING=FUNCTION=LIB================
;
; Function librery made for the work
; with the strings.
;
; Librarry contains C functions, specialized 
; to work with strings, made using Assembly 
;
; List of the functions:
;   Passing arguments through registers
;   1. rstrlen
;   2. rstrchr
;   3. rstrncpy
;   4. rstrncmp
;   5. ratoi
;   6. ritoa
;
;   Passing arguments through stack
;   1. sstrlen
;   2. sstrchr
;   3. sstrncpy
;   4. sstrncmp
;   5. satoi
;   6. sitoa
;
; Every function' description conrains arguements
; and where function expects them to find, 
; exit value location and destructive list, which
; includes registers, that will be used during
; procedure. Save their values before call if you
; need them.
;
; Every function made in two samples: using 
; registers and stack to receive arguments
;
;================================================

Start:      lea si, NUMSTR

            call ratoi

            Terminate:
            mov ah, STOP
            int 21h

NUMSTR db ' -102', 0
FSTSTR db 'hello', 0
SNDSTR db 'hello world', 0
NUMBER db 20 dup (1)

;-------------------RSTRLEN-----------------------
; 
; Description: Returns the length of the given 
; byte string, that is, the number of characters 
; in a character array whose first element is 
; pointed to by ES:DI up to and not including the 
; first null character. The behavior is undefined 
; if there is no null character in the character 
; array pointed to by str.
;
; Entry: DI - address of the first symbol in
;             the string
;        ES - points to the correct segment,
;             where string is stored
; Exit : CX - lenght of the string
; Destr: DI
; Note : Sets DF to zero
;------------------------------------------------

rstrlen  proc

        cld                     ; DF = 0
        xor al, al              ; comparing reg
        xor cx, cx              ; reset counter

    rstrlenLoop:                ; main cycle
        scasb                   ; cmp al, es:[di]; di++; 
        je rstrlenFin           ; stop if zero find

        inc cx                  ; increment counter
        jmp rstrlenLoop

    rstrlenFin:
        ret 

rstrlen  endp

;-------------------SSTRLEN-----------------------
; 
; Description: Returns the length of the given 
; byte string, that is, the number of characters 
; in a character array whose first element is 
; pointed to by ES:DI up to and not including the 
; first null character. The behavior is undefined 
; if there is no null character in the character 
; array pointed to by str.
;
; Entry: gets segment address and address of the
;        string from stack
;        first  arg - segment address
;        second arg - string address(offset)
; Exit : AX - lenght of the string
; Destr: CX, DI, ES
; Note : Sets DF to zero
;------------------------------------------------

sstrlen proc

        push bp                 ;prologue
        mov  bp, sp

        mov  di, [bp + 4]       ; getting args
        mov  es, [bp + 6]       

        call rstrlen

        pop bp                  ; epilogue
        ret 

sstrlen endp

;------------------RSTRCHR-----------------------
; 
; Description: Finds the first occurrence of ch 
; in the null-terminated byte string pointed to 
; by str. The terminating null character is 
; considered to be a part of the string and can
; be found when searching for '\0'.
; The behavior is undefined if ES:DI is not a 
; pointer to a null-terminated byte string.
;
; Entry: DI - address of the first symbol of
;             the string
;        ES - points to the segment, where 
;             string is stored
;        AL - symbol to be found
; Exit : DI - address of the founded symbol
;             or '0' if there is no in string
; Destr: DI
;------------------------------------------------

rstrchr proc

        cld                     ; DF = 0

    rstrchrLoop:
        cmp byte ptr es:[di], 0 ; is *string = 0
        je rstrchrNotFound      ; stop if *string zero

        scasb                   ; cmp al, es:[di]; di++;
        je rstrchrFound         ; symbol found
        jmp rstrchrLoop

    rstrchrFound:
        dec di                  ; return to found symb
        jmp rstrchrRet          

    rstrchrNotFound:
        xor di, di              ; return = 0
    
    rstrchrRet:
        ret

rstrchr endp

;------------------SSTRCHR-----------------------
; 
; Description: Finds the first occurrence of ch 
; in the null-terminated byte string pointed to 
; by str. The terminating null character is 
; considered to be a part of the string and can
; be found when searching for '\0'.
; The behavior is undefined if ES:DI is not a 
; pointer to a null-terminated byte string.
;
; Entry: first arg  - points to the segment, 
;                     where string is stored
;        second arg - address of the first symbol
;                     of the string
;        third arg  - symbol to be found
; Exit : DI - address of the founded symbol
;             or '0' if there is no in string
; Destr: ES, AX
;------------------------------------------------

sstrchr proc

        push bp                 ; prologue
        mov  bp, sp

        mov ax, [bp + 4]        ; getting args
        mov di, [bp + 6]
        mov es, [bp + 8]

        call rstrchr

        pop bp                  ; epilogue
        ret

sstrchr endp

;------------------RSTRNCPY----------------------
; 
; Description: Copies the character string 
; pointed to by DS:SI, including the null 
; terminator, to the character array whose 
; first element is pointed to by ES:DI.
; The behavior is undefined if the dest array 
; is not large enough. The behavior is undefined
; if the strings overlap.
;
; Entry: DS - points to the segment, where the 
;             string is stored
;        SI - address of the first symbol of the 
;             string
;        ES - points to the segment, where the 
;             destination string is stored
;        DI - addres of the first symbol of
;              destination string
;        CX - max number of bytes to be copied 
; Exit : None
; Destr: CX, SI
; Note : Sets DF to zero
;------------------------------------------------

rstrncpy proc

        push di                 ; saving di
        cld                     ; DF = 0

    rstrncpyLoop:
        cmp byte ptr ds:[si], 0 ; is *string = 0
        movsb                   ; ds:[si]->es:[di]; si++; di++;
        je rstrncpyRet          ; stop if *string = 0
        loop rstrncpyLoop       ; cx--;

        mov byte ptr es:[di], 0 ; set terminating 0

    rstrncpyRet:
        pop di                  ; restore di
        ret

rstrncpy endp

;------------------SSTRNCPY----------------------
; 
; Description: Copies the character string 
; pointed to by DS:SI, including the null 
; terminator, to the character array whose 
; first element is pointed to by ES:DI.
; The behavior is undefined if the dest array 
; is not large enough. The behavior is undefined
; if the strings overlap.
;
;  Entry: Arguments in stack: 
;        first  - points to the segment, where the 
;                 string is stored
;        second - address of the first symbol of
;                 the string
;        third  - points to the segment, where the
;                 destination string is stored
;        fourth - address of the first symbol of
;                 destination string
;        fifth  - max number of bytes to be copied
;
; Exit : DI - points to the first symbol of
;             destination string
; Destr: CX, DS, SI, ES
; Note : Sets DF to zero
;------------------------------------------------

sstrncpy proc

        push bp                 ; prologue
        mov  bp, sp

        mov cx, [bp + 4 ]       ; getting args
        mov di, [bp + 6 ]
        mov es, [bp + 8 ]
        mov si, [bp + 10]
        mov ds, [bp + 12]

        call rstrncpy

        pop bp
        ret

sstrncpy endp

;------------------RSTRNCMP----------------------
; 
; Description: Compares at most count characters
; of two possibly null-terminated arrays. 
; The comparison is done lexicographically. 
; Characters following the null character are 
; not compared.
; The sign of the result is the sign of the 
; difference between the values of the first pair
; of characters that differ in the arrays being
; compared.
; The behavior is undefined when access occurs 
; past the end of either array DS:SI or ES:DI. 
; The behavior is undefined when either lhs 
; or rhs is the null pointer.
;
; Entry: DS - points to the segment, where the 
;             first string is stored
;        ES - points to the segment, where the
;             second string is stored
;        SI - address of the first symbol of
;             first string
;        DI - address of the first symbol of
;             second string
;        CX - max amount of bytes to be compared
; Exit : AL - 0, if strings are equal
;             Positive value, if first string is
;             lexicographically more
;             Negative value, if second is
;             lexicographically less 
; Destr: DI, SI, CX, DL
; Note: sets DF to zero
;------------------------------------------------

rstrncmp    proc

            cld                 ; DF = 0
        
        rstrncmpLoop:
            lodsb               ; al = ds:[si]; si++
            mov dl, es:[di]
            inc di

            cmp al, 0           ; if *first = 0 stop
            je  rstrncmpRet

            cmp al, dl          ; if *first != *second stop
            jne rstrncmpRet

            loop rstrncmpLoop

        rstrncmpRet:
            sub al, dl          ; return value
            ret


rstrncmp    endp

;------------------SSTRNCMP----------------------
; 
; Description: Compares at most count characters
; of two possibly null-terminated arrays. 
; The comparison is done lexicographically. 
; Characters following the null character are 
; not compared.
; The sign of the result is the sign of the 
; difference between the values of the first pair
; of characters that differ in the arrays being
; compared.
; The behavior is undefined when access occurs 
; past the end of either array DS:SI or ES:DI. 
; The behavior is undefined when either lhs 
; or rhs is the null pointer.
;
; Entry: first  - points to the segment, where 
;                 the first string is stored
;        second  - address of the first symbol of
;                 first string
;        third  - points to the segment, where 
;                 the second string is stored
;        fourth - address of the first symbol of
;                 second string
;        fifth  - max amount of bytes to be 
;                 compared
; Exit : AL - 0, if strings are equal
;             Positive value, if first string is
;             lexicographically more
;             Negative value, if second is
;             lexicographically less 
; Destr: DI, SI, CX, DL, ES, DS
; Note: sets DF to zero
;------------------------------------------------

sstrncmp    proc

            push bp             ; prologue 
            mov  bp, sp

            mov ds, [bp + 12]   ; getting args
            mov si, [bp + 10]
            mov es, [bp + 8 ]
            mov di, [bp + 6 ]
            mov cx, [bp + 4 ]
        
            call rstrncmp

            pop bp
            ret


sstrncmp    endp


;--------------------RATOI-----------------------
; 
; Description: Interprets an integer value in a 
; byte string pointed to by str.
; Discards any whitespace characters until the 
; first non-whitespace character is found, then 
; takes as many characters as possible to form a 
; valid integer number representation and converts 
; them to an integer value. The valid integer 
; value consists of the following parts:
; 1. numeric digits
; 2. plus or minus sign (feature will be added soon)
;
; Entry: DS - points to segment, where string is 
;             stored
;        SI - points to the first symbol of 
;             string
; Exit : AX - number ( double word (DX, AX) )
; Destr: CX, SI, BX, DX
;------------------------------------------------

SPACE equ 020h
MINUS equ 02Dh
PLUS  equ 02Bh

;------------------------------------------------

.NextSymb   macro
            nop
            mov bl, ds:[si]
            inc si
            nop
            endm

ratoi   proc

        xor bh, bh              ; clean bh
        xor ax, ax              ; clean future return value
        mov cx, 0Ah             ; base of system
        mov dx, 1               ; sign multyplier

    ratoiSkipSpaces:            ; skip blank before number
        .NextSymb
        cmp bl, SPACE
        je ratoiSkipSpaces

        cmp bl, PLUS            ; plus sign
        je ratoiPos

        cmp bl, MINUS           ; minus sign
        je ratoiNeg

    ratoiMain:
        push dx                 ; save sign multyplier

    ratoiLoop:                  ; main cycle
        cmp bl, 0               ; if *string = 0 stop
        je ratoiRet
        mul cx                  ; ax = base * ax

        sub bl, '0'             ; converting code of symb
        add ax, bx              ; incrementing value

        mov bl, ds:[si]         ; load next symbol
        inc si
        jmp ratoiLoop

    ratoiPos:
        .NextSymb               ; iterate to next symbol
        jmp ratoiMain

    ratoiNeg:
        mov dx, -1              ; change sign multyplier
        .NextSymb               ; iterate to next symbol
        jmp ratoiMain

    ratoiRet:
        pop dx                  ; get sign multyplier
        mul dx
        ret

ratoi   endp

;--------------------SATOI-----------------------
; 
; Description: Interprets an integer value in a 
; byte string pointed to by str.
; Discards any whitespace characters until the 
; first non-whitespace character is found, then 
; takes as many characters as possible to form a 
; valid integer number representation and converts 
; them to an integer value. The valid integer 
; value consists of the following parts:
; 1. numeric digits
; 2. plus or minus sign (feature will be added soon)
;
; Entry: first  - points to segment, where string
;                 is stored
;        second - points to the first symbol of 
;                 string
; Exit : AX - number
; Destr: CX, SI, BX, DX, DS
; Note: sets DF to zero
;------------------------------------------------

SPACE equ 020h
MINUS equ 02Dh
PLUS  equ 02Bh

;------------------------------------------------

satoi   proc

        push bp                 ; prologue 
        mov  bp, sp

        mov ds, [bp + 6]        ; getting args
        mov si, [bp + 4]

        call ratoi
        
        pop bp                  ; epilogue
        ret

satoi   endp

;--------------------RNUMTOA------------------------
;
; Description: Translates number into string
; Entry:       DS - points to the segment, where
;                   string will be stored
;              SI - points to the address of the
;                   first symbol in string
;              BX - number to be translated
;              CX - base of the numeric system 
; Exit:        SI remains it value
; Destr:       BX, AX, DX
;------------------------------------------------

rnumtoa     proc

            mov ax, bx          

        rnumtoaCount:           ; counting offset
            xor dx, dx
            div cx
            cmp ax, 0
            je rnumtoaMain
            inc si              ; increments counter
            jmp rnumtoaCount

        rnumtoaMain:
            mov ax, bx

        rnumtoaLoop:
            xor dx, dx          ; for 'div' command
            div cx

            mov bx, dx          ; converting remainder to symbol
            mov dl, [bx + offset RSYMB_TABLE]   
                                ; prints number from end
            mov ds:[si], dl     
            dec si              ; iterate to next symbol

            cmp ax, 0
            jne rnumtoaLoop

            inc si              ; si points to the start of string
            ret

rnumtoa     endp

RSYMB_TABLE db '0123456789ABCDEF'

;--------------------SNUMTOA---------------------
;
; Description: Translates number into string
; Entry:       first  - points to the segment, 
;                       where string will be 
;                       stored
;              second - points to the address of 
;                       the first symbol in string
;              third  - number to be translated
;              fourth - base of the numeric system 
; Exit:        SI points to the start of the
;              start of string
;              (SI == second argument)
; Destr:       DS, AX, BX
;------------------------------------------------

snumtoa     proc

            push bp             ; prologue
            mov  bp, sp

            mov cx, [bp + 4 ]
            mov ax, [bp + 6 ]
            mov si, [bp + 8 ]
            mov ds, [bp + 10]   

            call rnumtoa

            pop bp              ; epilogue
            ret

snumtoa     endp

SSYMB_TABLE db '0123456789ABCDEF' 

;-----------------RNUMTOA2-----------------------
;
; Description: optimized version of 'rnumtoa'
;              function, used for numeric systems
;              with base 2^n, n = 1, 2, 3 or 4
; Entry:       DS - points to the segment, where
;                   string will be stored
;              SI - points to the first symbol 
;                   in this string
;              AX - number to be translated
;              CL - n
;              DX - mask
; Exit:        SI - remains it value
; Destr:       BX, AX
;------------------------------------------------

rnumtoa2    proc

            mov bx, ax

        rnumtoa2Count:          ; count shift in string
            shr bx, cl
            cmp bx, 0
            je  rnumtoa2Loop    ; stop if bx == 0 

            inc si              
            jmp rnumtoa2Count

        rnumtoa2Loop:           ; main cycle
            mov bx, ax 
            and bx, dx          ; using mask

            mov bl, [bx + offset XlatTable]
            mov ds:[si], bl
            dec si

            shr ax, cl          
            cmp ax, 0
            jne rnumtoa2Loop

            inc si              ; si points to the start
            ret

rnumtoa2    endp

XlatTable db '0123456789ABCDEF'

;-----------------SNUMTOA2-----------------------
;
; Description: optimized version of 'rnumtoa'
;              function, used for numeric systems
;              with base 2^n, n = 1, 2, 3 or 4
; Entry:       first  - points to the segment, 
;                      where string will be stored
;              second - points to the first 
;                       symbol in this string
;              third  - number to be translated
;              fourth - n
;              fifth  - mask
; Exit:        SI - remains it value
; WARNING:     DF must be 1   
; Destr:       BX, DS, AX, CX
;------------------------------------------------

snumtoa2    proc

            push bp
            mov  bp, sp

            mov ds, [bp + 12]
            mov si, [bp + 10]
            mov ax, [bp + 8 ]
            mov cx, [bp + 6 ]
            mov dx, [bp + 4 ]

            call rnumtoa2

            pop bp
            ret

snumtoa2    endp

;================================================

;--------------INTERRUPTION-CODES----------------

PUTS		equ 09h	    	; printing line	
STOP		equ 04Ch    	; terminating
;------------------------------------------------

end Start


