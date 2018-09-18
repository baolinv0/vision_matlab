/* Copyright 2012 The MathWorks, Inc. */

#ifndef _EXTRACTBRISK_
#define _EXTRACTBRISK_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API
int32_T extractBRISK_compute(const uint8_T * img, const int32_T nRows, const int32_T nCols,
                             real32_T * location, real32_T * metric,
                             real32_T * scale, real32_T * orientation,
                             int32_T * misc, const int32_T numKeyPoints, const boolean_T upright,
                             void ** features, void ** keypoints);

EXTERN_C LIBMWCVSTRT_API
int32_T extractBRISK_computeRM(const uint8_T * img, const int32_T nRows, const int32_T nCols,
                             real32_T * location, real32_T * metric,
                             real32_T * scale, real32_T * orientation,
                             int32_T * misc, const int32_T numKeyPoints, const boolean_T upright,
                             void ** features, void ** keypoints);

EXTERN_C LIBMWCVSTRT_API
void extractBRISK_assignOutput(void *ptrDescriptors, void *ptrKeyPoints,
                               real32_T * location, real32_T * metric,
                               real32_T * scale, real32_T * orientation,
                               int32_T * misc, uint8_T * features);

EXTERN_C LIBMWCVSTRT_API
void extractBRISK_assignOutputRM(void *ptrDescriptors, void *ptrKeyPoints,
                               real32_T * location, real32_T * metric,
                               real32_T * scale, real32_T * orientation,
                               int32_T * misc, uint8_T * features);
#endif
