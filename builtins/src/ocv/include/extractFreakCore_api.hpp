/* Copyright 2012 The MathWorks, Inc. */

#ifndef _EXTRACTFREAK_
#define _EXTRACTFREAK_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API int32_T extractFreak_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims, 
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int32_T *inMiscOrSignOfLap,
	int32_T numel, int32_T nbOctave, boolean_T orientationNormalized, boolean_T scaleNormalized, real32_T patternScale,
	void **outKeypoints, void **outDescriptors);

EXTERN_C LIBMWCVSTRT_API int32_T extractFreak_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int32_T *inMiscOrSignOfLap,
	int32_T numel, int32_T nbOctave, boolean_T orientationNormalized, boolean_T scaleNormalized, real32_T patternScale,
	void **outKeypoints, void **outDescriptors);

EXTERN_C LIBMWCVSTRT_API void extractFreak_assignOutput(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int32_T *outMiscOrSignOfLap, real32_T *outOrientation, uint8_T *outFeatures);

EXTERN_C LIBMWCVSTRT_API void extractFreak_assignOutputRM(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int32_T *outMiscOrSignOfLap, real32_T *outOrientation, uint8_T *outFeatures);


#endif
