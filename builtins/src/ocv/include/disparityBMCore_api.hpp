/* Copyright 2012 The MathWorks, Inc. */

#ifndef _DISPARITYBM_
#define _DISPARITYBM_

#include "vision_defines.h"

#ifndef typedef_cvstDBMStruct_T
#define typedef_cvstDBMStruct_T

 typedef struct {
	int preFilterCap; 
	int SADWindowSize; 
	int minDisparity; 
	int numberOfDisparities; 
	int textureThreshold; 
	int uniquenessRatio; 
	int disp12MaxDiff;
	int preFilterType; 
	int preFilterSize; 
	int speckleWindowSize; 
	int speckleRange;
	int trySmallerWindows;
} cvstDBMStruct_T;

#endif /*typedef_cvstDBMStruct_T: used by matlab coder*/

 EXTERN_C LIBMWCVSTRT_API void disparityBM_compute(
	const uint8_T* inImg1, const uint8_T* inImg2, int nRows, int nCols, 
	real32_T* dis,
	cvstDBMStruct_T *params);
 EXTERN_C LIBMWCVSTRT_API void disparityBM_computeRM(
	 const uint8_T* inImg1, const uint8_T* inImg2, int nRows, int nCols,
	 real32_T* dis,
	 cvstDBMStruct_T *params);

#endif
