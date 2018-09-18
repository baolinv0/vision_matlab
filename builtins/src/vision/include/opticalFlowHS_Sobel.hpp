/*
 *  It computes derivative of input image using Sobel convolution mask.
 *
 *  Copyright 1995-2014 The MathWorks, Inc.
 */

#ifndef _OPTICALFLOWHS_SOBEL_H_
#define _OPTICALFLOWHS_SOBEL_H_

#ifndef MAX
  #define MAX(a,b) ((a)>(b) ? (a) : (b))
#endif

#define SUM_A_2B_C( A, B, C)  ( (A) +  (B) + (B)  + (C)  ) 


template <typename ImT, typename T>
void MWCV_SobelDerivative_HS_DTypes( const ImT  *inImgA,
                                            const ImT  *inImgB,
                                                T  *tmpGradC,
                                                T  *tmpGradR,
                                                T  *buffCprev,/* nRows */
                                                T  *buffCnext,
                                                T  *buffRprev,/* nCols */
                                                T  *buffRnext,
                                                T  *gradCC,
                                                T  *gradRC,
                                                T  *gradRR,
                                                T  *gradCT,
                                                T  *gradRT,
                                                T  *alpha,
                                                const T  *lambda,
                                                int_T  inRows,
                                                int_T  inCols)
{
    int_T i, j, ij;
    int_T im1=0,ip1=0,jm1=0,jp1=0,jp1TimesR=0;
    // for uint8 image, ImT = uint8, T = single
    // for double image, ImT = double, T = double
    // for single image, ImT = single, T = single
    // all other images are converted to single before passing here
    boolean_T usingUint8 = (sizeof(ImT) != sizeof(T));
    T ONE_BY_8RANGE = usingUint8 ? (T)(1.0/(8.0 * 255.0)): (T)(1.0/8.0);
    T ONE_BY_RANGE  = usingUint8 ?  (T)(1.0/255.0) : (T)(1.0);

    /* since we are switching the buffer pointers, we use temporary pointer variable */
    T *buffCprevT = buffCprev;
    T *buffCnextT = buffCnext;
    T *buffRprevT = buffRprev;
    T *buffRnextT = buffRnext;

    T gradC, gradR, gradT;
    T tmp;
    const ImT *inImgAt;

  /********************* Scanning along row *************************/
  /* step-1.1 : populate column buffer */
    /* all elements in first column (first and last elements repeated) */
    for( i = 0; i < inRows; i++ )
    {
       im1 = (i==0)          ? 0 : i-1;
       ip1 = (i==(inRows-1)) ? i : i+1;
       buffCprevT[i] = (T)SUM_A_2B_C(inImgA[im1],
                                          inImgA[i],
                                          inImgA[ip1] );
    }

    /* for the first column, buffCprevT = buffCnextT */
    for( i = 0; i < inRows; i++ )   buffCnextT[i] = buffCprevT[i];
 
  /* step-1.2: use the column buffer to compute horizontal gradient */
  /*           also update the column buffer                        */

    for( j = 0; j < inCols; j++ )
    {
        jp1 = (j==(inCols-1)) ? j : j+1;
        jp1TimesR = jp1*inRows;
        for( i = 0; i < inRows; i++ )
        {   /* row scan */
            im1 = (i==0) ? 0 : i-1;
            ip1 = (i==(inRows-1)) ? i : i+1;
            tmp = (T)SUM_A_2B_C(inImgA[im1 + jp1TimesR],
                                     inImgA[i   + jp1TimesR],
                                     inImgA[ip1 + jp1TimesR]);
            tmpGradC[i+j*inRows] = (buffCprevT[i] - tmp ) * (T)ONE_BY_8RANGE;
            buffCprevT[i] = tmp;
        }

        /* switch the next and prev column buffers */
        {
            T *tmpBuff = buffCprevT;
            buffCprevT = buffCnextT;
            buffCnextT = tmpBuff;
        }
    }
  /********************* Scanning along column *************************/
  /* step-2.1 : populate row buffer */
    /* all elements in first column (first and last elements repeated) */
    inImgAt = inImgA;
    for( j = 0; j < inCols; j++ )
    {
        int_T negInRows  = (j==0)          ? 0 : -inRows;
        int_T plusInRows = (j==(inCols-1)) ? 0 : inRows;
        buffRprevT[j] = (T)SUM_A_2B_C(inImgAt[negInRows],
                                           inImgAt[0],   /* inImgAt[0]=inImgA[j*inRows] */
                                           inImgAt[plusInRows] );
        inImgAt += inRows;
    }

    /* for the first row, buffRprevT = buffRnextT*/
    for( j = 0; j < inCols; j++ )   buffRnextT[j] = buffRprevT[j];
 
 /* step-2.2: use the row buffer to compute horizontal gradient */
 /*           also update the row buffer                        */

    for( i = 0; i < inRows; i++ )
    {
        ip1 = (i==(inRows-1)) ? i : i+1;
        for( j = 0; j < inCols; j++ ) 
        {   /* column scan */
            jm1  = (j==0) ? 0 : j-1;
            jp1  = (j==(inCols-1)) ? j : j+1;
            tmp = (T)SUM_A_2B_C(inImgA[ip1 + jm1*inRows],
                                     inImgA[ip1 + j*inRows],
                                     inImgA[ip1 + jp1*inRows]);
            tmpGradR[i+j*inRows] = (buffRprevT[j] - tmp ) * (T)ONE_BY_8RANGE;
            buffRprevT[j] = tmp;
        }

        /* switch the next and prev row buffers */
        {
            T *tmpBuff = buffRprevT;
            buffRprevT = buffRnextT;
            buffRnextT = tmpBuff;
        }
    }
  /*******************COMPUTE OTHER GRADIENT VALUES*******************/

    for( ij = 0; ij < inRows*inCols; ij++ )
    {
        gradT = (T) (inImgB[ij] - inImgA[ij]) * ONE_BY_RANGE;
        gradR = tmpGradR[ij]; 
        gradC = tmpGradC[ij];

        gradCC[ij] = gradC * gradC;
        gradRC[ij] = gradC * gradR;
        gradRR[ij] = gradR * gradR;
        gradCT[ij] = gradC * gradT;
        gradRT[ij] = gradR * gradT;

        alpha[ij] = 1 / (lambda[0] + gradCC[ij] + gradRR[ij]);
    }
}
/* [EOF] sobelderivative_hs_d_rt.c */

#endif /* _OPTICALFLOWHS_H_SOBEL_ */