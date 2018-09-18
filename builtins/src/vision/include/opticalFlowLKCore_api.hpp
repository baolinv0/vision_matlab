/* Copyright 2012 The MathWorks, Inc. */

#ifndef _OPTICALFLOWLKCORE_
#define _OPTICALFLOWLKCORE_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API void MWCV_OpticalFlow_LK_double(const real_T  *inImgA,
                                        const real_T  *inImgB, 
                                        real_T  *outVelC, 
                                        real_T  *outVelR, 
                                        real_T  *gradCC,
                                        real_T  *gradRC,
                                        real_T  *gradRR,
                                        real_T  *gradCT,
                                        real_T  *gradRT,
                                        const real_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols);

EXTERN_C LIBMWCVSTRT_API void MWCV_OpticalFlow_LK_single(const real32_T  *inImgA,
                                        const real32_T  *inImgB, 
                                        real32_T  *outVelC, 
                                        real32_T  *outVelR, 
                                        real32_T  *gradCC,
                                        real32_T  *gradRC,
                                        real32_T  *gradRR,
                                        real32_T  *gradCT,
                                        real32_T  *gradRT,
                                        const real32_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols);

EXTERN_C LIBMWCVSTRT_API void MWCV_OpticalFlow_LK_uint8(const uint8_T  *inImgA,
                                        const uint8_T  *inImgB, 
                                        real32_T  *outVelC, 
                                        real32_T  *outVelR, 
                                        real32_T  *gradCC,
                                        real32_T  *gradRC,
                                        real32_T  *gradRR,
                                        real32_T  *gradCT,
                                        real32_T  *gradRT,
                                        const real32_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols);
#endif
