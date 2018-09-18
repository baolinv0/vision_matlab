/* mwvip_posval_bc_interp_tplt.c
*  Perform bicubic interpolation. 
*  Copyright 1995-2006 The MathWorks, Inc.
*/

/* assumes u and v are non-negative */
int_T i;
int_T ui  = (int_T)u;
int_T vi = (int_T)v;
DTYPE x1,x0,x2,x3, h0,h1,h2,h3;
DTYPE *val = (DTYPE *)malloc(4*nChans*sizeof(DTYPE));
int_T  idx, startCol = 0, endCol = 4, chanIdx;
if (v == vi) {
    /* calculate for just 1 column */
    startCol = 1;
    endCol = startCol+1;
} else if ((vi == 0) || (vi == (nCols-2))) {
    /* calculate for just 2 columns*/
    startCol = 1;
    endCol = 3;
}
if (u == ui) {
    idx = (vi-1+startCol)*nRows + ui;
    for (i = startCol; i < endCol; i++) {
        int_T i1 = i, idx1 = idx;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            val[i1] = I[idx1];
            idx1 += inChanWidth;
            i1   += 4;
        }
        idx += nRows;
    }
} else if ((ui == 0) || (ui == (nRows-2))) {
    DTYPE frac = u - ui;
    idx = (vi-1+startCol)*nRows;
    if (ui > 0)  idx += (nRows-2);
    for (i = startCol; i < endCol; i++) {
        int_T i1 = i, idx1 = idx;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            val[i1] = I[idx1]*(VAL_ONE-frac) + I[idx1+1]*frac;
            idx1   += inChanWidth;
            i1     += 4;
        }
        idx += nRows;
    }
} else {
    x1 = 1-u+ui;
    x0 = x1+1;
    x2 = u - ui;
    x3 = x2+1;
    h0 = -(x0*x0*x0) + 5*x0*x0 - 8*x0 + 4;
    h3 = -(x3*x3*x3) + 5*x3*x3 - 8*x3 + 4;
    h1 = x1*x1*x1 - 2*x1*x1 + 1;
    h2 = x2*x2*x2 - 2*x2*x2 + 1;
    idx = (vi-1+startCol)*nRows + (ui-1);
    for (i = startCol; i < endCol; i++) {
        int_T i1 = i, idx1 = idx;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            val[i1] = h3*I[idx1]+h2*I[idx1+1]+h1*I[idx1+2]+h0*I[idx1+3];
            idx1   += inChanWidth;
            i1     += 4;
        }
        idx += nRows;
    }
}

if ((startCol == 1) && (endCol == 3)) {
    if (v == vi) {
        int_T indx = 1;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            y[outIdx] = val[indx];
            outIdx += outChanWidth;
            indx   += 4;
        }
    } else {
        DTYPE frac = v-vi;
        int_T indx1 = 1, indx2 = 2;        
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            y[outIdx] = val[indx1]*(VAL_ONE-frac) + val[indx2]*frac;
            outIdx   += outChanWidth;
            indx1    += 4; 
            indx2    += 4; 
        }
    }
} else {
    if (v == vi) {
        int_T indx = 1;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            y[outIdx] = val[indx];
            outIdx += outChanWidth;
            indx   += 4;
        }
    } else {
        int_T indx0 = 0, indx1 = 1, indx2 = 2,  indx3 = 3;      
        x1 = 1-v+vi;
        x0 = x1+1;
        x2 = v - vi;
        x3 = x2+1;
        h0 = -(x0*x0*x0) + 5*x0*x0 - 8*x0 + 4;
        h3 = -(x3*x3*x3) + 5*x3*x3 - 8*x3 + 4;
        h1 = x1*x1*x1 - 2*x1*x1 + 1;
        h2 = x2*x2*x2 - 2*x2*x2 + 1;
        for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
            y[outIdx] = h3*val[indx0] + h2*val[indx1] + h1*val[indx2] + h0*val[indx3];
            outIdx   += outChanWidth;
            indx0    += 4; 
            indx1    += 4; 
            indx2    += 4; 
            indx3    += 4; 
        }
    }
}
free(val);

/* [EOF]  mwvip_posval_bc_interp_tplt.c */

