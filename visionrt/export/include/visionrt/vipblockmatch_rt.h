/*
 *  vipblockmatch_rt.h
 *
 *  Copyright 1995-2014 The MathWorks, Inc.
 */

#ifndef vipblockmatch_rt_h
#define vipblockmatch_rt_h

#ifdef MATLAB_MEX_FILE
#include "tmwtypes.h"
#else
#include "rtwtypes.h"
#endif
#include <float.h>
#include <string.h>
#include <math.h>
#include "libmwvisionrt_util.h"

#ifndef MAX
  #define MAX(a,b) ((a)>(b) ? (a) : (b))
#endif

#ifndef MIN
  #define MIN(a,b) ((a)<(b) ? (a) : (b))
#endif

#ifndef MAX_real_T
  #define MAX_real_T   DBL_MAX
#endif
#ifndef MAX_real32_T
  #define MAX_real32_T FLT_MAX
#endif

#ifndef fabsf
  #define fabsf(X)      (float)( fabs( (double)(X)) )
#endif

/* 
 * Function naming glossary 
 * --------------------------- 
 * 
 * MWVIP = MathWorks VIP Blockset 
 * 
 * Data types - (describe inputs to functions, not outputs) 
 * R = real single-precision 
 * D = real double-precision 
 */ 
 
/* Function naming convention 
 * -------------------------- 
 * 
 * MWVIP_BlockMatching_<SearchMethod>_<MatchingCriteria>_<DataType> 
 * 
 *    1) MWVIP_ is a prefix used with all Mathworks DSP runtime library 
 *       functions. 
 *    2) The second field indicates that this function is implementing the 
 *       Block Matching algorithm
 *    3) The third field indicates the searching method (exhaustive, 3-step etc)
 *    4) The fourth field indicates the matching criteria (MSE, MAD etc)
 *    4) The last field enumerates the data type of the output ports
 * 
 *    Examples: 
 *       MWVIP_BlockMatching_Full_MSE_D is the Block Matching function 
 *       for double precision inputs and it uses full (i.e. exhaustive) 
 *       search method and MSE as searching criteria
 */ 

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif
/* double */
LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MSE_D(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                real_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);


LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MAD_D(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                real_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MSE_D(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                real_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MAD_D(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                real_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

/* single */
LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MSE_R(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                real32_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);


LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MAD_R(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                real32_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MSE_R(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                real32_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MAD_R(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                real32_T *yMVsqmag,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

/* double complex output */
LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MSE_Z(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                creal_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);


LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MAD_Z(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                creal_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MSE_Z(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                creal_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MAD_Z(
                                const real_T *uImgCurr,
                                const real_T *uImgPrev,
                                real_T *paddedImgC,
                                real_T *paddedImgP,
                                creal_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

/* single complex output */
LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MSE_C(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                creal32_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);


LIBMWVISIONRT_API void MWVIP_BlockMatching_Full_MAD_C(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                creal32_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MSE_C(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                creal32_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);

LIBMWVISIONRT_API void MWVIP_BlockMatching_3Step_MAD_C(
                                const real32_T *uImgCurr,
                                const real32_T *uImgPrev,
                                real32_T *paddedImgC,
                                real32_T *paddedImgP,
                                creal32_T *yMVcplx,
                                int32_T *blockSize,
                                int32_T *overlapSize,
                                int32_T *maxDisplSize,
                                const int_T inRows,
                                const int_T inCols,
                                const int_T rowsPadImgC,
                                const int_T colsPadImgC,
                                const int_T rowsPadImgP,
                                const int_T colsPadImgP);


LIBMWVISIONRT_API void MWVIP_SearchMethod_Full_MSE_D(const real_T *blkCS, const real_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_Full_MAD_D(const real_T *blkCS, const real_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_3Step_MSE_D(const real_T *blkCS, const real_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_3Step_MAD_D(const real_T *blkCS, const real_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_Full_MSE_R(const real32_T *blkCS, const real32_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_Full_MAD_R(const real32_T *blkCS, const real32_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_3Step_MSE_R(const real32_T *blkCS, const real32_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

LIBMWVISIONRT_API void MWVIP_SearchMethod_3Step_MAD_R(const real32_T *blkCS, const real32_T *blkPB,
                                             int_T rowsImgCS,   int_T rowsImgPB,  
                                             int_T blkCSWidthX, int_T blkCSHeightY,  
                                             int_T blkPBWidthX, int_T blkPBHeightY,  
                                             int_T *xIdx,         int_T *yIdx);

#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipblockmatch_rt_h */

/* [EOF] vipblockmatch_rt.h */
