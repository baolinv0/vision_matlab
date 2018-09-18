/*
 *  vip2dconv_rt.h
 *
 *  Copyright 1995-2004 The MathWorks, Inc.
 */

#ifndef vipmdnfilter_rt_h
#define vipmdnfilter_rt_h

#include "dsp_rt.h"
#include "libmwvisionrt_util.h"

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif

#define s2d(a,b) {if (b < a) {real_T tmp = a; a = b; b = tmp;}}
#define s2s(a,b) {if (b < a) {real32_T tmp = a; a = b; b = tmp;}}
#define s2i8(a,b) {if (b < a) {int8_T tmp = a; a = b; b = tmp;}}
#define s2i16(a,b) {if (b < a) {int16_T tmp = a; a = b; b = tmp;}}
#define s2i32(a,b) {if (b < a) {int32_T tmp = a; a = b; b = tmp;}}
#define s2ui8(a,b) {if (b < a) {uint8_T tmp = a; a = b; b = tmp;}}
#define s2ui16(a,b) {if (b < a) {uint16_T tmp = a; a = b; b = tmp;}}
#define s2ui32(a,b) {if (b < a) {uint32_T tmp = a; a = b; b = tmp;}}

#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipmdn_rt_h */
