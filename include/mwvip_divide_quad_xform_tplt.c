/* mwvip_divide_quad_xform_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */

    /* subdivide input quadrilateral */
    int_T factor1 = numSubDivs+1;
    int_T dR2 = inPts[2]-inPts[0]; 
    int_T dC2 = inPts[3]-inPts[1];
    int_T dR_AD = inPts[6] - inPts[0];
    int_T dC_AD = inPts[7] - inPts[1];
    int_T dR_BC = inPts[4] - inPts[2];
    int_T dC_BC = inPts[5] - inPts[3];
    int_T row, col;
    int32_T inPtsAfterDivision[16];
    boolean_T areQuadPtsValid = true;
    PointStruct  PtStartTop, PtStartBottom, PtEndTop, PtEndBottom;
    PtStartTop.Row = inPts[0]; PtStartTop.Col = inPts[1]; 
    PtStartBottom  = PtStartTop;
    PtEndTop.Row   = inPts[2]; PtEndTop.Col = inPts[3]; 
    PtEndBottom    = PtEndTop;
    for (row = 1; row <= factor1; row++) {
        int_T dR1, dC1;
        PtStartTop = PtStartBottom;
        inPtsAfterDivision[2] = PtStartTop.Row;
        inPtsAfterDivision[3] = PtStartTop.Col;
        PtStartBottom.Row = inPts[0] + 
                            ROUND((DTYPE)row*dR_AD/factor1);
        PtStartBottom.Col = inPts[1] + 
                            ROUND((DTYPE)row*dC_AD/factor1);
        if (row == factor1) {
            if (PtStartBottom.Row != inPts[6]) PtStartBottom.Row = inPts[6];
            if (PtStartBottom.Col != inPts[7]) PtStartBottom.Col = inPts[7];
        }
        inPtsAfterDivision[4] = PtStartBottom.Row;
        inPtsAfterDivision[5] = PtStartBottom.Col;
        dR1 = dR2, dC1 = dC2;
        PtEndTop = PtEndBottom;
        PtEndBottom.Row = inPts[2] + (ROUND((DTYPE)row*dR_BC/factor1));
        PtEndBottom.Col = inPts[3] + (ROUND((DTYPE)row*dC_BC/factor1));
        if (row == factor1) {
            if (PtEndBottom.Row != inPts[4]) PtEndBottom.Row = inPts[4];
            if (PtEndBottom.Col != inPts[5]) PtEndBottom.Col = inPts[5];
        }
        dR2 = PtEndBottom.Row - PtStartBottom.Row;
        dC2 = PtEndBottom.Col - PtStartBottom.Col;
        for (col = 1; col <= factor1; col++) {
            DTYPE val1, val2;
            inPtsAfterDivision[0] = inPtsAfterDivision[2];
            inPtsAfterDivision[1] = inPtsAfterDivision[3];                    
            /* PtA1 = PtB1; */
            inPtsAfterDivision[2] = ROUND((DTYPE)col*dR1/factor1);
            inPtsAfterDivision[2] += PtStartTop.Row; 
            inPtsAfterDivision[3] = ROUND((DTYPE)col*dC1/factor1);
            inPtsAfterDivision[3] += PtStartTop.Col;
            if (col == factor1) {
                if (inPtsAfterDivision[2] != PtEndTop.Row)
                    inPtsAfterDivision[2] = PtEndTop.Row;
                if (inPtsAfterDivision[3] != PtEndTop.Col)
                    inPtsAfterDivision[3] = PtEndTop.Col;
            }            
            inPtsAfterDivision[6] = inPtsAfterDivision[4];
            inPtsAfterDivision[7] = inPtsAfterDivision[5];                    
            inPtsAfterDivision[4] = ROUND((DTYPE)col*dR2/factor1);
            inPtsAfterDivision[4] += PtStartBottom.Row; 
            inPtsAfterDivision[5] = ROUND((DTYPE)col*dC2/factor1);
            inPtsAfterDivision[5] += PtStartBottom.Col; 
            if (col == factor1) {
                if (inPtsAfterDivision[4] != PtEndBottom.Row)
                    inPtsAfterDivision[4] = PtEndBottom.Row;
                if (inPtsAfterDivision[5] != PtEndBottom.Col)
                    inPtsAfterDivision[5] = PtEndBottom.Col;
            }
            /* inPtsAfterDivision[0:7] correspond to subdivision in input quadrilateral */
            /* Check to see that 3 or more points in the quadrilateral are not collinear. */
            areQuadPtsValid = !MWVIP_Are3PtsCollinear(inPtsAfterDivision);
            if (areQuadPtsValid) {
                /* inPtsAfterDivision[8:15] correspond to points in output rectangle */
                val1 = A[15]*inPtsAfterDivision[1];
                val2 = A[16]*inPtsAfterDivision[0];
                inPtsAfterDivision[8]  = ROUND(
                    (A[12]*inPtsAfterDivision[1] + A[13]
                    *inPtsAfterDivision[0] + A[14])/(val1 + val2 + A[17]));
                inPtsAfterDivision[9]  = ROUND(
                    (A[9]*inPtsAfterDivision[1] + A[10]
                    *inPtsAfterDivision[0] + A[11])/(val1 + val2 + A[17]));
                val1 = A[15]*inPtsAfterDivision[3];
                val2 = A[16]*inPtsAfterDivision[2];
                inPtsAfterDivision[10] = ROUND(
                    (A[12]*inPtsAfterDivision[3] + A[13]
                    *inPtsAfterDivision[2] + A[14])/(val1 + val2 + A[17]));
                inPtsAfterDivision[11] = ROUND(
                    (A[9]*inPtsAfterDivision[3] + A[10]
                    *inPtsAfterDivision[2] + A[11])/(val1 + val2 + A[17]));
                val1 = A[15]*inPtsAfterDivision[5];
                val2 = A[16]*inPtsAfterDivision[4];
                inPtsAfterDivision[12] = ROUND(
                    (A[12]*inPtsAfterDivision[5] + A[13]
                    *inPtsAfterDivision[4] + A[14])/(val1 + val2 + A[17]));
                inPtsAfterDivision[13] = ROUND(
                    (A[9]*inPtsAfterDivision[5] + A[10]
                    *inPtsAfterDivision[4] + A[11])/(val1 + val2 + A[17]));
                val1 = A[15]*inPtsAfterDivision[7];
                val2 = A[16]*inPtsAfterDivision[6];
                inPtsAfterDivision[14] = ROUND(
                    (A[12]*inPtsAfterDivision[7] + A[13]
                    *inPtsAfterDivision[6] + A[14])/(val1 +  val2 + A[17]));
                inPtsAfterDivision[15] = ROUND(
                    (A[9]*inPtsAfterDivision[7] + A[10]
                    *inPtsAfterDivision[6] + A[11])/(val1 + val2 + A[17]));
                XFORM_FCN(allEdges,NUM_QUAD_VERTICES,inPtsAfterDivision+8,
                    sortItemArray,y,yg,yb,vp,nRowsIn,isInputRGB,
                    A,inR, inG, inB,isExactSoln, nRowsOut, nColsOut, 
                    nColsIn,interpMethod,0,0,nChans); 
            } else {
                break;
            }
        }
        if (!areQuadPtsValid) break;
    }

/* [EOF]  mwvip_calculate_xform_mtrx_tplt.c */

