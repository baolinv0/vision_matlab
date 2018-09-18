/* mwvip_create_edges_table_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */
    int_T numLineSegs = numVertices/2;
    int_T edge, i;
    int32_T *toPtr;
    int_T tableIdx = 0;
    /* Each adjacent set of vertices (the first and second, second and
     * third, last and first) defines an edge. For each edge, the 
     * following information needs to be kept in a table: 
     * 1. The minimum col. value of the two vertices. 
     * 2. The maximum col. value of the two vertices. 
     * 3. The row value associated with the minimum y value. 
     * 4. dr. 5. dc 6. integer part of dr/dc 7. error (initialized to 0)
     * 8. convertVtoP (used only for antialiasing filled polygons). 
     */
    for (edge = 0; edge < numLineSegs; edge++) {
      	PointStruct ptA, ptB;
        int_T tableIdx1 = tableIdx+numLineSegs;
        int_T tableIdx2 = tableIdx+offset[2];
        int_T tableIdx3 = tableIdx+offset[3];
        int_T tableIdx4 = tableIdx+offset[4];
        int_T tableIdx5 = tableIdx+offset[5];
        int_T tableIdx6 = tableIdx+offset[6];
        int_T rowMaxCol;
        ptA.Row = outPts[edge*2];
        ptA.Col = outPts[edge*2+1];
        ptB.Row = (edge == (numLineSegs-1)) ? outPts[0]
                                            : outPts[edge*2+2];
        ptB.Col = (edge == (numLineSegs-1)) ? outPts[1]
                                            : outPts[edge*2+3];
        if (ptA.Col < ptB.Col) {
            allEdges[tableIdx]    = ptA.Col; /* Ymin */
            allEdges[tableIdx1]   = ptB.Col; /* Ymax */
            allEdges[tableIdx2]   = ptA.Row; /* X->Ymin */
            rowMaxCol             = ptB.Row; /* X->Ymax */
        } else {
            allEdges[tableIdx]    = ptB.Col;
            allEdges[tableIdx1]   = ptA.Col;
            allEdges[tableIdx2]   = ptB.Row;
            rowMaxCol             = ptA.Row;
        }
        allEdges[tableIdx3] = rowMaxCol   - allEdges[tableIdx2]; /* dr */
        allEdges[tableIdx4] = allEdges[tableIdx1] - allEdges[tableIdx];
        /* dc is always positive */
        if (allEdges[tableIdx4] > 0) {
            allEdges[tableIdx5] =
                ABSVALINT(allEdges[tableIdx3])/allEdges[tableIdx4];
        }
        allEdges[tableIdx6] = 0; /* error term  is initialized to zero. */
        if (drawAntiAliased) {
            int_T tableIdx7 = tableIdx+offset[7];
           /* calculate convertVToP = abs(dc)/(sqrt(dr*dr + dc*dc)); */
            /* we calculate convertVToP based on cubic curve fit.
             * p1 = 263, p2 = -560, p3 = -2, p4 = 1024;
             * (coeffs are scaled up by 1024)
             * convertVToP = p1*slope^3 + p2*slope^2 + p3*slope + p4
             * which is scaled by 1024. 
             */
#ifdef ISFLTPT
                allEdges[tableIdx7] = (int32_T)((allEdges[tableIdx4]*1024.0)/(sqrt(allEdges[tableIdx3]*allEdges[tableIdx3] + allEdges[tableIdx4]*allEdges[tableIdx4])));
#else
                int32_T slope = abs((allEdges[tableIdx3] << upscaleFactorBits)/allEdges[tableIdx4]);
                if (abs(allEdges[tableIdx3]) < allEdges[tableIdx4]) { /* if dr < dc*/
                    int32_T P1 = 263, P2 = -560, P3 = -2;
                    int32_T temp = (slope*slope*slope) >> upscaleFactorBits;
                    temp *= P1;
                    temp >>= (2*upscaleFactorBits);
                    allEdges[tableIdx7] = temp + ((P2*slope*slope)>>(2*upscaleFactorBits)) + ((P3*slope)>>upscaleFactorBits) + upscaleFactor;
                } else { /* if dr > dc*/
                    /* Give slope = 1:0.1:1024, we need to compute
                     * allEdges[tableIdx7] = 1./sqrt(1+slope.*slope);
                     * Divide slope into 4 parts:- 1-15, 15-50, 50-200, 200 plus
                     * and use polynomial fit to caluculate the output */
                    if (slope <= 15*upscaleFactor) {
                        /* fittedmodel1to15(x) = p1*x^4 + p2*x^3 + p3*x^2 + p4*x + p5
                        * p1 =     0.09314 = 95 with 2^10 scaling
                        * p2 =      -3.639 = -3726 with 2^10 scaling
                        * p3 =       52.12 =  52
                        * p4 =      -336.1 = -336
                        * p5 =       964.7 = 964
                        */
                        int32_T P1 = 95, P2 = -3726; /* scaled of 2^upscaleFactorBits */
                        int32_T P3 = 52, P4 = -336, P5 = 964;
                        int32_T temp = (slope*slope*slope) >> upscaleFactorBits; 
                        int32_T temp1 = (temp * slope) >> upscaleFactorBits; 
                        temp1 *= P1;
                        temp1 >>= (2*upscaleFactorBits);
                        temp *= P2; 
                        temp >>= (2*upscaleFactorBits);
                        allEdges[tableIdx7] = (temp1 + temp + ((P3*slope*slope)>>upscaleFactorBits) + (P4*slope) + (P5<<upscaleFactorBits))>>upscaleFactorBits;
                    } else if (slope <= 50*upscaleFactor) {
                        int32_T P1 = -5; 
                        int32_T P2 = 172; 
                        int32_T P3 = -1966; 
                        int32_T P4 = 149;
                        int32_T temp = (slope*slope*slope) >> upscaleFactorBits; 
                        temp *= P1; 
                        temp >>= 22;
                        allEdges[tableIdx7] = (temp + ((P2*slope*slope)>>(2*upscaleFactorBits)) + ((P3*slope)>>8) + (P4<<upscaleFactorBits))>>upscaleFactorBits;
                    } else if (slope <= 200*upscaleFactor) {
                        int32_T P2 = 13; 
                        int32_T P3 = -580; 
                        int32_T P4 = 41;
                        allEdges[tableIdx7] = (((P2*slope*slope)>>22) + ((P3*slope)>>upscaleFactorBits) + (P4<<upscaleFactorBits))>>upscaleFactorBits;
                    } else {
                        if (slope > (513*upscaleFactor)) allEdges[tableIdx7] = 1;
                        else if (slope > (342*upscaleFactor)) allEdges[tableIdx7] = 2;
                        else if (slope > (257*upscaleFactor)) allEdges[tableIdx7] = 3;
                        else if (slope > (205*upscaleFactor)) allEdges[tableIdx7] = 4;
                        else allEdges[tableIdx7] = 5;
                    }
                }
#endif
        }
        tableIdx++;
    }
    /* Construct Global Edge Table which has the same properties as
     * allEdges. To do this, we need to sort allEdges table based on ymin,
     * ymax and x sortrows(allEdges, [1 2 3]). This function return a
     * vector of sorted row indices in outPts vector. 
     *  6 == SS_INT32 */
    MWVIP_SortRows(allEdges, numLineSegs,6,sortItemArray);

    /* Rearrange input rows according to the output of the sort algorithm.
     * y = x(ndx,:);
     */
    toPtr   = globalEdges;
    for (edge = 0; edge < numLineSegs; edge++) {
        int32_T *fromPtr = allEdges + sortItemArray[edge].index;
        int32_T *sortedPtr = toPtr;
        for (i = 0; i < NUM_TABLE_COLS; i++) { 
            *sortedPtr = *fromPtr;
            sortedPtr += numLineSegs;
            fromPtr   += numLineSegs;
        }
        toPtr++;
    }

/* [EOF]  mwvip_fillpolygon_interpflt_tplt.c.c */

