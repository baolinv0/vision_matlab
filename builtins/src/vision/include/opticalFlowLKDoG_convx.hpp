/*
*  Function for Optical Flow
*  (Lucas & Kanade method - Gaussian derivative).
*  Spacial Convolution
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#ifndef OPTICALFLOWLKDOG_CONVX_H
#define OPTICALFLOWLKDOG_CONVX_H

template <typename ImT, typename T>
void MWCV_OFLK_ConvX_T(const ImT *in, 
                                   T *out, 
                                   const T *kernel, 
                                   int_T inRows, 
                                   int_T inCols, 
                                   int_T kernelLen)
{
    int_T i, j, k;
    int_T halfKernelLen = kernelLen>>1;/* kernelLen/2 */
    int_T offset = halfKernelLen*inRows;
    for (i = 0; i < inRows; i++)
    {
        for (j = 0; j < inCols; j++)
        {
            int_T outIdx = j*inRows+i;
            out[outIdx] = 0;
            if inRange(i,j,halfKernelLen,inRows,inCols)
            {
                int_T inIdx;
                for (k = 0, inIdx = outIdx-offset; k < kernelLen; k++, inIdx += inRows)
                    out[outIdx] += (T)(in[inIdx])*kernel[k]; 
            }
        }
    }
}

#endif
/* [EOF] oflk_convx_d_rt.c */
