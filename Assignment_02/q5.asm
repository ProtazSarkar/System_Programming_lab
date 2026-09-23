.MODEL SMALL
.STACK 100H

.DATA

    msg1 DB 13,10,'Enter bracket expression: $'

    balancedMsg DB 13,10,'Balanced$'
    nonBalancedMsg DB 13,10,'Non-Balanced$'

    ; Do NOT name this "stack"
    ; because .STACK already uses that symbol.
    bracketStack DB 100 DUP(?)

.CODE

MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

    ;-----------------------------------------
    ; Display message
    ;-----------------------------------------

    LEA DX, msg1
    MOV AH, 09H
    INT 21H

    ;-----------------------------------------
    ; DI = Stack pointer
    ; Initially stack is empty
    ;-----------------------------------------

    MOV DI, 0

READ_CHAR:

    ; Read one character
    MOV AH, 01H
    INT 21H

    ; ENTER pressed?
    CMP AL, 0DH
    JE CHECK_STACK

    ;-----------------------------------------
    ; Opening brackets
    ;-----------------------------------------

    CMP AL, '('
    JE PUSH_BRACKET

    CMP AL, '['
    JE PUSH_BRACKET

    CMP AL, '{'
    JE PUSH_BRACKET

    ;-----------------------------------------
    ; Closing brackets
    ;-----------------------------------------

    CMP AL, ')'
    JE CHECK_ROUND

    CMP AL, ']'
    JE CHECK_SQUARE

    CMP AL, '}'
    JE CHECK_CURLY

    ; Ignore other characters
    JMP READ_CHAR


;=============================================
; PUSH OPENING BRACKET
;=============================================

PUSH_BRACKET:

    ; bracketStack[DI] = AL
    MOV bracketStack[DI], AL

    ; Increase stack pointer
    INC DI

    JMP READ_CHAR


;=============================================
; CHECK )
;=============================================

CHECK_ROUND:

    ; If stack empty -> invalid
    CMP DI, 0
    JE NOT_BALANCED

    ; POP
    DEC DI

    MOV BL, bracketStack[DI]

    ; Must be '('
    CMP BL, '('
    JNE NOT_BALANCED

    JMP READ_CHAR


;=============================================
; CHECK ]
;=============================================

CHECK_SQUARE:

    ; If stack empty -> invalid
    CMP DI, 0
    JE NOT_BALANCED

    ; POP
    DEC DI

    MOV BL, bracketStack[DI]

    ; Must be '['
    CMP BL, '['
    JNE NOT_BALANCED

    JMP READ_CHAR


;=============================================
; CHECK }
;=============================================

CHECK_CURLY:

    ; If stack empty -> invalid
    CMP DI, 0
    JE NOT_BALANCED

    ; POP
    DEC DI

    MOV BL, bracketStack[DI]

    ; Must be '{'
    CMP BL, '{'
    JNE NOT_BALANCED

    JMP READ_CHAR


;=============================================
; ENTER PRESSED
; Check whether stack is empty
;=============================================

CHECK_STACK:

    CMP DI, 0
    JNE NOT_BALANCED

    ;-----------------------------------------
    ; Balanced
    ;-----------------------------------------

    LEA DX, balancedMsg
    MOV AH, 09H
    INT 21H

    JMP EXIT


;=============================================
; Non-Balanced
;=============================================

NOT_BALANCED:

    LEA DX, nonBalancedMsg
    MOV AH, 09H
    INT 21H


;=============================================
; Exit
;=============================================

EXIT:

    MOV AH, 4CH
    INT 21H

MAIN ENDP

END MAIN