/* Copyright 2012 The MathWorks, Inc. */

#ifndef _DETECTFAST_
#define _DETECTFAST_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API int32_T detectFAST_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB, 
	int threshold,
	void **outKeypoints);

EXTERN_C LIBMWCVSTRT_API int32_T detectFAST_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB,
	int threshold,
	void **outKeypoints);

EXTERN_C LIBMWCVSTRT_API void detectFAST_assignOutput(void *ptrKeypoints,
	real32_T *outLoc, real32_T *outMetric);

EXTERN_C LIBMWCVSTRT_API void detectFAST_assignOutputRM(void *ptrKeypoints,
	real32_T *outLoc, real32_T *outMetric);
#endif
