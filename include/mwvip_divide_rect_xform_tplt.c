/* mwvip_divide_rect_xform_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */

    /* subdivide input rectangle */
    int_T height = isInRectSizeUserDef ? inRectPts[2]-1 : nRowsIn-1;
    int_T width  = isInRectSizeUserDef ? inRectPts[3]-1 : nColsIn-1;
    DTYPE dC = (DTYPE)width/(numSubDivs+1);
    DTYPE dR = (DTYPE)height/(numSubDivs+1);
    int_T rD, cD;
    DTYPE offsetR = isInRectSizeUserDef ? (DTYPE)inRectPts[0] : 0;
    for (rD = 0; rD <= numSubDivs; rD++ ) {
        DTYPE offsetC = isInRectSizeUserDef ? (DTYPE)inRectPts[1] : 0;
        for (cD=0; cD <= numSubDivs; cD++) {
            PointStruct PtA, PtB, PtC, PtD;
            DTYPE denom;
            int32_T outPts[10];
            PtA.Row = (int_T)offsetR;
            PtA.Col = (int_T)offsetC;
            if (PtA.Row  > height) PtA.Row = height;
            if (PtA.Col  > width)  PtA.Col = width;
            offsetC += dC;
            PtB.Row = PtA.Row;
            PtB.Col = (int_T)offsetC;
            if (PtB.Row > height) PtB.Row = height;
            if (PtB.Col > width) PtB.Col = width;
            if (cD == numSubDivs) PtB.Col = width;
            PtD.Row = (int_T)(offsetR+dR);
            PtD.Col = PtA.Col;
            if (PtD.Row > height) PtD.Row = height;
            if (rD == numSubDivs) PtD.Row = height;
            if (PtD.Col > width)  PtD.Col = width;
            PtC.Row = PtD.Row;
            PtC.Col = PtB.Col;
            if (PtC.Row > height) PtC.Row = height;
            if (PtC.Col > width) PtC.Col = width;
            
            denom = (DTYPE)1/(A[6]*PtA.Col + A[7]*PtA.Row + A[8]);
            outPts[0] = ROUND((A[3]*PtA.Col + A[4]*PtA.Row + A[5])*denom);
            outPts[1] = ROUND((A[0]*PtA.Col + A[1]*PtA.Row + A[2])*denom);
            denom = (DTYPE)1/(A[6]*PtB.Col + A[7]*PtB.Row + A[8]);
            outPts[2] = ROUND((A[3]*PtB.Col + A[4]*PtB.Row + A[5])*denom);
            outPts[3] = ROUND((A[0]*PtB.Col + A[1]*PtB.Row + A[2])*denom);
            denom = (DTYPE)1/(A[6]*PtC.Col + A[7]*PtC.Row + A[8]);
            outPts[4] = ROUND((A[3]*PtC.Col + A[4]*PtC.Row + A[5])*denom);
            outPts[5] = ROUND((A[0]*PtC.Col + A[1]*PtC.Row + A[2])*denom);
            denom = (DTYPE)1/(A[6]*PtD.Col + A[7]*PtD.Row + A[8]);
            outPts[6] = ROUND((A[3]*PtD.Col + A[4]*PtD.Row + A[5])*denom);
            outPts[7] = ROUND((A[0]*PtD.Col + A[1]*PtD.Row + A[2])*denom);

            XFORM_FCN(allEdges,NUM_QUAD_VERTICES,outPts,sortItemArray,
                y,yg,yb,vp,nRowsIn,isInputRGB,A+9,inR, inG, inB,
                isExactSoln, nRowsOut, nColsOut, nColsIn,interpMethod,
                inStartRowIdx,inStartColIdx, nChans);                
        }
        offsetR += dR;    
    }

/* [EOF]  mwvip_calculate_xform_mtrx_tplt.c */

