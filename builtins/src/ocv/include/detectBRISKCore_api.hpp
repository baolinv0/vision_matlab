/* Copyright 2012 The MathWorks, Inc. */

#ifndef _DETECTBRISK_
#define _DETECTBRISK_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API
int32_T detectBRISK_detect(uint8_T *img, 
                           int nRows, int nCols,
                           int threshold, int numOctaves,
                           void **outKeypoints);

EXTERN_C LIBMWCVSTRT_API
int32_T detectBRISK_detectRM(uint8_T *img, 
                           int nRows, int nCols,
                           int threshold, int numOctaves,
                           void **outKeypoints);

EXTERN_C LIBMWCVSTRT_API
void detectBRISK_assignOutputs(void *ptrKeypoints,
                               real32_T * location,real32_T * metric,
                               real32_T * scale, real32_T * orientation);

EXTERN_C LIBMWCVSTRT_API
void detectBRISK_assignOutputsRM(void *ptrKeypoints,
                               real32_T * location,real32_T * metric,
                               real32_T * scale, real32_T * orientation);

#endif
