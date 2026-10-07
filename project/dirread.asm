; =============================================================
; DIRREADER.ASM
; Directory Reading & File Viewing Subroutines for MYOS
; =============================================================

.DATA

    dirHeader   DB 13,10,'Directory listing:',13,10,'$'
    dirErr      DB 13,10,'No files found.$'
    notFound    DB 13,10,'File not found or invalid filename.$'
    newlineStr  DB 13,10,'$'

    ; Search pattern for directory listing
    searchPattern DB '*.*',0

    ; Disk Transfer Area for DOS Find First / Find Next
    dtaBuffer   DB 43 DUP(0)

    ; Buffer for reading file content
    fileReadBuf DB 128 DUP(0)
    fileHndl    DW ?

.CODE

; =============================================================
; ListDirectory PROC NEAR
; Lists all normal files in the current directory.
; =============================================================
ListDirectory PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; 1. Set DTA to our buffer (DOS Int 21h, AH=1Ah)
    LEA DX, dtaBuffer
    MOV AH, 1AH
    INT 21H

    ; 2. Print Directory Header
    LEA DX, dirHeader
    MOV AH, 09H
    INT 21H

    ; 3. Find First File (DOS Int 21h, AH=4Eh)
    LEA DX, searchPattern
    MOV CX, 0000H          ; Normal files only
    MOV AH, 4EH
    INT 21H
    JC dir_no_files

dir_print_loop:
    ; Filename starts at offset 1Eh in DTA
    LEA SI, dtaBuffer
    ADD SI, 1EH

dir_print_char:
    MOV DL, [SI]
    CMP DL, 0
    JE dir_print_next_line

    MOV AH, 02H
    INT 21H
    INC SI
    JMP dir_print_char

dir_print_next_line:
    LEA DX, newlineStr
    MOV AH, 09H
    INT 21H

    ; 4. Find Next File (DOS Int 21h, AH=4Fh)
    MOV AH, 4FH
    INT 21H
    JNC dir_print_loop
    JMP dir_end

dir_no_files:
    LEA DX, dirErr
    MOV AH, 09H
    INT 21H

dir_end:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ListDirectory ENDP


; =============================================================
; ReadFileContent PROC NEAR
; Displays the text contents of a file on screen.
; INPUT: DS:DX -> NULL terminated filename
; =============================================================
ReadFileContent PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Open file (DOS Int 21h, AH=3Dh, AL=0 read-only)
    MOV AH, 3DH
    MOV AL, 00H
    INT 21H
    JC read_file_err

    MOV fileHndl, AX

read_chunk_loop:
    MOV AH, 3FH
    MOV BX, fileHndl
    MOV CX, 128
    LEA DX, fileReadBuf
    INT 21H
    JC close_read_err
    CMP AX, 0
    JE close_read_ok

    ; Print read chunk
    MOV CX, AX
    LEA SI, fileReadBuf
print_chunk_bytes:
    MOV DL, [SI]
    MOV AH, 02H
    INT 21H
    INC SI
    LOOP print_chunk_bytes

    JMP read_chunk_loop

close_read_ok:
    MOV AH, 3EH
    MOV BX, fileHndl
    INT 21H

    LEA DX, newlineStr
    MOV AH, 09H
    INT 21H

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

close_read_err:
    MOV AH, 3EH
    MOV BX, fileHndl
    INT 21H

read_file_err:
    LEA DX, notFound
    MOV AH, 09H
    INT 21H

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ReadFileContent ENDP
