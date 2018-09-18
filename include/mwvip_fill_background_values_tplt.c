/* mwvip_fill_background_values_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */

    DTYPE fillR = *fillValPtr;
    int_T portWidth = nRowsOut*nColsOut;
    int_T i;
    if (isInputRGB) {
        DTYPE fillG = fillR;
        DTYPE fillB = fillR;
        if (!isScalarFillVal) {
            fillG = *(fillValPtr+1);
            fillB = *(fillValPtr+2);
        }

        if((fillR == 0) && (fillG == 0) && (fillB == 0)) {
            memset((byte_T *)yr, 0,portWidth*sizeof(DTYPE));
            memset((byte_T *)yg, 0,portWidth*sizeof(DTYPE));
            memset((byte_T *)yb, 0,portWidth*sizeof(DTYPE));
        } else {
            for (i = 0; i < nColsOut*nRowsOut; i++) {
                yr[i]   = fillR;
                yg[i]   = fillG;
                yb[i]   = fillB;
            }
        }
    } else {
        if (isScalarFillVal) {
            if (fillR == 0) {
                memset((byte_T *)yr, 0, portWidth*nChans*sizeof(DTYPE));
            } else { 
                portWidth *= nChans;
                for (i = 0; i < portWidth; i++) {
                    yr[i] = fillR;
                }
            }
        } else {
            int_T startIdx = 0, endIdx = portWidth, chanIdx;
            for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
                for (i = startIdx; i < endIdx; i++) {
                    yr[i] = *(fillValPtr+chanIdx);
                }
                startIdx += portWidth;
                endIdx   += portWidth;
            }
        }
    }

/* [EOF]  mwvip_fill_background_values_tplt.c */

