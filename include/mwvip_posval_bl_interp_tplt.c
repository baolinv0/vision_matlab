/* mwvip_posval_bl_interp_tplt.c
 *  Perform bilinear interpolation. 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */

    DTYPE deltaU,deltaV,val0,val1;
    int_T chanIdx,inIndx1,inIndx2,inIndx3,inIndx4;
    int_T v0,v1;
    int_T u0 = (int_T)u;
    int_T u1 = u0+1;
    if (u1 > (rows-1)) u1 = rows-1;
    v0 = (int_T)v;
    v1 =  v0+1;
    if (v1 > (cols-1)) v1 = cols-1;
    deltaU = u - u0;
    deltaV = v - v0;
    inIndx1 = u1+v0*rows;
    inIndx2 = u0+v0*rows;
    inIndx3 = u1+v1*rows;
    inIndx4 = u0+v1*rows;
    for (chanIdx = 0; chanIdx < nChans; chanIdx++) {
        val0 = deltaU*I[inIndx1] + (VAL_ONE-deltaU)*I[inIndx2];
        val1 = deltaU*I[inIndx3] + (VAL_ONE-deltaU)*I[inIndx4];
        y[outIdx] = val1*deltaV + val0*(VAL_ONE-deltaV);
        outIdx   += outChanWidth;
        inIndx1   += inChanWidth;
        inIndx2   += inChanWidth;
        inIndx3   += inChanWidth;
        inIndx4   += inChanWidth;
    }

/* [EOF]  mwvip_posval_bl_interp_tplt.c */

