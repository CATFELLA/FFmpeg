/*
 * Copyright (c) 2015 Henrik Gramner
 * Copyright (c) 2021 J. Dekker
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with FFmpeg; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <string.h>
#include "checkasm.h"
#include "libavcodec/avcodec.h"
#include "libavcodec/h264chroma.h"
#include "libavutil/common.h"
#include "libavutil/internal.h"
#include "libavutil/intreadwrite.h"
#include "libavutil/mem_internal.h"

static const int codec_ids[4] = { AV_CODEC_ID_H264, AV_CODEC_ID_VP8, AV_CODEC_ID_RV40, AV_CODEC_ID_SVQ3 };
static const uint32_t pixel_mask[3] = { 0xffffffff, 0x01ff01ff, 0x03ff03ff };

#define SIZEOF_PIXEL ((bit_depth + 7) / 8)
#define BUF_SIZE (3 * 16 * 17)

#define randomize_buffers()                        \
    do {                                           \
        uint32_t mask = pixel_mask[bit_depth - 8]; \
        int i;                                     \
        for (i = 0; i < BUF_SIZE; i += 4) {        \
            uint32_t r = rnd() & mask;             \
            AV_WN32A(buf0 + i, r);                 \
            AV_WN32A(buf1 + i, r);                 \
        }                                          \
    } while (0)

#define src0 (buf0 + 4 * 16) /* Offset to allow room for top and left */
#define src1 (buf1 + 4 * 16)

static void check_avg()
{
    int i, bit_depth, x, y;
    LOCAL_ALIGNED_16(uint8_t, buf0, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, buf1, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, dst0, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, dst1, [BUF_SIZE]);
    H264ChromaContext h;

    declare_func_emms(AV_CPU_FLAG_MMX, void, uint8_t *dst, uint8_t *src, ptrdiff_t stride, int h, int x, int y);
    for (bit_depth = 8; bit_depth <= 10; bit_depth++) {
        ff_h264chroma_init(&h, bit_depth);
        for (i = 0; i < 4; i++) {
            if (check_func(h.avg_h264_chroma_pixels_tab[i], "avg_chroma_mc%d_%d", 1 << (3 - i), bit_depth)) {
                randomize_buffers();
                x = rnd() & 0x7; y = rnd() & 0x7;
                call_ref(dst0, src0, 8, 4, x, y);
                call_new(dst1, src1, 8, 4, x, y);
                if (memcmp(buf0, buf1, BUF_SIZE))
                    fail();
                bench_new(dst1, src1, 8, 4, x, y);
            }
        }
    }
}

static void check_put()
{
    int i, bit_depth, x, y;
    LOCAL_ALIGNED_16(uint8_t, buf0, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, buf1, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, dst0, [BUF_SIZE]);
    LOCAL_ALIGNED_16(uint8_t, dst1, [BUF_SIZE]);
    H264ChromaContext h;

    declare_func_emms(AV_CPU_FLAG_MMX, void, uint8_t *dst, uint8_t *src, ptrdiff_t stride, int h, int x, int y);
    for (bit_depth = 8; bit_depth <= 10; bit_depth++) {
        ff_h264chroma_init(&h, bit_depth);
        for (i = 0; i < 4; i++) {
            if (check_func(h.put_h264_chroma_pixels_tab[i], "put_chroma_mc%d_%d", 1 << (3 - i), bit_depth)) {
                randomize_buffers();
                x = rnd() & 0x7; y = rnd() & 0x7;
                call_ref(dst0, src0, 8, 4, x, y);
                call_new(dst1, src1, 8, 4, x, y);
                if (memcmp(buf0, buf1, BUF_SIZE))
                    fail();
                bench_new(dst1, src1, 8, 4, x, y);
            }
        }
    }
}

void checkasm_check_h264chroma(void)
{
    check_avg();
    report("avg");
    check_put();
    report("put");
}
