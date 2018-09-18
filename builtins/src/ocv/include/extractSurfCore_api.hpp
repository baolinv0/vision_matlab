/* Copyright 2012 The MathWorks, Inc. */

#ifndef _EXTRACTSURF_
#define _EXTRACTSURF_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API void extractSurf_assignOutput(void *ptrKeypoints,
        void *ptrDescriptors,
	    real32_T *outLoc, real32_T *outScale, real32_T *outMetric, 
        int8_T *outSignOfLap, real32_T *outOrientation, real32_T *outFeatures);

EXTERN_C LIBMWCVSTRT_API void extractSurf_assignOutputRM(void *ptrKeypoints,
	void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	int8_T *outSignOfLap, real32_T *outOrientation, real32_T *outFeatures);

EXTERN_C LIBMWCVSTRT_API int32_T extractSurf_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims, 
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int8_T *inSignOfLap,
	int32_T numel, boolean_T isExtended, boolean_T isUpright, 
	void **outKeypoints, void **outDescriptors);

EXTERN_C LIBMWCVSTRT_API int32_T extractSurf_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int8_T *inSignOfLap,
	int32_T numel, boolean_T isExtended, boolean_T isUpright,
	void **outKeypoints, void **outDescriptors);

#endif
