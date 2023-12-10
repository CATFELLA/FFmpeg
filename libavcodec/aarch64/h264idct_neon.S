/*
 * Copyright (c) 2008 Mans Rullgard <mans@mansr.com>
 * Copyright (c) 2013 Janne Grunau <janne-libav@jannau.net>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "libavutil/aarch64/asm.S"
#include "neon.S"

function ff_h264_idct_add_neon, export=1
.L_ff_h264_idct_add_neon:
        AARCH64_VALID_CALL_TARGET
        ld1             {v0.4h, v1.4h, v2.4h, v3.4h},  [x1]
        sxtw            x2,     w2
        movi            v30.8h, #0

        add             v4.4h,  v0.4h,  v2.4h
        sshr            v16.4h, v1.4h,  #1
        st1             {v30.8h},    [x1], #16
        sshr            v17.4h, v3.4h,  #1
        st1             {v30.8h},    [x1], #16
        sub             v5.4h,  v0.4h,  v2.4h
        sub             v6.4h,  v16.4h, v3.4h
        add             v7.4h,  v1.4h,  v17.4h
        add             v0.4h,  v4.4h,  v7.4h
        add             v1.4h,  v5.4h,  v6.4h
        sub             v2.4h,  v5.4h,  v6.4h
        sub             v3.4h,  v4.4h,  v7.4h

        transpose_4x4h  v0, v1, v2, v3, v4, v5, v6, v7

        add             v4.4h,  v0.4h,  v2.4h
        ld1             {v18.s}[0], [x0], x2
        sshr            v16.4h,  v3.4h,  #1
        sshr            v17.4h,  v1.4h,  #1
        ld1             {v18.s}[1], [x0], x2
        sub             v5.4h,  v0.4h,  v2.4h
        ld1             {v19.s}[1], [x0], x2
        add             v6.4h,  v16.4h, v1.4h
        ins             v4.d[1],  v5.d[0]
        sub             v7.4h,  v17.4h, v3.4h
        ld1             {v19.s}[0], [x0], x2
        ins             v6.d[1],  v7.d[0]
        sub             x0,  x0,  x2, lsl #2
        add             v0.8h,  v4.8h,  v6.8h
        sub             v1.8h,  v4.8h,  v6.8h

        srshr           v0.8h,  v0.8h,  #6
        srshr           v1.8h,  v1.8h,  #6

        uaddw           v0.8h,  v0.8h,  v18.8b
        uaddw           v1.8h,  v1.8h,  v19.8b

        sqxtun          v0.8b, v0.8h
        sqxtun          v1.8b, v1.8h

        st1             {v0.s}[0],  [x0], x2
        st1             {v0.s}[1],  [x0], x2
        st1             {v1.s}[1],  [x0], x2
        st1             {v1.s}[0],  [x0], x2

        sub             x1,  x1,  #32
        ret
endfunc

function ff_h264_idct_dc_add_neon, export=1
.L_ff_h264_idct_dc_add_neon:
        AARCH64_VALID_CALL_TARGET
        sxtw            x2,  w2
        mov             w3,       #0
        ld1r            {v2.8h},  [x1]
        strh            w3,       [x1]
        srshr           v2.8h,  v2.8h,  #6
        ld1             {v0.s}[0],  [x0], x2
        ld1             {v0.s}[1],  [x0], x2
        uaddw           v3.8h,  v2.8h,  v0.8b
        ld1             {v1.s}[0],  [x0], x2
        ld1             {v1.s}[1],  [x0], x2
        uaddw           v4.8h,  v2.8h,  v1.8b
        sqxtun          v0.8b,  v3.8h
        sqxtun          v1.8b,  v4.8h
        sub             x0,  x0,  x2, lsl #2
        st1             {v0.s}[0],  [x0], x2
        st1             {v0.s}[1],  [x0], x2
        st1             {v1.s}[0],  [x0], x2
        st1             {v1.s}[1],  [x0], x2
        ret
endfunc

function ff_h264_idct_add16_neon, export=1
        mov             x12, x30
        mov             x6,  x0         // dest
        mov             x5,  x1         // block_offset
        mov             x1,  x2         // block
        mov             w9,  w3         // stride
        movrel          x7,  scan8
        mov             x10, #16
        movrel          x13, .L_ff_h264_idct_dc_add_neon
        movrel          x14, .L_ff_h264_idct_add_neon
1:      mov             w2,  w9
        ldrb            w3,  [x7], #1
        ldrsw           x0,  [x5], #4
        ldrb            w3,  [x4,  w3,  uxtw]
        subs            w3,  w3,  #1
        b.lt            2f
        ldrsh           w3,  [x1]
        add             x0,  x0,  x6
        ccmp            w3,  #0,  #4,  eq
        csel            x15, x13, x14, ne
        blr             x15
2:      subs            x10, x10, #1
        add             x1,  x1,  #32
        b.ne            1b
        ret             x12
endfunc

function ff_h264_idct_add16intra_neon, export=1
        mov             x12, x30
        mov             x6,  x0         // dest
        mov             x5,  x1         // block_offset
        mov             x1,  x2         // block
        mov             w9,  w3         // stride
        movrel          x7,  scan8
        mov             x10, #16
        movrel          x13, .L_ff_h264_idct_dc_add_neon
        movrel          x14, .L_ff_h264_idct_add_neon
1:      mov             w2,  w9
        ldrb            w3,  [x7], #1
        ldrsw           x0,  [x5], #4
        ldrb            w3,  [x4,  w3,  uxtw]
        add             x0,  x0,  x6
        cmp             w3,  #0
        ldrsh           w3,  [x1]
        csel            x15, x13, x14, eq
        ccmp            w3,  #0,  #0,  eq
        b.eq            2f
        blr             x15
2:      subs            x10, x10, #1
        add             x1,  x1,  #32
        b.ne            1b
        ret             x12
endfunc

function ff_h264_idct_add8_neon, export=1
        stp             x19, x20, [sp, #-0x40]!
        mov             x12, x30
        ldp             x6,  x15, [x0]          // dest[0], dest[1]
        add             x5,  x1,  #16*4         // block_offset
        add             x9,  x2,  #16*32        // block
        mov             w19, w3                 // stride
        movrel          x13, .L_ff_h264_idct_dc_add_neon
        movrel          x14, .L_ff_h264_idct_add_neon
        movrel          x7,  scan8, 16
        mov             x10, #0
        mov             x11, #16
1:      mov             w2,  w19
        ldrb            w3,  [x7, x10]          // scan8[i]
        ldrsw           x0,  [x5, x10, lsl #2]  // block_offset[i]
        ldrb            w3,  [x4, w3,  uxtw]    // nnzc[ scan8[i] ]
        add             x0,  x0,  x6            // block_offset[i] + dst[j-1]
        add             x1,  x9,  x10, lsl #5   // block + i * 16
        cmp             w3,  #0
        ldrsh           w3,  [x1]               // block[i*16]
        csel            x20, x13, x14, eq
        ccmp            w3,  #0,  #0,  eq
        b.eq            2f
        blr             x20
2:      add             x10, x10, #1
        cmp             x10, #4
        csel            x10, x11, x10, eq     // mov x10, #16
        csel            x6,  x15, x6,  eq
        cmp             x10, #20
        b.lt            1b
        ldp             x19, x20, [sp], #0x40
        ret             x12
endfunc

.macro  idct8x8_cols    pass
  .if \pass == 0
        va      .req    v18
        vb      .req    v30
        sshr            v18.8h, v26.8h, #1
        add             v16.8h, v24.8h, v28.8h
        ld1             {v30.8h, v31.8h}, [x1]
        st1             {v19.8h}, [x1],  #16
        st1             {v19.8h}, [x1],  #16
        sub             v17.8h,  v24.8h, v28.8h
        sshr            v19.8h,  v30.8h, #1
        sub             v18.8h,  v18.8h,  v30.8h
        add             v19.8h,  v19.8h,  v26.8h
  .else
        va      .req    v30
        vb      .req    v18
        sshr            v30.8h, v26.8h, #1
        sshr            v19.8h, v18.8h, #1
        add             v16.8h, v24.8h, v28.8h
        sub             v17.8h, v24.8h, v28.8h
        sub             v30.8h, v30.8h, v18.8h
        add             v19.8h, v19.8h, v26.8h
  .endif
        add             v26.8h, v17.8h, va.8h
        sub             v28.8h, v17.8h, va.8h
        add             v24.8h, v16.8h, v19.8h
        sub             vb.8h,  v16.8h, v19.8h
        sub             v16.8h, v29.8h, v27.8h
        add             v17.8h, v31.8h, v25.8h
        sub             va.8h,  v31.8h, v25.8h
        add             v19.8h, v29.8h, v27.8h
        sub             v16.8h, v16.8h, v31.8h
        sub             v17.8h, v17.8h, v27.8h
        add             va.8h,  va.8h,  v29.8h
        add             v19.8h, v19.8h, v25.8h
        sshr            v25.8h, v25.8h, #1
        sshr            v27.8h, v27.8h, #1
        sshr            v29.8h, v29.8h, #1
        sshr            v31.8h, v31.8h, #1
        sub             v16.8h, v16.8h, v31.8h
        sub             v17.8h, v17.8h, v27.8h
        add             va.8h,  va.8h,  v29.8h
        add             v19.8h, v19.8h, v25.8h
        sshr            v25.8h, v16.8h, #2
        sshr            v27.8h, v17.8h, #2
        sshr            v29.8h, va.8h,  #2
        sshr            v31.8h, v19.8h, #2
        sub             v19.8h, v19.8h, v25.8h
        sub             va.8h,  v27.8h, va.8h
        add             v17.8h, v17.8h, v29.8h
        add             v16.8h, v16.8h, v31.8h
  .if \pass == 0
        sub             v31.8h, v24.8h, v19.8h
        add             v24.8h, v24.8h, v19.8h
        add             v25.8h, v26.8h, v18.8h
        sub             v18.8h, v26.8h, v18.8h
        add             v26.8h, v28.8h, v17.8h
        add             v27.8h, v30.8h, v16.8h
        sub             v29.8h, v28.8h, v17.8h
        sub             v28.8h, v30.8h, v16.8h
  .else
        sub             v31.8h, v24.8h, v19.8h
        add             v24.8h, v24.8h, v19.8h
        add             v25.8h, v26.8h, v30.8h
        sub             v30.8h, v26.8h, v30.8h
        add             v26.8h, v28.8h, v17.8h
        sub             v29.8h, v28.8h, v17.8h
        add             v27.8h, v18.8h, v16.8h
        sub             v28.8h, v18.8h, v16.8h
  .endif
        .unreq          va
        .unreq          vb
.endm

function ff_h264_idct8_add_neon, export=1
.L_ff_h264_idct8_add_neon:
        AARCH64_VALID_CALL_TARGET
        movi            v19.8h,   #0
        sxtw            x2,       w2
        ld1             {v24.8h, v25.8h}, [x1]
        st1             {v19.8h},  [x1],   #16
        st1             {v19.8h},  [x1],   #16
        ld1             {v26.8h, v27.8h}, [x1]
        st1             {v19.8h},  [x1],   #16
        st1             {v19.8h},  [x1],   #16
        ld1             {v28.8h, v29.8h}, [x1]
        st1             {v19.8h},  [x1],   #16
        st1             {v19.8h},  [x1],   #16

        idct8x8_cols    0
        transpose_8x8h  v24, v25, v26, v27, v28, v29, v18, v31, v6, v7
        idct8x8_cols    1

        mov             x3,  x0
        srshr           v24.8h, v24.8h, #6
        ld1             {v0.8b},     [x0], x2
        srshr           v25.8h, v25.8h, #6
        ld1             {v1.8b},     [x0], x2
        srshr           v26.8h, v26.8h, #6
        ld1             {v2.8b},     [x0], x2
        srshr           v27.8h, v27.8h, #6
        ld1             {v3.8b},     [x0], x2
        srshr           v28.8h, v28.8h, #6
        ld1             {v4.8b},     [x0], x2
        srshr           v29.8h, v29.8h, #6
        ld1             {v5.8b},     [x0], x2
        srshr           v30.8h, v30.8h, #6
        ld1             {v6.8b},     [x0], x2
        srshr           v31.8h, v31.8h, #6
        ld1             {v7.8b},     [x0], x2
        uaddw           v24.8h, v24.8h, v0.8b
        uaddw           v25.8h, v25.8h, v1.8b
        uaddw           v26.8h, v26.8h, v2.8b
        sqxtun          v0.8b,  v24.8h
        uaddw           v27.8h, v27.8h, v3.8b
        sqxtun          v1.8b,  v25.8h
        uaddw           v28.8h, v28.8h, v4.8b
        sqxtun          v2.8b,  v26.8h
        st1             {v0.8b},     [x3], x2
        uaddw           v29.8h, v29.8h, v5.8b
        sqxtun          v3.8b,  v27.8h
        st1             {v1.8b},     [x3], x2
        uaddw           v30.8h, v30.8h, v6.8b
        sqxtun          v4.8b,  v28.8h
        st1             {v2.8b},     [x3], x2
        uaddw           v31.8h, v31.8h, v7.8b
        sqxtun          v5.8b,  v29.8h
        st1             {v3.8b},     [x3], x2
        sqxtun          v6.8b,  v30.8h
        sqxtun          v7.8b,  v31.8h
        st1             {v4.8b},     [x3], x2
        st1             {v5.8b},     [x3], x2
        st1             {v6.8b},     [x3], x2
        st1             {v7.8b},     [x3], x2

        sub             x1,  x1,  #128
        ret
endfunc

function ff_h264_idct8_dc_add_neon, export=1
.L_ff_h264_idct8_dc_add_neon:
        AARCH64_VALID_CALL_TARGET
        mov             w3,       #0
        sxtw            x2,       w2
        ld1r            {v31.8h}, [x1]
        strh            w3,       [x1]
        ld1             {v0.8b},  [x0], x2
        srshr           v31.8h, v31.8h, #6
        ld1             {v1.8b},     [x0], x2
        ld1             {v2.8b},     [x0], x2
        uaddw           v24.8h, v31.8h, v0.8b
        ld1             {v3.8b},     [x0], x2
        uaddw           v25.8h, v31.8h, v1.8b
        ld1             {v4.8b},     [x0], x2
        uaddw           v26.8h, v31.8h, v2.8b
        ld1             {v5.8b},     [x0], x2
        uaddw           v27.8h, v31.8h, v3.8b
        ld1             {v6.8b},     [x0], x2
        uaddw           v28.8h, v31.8h, v4.8b
        ld1             {v7.8b},     [x0], x2
        uaddw           v29.8h, v31.8h, v5.8b
        uaddw           v30.8h, v31.8h, v6.8b
        uaddw           v31.8h, v31.8h, v7.8b
        sqxtun          v0.8b,  v24.8h
        sqxtun          v1.8b,  v25.8h
        sqxtun          v2.8b,  v26.8h
        sqxtun          v3.8b,  v27.8h
        sub             x0,  x0,  x2, lsl #3
        st1             {v0.8b},     [x0], x2
        sqxtun          v4.8b,  v28.8h
        st1             {v1.8b},     [x0], x2
        sqxtun          v5.8b,  v29.8h
        st1             {v2.8b},     [x0], x2
        sqxtun          v6.8b,  v30.8h
        st1             {v3.8b},     [x0], x2
        sqxtun          v7.8b,  v31.8h
        st1             {v4.8b},     [x0], x2
        st1             {v5.8b},     [x0], x2
        st1             {v6.8b},     [x0], x2
        st1             {v7.8b},     [x0], x2
        ret
endfunc

function ff_h264_idct8_add4_neon, export=1
        mov             x12, x30
        mov             x6,  x0
        mov             x5,  x1
        mov             x1,  x2
        mov             w2,  w3
        movrel          x7,  scan8
        mov             w10, #16
        movrel          x13, .L_ff_h264_idct8_dc_add_neon
        movrel          x14, .L_ff_h264_idct8_add_neon
1:      ldrb            w9,  [x7], #4
        ldrsw           x0,  [x5], #16
        ldrb            w9,  [x4, w9, uxtw]
        subs            w9,  w9,  #1
        b.lt            2f
        ldrsh           w11,  [x1]
        add             x0,  x6,  x0
        ccmp            w11, #0,  #4,  eq
        csel            x15, x13, x14, ne
        blr             x15
2:      subs            w10, w10, #4
        add             x1,  x1,  #128
        b.ne            1b
        ret             x12
endfunc

const   scan8
        .byte           4+ 1*8, 5+ 1*8, 4+ 2*8, 5+ 2*8
        .byte           6+ 1*8, 7+ 1*8, 6+ 2*8, 7+ 2*8
        .byte           4+ 3*8, 5+ 3*8, 4+ 4*8, 5+ 4*8
        .byte           6+ 3*8, 7+ 3*8, 6+ 4*8, 7+ 4*8
        .byte           4+ 6*8, 5+ 6*8, 4+ 7*8, 5+ 7*8
        .byte           6+ 6*8, 7+ 6*8, 6+ 7*8, 7+ 7*8
        .byte           4+ 8*8, 5+ 8*8, 4+ 9*8, 5+ 9*8
        .byte           6+ 8*8, 7+ 8*8, 6+ 9*8, 7+ 9*8
        .byte           4+11*8, 5+11*8, 4+12*8, 5+12*8
        .byte           6+11*8, 7+11*8, 6+12*8, 7+12*8
        .byte           4+13*8, 5+13*8, 4+14*8, 5+14*8
        .byte           6+13*8, 7+13*8, 6+14*8, 7+14*8
endconst

function ff_h264_idct_add_neon_10, export=1
.L_ff_h264_idct_add_neon_10:
        ld1             {v0.4s, v1.4s, v2.4s, v3.4s},  [x1]

        sxtw            x2,     w2
        movi            v30.8h, #0

        add             v4.4s,  v0.4s,  v2.4s
        sshr            v16.4s, v1.4s,  #1
        st1             {v30.8h},    [x1], #16
        st1             {v30.8h},    [x1], #16
        sshr            v17.4s, v3.4s,  #1
        st1             {v30.8h},    [x1], #16
        st1             {v30.8h},    [x1], #16
        sub             v5.4s,  v0.4s,  v2.4s
        sub             v6.4s,  v16.4s, v3.4s
        add             v7.4s,  v1.4s,  v17.4s
        add             v0.4s,  v4.4s,  v7.4s
        add             v1.4s,  v5.4s,  v6.4s
        sub             v2.4s,  v5.4s,  v6.4s
        sub             v3.4s,  v4.4s,  v7.4s

        transpose_4x4s  v0, v1, v2, v3, v4, v5, v6, v7

        add             v4.4s,  v0.4s,  v2.4s
        ld1             {v18.d}[0], [x0], x2
        sshr            v16.4s,  v3.4s,  #1
        sshr            v17.4s,  v1.4s,  #1
        ld1             {v18.d}[1], [x0], x2
        sub             v5.4s,  v0.4s,  v2.4s
        ld1             {v19.d}[1], [x0], x2
        add             v6.4s,  v16.4s, v1.4s
        sub             v7.4s,  v17.4s, v3.4s
        ld1             {v19.d}[0], [x0], x2
        sub             x0,  x0,  x2, lsl #2
        add             v0.4s,  v4.4s,  v6.4s
        add             v1.4s,  v5.4s,  v7.4s
        sub             v2.4s,  v4.4s,  v6.4s
        sub             v3.4s,  v5.4s,  v7.4s

        srshr           v0.4s,  v0.4s,  #6
        srshr           v1.4s,  v1.4s,  #6
        srshr           v2.4s,  v2.4s,  #6
        srshr           v3.4s,  v3.4s,  #6

        uaddw           v0.4s,  v0.4s,  v18.4h
        uaddw2          v1.4s,  v1.4s,  v18.8h
        uaddw           v2.4s,  v2.4s,  v19.4h
        uaddw2          v3.4s,  v3.4s,  v19.8h

        sqxtun          v0.4h, v0.4s
        sqxtun2         v0.8h, v1.4s
        sqxtun          v1.4h, v2.4s
        sqxtun2         v1.8h, v3.4s

        mvni            v4.8h,  #0xFC,  lsl #8 // 1023 for clipping
        umin            v0.8h,  v0.8h,  v4.8h
        umin            v1.8h,  v1.8h,  v4.8h

        st1             {v0.d}[0],  [x0], x2
        st1             {v0.d}[1],  [x0], x2
        st1             {v1.d}[1],  [x0], x2
        st1             {v1.d}[0],  [x0], x2

        sub             x1,  x1,  #64
        ret
endfunc

function ff_h264_idct_dc_add_neon_10, export=1
.L_ff_h264_idct_dc_add_neon_10:
        sxtw            x2,  w2
        mov             x3,       #0
        ld1r            {v2.4s},  [x1]
        dup             v3.4s, v2.s[0]
        str             x3,       [x1]
        srshr           v2.4s,  v2.4s,  #6
        srshr           v3.4s,  v3.4s,  #6
        ld1             {v0.d}[0],  [x0], x2
        ld1             {v0.d}[1],  [x0], x2
        uaddw           v4.4s,  v2.4s,  v0.4h
        uaddw2          v5.4s,  v3.4s,  v0.8h
        ld1             {v1.d}[0],  [x0], x2
        ld1             {v1.d}[1],  [x0], x2
        uaddw           v6.4s,  v2.4s,  v1.4h
        uaddw2          v7.4s,  v3.4s,  v1.8h
        sqxtun          v0.4h,  v4.4s
        sqxtun2         v0.8h,  v5.4s
        sqxtun          v1.4h,  v6.4s
        sqxtun2         v1.8h,  v7.4s
        sub             x0,  x0,  x2, lsl #2

        mvni            v4.8h,  #0xFC,  lsl #8 // 1023 for clipping
        umin            v0.8h,  v0.8h,  v4.8h
        umin            v1.8h,  v1.8h,  v4.8h

        st1             {v0.d}[0],  [x0], x2
        st1             {v0.d}[1],  [x0], x2
        st1             {v1.d}[0],  [x0], x2
        st1             {v1.d}[1],  [x0], x2
        ret
endfunc

function ff_h264_idct_add16_neon_10, export=1
        mov             x12, x30
        mov             x6,  x0         // dest
        mov             x5,  x1         // block_offset
        mov             x1,  x2         // block
        mov             w9,  w3         // stride
        movrel          x7,  scan8
        mov             x10, #16
        movrel          x13, .L_ff_h264_idct_dc_add_neon_10
        movrel          x14, .L_ff_h264_idct_add_neon_10
1:      mov             w2,  w9
        ldrb            w3,  [x7], #1
        ldrsw           x0,  [x5], #4
        ldrb            w3,  [x4,  w3,  uxtw]
        subs            w3,  w3,  #1
        b.lt            2f
        ldrsh           w3,  [x1]
        add             x0,  x0,  x6
        ccmp            w3,  #0,  #4,  eq
        csel            x15, x13, x14, ne
        blr             x15
2:      subs            x10, x10, #1
        add             x1,  x1,  #64
        b.ne            1b
        ret             x12
endfunc

function ff_h264_idct_add16intra_neon_10, export=1
        mov             x12, x30
        mov             x6,  x0         // dest
        mov             x5,  x1         // block_offset
        mov             x1,  x2         // block
        mov             w9,  w3         // stride
        movrel          x7,  scan8
        mov             x10, #16
        movrel          x13, .L_ff_h264_idct_dc_add_neon_10
        movrel          x14, .L_ff_h264_idct_add_neon_10
1:      mov             w2,  w9
        ldrb            w3,  [x7], #1
        ldrsw           x0,  [x5], #4
        ldrb            w3,  [x4,  w3,  uxtw]
        add             x0,  x0,  x6
        cmp             w3,  #0
        ldrsh           w3,  [x1]
        csel            x15, x13, x14, eq
        ccmp            w3,  #0,  #0,  eq
        b.eq            2f
        blr             x15
2:      subs            x10, x10, #1
        add             x1,  x1,  #64
        b.ne            1b
        ret             x12
endfunc

function ff_h264_idct_add8_neon_10, export=1 // NO TESTS but test video looks fine (did not look fine before the fixes so it is definitely working somehow)
        stp             x19, x20, [sp, #-0x40]!
        mov             x12, x30
        ldp             x6,  x15, [x0]          // dest[0], dest[1]
        add             x5,  x1,  #16*4         // block_offset
        add             x9,  x2,  #16*32*2      // block
        mov             w19, w3                 // stride
        movrel          x13, .L_ff_h264_idct_dc_add_neon_10
        movrel          x14, .L_ff_h264_idct_add_neon_10
        movrel          x7,  scan8, 16
        mov             x10, #0                 // i
        mov             x11, #16
1:      mov             w2,  w19
        ldrb            w3,  [x7, x10]          // scan8[i]
        ldrsw           x0,  [x5, x10, lsl #2]  // block_offset[i]
        ldrb            w3,  [x4, w3,  uxtw]    // nnzc[ scan8[i] ]
        add             x0,  x0,  x6            // block_offset[i] + dst[j-1]
        add             x1,  x9,  x10, lsl #6   // block + i * 16 * 2
        cmp             w3,  #0
        ldrsh           w3,  [x1]               // block[i * 16 * 2]
        csel            x20, x13, x14, eq
        ccmp            w3,  #0,  #0,  eq
        b.eq            2f
        blr             x20
2:      add             x10, x10, #1
        cmp             x10, #4
        csel            x10, x11, x10, eq
        csel            x6,  x15, x6,  eq
        cmp             x10, #20
        b.lt            1b
        ldp             x19, x20, [sp], #0x40
        ret             x12
endfunc

.macro  idct8x8_cols_10 pass
  .if \pass == 0
        va      .req    v0
        vaa     .req    v1
        vb      .req    v28
        vbb     .req    v29

        sshr            v0.4s,  v20.4s, #1
        sshr            v1.4s,  v21.4s, #1
        add             v2.4s,  v16.4s, v24.4s   // a0
        add             v3.4s,  v17.4s, v25.4s

        ld1             {v28.4s, v29.4s, v30.4s, v31.4s}, [x1]
        st1             {v7.4s}, [x1],   #16
        st1             {v7.4s}, [x1],   #16
        st1             {v7.4s}, [x1],   #16
        st1             {v7.4s}, [x1],   #16

        sub             v4.4s,  v16.4s, v24.4s
        sub             v5.4s,  v17.4s, v25.4s
        sshr            v6.4s,  v28.4s, #1
        sshr            v7.4s,  v29.4s, #1
        sub             v0.4s,  v0.4s,  v28.4s
        sub             v1.4s,  v1.4s,  v29.4s
        add             v6.4s,  v6.4s,  v20.4s  // a6
        add             v7.4s,  v7.4s,  v21.4s
  .else
        va      .req    v28
        vaa     .req    v29
        vb      .req    v0
        vbb     .req    v1

        sshr            v28.4s, v20.4s, #1
        sshr            v29.4s, v21.4s, #1
        sshr            v6.4s,  v0.4s,  #1
        sshr            v7.4s,  v1.4s,  #1
        add             v2.4s,  v16.4s, v24.4s
        add             v3.4s,  v17.4s, v25.4s
        sub             v4.4s,  v16.4s, v24.4s
        sub             v5.4s,  v17.4s, v25.4s
        sub             v28.4s, v28.4s, v0.4s
        sub             v29.4s, v29.4s, v1.4s
        add             v6.4s,  v6.4s,  v20.4s
        add             v7.4s,  v7.4s,  v21.4s
  .endif
        add             v20.4s, v4.4s,  va.4s
        add             v21.4s, v5.4s,  vaa.4s
        sub             v24.4s, v4.4s,  va.4s
        sub             v25.4s, v5.4s,  vaa.4s
        add             v16.4s, v2.4s,  v6.4s   // b0
        add             v17.4s, v3.4s,  v7.4s
        sub             vb.4s,  v2.4s,  v6.4s
        sub             vbb.4s, v3.4s,  v7.4s
        sub             v2.4s,  v26.4s, v22.4s
        sub             v3.4s,  v27.4s, v23.4s
        add             v4.4s,  v30.4s, v18.4s
        add             v5.4s,  v31.4s, v19.4s
        sub             va.4s,  v30.4s, v18.4s
        sub             vaa.4s, v31.4s, v19.4s
        add             v6.4s,  v26.4s, v22.4s
        add             v7.4s,  v27.4s, v23.4s
        sub             v2.4s,  v2.4s,  v30.4s
        sub             v3.4s,  v3.4s,  v31.4s
        sub             v4.4s,  v4.4s,  v22.4s
        sub             v5.4s,  v5.4s,  v23.4s
        add             va.4s,  va.4s,  v26.4s
        add             vaa.4s, vaa.4s, v27.4s
        add             v6.4s,  v6.4s,  v18.4s
        add             v7.4s,  v7.4s,  v19.4s
        sshr            v18.4s, v18.4s, #1
        sshr            v19.4s, v19.4s, #1
        sshr            v22.4s, v22.4s, #1
        sshr            v23.4s, v23.4s, #1
        sshr            v26.4s, v26.4s, #1
        sshr            v27.4s, v27.4s, #1
        sshr            v30.4s, v30.4s, #1
        sshr            v31.4s, v31.4s, #1
        sub             v2.4s,  v2.4s,  v30.4s
        sub             v3.4s,  v3.4s,  v31.4s
        sub             v4.4s,  v4.4s,  v22.4s
        sub             v5.4s,  v5.4s,  v23.4s
        add             va.4s,  va.4s,  v26.4s
        add             vaa.4s, vaa.4s, v27.4s
        add             v6.4s,  v6.4s,  v18.4s  // a7
        add             v7.4s,  v7.4s,  v19.4s
        sshr            v18.4s, v2.4s,  #2
        sshr            v19.4s, v3.4s,  #2
        sshr            v22.4s, v4.4s,  #2
        sshr            v23.4s, v5.4s,  #2
        sshr            v26.4s, va.4s,  #2
        sshr            v27.4s, vaa.4s, #2
        sshr            v30.4s, v6.4s,  #2
        sshr            v31.4s, v7.4s,  #2
        sub             v6.4s,  v6.4s,  v18.4s
        sub             v7.4s,  v7.4s,  v19.4s
        sub             va.4s,  v22.4s, va.4s
        sub             vaa.4s, v23.4s, vaa.4s
        add             v4.4s,  v4.4s,  v26.4s
        add             v5.4s,  v5.4s,  v27.4s
        add             v2.4s,  v2.4s,  v30.4s
        add             v3.4s,  v3.4s,  v31.4s
  .if \pass == 0
        sub             v30.4s, v16.4s, v6.4s
        sub             v31.4s, v17.4s, v7.4s
        add             v16.4s, v16.4s, v6.4s
        add             v17.4s, v17.4s, v7.4s
        add             v18.4s, v20.4s, v0.4s
        add             v19.4s, v21.4s, v1.4s
        sub             v0.4s,  v20.4s, v0.4s
        sub             v1.4s,  v21.4s, v1.4s
        add             v20.4s, v24.4s, v4.4s
        add             v21.4s, v25.4s, v5.4s
        add             v22.4s, v28.4s, v2.4s
        add             v23.4s, v29.4s, v3.4s
        sub             v26.4s, v24.4s, v4.4s
        sub             v27.4s, v25.4s, v5.4s
        sub             v24.4s, v28.4s, v2.4s
        sub             v25.4s, v29.4s, v3.4s
  .else
        sub             v30.4s, v16.4s, v6.4s
        sub             v31.4s, v17.4s, v7.4s
        add             v16.4s, v16.4s, v6.4s
        add             v17.4s, v17.4s, v7.4s
        add             v18.4s, v20.4s, v28.4s
        add             v19.4s, v21.4s, v29.4s
        sub             v28.4s, v20.4s, v28.4s
        sub             v29.4s, v21.4s, v29.4s
        add             v20.4s, v24.4s, v4.4s
        add             v21.4s, v25.4s, v5.4s
        sub             v26.4s, v24.4s, v4.4s
        sub             v27.4s, v25.4s, v5.4s
        add             v22.4s, v0.4s,  v2.4s
        add             v23.4s, v1.4s,  v3.4s
        sub             v24.4s, v0.4s,  v2.4s
        sub             v25.4s, v1.4s,  v3.4s
  .endif
        .unreq          va
        .unreq          vaa
        .unreq          vb
        .unreq          vbb
.endm

function ff_h264_idct8_add_neon_10, export=1
.L_ff_h264_idct8_add_neon_10:
        movi            v7.4s,   #0
        sxtw            x2,       w2

        ld1             {v16.4s, v17.4s, v18.4s, v19.4s}, [x1]
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16

        ld1             {v20.4s, v21.4s, v22.4s, v23.4s}, [x1]
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16

        ld1             {v24.4s, v25.4s, v26.4s, v27.4s}, [x1]
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16
        st1             {v7.4s},  [x1],   #16

        idct8x8_cols_10 0

        transpose_8x8s  v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v0, v1, v30, v31, v2, v3, v4, v5
        idct8x8_cols_10 1

        mov             x3,  x0
        srshr           v16.4s, v16.4s, #6
        srshr           v17.4s, v17.4s, #6
        ld1             {v0.8h},     [x0], x2
        srshr           v18.4s, v18.4s, #6
        srshr           v19.4s, v19.4s, #6
        ld1             {v1.8h},     [x0], x2
        srshr           v20.4s, v20.4s, #6
        srshr           v21.4s, v21.4s, #6
        ld1             {v2.8h},     [x0], x2
        srshr           v22.4s, v22.4s, #6
        srshr           v23.4s, v23.4s, #6
        ld1             {v3.8h},     [x0], x2
        srshr           v24.4s, v24.4s, #6
        srshr           v25.4s, v25.4s, #6
        ld1             {v4.8h},     [x0], x2
        srshr           v26.4s, v26.4s, #6
        srshr           v27.4s, v27.4s, #6
        ld1             {v5.8h},     [x0], x2
        srshr           v28.4s, v28.4s, #6
        srshr           v29.4s, v29.4s, #6
        ld1             {v6.8h},     [x0], x2
        srshr           v30.4s, v30.4s, #6
        srshr           v31.4s, v31.4s, #6
        ld1             {v7.8h},     [x0], x2
        uaddw           v16.4s, v16.4s, v0.4h
        uaddw2          v17.4s, v17.4s, v0.8h
        uaddw           v18.4s, v18.4s, v1.4h
        uaddw2          v19.4s, v19.4s, v1.8h
        uaddw           v20.4s, v20.4s, v2.4h
        uaddw2          v21.4s, v21.4s, v2.8h
        sqxtun          v0.4h,  v16.4s
        sqxtun2         v0.8h,  v17.4s
        uaddw           v22.4s, v22.4s, v3.4h
        uaddw2          v23.4s, v23.4s, v3.8h
        sqxtun          v1.4h,  v18.4s
        sqxtun2         v1.8h,  v19.4s
        uaddw           v24.4s, v24.4s, v4.4h
        uaddw2          v25.4s, v25.4s, v4.8h
        sqxtun          v2.4h,  v20.4s
        sqxtun2         v2.8h,  v21.4s
        st1             {v0.8h},     [x3], x2
        uaddw           v26.4s, v26.4s, v5.4h
        uaddw2          v27.4s, v27.4s, v5.8h
        sqxtun          v3.4h,  v22.4s
        sqxtun2         v3.8h,  v23.4s
        st1             {v1.8h},     [x3], x2
        uaddw           v28.4s, v28.4s, v6.4h
        uaddw2          v29.4s, v29.4s, v6.8h
        sqxtun          v4.4h,  v24.4s
        sqxtun2         v4.8h,  v25.4s
        st1             {v2.8h},     [x3], x2
        uaddw           v30.4s, v30.4s, v7.4h
        uaddw2          v31.4s, v31.4s, v7.8h
        sqxtun          v5.4h,  v26.4s
        sqxtun2         v5.8h,  v27.4s
        st1             {v3.8h},     [x3], x2
        sqxtun          v6.4h,  v28.4s
        sqxtun2         v6.8h,  v29.4s
        sqxtun          v7.4h,  v30.4s
        sqxtun2         v7.8h,  v31.4s
        st1             {v4.8h},     [x3], x2
        st1             {v5.8h},     [x3], x2
        st1             {v6.8h},     [x3], x2
        st1             {v7.8h},     [x3], x2

        sub             x1,  x1,  #256
        ret
endfunc

function ff_h264_idct8_dc_add_neon_10, export=1
.L_ff_h264_idct8_dc_add_neon_10:
        mov             x3,       #0
        sxtw            x2,       w2
        ld1r            {v31.4s}, [x1]
        str             x3,       [x1]
        ld1             {v0.8h},  [x0], x2
        srshr           v30.4s, v31.4s, #6
        srshr           v31.4s, v31.4s, #6
        ld1             {v1.8h},     [x0], x2
        ld1             {v2.8h},     [x0], x2
        uaddw           v16.4s, v31.4s, v0.4h
        uaddw2          v17.4s, v31.4s, v0.8h
        ld1             {v3.8h},     [x0], x2
        uaddw           v18.4s, v31.4s, v1.4h
        uaddw2          v19.4s, v31.4s, v1.8h
        ld1             {v4.8h},     [x0], x2
        uaddw           v20.4s, v31.4s, v2.4h
        uaddw2          v21.4s, v31.4s, v2.8h
        ld1             {v5.8h},     [x0], x2
        uaddw           v22.4s, v31.4s, v3.4h
        uaddw2          v23.4s, v31.4s, v3.8h
        ld1             {v6.8h},     [x0], x2
        uaddw           v24.4s, v31.4s, v4.4h
        uaddw2          v25.4s, v31.4s, v4.8h
        ld1             {v7.8h},     [x0], x2
        uaddw           v26.4s, v31.4s, v5.4h
        uaddw2          v27.4s, v31.4s, v5.8h
        uaddw           v28.4s, v31.4s, v6.4h
        uaddw2          v29.4s, v31.4s, v6.8h
        uaddw           v30.4s, v31.4s, v7.4h
        uaddw2          v31.4s, v31.4s, v7.8h
        sqxtun          v0.4h,  v16.4s
        sqxtun2         v0.8h,  v17.4s
        sqxtun          v1.4h,  v18.4s
        sqxtun2         v1.8h,  v19.4s
        sqxtun          v2.4h,  v20.4s
        sqxtun2         v2.8h,  v21.4s
        sqxtun          v3.4h,  v22.4s
        sqxtun2         v3.8h,  v23.4s
        sub             x0,  x0,  x2, lsl #3

        mvni            v16.8h, #0xFC, lsl #8
        umin            v0.8h,  v0.8h,  v16.8h
        st1             {v0.8h},     [x0], x2
        sqxtun          v4.4h,  v24.4s
        sqxtun2         v4.8h,  v25.4s
        umin            v1.8h,  v1.8h,  v16.8h
        st1             {v1.8h},     [x0], x2
        sqxtun          v5.4h,  v26.4s
        sqxtun2         v5.8h,  v27.4s
        umin            v2.8h,  v2.8h,  v16.8h
        st1             {v2.8h},     [x0], x2
        sqxtun          v6.4h,  v28.4s
        sqxtun2         v6.8h,  v29.4s
        umin            v3.8h,  v3.8h,  v16.8h
        st1             {v3.8h},     [x0], x2
        sqxtun          v7.4h,  v30.4s
        sqxtun2         v7.8h,  v31.4s
        umin            v4.8h,  v4.8h,  v16.8h
        st1             {v4.8h},     [x0], x2
        umin            v5.8h,  v5.8h,  v16.8h
        st1             {v5.8h},     [x0], x2
        umin            v6.8h,  v6.8h,  v16.8h
        st1             {v6.8h},     [x0], x2
        umin            v7.8h,  v7.8h,  v16.8h
        st1             {v7.8h},     [x0], x2
        ret
endfunc

function ff_h264_idct8_add4_neon_10, export=1
        mov             x12, x30
        mov             x6,  x0
        mov             x5,  x1
        mov             x1,  x2
        mov             w2,  w3
        movrel          x7,  scan8
        mov             w10, #16
        movrel          x13, .L_ff_h264_idct8_dc_add_neon_10
        movrel          x14, .L_ff_h264_idct8_add_neon_10
1:      ldrb            w9,  [x7], #4
        ldrsw           x0,  [x5], #16        // block_offset
        ldrb            w9,  [x4, w9, UXTW]   // nnz
        subs            w9,  w9,  #1
        b.lt            2f
        ldr             w11,  [x1]
        add             x0,  x6,  x0
        ccmp            w11, #0,  #4,  eq
        csel            x15, x13, x14, ne
        blr             x15
2:      subs            w10, w10, #4
        add             x1,  x1,  #256
        b.ne            1b
        ret             x12
endfunc
