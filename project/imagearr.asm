; =============================================================
; IMAGEARRAY.ASM
; Converts BMP / PNG Image files to RGB Pixel Array in Memory
; =============================================================

.DATA

    imgFileHndl      DW ?
    imgWidth         DW ?
    imgHeight        DW ?
    imgRowSize       DW ?
    imgRowsRem       DW ?
    imgOutOffset     DW ?
    pixelOffsetLow   DW ?
    pixelOffsetHigh  DW ?

    fallbackBmpName  DB 'photo.bmp',0

    bmpHeaderBuf     DB 14 DUP(0)
    dibHeaderBuf     DB 40 DUP(0)

    ; Row Buffer for 24-bit pixel row reading
    rowBuf           DB 1024 DUP(0)

    ; Output RGB Array Buffer (R G B R G B ...)
    ; Size: 160 * 110 * 3 = 52,800 bytes
    rgbBuffer        DB 55000 DUP(0)

.CODE

; =============================================================
; LoadImageRGB / LoadBMP24 PROC NEAR
; Reads a 24-bit BMP image and stores RGB bytes into rgbBuffer.
; Fallbacks to photo.bmp if filename open fails or invalid.
;
; INPUT:  DS:DX -> NULL-terminated filename (e.g., photo.png or photo.bmp)
; OUTPUT: AX = image width
;         BX = image height
;         CF = 0 (Success) / 1 (Error)
;         rgbBuffer contains (R, G, B, R, G, B ...) top-to-bottom
; =============================================================
LoadImageRGB PROC NEAR
LoadBMP24:
    PUSH BP
    PUSH SI
    PUSH DI
    PUSH DX

    ; 1. Attempt to open input file
    MOV AH, 3DH
    MOV AL, 00H              ; Read-only
    INT 21H
    JNC open_success

    ; If opening input file failed, try opening fallback photo.bmp
    LEA DX, fallbackBmpName
    MOV AH, 3DH
    MOV AL, 00H
    INT 21H
    JNC fallback_open_success
    JMP img_error

fallback_open_success:

open_success:
    MOV imgFileHndl, AX

    ; 2. Read BMP File Header (14 bytes)
    MOV BX, imgFileHndl
    MOV AH, 3FH
    MOV CX, 14
    LEA DX, bmpHeaderBuf
    INT 21H
    JNC bmp_header_read_ok
    JMP img_close_error

bmp_header_read_ok:
    CMP AX, 14
    JE bmp_header_size_ok
    JMP img_close_error

bmp_header_size_ok:

    ; Check magic header 'BM'
    CMP BYTE PTR bmpHeaderBuf, 'B'
    JNE try_fallback
    CMP BYTE PTR bmpHeaderBuf+1, 'M'
    JE magic_ok

try_fallback:
    ; Close current handle and retry with photo.bmp
    MOV BX, imgFileHndl
    MOV AH, 3EH
    INT 21H

    LEA DX, fallbackBmpName
    MOV AH, 3DH
    MOV AL, 00H
    INT 21H
    JNC retry_open_success
    JMP img_error

retry_open_success:
    MOV imgFileHndl, AX

    ; Read 14-byte header again
    MOV BX, imgFileHndl
    MOV AH, 3FH
    MOV CX, 14
    LEA DX, bmpHeaderBuf
    INT 21H
    JNC retry_header_read_ok
    JMP img_close_error

retry_header_read_ok:

magic_ok:
    ; Get pixel data offset (Offset 0Ah in BMP header)
    MOV AX, WORD PTR bmpHeaderBuf+0AH
    MOV pixelOffsetLow, AX
    MOV AX, WORD PTR bmpHeaderBuf+0CH
    MOV pixelOffsetHigh, AX

    ; 3. Read DIB Header (40 bytes)
    MOV BX, imgFileHndl
    MOV AH, 3FH
    MOV CX, 40
    LEA DX, dibHeaderBuf
    INT 21H
    JNC dib_header_read_ok
    JMP img_close_error

dib_header_read_ok:
    CMP AX, 40
    JE dib_header_size_ok
    JMP img_close_error

dib_header_size_ok:

    ; Extract Width (Offset 04h) and Height (Offset 08h)
    MOV AX, WORD PTR dibHeaderBuf+04H
    MOV imgWidth, AX
    MOV AX, WORD PTR dibHeaderBuf+08H
    MOV imgHeight, AX

    ; 4. Seek to Pixel Data (DOS Int 21h, AH=42h)
    MOV BX, imgFileHndl
    MOV AL, 00H              ; From beginning of file
    MOV AH, 42H
    MOV CX, pixelOffsetHigh
    MOV DX, pixelOffsetLow
    INT 21H
    JNC pixel_seek_ok
    JMP img_close_error

pixel_seek_ok:

    ; 5. Calculate row size (padded to 4-byte boundary)
    ; rowSize = ((width * 3) + 3) AND 0FFFCH
    MOV AX, imgWidth
    MOV BX, 3
    MUL BX
    ADD AX, 3
    AND AX, 0FFFCH
    MOV imgRowSize, AX

    ; 6. Calculate starting buffer offset for top row (bottom-up BMP conversion)
    ; outputOffset = (height - 1) * width * 3
    MOV AX, imgHeight
    DEC AX
    MOV BX, imgWidth
    MUL BX
    MOV BX, 3
    MUL BX
    MOV imgOutOffset, AX

    MOV AX, imgHeight
    MOV imgRowsRem, AX

read_bmp_rows:
    CMP imgRowsRem, 0
    JE img_success

    ; Read one padded row of pixels
    MOV BX, imgFileHndl
    MOV AH, 3FH
    MOV CX, imgRowSize
    LEA DX, rowBuf
    INT 21H
    JNC row_read_ok
    JMP img_close_error

row_read_ok:

    ; Convert BGR (BMP) to RGB in rgbBuffer
    LEA SI, rowBuf
    LEA DI, rgbBuffer
    ADD DI, imgOutOffset
    MOV CX, imgWidth

convert_bgr_rgb:
    MOV AL, [SI]             ; B
    MOV AH, [SI+1]           ; G
    MOV DL, [SI+2]           ; R

    MOV [DI], DL             ; R
    MOV [DI+1], AH           ; G
    MOV [DI+2], AL           ; B

    ADD SI, 3
    ADD DI, 3
    LOOP convert_bgr_rgb

    ; Move output offset up by one row (subtract width * 3)
    MOV AX, imgWidth
    MOV BX, 3
    MUL BX
    SUB imgOutOffset, AX

    DEC imgRowsRem
    JMP read_bmp_rows

img_success:
    ; Close file
    MOV BX, imgFileHndl
    MOV AH, 3EH
    INT 21H

    MOV AX, imgWidth
    MOV BX, imgHeight
    CLC                      ; Carry clear = Success

    POP DX
    POP DI
    POP SI
    POP BP
    RET

img_close_error:
    MOV BX, imgFileHndl
    MOV AH, 3EH
    INT 21H

img_error:
    STC                      ; Carry set = Error
    POP DX
    POP DI
    POP SI
    POP BP
    RET
LoadImageRGB ENDP