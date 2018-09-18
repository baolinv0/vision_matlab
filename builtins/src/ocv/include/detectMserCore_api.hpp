/* Copyright 2012 The MathWorks, Inc. */

#ifndef _DETECTMSER_
#define _DETECTMSER_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API void detectMser_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB, 
	int delta,
	int minArea,
	int maxArea,
	float maxVariation,
	float minDiversity,
	int maxEvolution,
	double areaThreshold,
	double minMargin,
	int edgeBlurSize,
	int32_T *numTotalPts,
	int32_T *numRegions,
	void **outRegions);

EXTERN_C LIBMWCVSTRT_API void detectMser_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB,
	int delta,
	int minArea,
	int maxArea,
	float maxVariation,
	float minDiversity,
	int maxEvolution,
	double areaThreshold,
	double minMargin,
	int edgeBlurSize,
	int32_T *numTotalPts,
	int32_T *numRegions,
	void **outRegions);

EXTERN_C LIBMWCVSTRT_API void detectMser_assignOutput(void *ptrRegions,
	int32_T numTotalPts, int32_T *outPts, int32_T *outLengths);

EXTERN_C LIBMWCVSTRT_API void detectMser_assignOutputRM(void *ptrRegions,
	int32_T numTotalPts, int32_T *outPts, int32_T *outLengths);

#endif
