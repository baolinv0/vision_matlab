/* Copyright 2012 The MathWorks, Inc. */

#ifndef _FASTHESSIANDETECTOR_
#define _FASTHESSIANDETECTOR_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API int32_T fastHessianDetector_uint8(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims, 
	int32_T nOctaveLayers, int32_T nOctaves, int32_T hessianThreshold,
	void **dptrKeypoints);

EXTERN_C LIBMWCVSTRT_API void fastHessianDetector_keyPoints2field(void *keypointsV,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap);

EXTERN_C LIBMWCVSTRT_API void fastHessianDetector_keyPoints2fieldRM(void *keypointsV,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap);

EXTERN_C LIBMWCVSTRT_API void fastHessianDetector_deleteKeypoint(void *ptrKeypoints);
#endif
