.MODEL SMALL
.STACK 100H

.DATA

msg1 DB 13,10,'Enter number of elements (1-20): $'
msg2 DB 13,10,'Enter element $'
msg3 DB ': $'
msg4 DB 13,10,'Sorted array: $'

array DW 20 DUP(?)
n DW ?

.CODE

MAIN PROC

    MOV AX,@DATA
    MOV DS,AX

;================================================
; READ NUMBER OF ELEMENTS
;================================================

    LEA DX,msg1
    MOV AH,09H
    INT 21H

    CALL READ_NUM
    MOV n,AX

;================================================
; READ ELEMENTS
;================================================

    MOV CX,n
    MOV SI,0
    MOV BX,1              ; element number = 1

INPUT_LOOP:

    ; Print "Enter element "
    LEA DX,msg2
    MOV AH,09H
    INT 21H

    ; Print element number
    MOV AX,BX
    CALL PRINT_NUM

    ; Print ": "
    LEA DX,msg3
    MOV AH,09H
    INT 21H

    ; Read the actual number
    CALL READ_NUM

    ; Store number
    MOV array[SI],AX

    ; Next array position
    ADD SI,2

    ; Next element number
    INC BX

    LOOP INPUT_LOOP

;================================================
; BUBBLE SORT
;================================================

    MOV AX,n

    ; If n <= 1, no sorting needed
    CMP AX,1
    JBE DISPLAY_ARRAY

    DEC AX
    MOV CX,AX

OUTER_LOOP:

    MOV SI,0
    MOV BX,CX

INNER_LOOP:

    MOV AX,array[SI]
    MOV DX,array[SI+2]

    ; Compare array[i] and array[i+1]
    CMP AX,DX

    ; Already in correct order
    JLE NO_SWAP

    ;--------------------------------
    ; Swap
    ;--------------------------------

    MOV array[SI],DX
    MOV array[SI+2],AX

NO_SWAP:

    ADD SI,2

    DEC BX
    JNZ INNER_LOOP

    LOOP OUTER_LOOP

;================================================
; DISPLAY SORTED ARRAY
;================================================

DISPLAY_ARRAY:

    LEA DX,msg4
    MOV AH,09H
    INT 21H

    MOV CX,n
    MOV SI,0

DISPLAY_LOOP:

    MOV AX,array[SI]

    CALL PRINT_NUM

    ; Print space
    MOV DL,' '
    MOV AH,02H
    INT 21H

    ADD SI,2

    LOOP DISPLAY_LOOP

;================================================
; EXIT
;================================================

    MOV AH,4CH
    INT 21H

MAIN ENDP


;================================================
; READ_NUM
;
; Reads a multi-digit decimal number.
;
; Example:
;
; 123 ENTER
;
; Returns:
; AX = 123
;================================================

READ_NUM PROC

    PUSH BX
    PUSH CX
    PUSH DX

    XOR BX,BX

READ_DIGIT:

    MOV AH,01H
    INT 21H

    ; ENTER?
    CMP AL,0DH
    JE DONE_READ

    ; Ignore characters below '0'
    CMP AL,'0'
    JB READ_DIGIT

    ; Ignore characters above '9'
    CMP AL,'9'
    JA READ_DIGIT

    ; Convert ASCII to number
    SUB AL,'0'

    XOR AH,AH

    ; Save current digit
    PUSH AX

    ; BX = BX * 10
    MOV AX,BX
    MOV CX,10
    MUL CX

    MOV BX,AX

    ; Restore digit
    POP AX

    ; BX = BX * 10 + digit
    ADD BX,AX

    JMP READ_DIGIT

DONE_READ:

    MOV AX,BX

    POP DX
    POP CX
    POP BX

    RET

READ_NUM ENDP


;================================================
; PRINT_NUM
;
; AX = number to print
;================================================

PRINT_NUM PROC

    ; Preserve registers
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Special case: 0
    CMP AX,0
    JNE CONVERT

    MOV DL,'0'
    MOV AH,02H
    INT 21H

    JMP PRINT_DONE

CONVERT:

    XOR CX,CX
    MOV BX,10

CONVERT_LOOP:

    XOR DX,DX

    DIV BX

    PUSH DX
    INC CX

    CMP AX,0
    JNE CONVERT_LOOP

PRINT_LOOP:

    POP DX

    ADD DL,'0'

    MOV AH,02H
    INT 21H

    LOOP PRINT_LOOP

PRINT_DONE:

    ; Restore registers
    POP DX
    POP CX
    POP BX
    POP AX

    RET

PRINT_NUM ENDP

END MAIN