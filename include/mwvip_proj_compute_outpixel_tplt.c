/* mwvip_xform_one_subdivision_tplt.c
 * 
 *  Copyright 1995-2006 The MathWorks, Inc.
 */

    /* Handle each scan-line */
    if ((icurr_col >= vp.CMin) && (icurr_col <= vp.CMax)) {            
        DTYPE u0,v0,w0,u2,v2,w2,u,v,w = 0;
        if ((r0<=vp.RMax) && (r2>=vp.RMin)) {
            const int_T inChanWidth  = nRowsIn*nColsIn;
            const int_T outChanWidth = nRowsOut*nColsOut;
            DTYPE dx = 0, du = 0, dv = 0, dw = 0,
                  UD1= 0, UD2= 0, VD1= 0, VD2= 0;
            int_T outIdx,x;
            GET_INPTS_FRM_OUTPTS(r0, icurr_col, A, &u0, &v0, &w0);
            GET_INPTS_FRM_OUTPTS(r2, icurr_col, A, &u2, &v2, &w2);
            if (r0 != r2) {
                dx = (DTYPE)(1.0/(r2 - r0));
                if (isExactSoln) {
                    du = (u2 - u0)*dx;
                    dv = (v2 - v0)*dx;
                    dw = (w2 - w0)*dx;
                } else {
                    DTYPE recipW = 1/(w0 + w2);
                    DTYPE u1 = (u0 + u2)*recipW;
                    DTYPE v1 = (v0 + v2)*recipW;
                    DTYPE a1,b1,a2,b2;
                    recipW = 1/w0;
                    u0 = u0*recipW;
                    v0 = v0*recipW;
                    recipW = 1/w2;
                    u2 = u2*recipW;
                    v2 = v2*recipW;
                    /* compute quadratic polynomial coefficients:
                     * a2x^2 + a1x + a0
                     */
                    a1 = (-3*u0 + 4*u1 - u2)*dx; 
                    b1 = (-3*v0 + 4*v1 - v2)*dx;
                    a2 = 2*(u0 - 2*u1 + u2)*dx*dx;
                    b2 = 2*(v0 - 2*v1 + v2)*dx*dx;

                    /* forward difference parameters for quadratic polynomial */
                    UD1 = a1+a2;
                    VD1 = b1+b2;
                    UD2 = 2*a2;
                    VD2 = 2*b2;
                }
            }
            w = w0;
            u = u0;
            v = v0;
            outIdx = (icurr_col - vp.CMin)*nRowsOut 
                            + (r0-vp.RMin);
            for (x = r0; x <= r2; x++) {
                if ((x >= vp.RMin) && (x <= vp.RMax)) {
                    if (isExactSoln) {
                        DTYPE recipW = 1/w;
                        DTYPE row = u * recipW;
                        DTYPE col = v * recipW;
                        if (row < (DTYPE)inStartRowIdx) row = (DTYPE)inStartRowIdx;
                        if (col < (DTYPE)inStartColIdx) col = (DTYPE)inStartColIdx;
                        if (row > (DTYPE)(nRowsIn-1)) row = (DTYPE)nRowsIn-1;
                        if (col > (DTYPE)(nColsIn-1)) col = (DTYPE)nColsIn-1;
                        if (interpMethod == NEAREST_NBOR) {
                            if (isInputRGB) {
                                NN_INTERP_FCN(inR,row, col, nRowsIn,y,outIdx,1, 0, 0);
                                NN_INTERP_FCN(inG,row, col, nRowsIn,yg,outIdx,1, 0, 0);
                                NN_INTERP_FCN(inB,row, col, nRowsIn,yb,outIdx,1, 0, 0);
                            } else {
                                NN_INTERP_FCN(inR,row, col, nRowsIn,y,outIdx,nChans,
                                               inChanWidth, outChanWidth);
                            }
                        } else if (interpMethod == BILINEAR) {
                            if (isInputRGB) {
                                BL_INTERP_FCN(inR,row, col, nRowsIn, nColsIn,
                                    y,outIdx,1,0,0);
                                BL_INTERP_FCN(inG,row, col,nRowsIn, nColsIn,
                                    yg,outIdx,1,0,0);
                                BL_INTERP_FCN(inB,row, col,nRowsIn, nColsIn,
                                    yb,outIdx,1,0,0);
                            } else {
                                BL_INTERP_FCN(inR,row, col, nRowsIn, nColsIn,
                                    y,outIdx,nChans,inChanWidth, outChanWidth);
                            }
                        } else {
                            if (isInputRGB) {
                                BC_INTERP_FCN(inR,row, col, nRowsIn, nColsIn,
                                    y,outIdx,1,0,0);
                                BC_INTERP_FCN(inG,row, col,nRowsIn, nColsIn,
                                    yg,outIdx,1,0,0);
                                BC_INTERP_FCN(inB,row, col,nRowsIn, nColsIn,
                                    yb,outIdx,1,0,0);
                            } else {
                                BC_INTERP_FCN(inR,row, col, nRowsIn, nColsIn,
                                    y,outIdx,nChans,inChanWidth, outChanWidth);
                            }
                        }
                    } else {
                        /* mode is approximate */
                        if (u < inStartRowIdx) u = (DTYPE)inStartRowIdx;
                        if (v < inStartColIdx) v = (DTYPE)inStartColIdx;
                        if (u > (nRowsIn-1)) u = (DTYPE)nRowsIn-1;
                        if (v > (nColsIn-1)) v = (DTYPE)nColsIn-1;

                        if (interpMethod == NEAREST_NBOR) {
                            if (isInputRGB) {
                                NN_INTERP_FCN(inR,u, v, nRowsIn,y,outIdx,1,0,0);
                                NN_INTERP_FCN(inG,u, v, nRowsIn,yg,outIdx,1,0,0);
                                NN_INTERP_FCN(inB,u, v, nRowsIn,yb,outIdx,1,0,0);
                            } else {
                                NN_INTERP_FCN(inR,u, v, nRowsIn,y,outIdx,nChans,
                                               inChanWidth, outChanWidth);
                            }
                        } else if (interpMethod == BILINEAR) {
                            if (isInputRGB) {
                                BL_INTERP_FCN(inR,u, v, nRowsIn, nColsIn,y,outIdx,1,0,0);
                                BL_INTERP_FCN(inG,u, v, nRowsIn, nColsIn,yg,outIdx,1,0,0);
                                BL_INTERP_FCN(inB,u, v, nRowsIn, nColsIn,yb,outIdx,1,0,0);
                            } else {
                                BL_INTERP_FCN(inR,u, v, nRowsIn, nColsIn,y,outIdx,nChans,
                                               inChanWidth, outChanWidth);
                            }
                        } else {
                            if (isInputRGB) {
                                BC_INTERP_FCN(inR,u, v, nRowsIn, nColsIn,y,outIdx,1,0,0);
                                BC_INTERP_FCN(inG,u, v, nRowsIn, nColsIn,yg,outIdx,1,0,0);
                                BC_INTERP_FCN(inB,u, v, nRowsIn, nColsIn,yb,outIdx,1,0,0);
                            } else {
                                BC_INTERP_FCN(inR,u, v, nRowsIn, nColsIn,y,outIdx,nChans,
                                               inChanWidth, outChanWidth);
                            }
                        }
                    }
                }
                outIdx++;
                if (isExactSoln) {
                    u += du;
                    v += dv; 
                    w += dw;
                } else {
                    u += UD1;
                    v += VD1;
                    UD1 += UD2;
                    VD1 += VD2;
                }
            }
        }
    }

/* [EOF]  mwvip_proj_compute_outpixel_tplt.c */

