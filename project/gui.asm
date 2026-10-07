; =============================================================
; GUI.ASM
; VGA Graphics Mode Display, Image Renderer & Brightness Control
; =============================================================

.DATA

    intensity     DB 32              ; Initial brightness (0 to 63)
    ; UI Text Strings
    title_msg     DB '=== IMAGE VIEWER ===$'
    msg_controls  DB '[+] / [-] or keyboard +/- adjust brightness$'
    msg_quit      DB '[Q/ESC] Exit to Shell$'
    msg_val       DB 'Brightness: 32 $'

    imgW          DW 160
    imgH          DW 110
    startX        DW 80
    startY        DW 40

.CODE

INCLUDE changebr.asm

; =============================================================
; loadimage PROC NEAR / DisplayGUI
; Takes the RGB array from imagearray.asm and renders it in VGA 13h.
; INPUT: AX = width, BX = height
; =============================================================
loadimage PROC NEAR
DisplayGUI:
    PUSH BP
    PUSH SI
    PUSH DI

    MOV intensity, 32         ; Reset initial brightness to 32

    MOV imgW, AX
    MOV imgH, BX

    ; 1. Calculate centered screen coordinates (startX, startY)
    ; startX = (320 - imgW) / 2
    MOV CX, 320
    SUB CX, imgW
    SHR CX, 1
    MOV startX, CX

    ; startY = (200 - imgH) / 2
    MOV CX, 190
    SUB CX, imgH
    SHR CX, 1
    MOV startY, CX

    ; 2. Enter VGA Mode 13h (320x200 256 colors)
    MOV AX, 0013H
    INT 10H

    ; 3. Initialize VGA DAC 6x6x6 RGB Palette (Indices 16..231)
    CALL init_palette_base
    CALL update_dac_palette

    ; 4. Render RGB Image Array to VGA Memory 0A000h
    CALL render_rgb_image

    ; 5. Draw UI Borders & Background
    CALL draw_ui_elements

    ; 6. Initialize Mouse Driver
    MOV AX, 0000H
    INT 33H
    CMP AX, 0
    JE skip_mouse_init
    ; Normalize mouse coordinates to the VGA Mode 13h screen dimensions.
    MOV AX, 0007H
    MOV CX, 0
    MOV DX, 639
    INT 33H
    MOV AX, 0008H
    MOV CX, 0
    MOV DX, 199
    INT 33H
    MOV AX, 0001H            ; Show mouse cursor
    INT 33H
skip_mouse_init:

    ; 7. Render the initial brightness value
    CALL update_display_text

; =============================================================
; Interactive Event Loop (Keyboard & Mouse)
; =============================================================
gui_poll_input:
    ; Check Mouse Status (INT 33h, AX=03h)
    MOV AX, 0003H
    INT 33H
    TEST BX, 0001H           ; Left mouse click?
    JNZ handle_gui_click

    ; Non-blocking keyboard check (INT 16h, AH=01h)
    MOV AH, 01H
    INT 16H
    JZ gui_poll_input

    ; Read key (INT 16h, AH=00h)
    MOV AH, 00H
    INT 16H

    CMP AL, 'q'
    JE do_exit_gui
    CMP AL, 'Q'
    JE do_exit_gui
    CMP AL, 27               ; ESC key
    JE do_exit_gui

    ; Check '+' key: ASCII '+' (43), '=' (61); Scan codes: 4Eh (Keypad+), 0Dh (Main+=), 48h (Up), 4Dh (Right)
    CMP AL, '+'
    JE keyboard_inc_brightness
    CMP AL, '='
    JE keyboard_inc_brightness
    CMP AH, 4EH
    JE keyboard_inc_brightness
    CMP AH, 0DH
    JE keyboard_inc_brightness
    CMP AH, 48H
    JE keyboard_inc_brightness
    CMP AH, 4DH
    JE keyboard_inc_brightness

    ; Check '-' key: ASCII '-' (45), '_' (95); Scan codes: 4Ah (Keypad-), 0Ch (Main-_), 50h (Down), 4Bh (Left)
    CMP AL, '-'
    JE keyboard_dec_brightness
    CMP AL, '_'
    JE keyboard_dec_brightness
    CMP AH, 4AH
    JE keyboard_dec_brightness
    CMP AH, 0CH
    JE keyboard_dec_brightness
    CMP AH, 50H
    JE keyboard_dec_brightness
    CMP AH, 4BH
    JE keyboard_dec_brightness

    JMP gui_poll_input

do_exit_gui:
    JMP exit_gui

keyboard_inc_brightness:
    CALL hide_mouse
    CALL inc_brightness
    CALL show_mouse
    JMP gui_poll_input

keyboard_dec_brightness:
    CALL hide_mouse
    CALL dec_brightness
    CALL show_mouse
    JMP gui_poll_input

handle_gui_click:
    ; In Mode 13h, mouse X is 0..639. Scale down to 0..319:
    SHR CX, 1

    ; Check Y bounds for buttons (Y: 165 to 183)
    CMP DX, 165
    JGE check_click_y_max
    JMP gui_poll_input
check_click_y_max:
    CMP DX, 183
    JLE check_plus_btn
    JMP gui_poll_input

check_plus_btn:
    ; Check [+] Button X bounds (110 to 150)
    CMP CX, 110
    JGE check_plus_x_max
    JMP check_minus_btn
check_plus_x_max:
    CMP CX, 150
    JLE plus_button_clicked
    JMP check_minus_btn

plus_button_clicked:
    CALL hide_mouse
    CALL inc_brightness
    CALL show_mouse
    JMP wait_mouse_release

check_minus_btn:
    ; Check [-] Button X bounds (170 to 210)
    CMP CX, 170
    JGE check_minus_x_max
    JMP gui_poll_input
check_minus_x_max:
    CMP CX, 210
    JLE minus_button_clicked
    JMP gui_poll_input

minus_button_clicked:
    CALL hide_mouse
    CALL dec_brightness
    CALL show_mouse
    JMP wait_mouse_release

wait_mouse_release:
    MOV AX, 0003H
    INT 33H
    TEST BX, 0001H
    JNZ wait_mouse_release
    JMP gui_poll_input

exit_gui:
    ; Hide mouse
    MOV AX, 0002H
    INT 33H

    ; Restore 80x25 DOS Text Mode
    MOV AX, 0003H
    INT 10H

    POP DI
    POP SI
    POP BP
    RET
loadimage ENDP


; =============================================================
; render_rgb_image
; Quantizes RGB bytes from rgbBuffer and writes palette indices to 0A000h
; =============================================================
render_rgb_image PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES

    MOV AX, 0A000H
    MOV ES, AX

    LEA SI, rgbBuffer
    MOV DX, 0                ; Row index y

render_row_loop:
    CMP DX, imgH
    JB render_row_active
    JMP render_done

render_row_active:

    MOV CX, 0                ; Col index x

render_col_loop:
    CMP CX, imgW
    JAE next_row

    ; Get R, G, B bytes
    MOV AL, [SI]             ; R (0..255)
    MOV AH, [SI+1]           ; G (0..255)
    MOV BL, [SI+2]           ; B (0..255)
    ADD SI, 3
    PUSH CX
    MOV CL, BL               ; Preserve B while BL is used as a divisor

    ; Quantize R, G, B (divide by 43 to map 0..255 -> 0..5)
    ; r = R / 43
    PUSH AX
    MOV AH, 0
    MOV BH, 43
    DIV BH
    MOV BH, AL               ; BH = r (0..5)
    POP AX

    ; g = G / 43
    PUSH AX
    MOV AL, AH
    MOV AH, 0
    MOV BL, 43
    DIV BL
    MOV CH, AL               ; CH = g (0..5)
    POP AX

    ; b = B / 43
    PUSH AX
    MOV AL, CL
    MOV AH, 0
    MOV BL, 43
    DIV BL
    MOV CL, AL               ; CL = b (0..5)
    POP AX

    ; Palette Index P = 16 + 36 * r + 6 * g + b
    ; AL = 36 * r
    MOV AL, 36
    MUL BH
    ; AL = 36*r + 6*g
    PUSH AX
    MOV AL, 6
    MUL CH
    MOV BL, AL
    POP AX
    ADD AL, BL
    ADD AL, CL               ; + b
    ADD AL, 16               ; + 16 (base palette index)
    POP CX

    ; Calculate screen offset: DI = (startY + y) * 320 + (startX + x)
    PUSH AX
    PUSH DX
    MOV AX, startY
    ADD AX, DX               ; Y
    MOV DI, 320
    MUL DI
    ADD AX, startX
    ADD AX, CX               ; X
    MOV DI, AX
    POP DX
    POP AX

    ; Write pixel index to screen memory
    MOV ES:[DI], AL

    INC CX
    JMP render_col_loop

next_row:
    INC DX
    JMP render_row_loop

render_done:
    POP ES
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
render_rgb_image ENDP


; =============================================================
; init_palette_base
; Sets up standard UI colors in DAC palette
; =============================================================
init_palette_base PROC NEAR
    ; Index 7: Light Gray (UI Border)
    MOV DX, 03C8H
    MOV AL, 7
    OUT DX, AL
    INC DX                   ; 03C9h
    MOV AL, 40
    OUT DX, AL
    OUT DX, AL
    OUT DX, AL

    ; Index 8: Dark Gray (Button BG)
    MOV DX, 03C8H
    MOV AL, 8
    OUT DX, AL
    INC DX
    MOV AL, 15
    OUT DX, AL
    OUT DX, AL
    OUT DX, AL

    ; Index 15: White
    MOV DX, 03C8H
    MOV AL, 15
    OUT DX, AL
    INC DX
    MOV AL, 63
    OUT DX, AL
    OUT DX, AL
    OUT DX, AL
    RET
init_palette_base ENDP


; =============================================================
; update_display_text
; Renders UI header, quit message, live brightness text & buttons
; =============================================================
update_display_text PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX

    ; Title text at Row 1, Col 10
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 1
    MOV DL, 10
    INT 10H
    MOV AH, 09H
    LEA DX, title_msg
    INT 21H

    ; Brightness controls directly under the title
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 2
    MOV DL, 3
    INT 10H
    MOV AH, 09H
    LEA DX, msg_controls
    INT 21H

    ; Quit msg at Row 22, Col 9
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 22
    MOV DL, 9
    INT 10H
    MOV AH, 09H
    LEA DX, msg_quit
    INT 21H

    ; Brightness value text at Row 19, Col 12
    MOV AL, intensity
    AAM                      ; AH = Tens, AL = Ones
    ADD AX, 3030H
    MOV BYTE PTR [msg_val + 12], AH
    MOV BYTE PTR [msg_val + 13], AL

    MOV AH, 02H
    MOV BH, 0
    MOV DH, 19
    MOV DL, 12
    INT 10H
    MOV AH, 09H
    LEA DX, msg_val
    INT 21H

    POP DX
    POP BX
    POP AX
    RET
update_display_text ENDP


; =============================================================
; draw_ui_elements
; Draws image border box and [+] / [-] buttons
; =============================================================
draw_ui_elements PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES

    MOV AX, 0A000H
    MOV ES, AX

    ; --- Draw [+] Button Box (X: 110..150, Y: 165..183) ---
    MOV DX, 165
d_plus_row:
    MOV CX, 110
d_plus_col:
    MOV AX, DX
    MOV BX, 320
    MUL BX
    ADD AX, CX
    MOV DI, AX

    CMP DX, 165
    JE btn_p_border
    CMP DX, 183
    JE btn_p_border
    CMP CX, 110
    JE btn_p_border
    CMP CX, 150
    JE btn_p_border
    MOV BYTE PTR ES:[DI], 8  ; Dark Gray BG
    JMP btn_p_next
btn_p_border:
    MOV BYTE PTR ES:[DI], 15 ; White Border
btn_p_next:
    INC CX
    CMP CX, 150
    JNE d_plus_col
    INC DX
    CMP DX, 183
    JNE d_plus_row

    ; Draw '+' symbol inside button
    MOV DX, 174
    MOV CX, 124
d_p_hbar:
    MOV AX, DX
    MOV BX, 320
    MUL BX
    ADD AX, CX
    MOV DI, AX
    MOV BYTE PTR ES:[DI], 15
    INC CX
    CMP CX, 137
    JNE d_p_hbar

    MOV DX, 169
d_p_vbar_r:
    MOV CX, 130
    MOV AX, DX
    MOV BX, 320
    MUL BX
    ADD AX, CX
    MOV DI, AX
    MOV BYTE PTR ES:[DI], 15
    INC DX
    CMP DX, 180
    JNE d_p_vbar_r


    ; --- Draw [-] Button Box (X: 170..210, Y: 165..183) ---
    MOV DX, 165
d_minus_row:
    MOV CX, 170
d_minus_col:
    MOV AX, DX
    MOV BX, 320
    MUL BX
    ADD AX, CX
    MOV DI, AX

    CMP DX, 165
    JE btn_m_border
    CMP DX, 183
    JE btn_m_border
    CMP CX, 170
    JE btn_m_border
    CMP CX, 210
    JE btn_m_border
    MOV BYTE PTR ES:[DI], 8  ; Dark Gray BG
    JMP btn_m_next
btn_m_border:
    MOV BYTE PTR ES:[DI], 15 ; White Border
btn_m_next:
    INC CX
    CMP CX, 210
    JNE d_minus_col
    INC DX
    CMP DX, 183
    JNE d_minus_row

    ; Draw '-' symbol inside button
    MOV DX, 174
    MOV CX, 184
d_m_hbar:
    MOV AX, DX
    MOV BX, 320
    MUL BX
    ADD AX, CX
    MOV DI, AX
    MOV BYTE PTR ES:[DI], 15
    INC CX
    CMP CX, 197
    JNE d_m_hbar

    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
draw_ui_elements ENDP


hide_mouse PROC NEAR
    MOV AX, 0002H
    INT 33H
    RET
hide_mouse ENDP

show_mouse PROC NEAR
    MOV AX, 0001H
    INT 33H
    RET
show_mouse ENDP