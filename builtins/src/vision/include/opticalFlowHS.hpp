/* 
 * This file contains the optical flow Horn-Schunck algorithm.
 *
 *  Copyright 1995-2014 The MathWorks, Inc.
 */

#ifndef _OPTICALFLOWHS_H_
#define _OPTICALFLOWHS_H_

#include <string.h>
#include <math.h>
#include "opticalFlowHS_Sobel.hpp"

template <typename ImT, typename T> 
void MWCV_OpticalFlow_HS_DTypes( const ImT  *inImgA, //input image A
                                        const ImT  *inImgB, //input image B
                                        T  *outVelC, // output velocity - component along column
                                        T  *outVelR, // output velocity - component along row
                                        T  *buffCprev, 
                                        T  *buffCnext, 
                                        T  *buffRprev, 
                                        T  *buffRnext, 
                                        T  *gradCC, 
                                        T  *gradRC, 
                                        T  *gradRR, 
                                        T  *gradCT, 
                                        T  *gradRT, 
                                        T  *alpha,  
                                        T  *velBufCcurr, 
                                        T  *velBufCprev, 
                                        T  *velBufRcurr, 
                                        T  *velBufRprev, 
                                        const T  *lambda,
                                        boolean_T useMaxIter, 
                                        boolean_T useAbsVelDiff,
                                        const int32_T *maxIter, 
                                        const T  *maxAllowableAbsDiffVel, 
                                        int_T  inRows, // num rows of inImgA
                                        int_T  inCols) // num cols of inImgA
{
    const int_T inSize  = inRows*inCols;
    const int_T bytesPerInpCol = inRows * sizeof( T );

    int_T i, j;

    int_T prevCol;
    const int_T endCol = (inCols-1)*inRows;

    int_T numIter;
    T maxAbsVelDiff=0;

    MWCV_SobelDerivative_HS_DTypes<ImT, T>( inImgA,
                                inImgB,
                                outVelC,/* tmpGradC */
                                outVelR,/* tmpGradR */
                                buffCprev,
                                buffCnext,
                                buffRprev,
                                buffRnext,
                                gradCC,
                                gradRC,
                                gradRR,
                                gradCT,
                                gradRT,
                                alpha,
                                lambda,
                                inRows,
                                inCols);

    /* set initial motion vector to zero */
    memset(outVelC, 0, sizeof(T)*inSize);
    memset(outVelR, 0, sizeof(T)*inSize);
    
    /* Gauss-Seidel iterative solution for Optical Flow constraint equation */
    numIter = 1;
    do
    {
        int_T ij = 0;
        int_T ijM1, ijP1, ijMinRows, ijPinRows;
        
        T *velBufCcurrT, *velBufCprevT = NULL, *velBufRcurrT, *velBufRprevT = NULL;

        maxAbsVelDiff = 0;
        velBufCcurrT = velBufCcurr;
        velBufCprevT = velBufCprev;
        velBufRcurrT = velBufRcurr;
        velBufRprevT = velBufRprev;

        for( j = 0; j < inCols; j++ )
        {
            prevCol = (j-1)*inRows;/* it is used only when j>0 */
            for( i = 0; i < inRows; i++ )  /* scanning along column */
            {
                T avgVelC, avgVelR;
                T absVelDiffC, absVelDiffR;

                /* at each iteration we need to use the velocity of the previous iteration
                 * (we need velocity of 4 neighboring pixels from prev iteration)
                 * that's why we can't store the velocity at each iteration to output.
                 * we need to maintain temporary line buffers at each iteration
                 */

                /* mask for computing avg velocity (for prev iteration) (init vel=0):
                 * here (i,j) th element (in 2D) means ==> (ij) th element (in 1D)
                 *
                 *
                 *                                1
                 *                              (i-1,j)
                 *                              = ij-1
                 *
                 *       
                 *                   1            0            1
                 *             (i,j-1)          (i,j)        (i,j+1)
                 *             =ij-inRows       = ij         =ij+inRows
                 *
                 *          
                 *                                1
                 *                             (i+1,j)
                 *                             = ij+1
                 */
                ijM1 = (i==0)          ? ij : ij-1;
                ijP1 = (i==(inRows-1)) ? ij : ij+1;

                ijMinRows = (j==0)          ? ij : ij-inRows;
                ijPinRows = (j==(inCols-1)) ? ij : ij+inRows;
 

                avgVelC = (outVelC[ijM1]      +
                           outVelC[ijP1]      +
                           outVelC[ijMinRows] +
                           outVelC[ijPinRows]) / 4;
                avgVelR = (outVelR[ijM1]      +
                           outVelR[ijP1]      +
                           outVelR[ijMinRows] +
                           outVelR[ijPinRows]) / 4;

                velBufCcurrT[i] = avgVelC -
                    (gradCC[ij] * avgVelC +
                     gradRC[ij] * avgVelR + gradCT[ij]) * alpha[ij];

                velBufRcurrT[i] = avgVelR -
                    (gradRC[ij] * avgVelC +
                     gradRR[ij] * avgVelR + gradRT[ij]) * alpha[ij];

                /* compute max(vel diff along row, vel diff along col) for this frame */
                if(useAbsVelDiff)
                {
                    
                    absVelDiffC   = (T)fabs(outVelC[ij] - velBufCcurrT[i]);
                    absVelDiffR   = (T)fabs(outVelR[ij] - velBufRcurrT[i]);
                    maxAbsVelDiff = MAX( MAX(absVelDiffC,absVelDiffR), maxAbsVelDiff );
                }
                ij++;
            }

            /* 
             * since we are done scanning this column, we save velocity buffer content 
             * of the previous column to output. 
             */
            if( j > 0 )/* skip first column */
            {
                memcpy( &outVelC[prevCol], velBufCprevT, bytesPerInpCol);
                memcpy( &outVelR[prevCol], velBufRprevT, bytesPerInpCol);
            }

            /* switch the next and prev velocity buffers */
            {
                T *tmpBuff;
                /* column velocity buffers */
                tmpBuff      = velBufCcurrT;
                velBufCcurrT = velBufCprevT;
                velBufCprevT = tmpBuff;
                /* row velocity buffers */
                tmpBuff      = velBufRcurrT;
                velBufRcurrT = velBufRprevT;
                velBufRprevT = tmpBuff;

            }
        }

        /* copy the last column of velocity (j=inCols) to output */ 
        memcpy( &outVelC[endCol], velBufCprevT, bytesPerInpCol);
        memcpy( &outVelR[endCol], velBufRprevT, bytesPerInpCol);
    }
    while (!(  ( useMaxIter && (numIter++ == maxIter[0]) )  
          ||   ( useAbsVelDiff && (maxAbsVelDiff < maxAllowableAbsDiffVel[0]) ))); 
    
}

#endif /* _OPTICALFLOWHS_H_ */
