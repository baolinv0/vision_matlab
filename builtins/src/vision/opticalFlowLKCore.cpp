///////////////////////////////////////////////////////////////////////////
//
//  APIs for optical flow computation using Lucas-Kanade algorithm
//
///////////////////////////////////////////////////////////////////////////    

#include "opticalFlowLKCore_api.hpp"
#include "opticalFlowLK.hpp"

void MWCV_OpticalFlow_LK_double( const real_T  *inImgA, 
                                        const real_T  *inImgB,
                                        real_T  *outVelC, 
                                        real_T  *outVelR,
                                        real_T  *gradCC,
                                        real_T  *gradRC,
                                        real_T  *gradRR,
                                        real_T  *gradCT,
                                        real_T  *gradRT,
                                        const real_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols) 
{
 MWCV_OpticalFlow_LK_DTypes<real_T, real_T>( inImgA, 
                                 inImgB,
                                 outVelC, 
                                 outVelR,
                                 gradCC, 
                                 gradRC, 
                                 gradRR, 
                                 gradCT, 
                                 gradRT, 
                                 eigTh,
                                 inRows, 
                                 inCols);
}

void MWCV_OpticalFlow_LK_single( const real32_T  *inImgA, 
                                        const real32_T  *inImgB,
                                        real32_T  *outVelC, 
                                        real32_T  *outVelR,
                                        real32_T  *gradCC,
                                        real32_T  *gradRC,
                                        real32_T  *gradRR,
                                        real32_T  *gradCT,
                                        real32_T  *gradRT,
                                        const real32_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols) 
{
 MWCV_OpticalFlow_LK_DTypes<real32_T, real32_T>( inImgA, 
                                 inImgB,
                                 outVelC, 
                                 outVelR,
                                 gradCC, 
                                 gradRC, 
                                 gradRR, 
                                 gradCT, 
                                 gradRT, 
                                 eigTh,
                                 inRows, 
                                 inCols);
}
 
void MWCV_OpticalFlow_LK_uint8( const uint8_T  *inImgA, 
                                        const uint8_T  *inImgB,
                                        real32_T  *outVelC, 
                                        real32_T  *outVelR,
                                        real32_T  *gradCC,
                                        real32_T  *gradRC,
                                        real32_T  *gradRR,
                                        real32_T  *gradCT,
                                        real32_T  *gradRT,
                                        const real32_T  *eigTh,
                                        int_T  inRows,
                                        int_T  inCols) 
{
 MWCV_OpticalFlow_LK_DTypes<uint8_T, real32_T>( inImgA, 
                                 inImgB,
                                 outVelC, 
                                 outVelR,
                                 gradCC, 
                                 gradRC, 
                                 gradRR, 
                                 gradCT, 
                                 gradRT, 
                                 eigTh,
                                 inRows, 
                                 inCols);
}

