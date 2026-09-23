.MODEL SMALL
.STACK 100H

.DATA
    password DB '1234'
    passLen EQU 4

    msg1 DB 13,10,'BIOS Password Verification System',13,10,'$'
    msg2 DB 'Enter password: $'
    success DB 13,10,'Access Granted!',13,10,'$'
    wrong DB 13,10,'Wrong Password!',13,10,'$'
    locked DB 13,10,'System Locked!',13,10,'$'

    input DB 10 DUP(?)

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    LEA DX, msg1
    MOV AH, 09H
    INT 21H

    MOV BL, 3              ; 3 attempts

TRY_AGAIN:

    LEA DX, msg2
    MOV AH, 09H
    INT 21H

    LEA SI, input
    MOV CX, passLen

READ_PASSWORD:

    ; BIOS keyboard interrupt
    MOV AH, 00H
    INT 16H                ; AL = key pressed

    ; Enter?
    CMP AL, 0DH
    JE CHECK_PASSWORD

    MOV [SI], AL
    INC SI

    ; Print *
    MOV DL, '*'
    MOV AH, 02H
    INT 21H

    LOOP READ_PASSWORD

CHECK_PASSWORD:

    ; Compare password
    LEA SI, input
    LEA DI, password
    MOV CX, passLen

COMPARE:
    MOV AL, [SI]
    CMP AL, [DI]
    JNE PASSWORD_WRONG

    INC SI
    INC DI
    LOOP COMPARE

    ; Correct
    LEA DX, success
    MOV AH, 09H
    INT 21H
    JMP EXIT

PASSWORD_WRONG:

    LEA DX, wrong
    MOV AH, 09H
    INT 21H

    DEC BL
    CMP BL, 0
    JNE TRY_AGAIN

    LEA DX, locked
    MOV AH, 09H
    INT 21H

EXIT:
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN