/*
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

.macro  transpose_8x8B  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9
        trn1            \r8\().8B,  \r0\().8B,  \r1\().8B
        trn2            \r9\().8B,  \r0\().8B,  \r1\().8B
        trn1            \r1\().8B,  \r2\().8B,  \r3\().8B
        trn2            \r3\().8B,  \r2\().8B,  \r3\().8B
        trn1            \r0\().8B,  \r4\().8B,  \r5\().8B
        trn2            \r5\().8B,  \r4\().8B,  \r5\().8B
        trn1            \r2\().8B,  \r6\().8B,  \r7\().8B
        trn2            \r7\().8B,  \r6\().8B,  \r7\().8B

        trn1            \r4\().4H,  \r0\().4H,  \r2\().4H
        trn2            \r2\().4H,  \r0\().4H,  \r2\().4H
        trn1            \r6\().4H,  \r5\().4H,  \r7\().4H
        trn2            \r7\().4H,  \r5\().4H,  \r7\().4H
        trn1            \r5\().4H,  \r9\().4H,  \r3\().4H
        trn2            \r9\().4H,  \r9\().4H,  \r3\().4H
        trn1            \r3\().4H,  \r8\().4H,  \r1\().4H
        trn2            \r8\().4H,  \r8\().4H,  \r1\().4H

        trn1            \r0\().2S,  \r3\().2S,  \r4\().2S
        trn2            \r4\().2S,  \r3\().2S,  \r4\().2S

        trn1            \r1\().2S,  \r5\().2S,  \r6\().2S
        trn2            \r5\().2S,  \r5\().2S,  \r6\().2S

        trn2            \r6\().2S,  \r8\().2S,  \r2\().2S
        trn1            \r2\().2S,  \r8\().2S,  \r2\().2S

        trn1            \r3\().2S,  \r9\().2S,  \r7\().2S
        trn2            \r7\().2S,  \r9\().2S,  \r7\().2S
.endm

.macro  transpose_8x16B r0, r1, r2, r3, r4, r5, r6, r7, t0, t1
        trn1            \t0\().16B, \r0\().16B, \r1\().16B
        trn2            \t1\().16B, \r0\().16B, \r1\().16B
        trn1            \r1\().16B, \r2\().16B, \r3\().16B
        trn2            \r3\().16B, \r2\().16B, \r3\().16B
        trn1            \r0\().16B, \r4\().16B, \r5\().16B
        trn2            \r5\().16B, \r4\().16B, \r5\().16B
        trn1            \r2\().16B, \r6\().16B, \r7\().16B
        trn2            \r7\().16B, \r6\().16B, \r7\().16B

        trn1            \r4\().8H,  \r0\().8H,  \r2\().8H
        trn2            \r2\().8H,  \r0\().8H,  \r2\().8H
        trn1            \r6\().8H,  \r5\().8H,  \r7\().8H
        trn2            \r7\().8H,  \r5\().8H,  \r7\().8H
        trn1            \r5\().8H,  \t1\().8H,  \r3\().8H
        trn2            \t1\().8H,  \t1\().8H,  \r3\().8H
        trn1            \r3\().8H,  \t0\().8H,  \r1\().8H
        trn2            \t0\().8H,  \t0\().8H,  \r1\().8H

        trn1            \r0\().4S,  \r3\().4S,  \r4\().4S
        trn2            \r4\().4S,  \r3\().4S,  \r4\().4S

        trn1            \r1\().4S,  \r5\().4S,  \r6\().4S
        trn2            \r5\().4S,  \r5\().4S,  \r6\().4S

        trn2            \r6\().4S,  \t0\().4S,  \r2\().4S
        trn1            \r2\().4S,  \t0\().4S,  \r2\().4S

        trn1            \r3\().4S,  \t1\().4S,  \r7\().4S
        trn2            \r7\().4S,  \t1\().4S,  \r7\().4S
.endm

.macro  transpose_4x16B r0, r1, r2, r3, t4, t5, t6, t7
        trn1            \t4\().16B, \r0\().16B,  \r1\().16B
        trn2            \t5\().16B, \r0\().16B,  \r1\().16B
        trn1            \t6\().16B, \r2\().16B,  \r3\().16B
        trn2            \t7\().16B, \r2\().16B,  \r3\().16B

        trn1            \r0\().8H,  \t4\().8H,  \t6\().8H
        trn2            \r2\().8H,  \t4\().8H,  \t6\().8H
        trn1            \r1\().8H,  \t5\().8H,  \t7\().8H
        trn2            \r3\().8H,  \t5\().8H,  \t7\().8H
.endm

.macro  transpose_4x8B  r0, r1, r2, r3, t4, t5, t6, t7
        trn1            \t4\().8B,  \r0\().8B,  \r1\().8B
        trn2            \t5\().8B,  \r0\().8B,  \r1\().8B
        trn1            \t6\().8B,  \r2\().8B,  \r3\().8B
        trn2            \t7\().8B,  \r2\().8B,  \r3\().8B

        trn1            \r0\().4H,  \t4\().4H,  \t6\().4H
        trn2            \r2\().4H,  \t4\().4H,  \t6\().4H
        trn1            \r1\().4H,  \t5\().4H,  \t7\().4H
        trn2            \r3\().4H,  \t5\().4H,  \t7\().4H
.endm

.macro  transpose_4x4H  r0, r1, r2, r3, r4, r5, r6, r7
        trn1            \r4\().4H,  \r0\().4H,  \r1\().4H
        trn2            \r5\().4H,  \r0\().4H,  \r1\().4H
        trn1            \r6\().4H,  \r2\().4H,  \r3\().4H
        trn2            \r7\().4H,  \r2\().4H,  \r3\().4H

        trn1            \r0\().2S,  \r4\().2S,  \r6\().2S
        trn2            \r2\().2S,  \r4\().2S,  \r6\().2S
        trn1            \r1\().2S,  \r5\().2S,  \r7\().2S
        trn2            \r3\().2S,  \r5\().2S,  \r7\().2S
.endm

.macro transpose_4x8H r0, r1, r2, r3, t4, t5, t6, t7
        trn1            \t4\().8H,  \r0\().8H,  \r1\().8H
        trn2            \t5\().8H,  \r0\().8H,  \r1\().8H
        trn1            \t6\().8H,  \r2\().8H,  \r3\().8H
        trn2            \t7\().8H,  \r2\().8H,  \r3\().8H

        trn1            \r0\().4S,  \t4\().4S,  \t6\().4S
        trn2            \r2\().4S,  \t4\().4S,  \t6\().4S
        trn1            \r1\().4S,  \t5\().4S,  \t7\().4S
        trn2            \r3\().4S,  \t5\().4S,  \t7\().4S
.endm

.macro  transpose_8x8H  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9
        trn1            \r8\().8H,  \r0\().8H,  \r1\().8H
        trn2            \r9\().8H,  \r0\().8H,  \r1\().8H
        trn1            \r1\().8H,  \r2\().8H,  \r3\().8H
        trn2            \r3\().8H,  \r2\().8H,  \r3\().8H
        trn1            \r0\().8H,  \r4\().8H,  \r5\().8H
        trn2            \r5\().8H,  \r4\().8H,  \r5\().8H
        trn1            \r2\().8H,  \r6\().8H,  \r7\().8H
        trn2            \r7\().8H,  \r6\().8H,  \r7\().8H

        trn1            \r4\().4S,  \r0\().4S,  \r2\().4S
        trn2            \r2\().4S,  \r0\().4S,  \r2\().4S
        trn1            \r6\().4S,  \r5\().4S,  \r7\().4S
        trn2            \r7\().4S,  \r5\().4S,  \r7\().4S
        trn1            \r5\().4S,  \r9\().4S,  \r3\().4S
        trn2            \r9\().4S,  \r9\().4S,  \r3\().4S
        trn1            \r3\().4S,  \r8\().4S,  \r1\().4S
        trn2            \r8\().4S,  \r8\().4S,  \r1\().4S

        trn1            \r0\().2D,  \r3\().2D,  \r4\().2D
        trn2            \r4\().2D,  \r3\().2D,  \r4\().2D

        trn1            \r1\().2D,  \r5\().2D,  \r6\().2D
        trn2            \r5\().2D,  \r5\().2D,  \r6\().2D

        trn2            \r6\().2D,  \r8\().2D,  \r2\().2D
        trn1            \r2\().2D,  \r8\().2D,  \r2\().2D

        trn1            \r3\().2D,  \r9\().2D,  \r7\().2D
        trn2            \r7\().2D,  \r9\().2D,  \r7\().2D

.endm

.macro transpose_4x4S r0, r1, r2, r3, r4, r5, r6, r7
        trn1            \r4\().4s,  \r0\().4s,  \r1\().4s
        trn2            \r5\().4s,  \r0\().4s,  \r1\().4s
        trn1            \r6\().4s,  \r2\().4s,  \r3\().4s
        trn2            \r7\().4s,  \r2\().4s,  \r3\().4s
        trn1            \r0\().2d,  \r4\().2d,  \r6\().2d
        trn2            \r2\().2d,  \r4\().2d,  \r6\().2d
        trn1            \r1\().2d,  \r5\().2d,  \r7\().2d
        trn2            \r3\().2d,  \r5\().2d,  \r7\().2d
.endm

// Transpose a 8x8 matrix of 32 bit elements, where each row is spread out
// over two registers.
.macro transpose_8x8S r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, t0, t1, t2, t3
        transpose_4x4S  \r0,  \r2,  \r4,  \r6,  \t0, \t1, \t2, \t3
        transpose_4x4S  \r9,  \r11, \r13, \r15, \t0, \t1, \t2, \t3

        // Do 4x4 transposes of r1,r3,r5,r7 and r8,r10,r12,r14
        // while swapping the two 4x4 matrices between each other

        // First step of the 4x4 transpose of r1-r7, into t0-t3
        trn1            \t0\().4s,  \r1\().4s,  \r3\().4s
        trn2            \t1\().4s,  \r1\().4s,  \r3\().4s
        trn1            \t2\().4s,  \r5\().4s,  \r7\().4s
        trn2            \t3\().4s,  \r5\().4s,  \r7\().4s

        // First step of the 4x4 transpose of r8-r12, into r1-r7
        trn1            \r1\().4s,  \r8\().4s,  \r10\().4s
        trn2            \r3\().4s,  \r8\().4s,  \r10\().4s
        trn1            \r5\().4s,  \r12\().4s, \r14\().4s
        trn2            \r7\().4s,  \r12\().4s, \r14\().4s

        // Second step of the 4x4 transpose of r1-r7 (now in t0-r3), into r8-r12
        trn1            \r8\().2d,  \t0\().2d,  \t2\().2d
        trn2            \r12\().2d, \t0\().2d,  \t2\().2d
        trn1            \r10\().2d, \t1\().2d,  \t3\().2d
        trn2            \r14\().2d, \t1\().2d,  \t3\().2d

        // Second step of the 4x4 transpose of r8-r12 (now in r1-r7), in place as far as possible
        trn1            \t0\().2d,  \r1\().2d,  \r5\().2d
        trn2            \r5\().2d,  \r1\().2d,  \r5\().2d
        trn1            \t1\().2d,  \r3\().2d,  \r7\().2d
        trn2            \r7\().2d,  \r3\().2d,  \r7\().2d

        // Move the outputs of trn1 back in place
        mov             \r1\().16b,  \t0\().16b
        mov             \r3\().16b,  \t1\().16b
.endm