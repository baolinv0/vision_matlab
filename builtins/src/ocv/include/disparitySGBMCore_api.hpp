/* Copyright 2012 The MathWorks, Inc. */

#ifndef _DISPARITYSGBM_
#define _DISPARITYSGBM_

#include "vision_defines.h"

#ifndef typedef_cvstDSGBMStruct_T
#define typedef_cvstDSGBMStruct_T

 typedef struct {
	int preFilterCap; 
	int SADWindowSize; 
	int minDisparity; 
	int numberOfDisparities; 
	int uniquenessRatio; 
	int disp12MaxDiff; 
	int speckleWindowSize; 
	int speckleRange;
    int P1;
    int P2;
    bool fullDP;
 } cvstDSGBMStruct_T;


#endif /*typedef_cvstDSGBMStruct_T: used by matlab coder*/

 EXTERN_C LIBMWCVSTRT_API void disparitySGBM_compute(
	const uint8_T* inImg1, const uint8_T* inImg2, int nRows, int nCols, 
	real32_T* dis,
	cvstDSGBMStruct_T *params);

 EXTERN_C LIBMWCVSTRT_API void disparitySGBM_computeRM(
	 const uint8_T* inImg1, const uint8_T* inImg2, int nRows, int nCols,
	 real32_T* dis,
	 cvstDSGBMStruct_T *params);

#endif
