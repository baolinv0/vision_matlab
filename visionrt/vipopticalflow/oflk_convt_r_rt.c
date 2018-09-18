/*
*  OFLK_CONVT_R_RT runtime function for Optical Flow Block
*  (Lucas & Kanade method - Gaussian derivative).
*  Temporal Convolution
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipopticalflow_rt.h" 

LIBMWVISIONRT_API void MWVIP_OFLK_ConvT_R(real32_T  * const *inPortAddr,
                                   real32_T *out, 
                                   const real32_T *kernel, 
                                   int_T inWidth, 
                                   int_T kernelLen)
{
    int_T i, k, prtIdx; 
    int_T highestPrtIdx = kernelLen-1;
    for (i=0; i<inWidth; i++)
    {
        real32_T tmpVal = 0.0;

        for (k=0, prtIdx=highestPrtIdx; k<kernelLen; k++, prtIdx--)
        {
            tmpVal += inPortAddr[prtIdx][i]*kernel[k];
        }
        out[i] = tmpVal;
    }
}

/* [EOF] oflk_convt_r_rt.c */
