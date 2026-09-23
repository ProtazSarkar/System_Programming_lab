.MODEL SMALL
.STACK 100H

.DATA

prompt      DB 13,10,'MYOS> $'

dirMsg      DB 13,10,'Files:',13,10
            DB 'FILE1.TXT',13,10
            DB 'FILE2.TXT',13,10,'$'

file1Name   DB 'FILE1.TXT',0
file2Name   DB 'FILE2.TXT',0

file1Data   DB 'Hello from FILE1.TXT!',13,10,'$'
file2Data   DB 'This is FILE2.TXT.',13,10,'$'

copyMsg     DB 13,10,'File copied successfully.$'
notFound    DB 13,10,'File not found.$'
badCommand  DB 13,10,'Invalid command.$'

input       DB 100,0,100 DUP(0)

.CODE

MAIN PROC

    MOV AX,@DATA
    MOV DS,AX

SHELL:

    LEA DX,prompt
    MOV AH,09H
    INT 21H

    ; Read command
    LEA DX,input
    MOV AH,0AH
    INT 21H

    ; Check EXIT
    LEA SI,input+2

    MOV AL,[SI]
    CMP AL,'E'
    JNE CHECK_DIR

    MOV AL,[SI+1]
    CMP AL,'X'
    JNE CHECK_DIR

    MOV AL,[SI+2]
    CMP AL,'I'
    JNE CHECK_DIR

    MOV AL,[SI+3]
    CMP AL,'T'
    JNE CHECK_DIR

    JMP EXIT_SHELL

CHECK_DIR:

    LEA SI,input+2

    MOV AL,[SI]
    CMP AL,'D'
    JNE CHECK_TYPE

    MOV AL,[SI+1]
    CMP AL,'I'
    JNE CHECK_TYPE

    MOV AL,[SI+2]
    CMP AL,'R'
    JNE CHECK_TYPE

    LEA DX,dirMsg
    MOV AH,09H
    INT 21H

    JMP SHELL

CHECK_TYPE:

    LEA SI,input+2

    MOV AL,[SI]
    CMP AL,'T'
    JNE CHECK_COPY

    MOV AL,[SI+1]
    CMP AL,'Y'
    JNE CHECK_COPY

    MOV AL,[SI+2]
    CMP AL,'P'
    JNE CHECK_COPY

    MOV AL,[SI+3]
    CMP AL,'E'
    JNE CHECK_COPY

    ; For simplicity TYPE supports FILE1.TXT
    LEA DX,file1Data
    MOV AH,09H
    INT 21H

    JMP SHELL

CHECK_COPY:

    LEA SI,input+2

    MOV AL,[SI]
    CMP AL,'C'
    JNE INVALID

    MOV AL,[SI+1]
    CMP AL,'O'
    JNE INVALID

    MOV AL,[SI+2]
    CMP AL,'P'
    JNE INVALID

    MOV AL,[SI+3]
    CMP AL,'Y'
    JNE INVALID

    LEA DX,copyMsg
    MOV AH,09H
    INT 21H

    JMP SHELL

INVALID:

    LEA DX,badCommand
    MOV AH,09H
    INT 21H

    JMP SHELL

EXIT_SHELL:

    MOV AH,4CH
    INT 21H

MAIN ENDP
END MAIN