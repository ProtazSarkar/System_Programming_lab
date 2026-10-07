; =============================================================
; MAIN.ASM
; Main Command Shell for MYOS:
; Handles Directory Reading, File Viewing & Image Display / Brightness
; =============================================================

.MODEL SMALL
.STACK 400H

INCLUDE dirread.asm
INCLUDE imagearr.asm
INCLUDE gui.asm

.DATA

    welcomeMsg   DB 13,10,'========================================',13,10
                 DB '      MYOS FILE & IMAGE SYSTEM          ',13,10
                 DB '========================================',13,10
                 DB 'Commands:',13,10
                 DB '  DIR              - List directory files',13,10
                 DB '  TYPE <filename>  - View text file',13,10
                 DB '  LOAD <filename>  - Load & display image (e.g. LOAD photo.png)',13,10
                 DB '  EXIT             - Exit program',13,10,'$'

    cmdPrompt    DB 13,10,'MYOS> $'
    badCmdMsg    DB 13,10,'Invalid command. Type DIR, TYPE <file>, LOAD <file>, or EXIT.$'
    imgLoadErr   DB 13,10,'Error: Failed to load image file.$'

    ; Input buffer for DOS Int 21h, AH=0Ah
    cmdBuf       DB 80, 0, 80 DUP(0)
    paramFile    DB 64 DUP(0)

.CODE

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    ; Print Welcome Banner
    LEA DX, welcomeMsg
    MOV AH, 09H
    INT 21H

SHELL_LOOP:
    ; Print Prompt
    LEA DX, cmdPrompt
    MOV AH, 09H
    INT 21H

    ; Read command string
    LEA DX, cmdBuf
    MOV AH, 0AH
    INT 21H

    ; Add NULL terminator after input string
    XOR BX, BX
    MOV BL, cmdBuf[1]
    MOV BYTE PTR cmdBuf[BX+2], 0

    ; Skip if empty input
    CMP BL, 0
    JE SHELL_LOOP

    ; Pointer to typed command string
    LEA SI, cmdBuf+2

    ; Skip leading spaces
skip_spaces:
    MOV AL, [SI]
    CMP AL, ' '
    JNE check_cmds
    INC SI
    JMP skip_spaces

check_cmds:
    ; 1. Check "EXIT"
    CMP BYTE PTR [SI], 'E'
    JE check_exit_rest
    CMP BYTE PTR [SI], 'e'
    JNE check_dir_cmd

check_exit_rest:
    MOV AL, [SI+1]
    AND AL, 0DFH             ; Convert to UPPERCASE
    CMP AL, 'X'
    JNE check_dir_cmd

    MOV AL, [SI+2]
    AND AL, 0DFH
    CMP AL, 'I'
    JNE check_dir_cmd

    MOV AL, [SI+3]
    AND AL, 0DFH
    CMP AL, 'T'
    JNE exit_command_not_selected
    JMP DO_EXIT

exit_command_not_selected:

check_dir_cmd:
    ; 2. Check "DIR"
    MOV AL, [SI]
    AND AL, 0DFH
    CMP AL, 'D'
    JNE check_type_cmd

    MOV AL, [SI+1]
    AND AL, 0DFH
    CMP AL, 'I'
    JNE check_type_cmd

    MOV AL, [SI+2]
    AND AL, 0DFH
    CMP AL, 'R'
    JNE check_type_cmd

    ; Run DIR command
    CALL ListDirectory
    JMP SHELL_LOOP

check_type_cmd:
    ; 3. Check "TYPE"
    MOV AL, [SI]
    AND AL, 0DFH
    CMP AL, 'T'
    JNE check_load_cmd

    MOV AL, [SI+1]
    AND AL, 0DFH
    CMP AL, 'Y'
    JNE check_load_cmd

    MOV AL, [SI+2]
    AND AL, 0DFH
    CMP AL, 'P'
    JNE check_load_cmd

    MOV AL, [SI+3]
    AND AL, 0DFH
    CMP AL, 'E'
    JNE check_load_cmd

    ; Extract filename after space
    ADD SI, 4
    CALL extract_filename
    JC BAD_CMD

    LEA DX, paramFile
    CALL ReadFileContent
    JMP SHELL_LOOP

check_load_cmd:
    ; 4. Check "LOAD"
    MOV AL, [SI]
    AND AL, 0DFH
    CMP AL, 'L'
    JNE BAD_CMD

    MOV AL, [SI+1]
    AND AL, 0DFH
    CMP AL, 'O'
    JNE BAD_CMD

    MOV AL, [SI+2]
    AND AL, 0DFH
    CMP AL, 'A'
    JNE BAD_CMD

    MOV AL, [SI+3]
    AND AL, 0DFH
    CMP AL, 'D'
    JNE BAD_CMD

    ; Extract image filename after space
    ADD SI, 4
    CALL extract_filename
    JC BAD_CMD

    ; Call imagearray.asm routine
    LEA DX, paramFile
    CALL LoadImageRGB
    JC IMG_FAIL

    ; Call gui.asm routine (AX=width, BX=height)
    CALL loadimage
    JMP SHELL_LOOP

IMG_FAIL:
    LEA DX, imgLoadErr
    MOV AH, 09H
    INT 21H
    JMP SHELL_LOOP

BAD_CMD:
    LEA DX, badCmdMsg
    MOV AH, 09H
    INT 21H
    JMP SHELL_LOOP

DO_EXIT:
    MOV AH, 4CH
    MOV AL, 00H
    INT 21H
MAIN ENDP


; =============================================================
; extract_filename PROC NEAR
; Copies next word from [SI] to paramFile as NULL terminated ASCIIZ
; =============================================================
extract_filename PROC NEAR
    ; Skip spaces
find_fn_start:
    MOV AL, [SI]
    CMP AL, 0
    JE fn_err
    CMP AL, ' '
    JNE fn_found_start
    INC SI
    JMP find_fn_start

fn_found_start:
    LEA DI, paramFile
copy_fn_loop:
    MOV AL, [SI]
    CMP AL, 0
    JE fn_finish
    CMP AL, ' '
    JE fn_finish
    CMP AL, 13               ; Carriage Return
    JE fn_finish

    MOV [DI], AL
    INC SI
    INC DI
    JMP copy_fn_loop

fn_finish:
    MOV BYTE PTR [DI], 0
    CLC
    RET

fn_err:
    STC
    RET
extract_filename ENDP

END MAIN
