;
; FastBasic - Fast basic interpreter for the Atari 8-bit computers
; Copyright (C) 2017-2022 Daniel Serpell
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program.  If not, see <http://www.gnu.org/licenses/>
;
; In addition to the permissions in the GNU General Public License, the
; authors give you unlimited permission to link the compiled version of
; this file into combinations with other programs, and to distribute those
; combinations without any restriction coming from the use of this file.
; (The General Public License restrictions do apply in other respects; for
; example, they cover modification of the file, and distribution when not
; linked into a combine executable.)


; String copy (assign) and concatenate
; ------------------------------------

        .import         alloc_array
        .importzp       array_ptr, tmp1, tmp2, tmp3, saddr, next_instruction

        .segment        "RUNTIME"

; Store source and destination pointers, allocating destination string if needed.
; Returns Y=0
.proc   get_pointers
        ; Store source pointer
        sta     tmp3
        stx     tmp3+1
        ; Get destination pointer - allocate if 0
        ldy     #1
        lda     (saddr), y
        beq     alloc

        sta     tmp2+1
        dey
        lda     (saddr), y
        sta     tmp2
        rts

alloc:
        ; Copy current memory pointer to the variable
        lda     array_ptr+1
        sta     (saddr), y
        dey
        lda     array_ptr
        sta     (saddr), y
        ; Allocate 256 bytes
        tya
        ldx     #1
        jmp     alloc_array
.endproc

; Copy one string to another, allocating the destination if necessary
.proc   EXE_COPY_STR    ; AX: source string   (SP): destination *variable* address
        jsr     get_pointers

        ; Copy length
        lda     (tmp3), y
        sta     (tmp2), y
        tay
        beq     xit

        ; Copy data
cloop:  lda     (tmp3), y
        sta     (tmp2), y
        dey
        bne     cloop
xit:    jmp     next_instruction
.endproc

; Concatenate the source string to the end of the destination string
.proc   EXE_CAT_STR    ; AX: source string   (SP): destination *variable* address
        jsr     get_pointers

        lda     (tmp2), y       ; Destination length
        sta     tmp1

        clc
        adc     (tmp3), y       ; Source length
        bcc     ok_len
        lda     #255            ; String length overflow, fix at maximum
ok_len:
        sta     (tmp2), y       ; Store new length

        ; Get ending source position into Y
        sec
        sbc     tmp1
        beq     EXE_COPY_STR::xit       ; No bytes to copy
        tay

        ; Fix destination pointer and jump to copy loop
        lda     tmp1
        clc
        adc     tmp2
        sta     tmp2
        bcc     EXE_COPY_STR::cloop
        inc     tmp2+1
        bcs     EXE_COPY_STR::cloop
.endproc

        .include "deftok.inc"
        deftoken "COPY_STR"
        deftoken "CAT_STR"

; vi:syntax=asm_ca65
