/* Copyright 2012 The MathWorks, Inc. */

#ifndef _OPTICALFLOWFARNEBACK_
#define _OPTICALFLOWFARNEBACK_

#include "vision_defines.h"

#ifndef typedef_cvstFarnebackStruct_T
#define typedef_cvstFarnebackStruct_T

typedef struct {
	double pyr_scale;
	double poly_sigma;
	int levels; 
	int winsize; 
	int iterations; 
	int poly_n; 
	int flags;
} cvstFarnebackStruct_T;


#endif /*typedef_cvstFarnebackStruct_T: used by matlab coder*/

EXTERN_C LIBMWCVSTRT_API void opticalFlowFarneback_compute(uint8_T *inImgPrev, uint8_T *inImgCurr,
	float *inFlowXY, float *outFlowXY,
	cvstFarnebackStruct_T *params,
	int32_T nRows, int32_T nCols);
EXTERN_C LIBMWCVSTRT_API void opticalFlowFarneback_computeRM(uint8_T *inImgPrev, uint8_T *inImgCurr,
	float *inFlowXY, float *outFlowXY,
	cvstFarnebackStruct_T *params,
	int32_T nRows, int32_T nCols);

#endif
