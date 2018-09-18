/*
 *  vipedge_rt.h
 *
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

#ifndef vipedge_rt_h
#define vipedge_rt_h

#include "dsp_rt.h"
#include "libmwvisionrt_util.h"

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
 * MWVIP_EdgeCanny_userTh_<DataType> 
 * 
 *    1) MWVIP_ is a prefix used with all Mathworks DSP runtime library 
 *       functions. 
 *    2) The second field indicates that this function is implementing the 
 *       Edge function using Canny method
 *    3) The third field can be 'userTh' which indicates that this function
 *       is implementing the canny method using user-defined threshold or   
 *       'autoTh' which means threshold is calculated internally
 *    4) The last field enumerates the data type of the output ports
 * 
 *    Examples: 
 *       MWVIP_EdgeCanny_userTh_D is the Edge function for double precision outputs
 *       and thershold is specified by the user. 
 */ 

/* datatype double */
#ifdef __cplusplus
extern "C" {
#endif

#define N_BINS       256
#define N_BINS_MIN1  255
#define MAG_SCALE 20
#define Dnorm(x, y)  ((real_T) sqrt ( (real_T)((x)*(x) + (y)*(y)) ))
#define Rnorm(x, y)  ((real32_T) sqrt ( (real32_T)((x)*(x) + (y)*(y)) ))
#define isInRange(r,c,inpRows,inpCols)   \
	((r) >= 0 && (r) < (inpRows) && (c) >= 0 && (c) < (inpCols))

LIBMWVISIONRT_API void MWVIP_RC_Gaussian_Smoothing_D(const real_T *input,
                                 const real_T *gauss1D,
                                       real_T *filteredDataC,
                                       real_T *filteredDataR,
                                       int_T inpRows,
                                       int_T inpCols,
                                       int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_RC_Gaussian_Smoothing_R(const real32_T *input,
                                 const real32_T *gauss1D,
                                       real32_T *filteredDataC,
                                       real32_T *filteredDataR,
                                       int_T inpRows,
                                       int_T inpCols,
                                       int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_C_Derivative_Image_D(const real_T *input,
                              const real_T *dgauss1D,
                                    real_T *filteredDataC,
                                    int_T inpRows,
                                    int_T inpCols,
                                    int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_C_Derivative_Image_R(const real32_T *input,
                              const real32_T *dgauss1D,
                                    real32_T *filteredDataC,
                                    int_T inpRows,
                                    int_T inpCols,
                                    int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_R_Derivative_Image_D(const real_T *input,
                              const real_T *dgauss1D,
                                    real_T *filteredDataR,
                                    int_T inpRows,
                                    int_T inpCols,
                                    int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_R_Derivative_Image_R(const real32_T *input,
                              const real32_T *dgauss1D,
                                    real32_T *filteredDataR,
                                    int_T inpRows,
                                    int_T inpCols,
                                    int_T halfFiltLen);

LIBMWVISIONRT_API void MWVIP_NonMaximum_Suppression_D(real_T *dc,
                                  real_T *dr,
                                  real_T *tmpOrMag,
                                  int_T inpRows,
                                  int_T inpCols);

LIBMWVISIONRT_API void MWVIP_NonMaximum_Suppression_R(real32_T *dc,
                                  real32_T *dr,
                                  real32_T *tmpOrMag,
                                  int_T inpRows,
                                  int_T inpCols);

LIBMWVISIONRT_API void MWVIP_EdgeCanny_userTh_D(
    const real_T  *inpImg,
    const real_T  *gauss1D,
    const real_T  *dgauss1D,
          real_T  *cFiltered,  /* DWork same size as image */
          real_T  *rFiltered,  /* DWork same size as image */
       boolean_T  *outEdge,
          real_T  *tmpOrMag,   /* DWork same size as image */
    const real_T  *ThreshCanny,
          int_T  inpRows,
          int_T  inpCols,
          int_T  halfFiltLen
                                );

LIBMWVISIONRT_API void MWVIP_EdgeCanny_userTh_R(
    const real32_T  *inpImg,
    const real32_T  *gauss1D,
    const real32_T  *dgauss1D,
          real32_T  *cFiltered,  /* DWork same size as image */
          real32_T  *rFiltered,  /* DWork same size as image */
         boolean_T  *outEdge,
          real32_T  *tmpOrMag,   /* DWork same size as image */
    const real32_T  *ThreshCanny,
          int_T  inpRows,
          int_T  inpCols,
          int_T  halfFiltLen
                                );

LIBMWVISIONRT_API void MWVIP_EdgeCanny_autoTh_D(
    const real_T  *inpImg,
    const real_T  *gauss1D,
    const real_T  *dgauss1D,
          real_T  *cFiltered,  /* DWork same size as image */
          real_T  *rFiltered,  /* DWork same size as image */
       boolean_T  *outEdge,
          real_T  *tmpOrMag,   /* DWork same size as image */
    const real_T  *autoPercent,
          int_T  inpRows,
          int_T  inpCols,
          int_T  halfFiltLen
                                );

LIBMWVISIONRT_API void MWVIP_EdgeCanny_autoTh_R(
    const real32_T  *inpImg,
    const real32_T  *gauss1D,
    const real32_T  *dgauss1D,
          real32_T  *cFiltered,  /* DWork same size as image */
          real32_T  *rFiltered,  /* DWork same size as image */
         boolean_T  *outEdge,
          real32_T  *tmpOrMag,   /* DWork same size as image */
    const real32_T  *autoPercent,
          int_T  inpRows,
          int_T  inpCols,
          int_T  halfFiltLen
                                );

#ifdef __cplusplus
} /*  close brace for extern C from above */
#endif

#if (!defined(__cplusplus)) && (!defined(__true_false_are_keywords))
#  ifndef false
#   define false                       (0U)
#  endif

#  ifndef true
#   define true                        (1U)
#  endif
#endif


#endif /* vipedge_rt_h */

/* [EOF] vipedge_rt.h */
