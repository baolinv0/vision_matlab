/* 
 * This file contains the optical flow Lucas-Kanade (difference filter) algorithm.
 *
 *  Copyright 1995-2014 The MathWorks, Inc.
 */

#ifndef _OPTICALFLOWLK_H_
#define _OPTICALFLOWLK_H_

#include <string.h>
#include <math.h>

template <typename ImT, typename T> 
void MWCV_OpticalFlow_LK_DTypes( const ImT  *inImgA, //input image A
                                        const ImT  *inImgB, //input image B
                                        T  *outVelC, // output velocity - component along column
                                        T  *outVelR, // output velocity - component along row
                                        T  *gradCC,
                                        T  *gradRC,
                                        T  *gradRR,
                                        T  *gradCT,
                                        T  *gradRT,
                                        const T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols) 
{
    int_T i, j, ij, mn;
    int_T cFilterHalfLen = 2;
    int_T rFilterHalfLen = 2;
    int_T BytesPerInCol = sizeof(T)*inRows;

    T threshEigen      = eigTh[0]; 
    T THRESH_ABS_DELTA = 0; /* delta is the determinant of the 2x2 matrix */
    T THRESH_NORM      = 0;

    // for uint8 image, ImT = uint8, T = single
    // for double image, ImT = double, T = double
    // for single image, ImT = single, T = single
    // all other images are converted to single before passing here
    boolean_T usingUint8 = (sizeof(ImT) != sizeof(T));
    T ONE_BY_RANGE  = usingUint8 ?  (T)(1.0/255.0) : (T)(1.0);
    T RANGE  = usingUint8 ?  (T)255.0 : (T)1.0;

    T gradKernel[5] = {-1/12.0F,8/12.0F,0,-8/12.0F,1/12.0F};
    T gradKernelRange[5] = {-1/(12.0F*RANGE),8/(12.0F*RANGE),0,-8/(12.0F*RANGE),1/(12.0F*RANGE)};

    /* Gaussian separable kernels {1/16,4/16,6/16,4/16,1/16} */
    T gauss1DFilt[5] = {0.0625,0.25,0.375,0.25,0.0625};
    T gauss1DFiltRange[5] = {(0.0625F/RANGE),(0.25F/RANGE),(0.375F/RANGE),(0.25F/RANGE),(0.0625F/RANGE)};

    T *cFilter;
    T *rFilter;

    T *cFilterRange;
    T *rFilterRange;

    int_T colIdx=0;
    T sum;
    int_T pixelIdx=0;

    cFilter = (T *)&gradKernel[cFilterHalfLen];
    rFilter = (T *)&gradKernel[rFilterHalfLen];

    cFilterRange = (T *)&gradKernelRange[cFilterHalfLen];
    rFilterRange = (T *)&gradKernelRange[rFilterHalfLen];

    ij=0;
    mn=0;

    for( colIdx = 0; colIdx < inCols; colIdx++ )
    {
        /***********************************************************************************************/		    
        /*************** FILTERING (TO FIND DERIVATIVE) ALONG COLUMN DIRECTION *************************/
        /***********************************************************************************************/
        int_T leftSpace;
        int_T rightSpace;

        if( colIdx < cFilterHalfLen )	 /* process first cFilterHalfLen pixels */
        {
            leftSpace = colIdx;
            rightSpace = cFilterHalfLen;

            pixelIdx = 0;
            for( j = 0; j < inRows; j++ )
            {
                int_T addr = 0;
                sum = 0;

                for( i = -leftSpace; i <= rightSpace; i++ )
                {
                    sum += inImgA[addr + j] * cFilterRange[i];
                    addr += inRows;
                }
                gradCC[ij++] = sum;
            }
        }
        else if( colIdx < inCols - cFilterHalfLen ) /* process middle part */
        {
            pixelIdx = (colIdx - cFilterHalfLen) * inRows;
            for( j = 0; j < inRows; j++ )
            {
                int_T addr = pixelIdx;
                gradCC[ij++] = (-inImgA[addr + j] + inImgA[addr+4*inRows + j])*cFilterRange[2]
                +(inImgA[addr+inRows + j] - inImgA[addr+3*inRows + j])*cFilterRange[-1];
            }
        }
        else  /* process last cFilterHalfLen pixels; if( colIdx >= inCols - cFilterHalfLen ) */
        {
            leftSpace = cFilterHalfLen;
            rightSpace = inCols - colIdx - 1;

            pixelIdx = (colIdx - leftSpace) * inRows;
            for( j = 0; j < inRows; j++ )
            {
                int_T addr = pixelIdx;
                sum = 0;

                for( i = -leftSpace; i <= rightSpace; i++ )
                {
                    sum += inImgA[addr + j] * cFilterRange[i];
                    addr += inRows;
                }
                gradCC[ij++] = sum;
            }
        }
        /***********************************************************************************************/		    
        /*************** FILTERING (TO FIND DERIVATIVE) ALONG ROW DIRECTION ****************************/
        /***********************************************************************************************/
        /* process first rFilterHalfLen pixels */
        for( j = 0; j < rFilterHalfLen; j++ )
        {
            int_T jj;

            sum = 0;

            for( jj = -j; jj <= rFilterHalfLen; jj++ )
            {
                sum += inImgA[mn + jj] * rFilterRange[jj];
            }
            gradRR[mn] = sum;
            mn++;
        }
        /* process inner part of line */
        for( j = rFilterHalfLen; j < inRows - rFilterHalfLen; j++ )
        {
            gradRR[mn]  = (inImgA[mn - 1] - inImgA[mn + 1])* rFilterRange[-1]  /* 8/12 */
            + (-inImgA[mn - 2] + inImgA[mn + 2])* rFilterRange[2]; /* 1/12 */
            mn++;
        }
        /* process right side */
        for( j = inRows - rFilterHalfLen; j < inRows; j++ )
        {
            int_T jj;

            sum = 0;

            for( jj = -rFilterHalfLen; jj < inRows - j; jj++ )
            {
                sum += inImgA[mn + jj] * rFilterRange[jj];
            }
            gradRR[mn] = sum;
            mn++;
        }
    }
    for( j = 0; j < inRows*inCols; j++ )
    {
        T tmpGradR = gradRR[j]; 
        T tmpGradC = gradCC[j];
        T tmpGradT = ((T)inImgB[j] - (T)inImgA[j])*ONE_BY_RANGE; /* GradT */

        gradRR[j] = tmpGradR*tmpGradR; 
        gradCC[j] = tmpGradC*tmpGradC; 
        gradRC[j] = tmpGradR*tmpGradC; 

        gradRT[j] = tmpGradR*tmpGradT; 
        gradCT[j] = tmpGradC*tmpGradT; 
    }

    /***********************************************************************************************/		    
    /************** GAUSSIAN FILTERING (TO INTRODUCE WEIGHT) ALONG ROW DIRECTION *******************/
    /***********************************************************************************************/
    mn = 0;
    cFilter = (T *)&gauss1DFilt[cFilterHalfLen];
    rFilter = (T *)&gauss1DFilt[rFilterHalfLen];

    cFilterRange = (T *)&gauss1DFiltRange[cFilterHalfLen];
    rFilterRange = (T *)&gauss1DFiltRange[rFilterHalfLen];

    for( colIdx = 0; colIdx < inCols; colIdx++ )
    {
        T *tmpWGradRR = (T *)outVelC;
        T *tmpWGradCC = tmpWGradRR + inRows;
        T *tmpWGradRC = tmpWGradCC + inRows;
        T *tmpWGradRT = tmpWGradRC + inRows;
        T *tmpWGradCT = tmpWGradRT + inRows;
        int_T     colIdxTimesInRows = colIdx*inRows;

        memcpy(tmpWGradRR, &gradRR[colIdxTimesInRows],BytesPerInCol);
        memcpy(tmpWGradCC, &gradCC[colIdxTimesInRows],BytesPerInCol);
        memcpy(tmpWGradRC, &gradRC[colIdxTimesInRows],BytesPerInCol);
        memcpy(tmpWGradRT, &gradRT[colIdxTimesInRows],BytesPerInCol);
        memcpy(tmpWGradCT, &gradCT[colIdxTimesInRows],BytesPerInCol);
        ij=0;
        /* process top side */
        for( j = 0; j < rFilterHalfLen; j++ )
        {
            int_T jj;

            tmpWGradRR[ij] = 0;
            tmpWGradCC[ij] = 0;
            tmpWGradRC[ij] = 0;
            tmpWGradRT[ij] = 0;
            tmpWGradCT[ij] = 0;

            for( jj = -j; jj <= rFilterHalfLen; jj++ )
            {
                tmpWGradRR[ij] += gradRR[mn + jj] * rFilter[jj];
                tmpWGradCC[ij] += gradCC[mn + jj] * rFilter[jj];
                tmpWGradRC[ij] += gradRC[mn + jj] * rFilter[jj];
                tmpWGradRT[ij] += gradRT[mn + jj] * rFilter[jj];
                tmpWGradCT[ij] += gradCT[mn + jj] * rFilter[jj];
            }
            mn++;
            ij++;
        }
        /* process inner part of line */
        for( j = rFilterHalfLen; j < inRows - rFilterHalfLen; j++ )
        {
            int_T jj;
            tmpWGradRR[ij] = 0;
            tmpWGradCC[ij] = 0;
            tmpWGradRC[ij] = 0;
            tmpWGradRT[ij] = 0;
            tmpWGradCT[ij] = 0;

            for( jj = 1; jj <= rFilterHalfLen; jj++ )
            {
                tmpWGradRR[ij] += (gradRR[mn - jj] + gradRR[mn + jj]) * rFilter[jj];
                tmpWGradCC[ij] += (gradCC[mn - jj] + gradCC[mn + jj]) * rFilter[jj];
                tmpWGradRC[ij] += (gradRC[mn - jj] + gradRC[mn + jj]) * rFilter[jj];
                tmpWGradRT[ij] += (gradRT[mn - jj] + gradRT[mn + jj]) * rFilter[jj];
                tmpWGradCT[ij] += (gradCT[mn - jj] + gradCT[mn + jj]) * rFilter[jj];
            }
            tmpWGradRR[ij] += gradRR[mn] * rFilter[0];
            tmpWGradCC[ij] += gradCC[mn] * rFilter[0];
            tmpWGradRC[ij] += gradRC[mn] * rFilter[0];
            tmpWGradRT[ij] += gradRT[mn] * rFilter[0];
            tmpWGradCT[ij] += gradCT[mn] * rFilter[0];

            mn++;  
            ij++;
        }
        /* process bottom side */
        for( j = inRows - rFilterHalfLen; j < inRows; j++ )
        {
            int_T jj;

            tmpWGradRR[ij] = 0;
            tmpWGradCC[ij] = 0;
            tmpWGradRC[ij] = 0;
            tmpWGradRT[ij] = 0;
            tmpWGradCT[ij] = 0;

            for( jj = -rFilterHalfLen; jj < inRows - j; jj++ )
            {
                tmpWGradRR[ij] += gradRR[mn + jj] * rFilter[jj];
                tmpWGradCC[ij] += gradCC[mn + jj] * rFilter[jj];
                tmpWGradRC[ij] += gradRC[mn + jj] * rFilter[jj];
                tmpWGradRT[ij] += gradRT[mn + jj] * rFilter[jj];
                tmpWGradCT[ij] += gradCT[mn + jj] * rFilter[jj];
            }
            mn++;  
            ij++;
        }
        memcpy(&gradRR[colIdxTimesInRows],tmpWGradRR, BytesPerInCol);
        memcpy(&gradCC[colIdxTimesInRows],tmpWGradCC, BytesPerInCol);
        memcpy(&gradRC[colIdxTimesInRows],tmpWGradRC, BytesPerInCol);
        memcpy(&gradRT[colIdxTimesInRows],tmpWGradRT, BytesPerInCol);
        memcpy(&gradCT[colIdxTimesInRows],tmpWGradCT, BytesPerInCol);

    }

    /*******************************************************************************************/		    
    /************* GAUSSIAN FILTERING (TO INTRODUCE WEIGHT) ALONG COLUMN DIRECTION *************/
    /*******************************************************************************************/
    mn=0;
    for( colIdx = 0; colIdx < inCols; colIdx++ )
    {
        int_T leftSpace;
        int_T rightSpace;

        if( colIdx < cFilterHalfLen )
            leftSpace = colIdx;
        else
            leftSpace = cFilterHalfLen;

        if( colIdx >= inCols - cFilterHalfLen )
            rightSpace = inCols - colIdx - 1;
        else
            rightSpace = cFilterHalfLen;

        pixelIdx = (colIdx - leftSpace) * inRows;
        for( j = 0; j < inRows; j++ )
        {
            int_T addr = pixelIdx;

            T WWGradRR = 0;
            T WWGradCC = 0;
            T WWGradRC = 0;
            T WWGradRT = 0;
            T WWGradCT = 0;

            for( i = -leftSpace; i <= rightSpace; i++ )
            {
                WWGradRR += gradRR[addr + j] * cFilter[i];
                WWGradCC += gradCC[addr + j] * cFilter[i];
                WWGradRC += gradRC[addr + j] * cFilter[i];
                WWGradRT += gradRT[addr + j] * cFilter[i];
                WWGradCT += gradCT[addr + j] * cFilter[i];

                addr += inRows;
            }
            /************************************************************************/
            /********************** Solve Linear System *****************************/
            /************************************************************************/
            {
                T delta = (WWGradRC * WWGradRC - WWGradCC * WWGradRR);
                T A = (WWGradCC+WWGradRR)/2.0F;
                T tmp  = WWGradCC-WWGradRR;
                T B = 4.0F*WWGradRC*WWGradRC + tmp*tmp;
                T sqrtBby2 = (T)sqrt(B)/(T)2.0;
                T eig1=A+sqrtBby2;   /* Largest eigenvalue first  */
                T eig2=A-sqrtBby2;
                if ((eig1 >= threshEigen) && (eig2 >= threshEigen) && (fabs(delta)>=THRESH_ABS_DELTA))
                {
                    /* Solving by Cramer's rule */
                    T deltaC = -(WWGradRT * WWGradRC - WWGradCT * WWGradRR);
                    T deltaR = -(WWGradRC * WWGradCT - WWGradCC * WWGradRT);
                    T Idelta = 1.0F / delta;

                    outVelC[mn] = deltaC * Idelta;
                    outVelR[mn] = deltaR * Idelta;
                    mn++;
                }
                else if ((eig1 >= threshEigen) && (eig2 < threshEigen))
                {
                    /* singular system - find optical flow in gradient direction */
                    /* singular system, determinant is non-invertible */
                    /* gradient flow is normalized */

                    T tmpRC_CC = WWGradRC + WWGradCC;
                    T tmpRR_RC = WWGradRR + WWGradRC;
                    T norm = tmpRC_CC*tmpRC_CC + tmpRR_RC*tmpRR_RC;

                    if( norm >= THRESH_NORM )
                    {
                        T invNorm = 1.0F / norm;
                        T temp = -(WWGradRT + WWGradCT) * invNorm;
                        outVelC[mn] = tmpRC_CC * temp;
                        outVelR[mn] = tmpRR_RC * temp;

                        mn++;
                    }
                    else
                    {
                        outVelC[mn] = 0;
                        outVelR[mn] = 0;
                        mn++;
                    }
                }
                else
                {
                    outVelC[mn] = 0;
                    outVelR[mn] = 0;
                    mn++;
                }
            }
        }
    }

}

#endif /* _OPTICALFLOWLK_H_ */
