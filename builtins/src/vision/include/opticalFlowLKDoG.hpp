/* 
 * This file contains the optical flow Lucas-Kanade (derivative of Gaussian) algorithm
 *
 *  Copyright 1995-2014 The MathWorks, Inc.
 */

#ifndef _OPTICALFLOWLKDOG_H_
#define _OPTICALFLOWLKDOG_H_

#include <string.h>
#include <math.h>

#define inRange(i,j,halfKernelLen,inRows,inCols) \
    ((i>=halfKernelLen) && (i<inRows-halfKernelLen) && \
     (j>=halfKernelLen) && (j<inCols-halfKernelLen))

#include "opticalFlowLKDoG_convt.hpp"
#include "opticalFlowLKDoG_convx.hpp"
#include "opticalFlowLKDoG_convy.hpp"

/*
* ordering for INPORT Index and for TEMPORAL FILTERING
*   
*  INPORT index: 
* -------------
*                                                                _____________
*  (Latest Frame ->) --------------------------------------------|InportIdx=0
*                       |--DELAY---------------------------------|InportIdx=1
*                                 |--DELAY-----------------------|InportIdx=2
*                                           |--DELAY-------------|InportIdx=3
*                                  (Oldest Frame -->) |--DELAY---|InportIdx=4
*                                                                -------------
* 
*  TEMPORAL FILTERING:
*  -------------------
* 
*  For temporal filtering each frame is reshaped to a column vector.
*  The i-th element (0<=i<frameWidth) of each column are filtered 
*    with temporal filter
* 
*             Old                     Latest
* InportIdx=>  4     3     2     1     0
*              |     |     |     |     |   
*              |     |     |     |     |   
*              |     |     |     |     |   
*              |     |     |     |     |   
*              |     |     |     |     |   
* 
*   so, the signal with Highest InportIdx is multiplied with the 
*      first filter coeff 
* 
*   Note: InportIdx=2 contains "current" signal, 
*                     We are computing Optical Flow for this frame
*         InportIdx=(3&4) are "previous" frames
*         InportIdx=(1&0) are "look-ahead" frames
* 
*/

/* 
* CGIR code calls the following function with (pointer_T * => void **) 
* as the first argument type.
* Since, we can't cast it explicitly to (const real_T **) in codegen, 
* we are changing the first argument type to (void **) in this function
*/

#define convolveXY1D_T(in, out, kernel, inRows, inCols, kernelLen) \
    MWCV_OFLK_ConvX_T<T>((const T *)in, out, kernel, inRows, inCols, kernelLen); \
    MWCV_OFLK_ConvY_T<T>((const T *)out, in, kernel, inRows, inCols, kernelLen);

#define THRESH_ABS_DELTA_GDER (0.00000001/255) 

template <typename ImT> 
void MWCV_populateAddressBuffer(const ImT  *inImgA, 
                                    const ImT  *delayBuffer, 
                                    const uint32_T *allIdx,
                                    const ImT **portAddressBuffer, // same as portAddressBuffer
                                    const int_T  numFramesInBuffer,
                                    int_T   inRows,
                                    int_T   inCols)
{
    int i, k = 0;
    int_T frameWidth = inRows*inCols;
    //int_T numFramesInBuffer =  (int_T)mxGetN(prhs[1])/inCols; 

    portAddressBuffer[k++] = inImgA;
    for (i=0; i<numFramesInBuffer;i++)
        portAddressBuffer[k++] = &delayBuffer[(allIdx[i]-1)*frameWidth];//allIdx[ii] is 1 based;
}

template <typename ImT, typename T> 
void MWCV_OpticalFlow_LKDoG_DTypes( const ImT **portAddressBuffer,   
                                            T  *outVelC, // output velocity - component along column
                                            T  *outVelR, // output velocity - component along row
                                            T  *dx, /* xx => gradCC */
                                            T  *dy, /* yy => gradRC */
                                            T  *dt, /* xy => gradRR */
                                            T  *xt, /* gradCT */
                                            T  *yt, /* gradRT */
                                            const T *eigTh,
                                            const T *tGradKernel,
                                            const T *sGradKernel,
                                            const T *tKernel,
                                            const T *sKernel,
                                            const T *wKernel,
                                            int_T   inRows,
                                            int_T   inCols,
                                            int_T tGradKernelLen,
                                            int_T sGradKernelLen,
                                            int_T tKernelLen,
                                            int_T sKernelLen,
                                            int_T wKernelLen,
                                            boolean_T includeNormalFlow)
{
    T threshEigen = eigTh[0]; 
    int_T i, j, idx;
    int_T numInFrames;
    const int_T inWidth = inRows*inCols;
    int_T startPortIdx_tKer=0;
    int_T startPortIdx_tGker=0;
    int_T halfwKernelLen = wKernelLen >>1; 
    T *tempBuf = (T *)outVelC;
    T *xx;
    T *yy;
    T *xy;
    T tmp_dx, tmp_dy, tmp_dt;
    T velRe, velIm;

    if (tGradKernelLen > tKernelLen)
    {
        startPortIdx_tKer = (tGradKernelLen - tKernelLen)>>1;/* divide by 2 */
        numInFrames = tGradKernelLen;
    }
    else
    {
        startPortIdx_tGker = (tKernelLen - tGradKernelLen)>>1; 
        numInFrames = tKernelLen;
    } 

    /* Temporal convolution */
    /* dx = convolvet(im, tKernel); */
    MWCV_OFLK_ConvT_T<ImT, T>((const ImT **)&portAddressBuffer[startPortIdx_tKer], 
                       dx, tKernel, inWidth, tKernelLen);
    /* dy = dx; */
    memcpy(dy, dx, inWidth*sizeof(T));
    /* dt = convolvet(im, tGradKernel); */
    MWCV_OFLK_ConvT_T<ImT, T>((const ImT **)&portAddressBuffer[startPortIdx_tGker], 
                       dt, tGradKernel, inWidth, tGradKernelLen);

    /* Spatial convolution */
    /* tempBuf = convolvex(dx, sGradKernel); */
    MWCV_OFLK_ConvX_T<T>(dx, tempBuf, sGradKernel, inRows, inCols, sGradKernelLen);
    /* dx = convolvey(tempBuf, sKernel'); */
    MWCV_OFLK_ConvY_T<T>(tempBuf, dx, sKernel, inRows, inCols, sKernelLen);

    /* tempBuf = convolvex(dy, sKernel); */
    MWCV_OFLK_ConvX_T<T>(dy, tempBuf, sKernel, inRows, inCols, sKernelLen);
    /* dy = convolvey(tempBuf, sGradKernel'); */
    MWCV_OFLK_ConvY_T<T>(tempBuf, dy, sGradKernel, inRows, inCols, sGradKernelLen);

    /* tempBuf = convolvex(dt, sKernel); */
    MWCV_OFLK_ConvX_T<T>(dt, tempBuf, sKernel, inRows, inCols, sKernelLen);
    /* dt = convolvey(tempBuf, sKernel'); */
    MWCV_OFLK_ConvY_T<T>(tempBuf, dt, sKernel, inRows, inCols, sKernelLen);

    /* xx = dx.*dx; */
    /* yy = dy.*dy; */
    /* xy = dx.*dy; */
    /* xt = dx.*dt; */
    /* yt = dy.*dt; */
    xx = dx;
    yy = dy;
    xy = dt; /* xt, yt new buffers */
    for (i = 0; i < inRows*inCols; i++)
    {
        tmp_dx = dx[i];
        tmp_dy = dy[i];
        tmp_dt = dt[i];

        xx[i] = tmp_dx * tmp_dx;
        yy[i] = tmp_dy * tmp_dy;
        xy[i] = tmp_dx * tmp_dy;
        xt[i] = tmp_dx * tmp_dt;
        yt[i] = tmp_dy * tmp_dt;
    }
    /* xx = convolvexy1D(xx, G);% convolving with G and G' */
    convolveXY1D_T(xx, tempBuf, wKernel, inRows, inCols, wKernelLen);/* output in xx; */
    /* yy = convolvexy1D(yy, G);% convolving with G and G' */
    convolveXY1D_T(yy, tempBuf, wKernel, inRows, inCols, wKernelLen);/* output in yy; */
    /* xy = convolvexy1D(xy, G);% convolving with G and G' */
    convolveXY1D_T(xy, tempBuf, wKernel, inRows, inCols, wKernelLen);/* output in xy; */
    /* xt = convolvexy1D(xt, G);% convolving with G and G' */
    convolveXY1D_T(xt, tempBuf, wKernel, inRows, inCols, wKernelLen);/* output in xt; */
    /* yt = convolvexy1D(yt, G);% convolving with G and G' */
    convolveXY1D_T(yt, tempBuf, wKernel, inRows, inCols, wKernelLen);/* output in yt; */

    idx = 0;
    for (j = 0; j < inCols; j++)
    {
        for (i = 0; i < inRows; i++, idx++)
        {
            if ((i<halfwKernelLen) || (j<halfwKernelLen)) 
            {
                //outVel[idx] = 0;
                outVelC[idx] = 0;
                outVelR[idx] = 0;
            }
            else 
            {
                /* eigenvalue computation */
                T delta = (xy[idx] * xy[idx] - xx[idx] * yy[idx]);
                T A = (xx[idx]+yy[idx])/2.0F;
                T tmp = xx[idx]-yy[idx];
                T B = 4*xy[idx]*xy[idx] + (tmp*tmp);
                T sqrtBby2 = (T)sqrt(B)/(T)2.0;
                T eig1=A+sqrtBby2;
                T eig2=A-sqrtBby2; 

                if ((eig2 >= threshEigen) && (delta <0))/* eig2>eig1 (>= threshEigen) */
                {
                    /* Solving by Cramer's rule  */
                    T deltaX = -(yt[idx] * xy[idx] - xt[idx] * yy[idx]);
                    T deltaY = -(xy[idx] * xt[idx] - xx[idx] * yt[idx]);
                    T Idelta = 1.0F / delta;

                    //velRe = deltaX * Idelta;
                    //velIm = deltaY * Idelta;
                    //outVel[idx] = velRe*velRe + velIm*velIm;
                    outVelC[idx] = deltaX * Idelta;
                    outVelR[idx] = deltaY * Idelta;

                }     /* always eig1 > eig2*/
                else if (includeNormalFlow && 
                         (eig1 >= threshEigen) && (fabs(delta) > THRESH_ABS_DELTA_GDER))
                {
                    /* always eig1 > eig2; Find eigenVector corresponding to largest eigenValue*/
                    /* eigVec = [xy; (eig1-xx)]./sqrt((xx-eig1)*(xx-eig1) + xy*xy); */
                    T mFactor = (T)1/(T)sqrt((xx[idx]-eig1)*(xx[idx]-eig1) + xy[idx]*xy[idx]); 
                    T eigVec1_0 = xy[idx]*mFactor;
                    T eigVec1_1 = (eig1-xx[idx])*mFactor;
                    T tmpVel;
                    /**/ 
                    T deltaX = -(yt[idx] * xy[idx] - xt[idx] * yy[idx]);
                    T deltaY = -(xy[idx] * xt[idx] - xx[idx] * yt[idx]);
                    T Idelta = 1.0F / delta;

                    velRe = deltaX * Idelta;
                    velIm = deltaY * Idelta;
                    /**/
                    tmpVel = -(velRe*eigVec1_0 + velIm*eigVec1_1);
                    //velRe = tmpVel*eigVec1_1;
                    //velIm = tmpVel*eigVec1_0;
                    //outVel[idx] = velRe*velRe + velIm*velIm;
                    outVelC[idx] = tmpVel*eigVec1_1;
                    outVelR[idx] = tmpVel*eigVec1_0;
                }
                else
                {
                    //outVel[idx] = 0;
                    outVelC[idx] = 0;
                    outVelR[idx] = 0;
                }
            }                
        }
    }
}

#endif /* _OPTICALFLOWLKDOG_H_ */
