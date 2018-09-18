/* mwvip_calculate_q2q_xform_mtrx_tplt.c
 * 
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

    int_T intermediateRectPts[4];
    intermediateRectPts[0] = 0;
    intermediateRectPts[1] = 0;
    intermediateRectPts[2] = nRowsIn;
    intermediateRectPts[3] = nColsIn;
    CALCULATE_XFROM_MATRIX_FCN(inPtsValid, intermediateRectPts,
        nRowsIn, nColsIn, QUAD_TO_QUAD, 0, 0 , A);
    /* Now let's calculate Af_fwd and AI_fwd when going 
     * from rectangle to quadrilateral. */
    CALCULATE_XFROM_MATRIX_FCN(outPts, intermediateRectPts, 
        nRowsIn, nColsIn, RECTANGLE_T0_QUAD, 0, 0 , A+18);

    A[36] = A[27]*A[0] + A[30]*A[1] + A[33]*A[2];
    A[39] = A[27]*A[3] + A[30]*A[4] + A[33]*A[5];
    A[42] = A[27]*A[6] + A[30]*A[7] + A[33];
    A[37] = A[28]*A[0] + A[31]*A[1] + A[34]*A[2];
    A[40] = A[28]*A[3] + A[31]*A[4] + A[34]*A[5];
    A[43] = A[28]*A[6] + A[31]*A[7] + A[34];
    A[38] = A[29]*A[0] + A[32]*A[1] + A[35]*A[2];
    A[41] = A[29]*A[3] + A[32]*A[4] + A[35]*A[5];
    A[44] = A[29]*A[6] + A[32]*A[7] + A[35];
    
    if (useSubdivision) {
        /* A_fwd = AI_inv*AF_fwd; */
        A[45] = A[9]*A[18] + A[12]*A[19] + A[15]*A[20];
        A[48] = A[9]*A[21] + A[12]*A[22] + A[15]*A[23];
        A[51] = A[9]*A[24] + A[12]*A[25] + A[15];
        A[46] = A[10]*A[18] + A[13]*A[19] + A[16]*A[20];
        A[49] = A[10]*A[21] + A[13]*A[22] + A[16]*A[23];
        A[52] = A[10]*A[24] + A[13]*A[25] + A[16];
        A[47] = A[11]*A[18] + A[14]*A[19] + A[17]*A[20];
        A[50] = A[11]*A[21] + A[14]*A[22] + A[17]*A[23];
        A[53] = A[11]*A[24] + A[14]*A[25] + A[17];
    }

/* [EOF]  mwvip_calculate_q2q_xform_mtrx_tplt.c */

