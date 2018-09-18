/* mwvip_xform_one_subdivision_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */


#if (ISFILLPOLYGON && DRAWANTIALIASED)
    boolean_T start = true;
#endif
    int_T i, j, k;
    int32_T *globalEdges  = allEdges + NUM_TABLE_COLS*numPts/2;
    /* Loop over each column in polygon extent*/
    int_T sizeActiveET = 0;
    /* next global edge table entry to be copied*/
    int_T indx_global  = 0; 
    /* #rows in globalEdges*/
    int_T   numLineSegs = numPts/2;
    int_T   imax_global = numLineSegs;
    int_T   icurr_col; 
    int_T   last_col;
    int32_T offset[8];
    offset[0] = 0;
    offset[1] = numLineSegs;
    offset[2] = 2*numLineSegs;
    offset[3] = offset[2]+numLineSegs;
    offset[4] = offset[3]+numLineSegs;
    offset[5] = offset[4]+numLineSegs;
    offset[6] = offset[5]+numLineSegs; 
    offset[7] = offset[6]+numLineSegs; 
    CREATE_EDGES_TABLE_FCN(outPts, numPts, allEdges, globalEdges,
                           sortItemArray, offset, DRAWANTIALIASED);
    last_col     = globalEdges[numPts-1];
    icurr_col    = globalEdges[0]; 
    while (true) {
        int_T sizeActiveETMinus1; 
#if !ISFILLPOLYGON
        int_T r0, r2;
#endif
        if (sizeActiveET > 0) {
            int_T count = sizeActiveET;
            int_T rowToDelete  = 0; 
            /* extra if condition added to plot the last column as well. */
            if (icurr_col == last_col) {
                while (count--) {
                    if (allEdges[rowToDelete+numLineSegs] == last_col) 
                        allEdges[rowToDelete+numLineSegs]++;
                    rowToDelete++;
                }
            }
            count = sizeActiveET;
            rowToDelete  = 0;
            while (count--) {
                if (icurr_col == allEdges[rowToDelete + numLineSegs]) {
                    /* If Ymax is equal to icurr_col, we need to 
                     * remove that entry
                     */
                    for (i = 0; i < NUM_TABLE_COLS; i++) {
                        for (k = 0; k <(sizeActiveET-rowToDelete-1);k++) {
                            allEdges[k+rowToDelete+i*numLineSegs] = 
                                allEdges[k+rowToDelete+1+i*numLineSegs];
                        }
                    }
                    sizeActiveET--;
                } else {
                    rowToDelete++;
                }
            }
        }

        /* Add new edges to active edge table
         * compare curr col index to next edge cmin in global ET
         */
        while ((indx_global < imax_global) && 
                (icurr_col == globalEdges[indx_global])) {
            if (globalEdges[indx_global] != 
                globalEdges[indx_global+numLineSegs]) {
                int32_T t3 = globalEdges[indx_global+ offset[2]];
                boolean_T app = true;
                int_T elemsShiftDown = (sizeActiveET-1);
                for (i = 0; i < sizeActiveET; i++) {
                    if (t3 < allEdges[i+offset[2]]) {
                        app = false;
                        /* move rows down, insert new row */
                        for (j = 0; j < (NUM_TABLE_COLS); j++) {
                            for (k = elemsShiftDown; k >= 0; k--) {
                                allEdges[k+i+1+j*numLineSegs]= 
                                    allEdges[k+i+j*numLineSegs];
                            }
                            allEdges[i+j*numLineSegs] = 
                                globalEdges[indx_global+j*numLineSegs];
                        }
                        sizeActiveET++;
                        break;
                    }
                    elemsShiftDown--;
                }
                if (app) {
                    for (j = 0; j < (NUM_TABLE_COLS); j++) {
                        allEdges[sizeActiveET+j*numLineSegs]= 
                            globalEdges[indx_global+j*numLineSegs];
                    }
                    sizeActiveET++;
                }
            }
            indx_global++;
        }
        if (sizeActiveET == 0) {
            break;
        }
#if ISFILLPOLYGON
    #if DRAWANTIALIASED
        #if ISRGB
            FILL_AA_VERTICAL_SCANLINE_FCN
                (y,
                 yg,
                 yb,
                 icurr_col,
                 vp,
                 nRowsIn,
                 sizeActiveET,
                 allEdges,
                 val,
                 opacityValPtr,
                 offset,
                 table,
                 tableIdx,
                 outPts,
                 numPts/2,
                 start);
        #else
            FILL_AA_VERTICAL_SCANLINE_FCN(y,
            icurr_col,vp,nRowsIn,sizeActiveET,allEdges,
            val,opacityValPtr, offset,table,tableIdx,outPts,numPts/2, start,
            nChans, chanWidth);
        #endif
        start = false;
    #else
        #if ISRGB
            FILL_VERTICAL_SCANLINE_FCN(y,yg,yb,
            icurr_col,vp,nRowsIn,
            sizeActiveET,allEdges,val,opacityValPtr,offset[2]);
        #else
            FILL_VERTICAL_SCANLINE_FCN(y,icurr_col,vp,nRowsIn,sizeActiveET,
                allEdges,val,opacityValPtr,offset[2],nChans,chanWidth);
        #endif
    #endif
#else
        r0 = allEdges[offset[2]];
        r2 = allEdges[1+offset[2]];
        COMPUTE_OUTVAL_FCN( y, yg, yb,icurr_col,vp,r0,r2,nRowsIn,isInputRGB,
            inR, inG, inB,A,nColsIn, nRowsOut,nColsOut,interpMethod,isExactSoln,
            inStartRowIdx, inStartColIdx, nChans);
#endif
        /* offset[2] -> current row value
         * offset[5] -> integer part of dr/dc
         * update error term for the next column/row. 
         * add/subtract integer part of slope to the current row
         * Conditionally increment/devrement the row and change the error term 
         * if the actual point lies in the lower half of the pixel. 
         */
        for (i = 0; i < sizeActiveET; i++) {
            int_T dr  = allEdges[i+offset[3]];
            int_T dc  = allEdges[i+offset[4]];
            int_T eps = allEdges[i+offset[6]];
            if (dr > 0) {
                /* positive slope. */
                eps += dr - allEdges[i+offset[5]]*dc;
                allEdges[i+offset[2]] += allEdges[i+offset[5]];
                if (2*eps >= dc) {
                    allEdges[i+offset[2]]++;
                    eps -= dc;
                } 
            } else {
                /* negative slope.  */
                eps += dr + allEdges[i+offset[5]]*dc;
                allEdges[i+offset[2]] -= allEdges[i+offset[5]];
                if (2*eps < -dc) {
                    allEdges[i+offset[2]]--;
                    eps += dc;
                } 
            }
            allEdges[i+offset[6]] = eps;
        }
        /* Bubble sort */
        sizeActiveETMinus1 = sizeActiveET-1;
        while (sizeActiveETMinus1 > 0) {
            boolean_T sw = false;
            int32_T tmp = allEdges[sizeActiveETMinus1 + offset[2]];
            for (j = 0; j < sizeActiveETMinus1; j++) {
                sw = (boolean_T)(tmp < allEdges[j + offset[2]]);
                if (sw) break;
            }
            if (sw) {
                int_T indx = sizeActiveETMinus1;
                int_T diff = sizeActiveETMinus1 - j;
                for (k = 0; k < NUM_TABLE_COLS; k++) {
                    int_T diff1 = diff;
                    tmp = allEdges[indx];
                    while (diff1--) {
                        allEdges[j+1+diff1 ] = allEdges[j+diff1];
                    }
                    allEdges[j] = tmp;
                    j += numLineSegs;
                    indx += numLineSegs;
                }
            } else {
                sizeActiveETMinus1--;
            }
        }
        icurr_col++;
    }

/* [EOF]  mwvip_xform_one_subdivision_tplt.c */

