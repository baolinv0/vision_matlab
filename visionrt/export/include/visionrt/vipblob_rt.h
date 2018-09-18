/*
 *  vipblob_rt.h
 *
 *  Copyright 1995-2004 The MathWorks, Inc.
 */

#ifndef vipblob_rt_h
#define vipblob_rt_h

#include "dsp_rt.h"
#include "libmwvisionrt_util.h"

/* 
 * Function naming glossary 
 * --------------------------- 
 * 
 * MWVIP = MathWorks VIP Blockset 
 * 
 * R = real single-precision 
 * D = real double-precision 
 */ 
 
/* Function naming convention 
 * -------------------------- 
 * 
 * MWVIP_Blob_Fcn_<DataType> 
 * 
 *    1) MWVIP_ is a prefix used with all Mathworks DSP runtime library 
 *       functions. 
 *    2) The second field indicates that this function is implementing
 *       blob analysis function.
 *    3) The third field indicates which blob feature is computed.
 *    4) The last field enumerates the data type from the above list. 
 *       Single/double precision are specified within a single letter. 
 *       The data types of the input and output are the same. 
 * 
 *    Examples: 
 *       MWVIP_Blob_Area_D is the function which computes areas of blobs
 *       for double precision inputs. 
 */ 

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif

LIBMWVISIONRT_API void MWVIP_Blob_Ellipse_D(
    const int16_T    *pixListN,
    const int16_T    *pixListM,
    const real_T      c0,           /*centroid */
    const real_T      c1,           /*centroid */
    const int32_T     a,            /*area */
    real_T            *majoraxisptr,
    real_T            *minoraxisptr,
    real_T            *eccentricityptr,
    real_T            *orientationptr  );
    
LIBMWVISIONRT_API void MWVIP_Blob_Ellipse_R(
    const int16_T     *pixListN,
    const int16_T     *pixListM,
    const real32_T     c0,           /*centroid */
    const real32_T     c1,           /*centroid */
    const int32_T      a,            /*area */
    real32_T          *majoraxisptr,
    real32_T          *minoraxisptr,
    real32_T          *eccentricityptr,
    real32_T          *orientationptr  );


#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipblob_rt_h */

/* [EOF] vipblob_rt.h */
