/*
*  Function for Optical Flow
*  (Lucas & Kanade method - Gaussian derivative).
*  Temporal Convolution
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#ifndef OPTICALFLOWLKDOG_CONVT_H
#define OPTICALFLOWLKDOG_CONVT_H

template <typename ImT, typename T>
void MWCV_OFLK_ConvT_T(const ImT **inPortAddr, 
                                   T *out, 
                                   const T *kernel, 
                                   int_T inWidth, 
                                   int_T kernelLen)
{
    int_T i, k, prtIdx; 
    int_T highestPrtIdx = kernelLen-1;

    boolean_T usingUint8 = (sizeof(ImT) != sizeof(T));
    T ONE_BY_RANGE  = usingUint8 ?  (T)(1.0/255.0) : (T)(1.0);

    for (i=0; i<inWidth; i++)
    {
        T tmpVal = 0.0;

        for (k=0, prtIdx=highestPrtIdx; k<kernelLen; k++, prtIdx--)
        {
            tmpVal += (T)(inPortAddr[prtIdx][i])*kernel[k]*ONE_BY_RANGE;
        }
        out[i] = tmpVal;
    }
}

#endif 
