; =============================================================
; CHANGEBR.ASM
; Brightness controls for the RGB image buffer in GUI.ASM
; =============================================================

; Brightness is shown on a 0..63 scale (default 32).
inc_brightness PROC NEAR
    CMP intensity, 59
    JAE brightness_inc_max
    ADD intensity, 4
    JMP brightness_inc_update
brightness_inc_max:
    MOV intensity, 63
brightness_inc_update:
    CALL adjust_rgb_pixels
    CALL update_display_text
    RET
inc_brightness ENDP

dec_brightness PROC NEAR
    CMP intensity, 4
    JBE brightness_dec_min
    SUB intensity, 4
    JMP brightness_dec_update
brightness_dec_min:
    MOV intensity, 0
brightness_dec_update:
    CALL adjust_rgb_pixels
    CALL update_display_text
    RET
dec_brightness ENDP

; Update VGA hardware DAC palette entries 16..231 for current intensity
adjust_rgb_pixels PROC NEAR
    CALL update_dac_palette
    RET
adjust_rgb_pixels ENDP


; =============================================================
; update_dac_palette
; Updates VGA hardware DAC entries 16..231 for 6x6x6 RGB cube
; adjusted by the current intensity (0..63).
; =============================================================
update_dac_palette PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Calculate brightness offset BL = intensity - 32 (signed -32..+31)
    MOV BL, intensity
    SUB BL, 32

    ; Write DAC palette starting from index 16
    MOV DX, 03C8H
    MOV AL, 16
    OUT DX, AL

    MOV DX, 03C9H            ; DX = port 03C9h for RGB data writes

    MOV CH, 0                ; CH = r index (0..5)
dac_r_loop:
    MOV CL, 0                ; CL = g index (0..5)
dac_g_loop:
    MOV BH, 0                ; BH = b index (0..5)
dac_b_loop:

    ; --- Calculate & Write RED channel ---
    MOV AL, CH
    MOV AH, 12
    MUL AH                   ; AL = CH * 12
    CMP CH, 0
    JE r_base_ok
    ADD AL, 3
r_base_ok:
    MOV AH, AL
    ADD AH, BL
    CMP BL, 0
    JL clamp_r_dark
    CMP AH, 63
    JBE r_val_ok
    CMP AH, AL
    JAE set_r_max
set_r_max:
    MOV AH, 63
    JMP r_val_ok

clamp_r_dark:
    CMP AH, AL
    JA set_r_zero
    JMP r_val_ok
set_r_zero:
    MOV AH, 0

r_val_ok:
    MOV AL, AH
    OUT DX, AL               ; Write Red to 03C9h

    ; --- Calculate & Write GREEN channel ---
    MOV AL, CL
    MOV AH, 12
    MUL AH
    CMP CL, 0
    JE g_base_ok
    ADD AL, 3
g_base_ok:
    MOV AH, AL
    ADD AH, BL
    CMP BL, 0
    JL clamp_g_dark
    CMP AH, 63
    JBE g_val_ok
    CMP AH, AL
    JAE set_g_max
set_g_max:
    MOV AH, 63
    JMP g_val_ok

clamp_g_dark:
    CMP AH, AL
    JA set_g_zero
    JMP g_val_ok
set_g_zero:
    MOV AH, 0

g_val_ok:
    MOV AL, AH
    OUT DX, AL               ; Write Green to 03C9h

    ; --- Calculate & Write BLUE channel ---
    MOV AL, BH
    MOV AH, 12
    MUL AH
    CMP BH, 0
    JE b_base_ok
    ADD AL, 3
b_base_ok:
    MOV AH, AL
    ADD AH, BL
    CMP BL, 0
    JL clamp_b_dark
    CMP AH, 63
    JBE b_val_ok
    CMP AH, AL
    JAE set_b_max
set_b_max:
    MOV AH, 63
    JMP b_val_ok

clamp_b_dark:
    CMP AH, AL
    JA set_b_zero
    JMP b_val_ok
set_b_zero:
    MOV AH, 0

b_val_ok:
    MOV AL, AH
    OUT DX, AL               ; Write Blue to 03C9h

    INC BH                   ; Next b (0..5)
    CMP BH, 6
    JAE dac_b_done
    JMP dac_b_loop
dac_b_done:

    INC CL                   ; Next g (0..5)
    CMP CL, 6
    JAE dac_g_done
    JMP dac_g_loop
dac_g_done:

    INC CH                   ; Next r (0..5)
    CMP CH, 6
    JAE dac_r_done
    JMP dac_r_loop
dac_r_done:

    POP DX
    POP CX
    POP BX
    POP AX
    RET
update_dac_palette ENDP
