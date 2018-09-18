/* Copyright 2012 The MathWorks, Inc. */

#ifndef _MATCHFEATURES_
#define _MATCHFEATURES_

#include "vision_defines.h"

EXTERN_C LIBMWCVSTRT_API
void findApproximateNearestNeighbors_real32(const real32_T * features1, 
        const real32_T * features2, const char * metric, 
        const int32_T numFeatures1, const int32_T numFeatures2,
        const int32_T numelInFeatureVec, const int32_T knn, 
        int32_T * indexPairs, real32_T * dist);

EXTERN_C LIBMWCVSTRT_API
void findApproximateNearestNeighbors_uint8(const uint8_T * features1, 
        const uint8_T * features2, const char * metric, 
        const int32_T numFeatures1, const int32_T numFeatures2, 
        const int32_T numelInFeatureVec, const int32_T knn, 
        int32_T * indexPairs, int32_T * dist);


#endif
