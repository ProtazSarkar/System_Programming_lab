DATA SEGMENT
    MSG1 DB 'Enter an uppercase letter: $'
    MSG2 DB 13, 10, 'Lowercase letter: $'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA

START:
    MOV AX, DATA
    MOV DS, AX
    LEA DX, MSG1
    MOV AH, 09H
    INT 21H
    MOV AH, 01H
    INT 21H
    ADD AL, 20H
    MOV BL, AL
    LEA DX, MSG2
    MOV AH, 09H
    INT 21H
    MOV DL, BL
    MOV AH, 02H
    INT 21H
    MOV AH, 4CH
    INT 21H

CODE ENDS
END START
