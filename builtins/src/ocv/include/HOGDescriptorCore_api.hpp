/* Copyright 2012 The MathWorks, Inc. */

#ifndef _HOGDESCRIPTOR_
#define _HOGDESCRIPTOR_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_detectMultiScale(void *ptrClass, void **ptr2ptrDetectedObj, void **ptr2ptrDetectionScores,
	uint8_T *inImg, int32_T nRows, int32_T nCols, boolean_T isRGB, 
	double scaleFactor, double svmThreshold, double mergeThreshold,	
	int32_T *ptrMinSize, int32_T *ptrMaxSize, int32_T *ptrWinStride,
	boolean_T useMeanShiftMerging,
	int32_T *numDetectedObj, int32_T *numDetectionScores);

EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_detectMultiScaleRM(void *ptrClass, void **ptr2ptrDetectedObj, void **ptr2ptrDetectionScores,
	uint8_T *inImg, int32_T nRows, int32_T nCols, boolean_T isRGB,
	double scaleFactor, double svmThreshold, double mergeThreshold,
	int32_T *ptrMinSize, int32_T *ptrMaxSize, int32_T *ptrWinStride,
	boolean_T useMeanShiftMerging,
	int32_T *numDetectedObj, int32_T *numDetectionScores);

EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_setup(void *ptrClass, int whichModel);
EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_construct(void **ptr2ptrClass);
EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_assignOutputDeleteVectors(void *ptrDetectedObj, void *ptrDetectionScores, int32_T *outBBox, double *outScore);
EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_assignOutputDeleteVectorsRM(void *ptrDetectedObj, void *ptrDetectionScores, int32_T *outBBox, double *outScore);
EXTERN_C LIBMWCVSTRT_API void HOGDescriptor_deleteObj(void *ptrClass);

#endif
