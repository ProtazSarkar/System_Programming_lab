.MODEL SMALL
.STACK 100H

.DATA

MAX     EQU 20

n       DW ?

pid     DB MAX DUP(?)
arrival DW MAX DUP(?)
burst   DW MAX DUP(?)
startT  DW MAX DUP(?)
complete DW MAX DUP(?)
turnaround DW MAX DUP(?)
waiting DW MAX DUP(?)

currentTime DW 0

msg1 DB 13,10,'FCFS CPU SCHEDULING',13,10,'$'
msg2 DB 13,10,'Enter number of processes: $'

msgA DB 13,10,'Enter Arrival Time for P$'
msgB DB ': $'

msgC DB 13,10,'Enter Burst Time for P$'

header DB 13,10,13,10
       DB 'Process  Arrival  Burst  Start  Completion  Waiting  Turnaround'
       DB 13,10
       DB '--------------------------------------------------------------'
       DB 13,10,'$'

ganttMsg DB 13,10,13,10,'Execution Timeline:',13,10,'$'

arrow DB ' -> $'

avgMsg DB 13,10,13,10,'Average Waiting Time = $'

.CODE

MAIN PROC

    MOV AX,@DATA
    MOV DS,AX

;==================================================
; TITLE
;==================================================

    LEA DX,msg1
    MOV AH,09H
    INT 21H

;==================================================
; READ NUMBER OF PROCESSES
;==================================================

    LEA DX,msg2
    MOV AH,09H
    INT 21H

    CALL READ_NUM
    MOV n,AX

;==================================================
; INPUT ARRIVAL AND BURST TIME
;==================================================

    MOV CX,n
    MOV SI,0
    MOV BL,1

INPUT_LOOP:

    ; Store process ID
    MOV pid[SI],BL

;--------------------------------
; Arrival Time
;--------------------------------

    LEA DX,msgA
    MOV AH,09H
    INT 21H

    XOR AX,AX
    MOV AL,BL
    CALL PRINT_NUM

    LEA DX,msgB
    MOV AH,09H
    INT 21H

    CALL READ_NUM
    MOV arrival[SI],AX

;--------------------------------
; Burst Time
;--------------------------------

    LEA DX,msgC
    MOV AH,09H
    INT 21H

    XOR AX,AX
    MOV AL,BL
    CALL PRINT_NUM

    LEA DX,msgB
    MOV AH,09H
    INT 21H

    CALL READ_NUM
    MOV burst[SI],AX

    INC BL
    ADD SI,2

    LOOP INPUT_LOOP

;==================================================
; SORT PROCESSES BY ARRIVAL TIME
;==================================================

    MOV CX,n
    DEC CX

OUTER_SORT:

    MOV SI,0
    MOV BX,CX

INNER_SORT:

    MOV AX,arrival[SI]
    CMP AX,arrival[SI+2]

    JLE NO_SWAP

;--------------------------------
; Swap Arrival Time
;--------------------------------

    MOV DX,arrival[SI]
    XCHG DX,arrival[SI+2]
    MOV arrival[SI],DX

;--------------------------------
; Swap Burst Time
;--------------------------------

    MOV DX,burst[SI]
    XCHG DX,burst[SI+2]
    MOV burst[SI],DX

;--------------------------------
; Swap Process ID
;--------------------------------

    MOV DL,pid[SI]
    MOV DH,pid[SI+2]
    MOV pid[SI],DH
    MOV pid[SI+2],DL

NO_SWAP:

    ADD SI,2
    DEC BX
    JNZ INNER_SORT

    LOOP OUTER_SORT

;==================================================
; FCFS CALCULATION
;==================================================

    MOV currentTime,0

    MOV CX,n
    MOV SI,0

CALCULATE:

;--------------------------------
; If CPU is idle:
;
; currentTime < arrival
; currentTime = arrival
;--------------------------------

    MOV AX,currentTime
    CMP AX,arrival[SI]
    JGE CPU_READY

    MOV AX,arrival[SI]
    MOV currentTime,AX

CPU_READY:

;--------------------------------
; Start Time
;--------------------------------

    MOV startT[SI],AX

;--------------------------------
; Completion Time
;
; Completion = Start + Burst
;--------------------------------

    ADD AX,burst[SI]
    MOV complete[SI],AX
    MOV currentTime,AX

;--------------------------------
; Turnaround Time
;
; TAT = Completion - Arrival
;--------------------------------

    MOV DX,AX
    SUB DX,arrival[SI]
    MOV turnaround[SI],DX

;--------------------------------
; Waiting Time
;
; WT = Turnaround - Burst
;--------------------------------

    SUB DX,burst[SI]
    MOV waiting[SI],DX

    ADD SI,2

    LOOP CALCULATE

;==================================================
; DISPLAY TABLE
;==================================================

    LEA DX,header
    MOV AH,09H
    INT 21H

    MOV CX,n
    MOV SI,0

DISPLAY_LOOP:

;--------------------------------
; Print P
;--------------------------------

    MOV DL,'P'
    MOV AH,02H
    INT 21H

    XOR AX,AX
    MOV AL,pid[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Arrival
;--------------------------------

    MOV AX,arrival[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Burst
;--------------------------------

    MOV AX,burst[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Start
;--------------------------------

    MOV AX,startT[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Completion
;--------------------------------

    MOV AX,complete[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Waiting
;--------------------------------

    MOV AX,waiting[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

;--------------------------------
; Turnaround
;--------------------------------

    MOV AX,turnaround[SI]
    CALL PRINT_NUM

    MOV DL,13
    MOV AH,02H
    INT 21H

    MOV DL,10
    MOV AH,02H
    INT 21H

    ADD SI,2

    LOOP DISPLAY_LOOP

;==================================================
; EXECUTION TIMELINE
;==================================================

    LEA DX,ganttMsg
    MOV AH,09H
    INT 21H

    MOV CX,n
    MOV SI,0

GANTT:

    MOV DL,'P'
    MOV AH,02H
    INT 21H

    XOR AX,AX
    MOV AL,pid[SI]
    CALL PRINT_NUM

    MOV DL,' '
    MOV AH,02H
    INT 21H

    MOV AX,startT[SI]
    CALL PRINT_NUM

    LEA DX,arrow
    MOV AH,09H
    INT 21H

    MOV AX,complete[SI]
    CALL PRINT_NUM

    MOV DL,13
    MOV AH,02H
    INT 21H

    MOV DL,10
    MOV AH,02H
    INT 21H

    ADD SI,2

    LOOP GANTT

;==================================================
; EXIT
;==================================================

    MOV AH,4CH
    INT 21H

MAIN ENDP


;==================================================
; READ_NUM
;
; Reads a decimal number from keyboard.
; Result returned in AX.
;==================================================

READ_NUM PROC

    PUSH BX
    PUSH CX
    PUSH DX

    XOR BX,BX

READ_LOOP:

    MOV AH,01H
    INT 21H

    CMP AL,13
    JE READ_DONE

    CMP AL,'0'
    JB READ_LOOP

    CMP AL,'9'
    JA READ_LOOP

    SUB AL,'0'

    XOR AH,AH

    PUSH AX

    MOV AX,BX
    MOV CX,10
    MUL CX

    MOV BX,AX

    POP AX

    ADD BX,AX

    JMP READ_LOOP

READ_DONE:

    MOV AX,BX

    POP DX
    POP CX
    POP BX

    RET

READ_NUM ENDP


;==================================================
; PRINT_NUM
;
; Prints decimal number in AX.
;
; IMPORTANT:
; CX is preserved so LOOP instructions
; outside this procedure are not damaged.
;==================================================

PRINT_NUM PROC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

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

    POP DX
    POP CX
    POP BX
    POP AX

    RET

PRINT_NUM ENDP

END MAIN