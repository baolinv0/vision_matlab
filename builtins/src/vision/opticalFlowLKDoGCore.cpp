///////////////////////////////////////////////////////////////////////////
//
//  APIs for optical flow computation using Lucas-Kanade
//  (derivative of Gaussian) algorithm
//
///////////////////////////////////////////////////////////////////////////    

#include "opticalFlowLKDoGCore_api.hpp"
#include "opticalFlowLKDoG.hpp"
#include <stdlib.h>     // for malloc

void MWCV_OpticalFlow_LKDoG_double( const real_T  *inImgA, 
                                    const real_T  *delayBuffer, 
                                    const uint32_T *allIdx,
                                    const int_T  numFramesInBuffer, // does not include current frame 
                                            real_T  *outVelC, /* output velocity - component along column */
                                            real_T  *outVelR, /* output velocity - component along row */
                                            real_T  *dx, /* xx => gradCC */
                                            real_T  *dy, /* yy => gradRC */
                                            real_T  *dt, /* xy => gradRR */
                                            real_T  *xt, /* gradCT */
                                            real_T  *yt, /* gradRT */
                                            const real_T *eigTh,
                                            const real_T *tGradKernel,
                                            const real_T *sGradKernel,
                                            const real_T *tKernel,
                                            const real_T *sKernel,
                                            const real_T *wKernel,
                                            int_T   inRows,
                                            int_T   inCols,
                                            int_T tGradKernelLen,
                                            int_T sGradKernelLen,
                                            int_T tKernelLen,
                                            int_T sKernelLen,
                                            int_T wKernelLen,
                                            boolean_T includeNormalFlow)
{
 // address buffer contains current and previous frame addresses
 const real_T **portAddressBuffer = (const real_T **)malloc((numFramesInBuffer+1)*sizeof(real_T *));

 MWCV_populateAddressBuffer<real_T>(inImgA,
                                             delayBuffer,
                                             allIdx,
                                             portAddressBuffer,
                                             numFramesInBuffer,
                                             inRows,
                                             inCols);

 MWCV_OpticalFlow_LKDoG_DTypes<real_T, real_T>(portAddressBuffer,   
                                            outVelC,
                                            outVelR,
                                            dx,
                                            dy,
                                            dt,
                                            xt,
                                            yt,
                                            eigTh,
                                            tGradKernel,
                                            sGradKernel,
                                            tKernel,
                                            sKernel,
                                            wKernel,
                                            inRows,
                                            inCols,
                                            tGradKernelLen,
                                            sGradKernelLen,
                                            tKernelLen,
                                            sKernelLen,
                                            wKernelLen,
                                            includeNormalFlow);
free(portAddressBuffer);
}

void MWCV_OpticalFlow_LKDoG_single( const real32_T  *inImgA, 
                                    const real32_T  *delayBuffer, 
                                    const uint32_T *allIdx,
                                    const int_T  numFramesInBuffer, // does not include current frame 
                                            real32_T  *outVelC, /* output velocity - component along column */
                                            real32_T  *outVelR, /* output velocity - component along row */
                                            real32_T  *dx, /* xx => gradCC */
                                            real32_T  *dy, /* yy => gradRC */
                                            real32_T  *dt, /* xy => gradRR */
                                            real32_T  *xt, /* gradCT */
                                            real32_T  *yt, /* gradRT */
                                            const real32_T *eigTh,
                                            const real32_T *tGradKernel,
                                            const real32_T *sGradKernel,
                                            const real32_T *tKernel,
                                            const real32_T *sKernel,
                                            const real32_T *wKernel,
                                            int_T   inRows,
                                            int_T   inCols,
                                            int_T tGradKernelLen,
                                            int_T sGradKernelLen,
                                            int_T tKernelLen,
                                            int_T sKernelLen,
                                            int_T wKernelLen,
                                            boolean_T includeNormalFlow)
{
 // address buffer contains current and previous frame addresses
 const real32_T **portAddressBuffer = (const real32_T **)malloc((numFramesInBuffer+1)*sizeof(real32_T *));

 MWCV_populateAddressBuffer<real32_T>(inImgA,
                                             delayBuffer,
                                             allIdx,
                                             portAddressBuffer,
                                             numFramesInBuffer,
                                             inRows,
                                             inCols);
 MWCV_OpticalFlow_LKDoG_DTypes<real32_T, real32_T>(portAddressBuffer,   
                                            outVelC,
                                            outVelR,
                                            dx,
                                            dy,
                                            dt,
                                            xt,
                                            yt,
                                            eigTh,
                                            tGradKernel,
                                            sGradKernel,
                                            tKernel,
                                            sKernel,
                                            wKernel,
                                            inRows,
                                            inCols,
                                            tGradKernelLen,
                                            sGradKernelLen,
                                            tKernelLen,
                                            sKernelLen,
                                            wKernelLen,
                                            includeNormalFlow);
free(portAddressBuffer);
}

void MWCV_OpticalFlow_LKDoG_uint8( const uint8_T  *inImgA, 
                                    const uint8_T  *delayBuffer, 
                                    const uint32_T *allIdx,
                                    const int_T  numFramesInBuffer, // does not include current frame 
                                            real32_T  *outVelC, /* output velocity - component along column */
                                            real32_T  *outVelR, /* output velocity - component along row */
                                            real32_T  *dx, /* xx => gradCC */
                                            real32_T  *dy, /* yy => gradRC */
                                            real32_T  *dt, /* xy => gradRR */
                                            real32_T  *xt, /* gradCT */
                                            real32_T  *yt, /* gradRT */
                                            const real32_T *eigTh,
                                            const real32_T *tGradKernel,
                                            const real32_T *sGradKernel,
                                            const real32_T *tKernel,
                                            const real32_T *sKernel,
                                            const real32_T *wKernel,
                                            int_T   inRows,
                                            int_T   inCols,
                                            int_T tGradKernelLen,
                                            int_T sGradKernelLen,
                                            int_T tKernelLen,
                                            int_T sKernelLen,
                                            int_T wKernelLen,
                                            boolean_T includeNormalFlow)
{
 // address buffer contains current and previous frame addresses
 const uint8_T **portAddressBuffer = (const uint8_T **)malloc((numFramesInBuffer+1)*sizeof(uint8_T *));

 MWCV_populateAddressBuffer<uint8_T>(inImgA,
                                             delayBuffer,
                                             allIdx,
                                             portAddressBuffer,
                                             numFramesInBuffer,
                                             inRows,
                                             inCols);

 MWCV_OpticalFlow_LKDoG_DTypes<uint8_T, real32_T>(portAddressBuffer,   
                                            outVelC,
                                            outVelR,
                                            dx,
                                            dy,
                                            dt,
                                            xt,
                                            yt,
                                            eigTh,
                                            tGradKernel,
                                            sGradKernel,
                                            tKernel,
                                            sKernel,
                                            wKernel,
                                            inRows,
                                            inCols,
                                            tGradKernelLen,
                                            sGradKernelLen,
                                            tKernelLen,
                                            sKernelLen,
                                            wKernelLen,
                                            includeNormalFlow);
free(portAddressBuffer);
}
