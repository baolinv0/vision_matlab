/*
*  vipopticalflow_rt.h
*
*  Copyright 1995-2014 The MathWorks, Inc.
*/

#ifndef vipopticalflow_rt_h
#define vipopticalflow_rt_h

#ifdef MATLAB_MEX_FILE
#include "tmwtypes.h"
#else
#include "rtwtypes.h"
#endif

#include <float.h>
#include <string.h>
#include <math.h>
#include "libmwvisionrt_util.h"

#ifndef fabsf
  #define fabsf(X)      (float)( fabs( (double)(X)) )
#endif

#ifndef sqrtf
  #define sqrtf(X)     (float)( sqrt( (double)(X)) )
  #endif

#ifndef MAX
  #define MAX(a,b) ((a)>(b) ? (a) : (b))
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
* MWVIP_OpticalFlow_<Method>_<DataType> 
* 
*    1) MWVIP_ is a prefix used with all Mathworks VIP runtime library 
*       functions. 
*    2) The second field indicates that this function is implementing the 
*       Optical Flow estimation algorithm
*    3) The third field indicates the method used in Optical Flow estimation 
*    4) The last field enumerates the data type of the output ports
* 
*    Examples: 
*       MWVIP_OpticalFlow_HS_D is the Optical Flow estimation function 
*       for double precision outputs and it uses Horn & Schunck method. 
*/ 

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif

#define DIV_BY_EIGHT_DBL  0.125
#define DIV_BY_EIGHT_SGL  0.125F
#define MIN_INPUT_COLS	  5	/* We reuse output buffer to compute 5 parameters:
WGradRR, WGradCC, WGradRC, WGradRT, WGradCT */

#define GETAPLUS2BPLUSC( A, B, C)  ( (A) +  (B) + (B)  + (C)  ) 

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_HS_D(  const real_T  *inImgA,
        const real_T  *inImgB,
        real_T *outVel, 
        real_T *velR, 
        real_T  *memC0,
        real_T  *memC1,
        real_T  *memR0,
        real_T  *memR1,
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        real_T  *alpha,
        real_T  *velBufC0,
        real_T  *velBufC1,
        real_T  *velBufR0,
        real_T  *velBufR1,
        const real_T  *lambda, 
        boolean_T useMaxIter,
        boolean_T useAbsVelDiff,
        const int32_T *maxIter,
        const real_T  *maxAllowableAbsDiffVel,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_HS_R(  const real32_T  *inImgA,
        const real32_T  *inImgB,
        real32_T *outVel, 
        real32_T *velR,
        real32_T  *memC0,
        real32_T  *memC1,
        real32_T  *memR0,
        real32_T  *memR1,
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        real32_T  *alpha,
        real32_T  *velBufC0,
        real32_T  *velBufC1,
        real32_T  *velBufR0,
        real32_T  *velBufR1,
        const real32_T  *lambda, 
        boolean_T useMaxIter,
        boolean_T useAbsVelDiff,
        const int32_T *maxIter,
        const real32_T  *maxAllowableAbsDiffVel,  
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_HS_Z(  const real_T  *inImgA,
        const real_T  *inImgB,
        creal_T *outVel, 
        real_T  *memC0,
        real_T  *memC1,
        real_T  *memR0,
        real_T  *memR1,
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        real_T  *alpha,
        real_T  *velBufC0,
        real_T  *velBufC1,
        real_T  *velBufR0,
        real_T  *velBufR1,
        const real_T  *lambda, 
        boolean_T useMaxIter,
        boolean_T useAbsVelDiff,
        const int32_T *maxIter,
        const real_T  *maxAllowableAbsDiffVel,    
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_HS_C(  const real32_T  *inImgA,
        const real32_T  *inImgB,
        creal32_T *outVel, 
        real32_T  *memC0,
        real32_T  *memC1,
        real32_T  *memR0,
        real32_T  *memR1,
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        real32_T  *alpha,
        real32_T  *velBufC0,
        real32_T  *velBufC1,
        real32_T  *velBufR0,
        real32_T  *velBufR1,
        const real32_T  *lambda, 
        boolean_T useMaxIter,
        boolean_T useAbsVelDiff,
        const int32_T *maxIter,
        const real32_T  *maxAllowableAbsDiffVel,  
        int_T  inRows,
        int_T  inCols);


    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_D(  const real_T  *inImgA,
        const real_T  *inImgB,
        real_T *outVel, 
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        const real_T  *eigTh,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_R(  const real32_T  *inImgA,
        const real32_T  *inImgB,
        real32_T *outVel, 
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        const real32_T  *eigTh,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_Z(  const real_T  *inImgA,
        const real_T  *inImgB,
        creal_T *outVel, 
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        const real_T  *eigTh,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_C(  const real32_T  *inImgA,
        const real32_T  *inImgB,
        creal32_T *outVel, 
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        const real32_T  *eigTh,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_GDER_D(void * const  *inPortAddr,
        real_T  *outVel, 
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        const real_T  *eigTh,
        const real_T  *tGradKernel,
        const real_T  *sGradKernel,
        const real_T  *tKernel,
        const real_T  *sKernel,
        const real_T  *wKernel,
        int_T  inRows,
        int_T  inCols,
        int_T  tGradKernelLen,
        int_T  sGradKernelLen,
        int_T  tKernelLen,
        int_T  sKernelLen,
        int_T  wKernelLen,
        boolean_T includeNormalFlow);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_GDER_R(void * const  *inPortAddr,
        real32_T  *outVel, 
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        const real32_T  *eigTh,
        const real32_T  *tGradKernel,
        const real32_T  *sGradKernel,
        const real32_T  *tKernel,
        const real32_T  *sKernel,
        const real32_T  *wKernel,
        int_T  inRows,
        int_T  inCols,
        int_T  tGradKernelLen,
        int_T  sGradKernelLen,
        int_T  tKernelLen,
        int_T  sKernelLen,
        int_T  wKernelLen,
        boolean_T includeNormalFlow);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_GDER_Z(void * const  *inPortAddr,
        creal_T  *outVel, 
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        const real_T  *eigTh,
        const real_T  *tGradKernel,
        const real_T  *sGradKernel,
        const real_T  *tKernel,
        const real_T  *sKernel,
        const real_T  *wKernel,
        int_T  inRows,
        int_T  inCols,
        int_T  tGradKernelLen,
        int_T  sGradKernelLen,
        int_T  tKernelLen,
        int_T  sKernelLen,
        int_T  wKernelLen,
        boolean_T includeNormalFlow);

    LIBMWVISIONRT_API void MWVIP_OpticalFlow_LK_GDER_C(void * const  *inPortAddr,
        creal32_T  *outVel, 
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        const real32_T  *eigTh,
        const real32_T  *tGradKernel,
        const real32_T  *sGradKernel,
        const real32_T  *tKernel,
        const real32_T  *sKernel,
        const real32_T  *wKernel,
        int_T  inRows,
        int_T  inCols,
        int_T  tGradKernelLen,
        int_T  sGradKernelLen,
        int_T  tKernelLen,
        int_T  sKernelLen,
        int_T  wKernelLen,
        boolean_T includeNormalFlow);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvX_D(const real_T *in, 
        real_T *out, 
        const real_T *kernel, 
        int_T inRows, 
        int_T inCols, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvX_R(const real32_T *in, 
        real32_T *out, 
        const real32_T *kernel, 
        int_T inRows, 
        int_T inCols, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvY_D(const real_T *in, 
        real_T *out, 
        const real_T *kernel, 
        int_T inRows, 
        int_T inCols, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvY_R(const real32_T *in, 
        real32_T *out, 
        const real32_T *kernel, 
        int_T inRows, 
        int_T inCols, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvT_D(real_T * const *inPortAddr, 
        real_T *out, 
        const real_T *kernel, 
        int_T inWidth, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_OFLK_ConvT_R(real32_T * const *inPortAddr, 
        real32_T *out, 
        const real32_T *kernel, 
        int_T inWidth, 
        int_T kernelLen);

    LIBMWVISIONRT_API void MWVIP_SobelDerivative_HS_D( const real_T  *inImgA,
        const real_T  *inImgB,
        real_T  *tmpGradC,
        real_T  *tmpGradR,
        real_T  *memC0,
        real_T  *memC1,
        real_T  *memR0,
        real_T  *memR1,
        real_T  *gradCC,
        real_T  *gradRC,
        real_T  *gradRR,
        real_T  *gradCT,
        real_T  *gradRT,
        real_T  *alpha,
        const real_T  *lambda,
        int_T  inRows,
        int_T  inCols);

    LIBMWVISIONRT_API void MWVIP_SobelDerivative_HS_R( const real32_T  *inImgA,
        const real32_T  *inImgB,
        real32_T  *tmpGradC,
        real32_T  *tmpGradR,
        real32_T  *memC0,
        real32_T  *memC1,
        real32_T  *memR0,
        real32_T  *memR1,
        real32_T  *gradCC,
        real32_T  *gradRC,
        real32_T  *gradRR,
        real32_T  *gradCT,
        real32_T  *gradRT,
        real32_T  *alpha,
        const real32_T  *lambda,
        int_T  inRows,
        int_T  inCols);


#define inRange(i,j,halfKernelLen,inRows,inCols) \
    ((i>=halfKernelLen) && (i<inRows-halfKernelLen) && \
     (j>=halfKernelLen) && (j<inCols-halfKernelLen))

/*
 * in and out not in-place  
 * Convolving with kernel and kernel' 
 */

#define convolveXY1D_D(in, out, kernel, inRows, inCols, kernelLen) \
    MWVIP_OFLK_ConvX_D((const real_T *)in, out, kernel, inRows, inCols, kernelLen); \
    MWVIP_OFLK_ConvY_D((const real_T *)out, in, kernel, inRows, inCols, kernelLen);

#define convolveXY1D_R(in, out, kernel, inRows, inCols, kernelLen) \
    MWVIP_OFLK_ConvX_R((const real32_T *)in, out, kernel, inRows, inCols, kernelLen); \
    MWVIP_OFLK_ConvY_R((const real32_T *)out, in, kernel, inRows, inCols, kernelLen);

#define THRESH_ABS_DELTA_GDER (0.00000001/255)  


#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#endif /* vipopticalflow_rt_h */

/* [EOF] vipopticalflow_rt.h */
