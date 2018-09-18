/* mwvip_calculate_xform_mtrx_tplt.c
 * 
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

/* 
 * rectROIPts = Rectangular ROI. [r,c,dr,dc]
 * [rectRows, rectCols] = Height and width of rectangle. 
 */
/* Used 'Digital Image warping' by George Wolberg as a reference to calculate
 * Af and AI transformation matrices with the exception that the underlying
 * code doesn't assume unity height and width of the square but a rectangle
 * Page 54-56. ch. Spatial transformation
 * If the rectangle doesn't have starting [r,c] co-ordinates as [0,0]
 * then we need additional transformation to translate matrix (T)
 * T      = [1 0 0; 0 1 0; colTranslate rowTranslate 1]
 * inv(T) = [1 0 0; 0 1 0; -colTranslate -rowTranslate 1]
 * Overall transformation matrix is AI*T or inv(T)*Af
 */

    DTYPE T31=0,T32=0,X1,X2,X3,X4,Y1,Y2,Y3,Y4,dx1,dx2,dx3,dy1,dy2,dy3;
    int_T rowOffsetExists, colOffsetExists, height, width ;
    DTYPE *Af, *AI, denom1, denom2;
    if (mode == RECTANGLE_T0_QUAD) {
        rowOffsetExists = isInRectSizeUserDef && (rectROIPts[0] != 0);
        colOffsetExists = isInRectSizeUserDef && (rectROIPts[1] != 0);
        height = isInRectSizeUserDef ? rectROIPts[2]-1 : rectRows-1;
        width  = isInRectSizeUserDef ? rectROIPts[3]-1 : rectCols-1;
    } else {
        rowOffsetExists = (rectROIPts[0] != 0);
        colOffsetExists = (rectROIPts[1] != 0);
        height = rectROIPts[2]-1;
        width  = rectROIPts[3]-1;
    } 
    if (rowOffsetExists) {
        T32 = (DTYPE)rectROIPts[0];
        if (mode != RECTANGLE_T0_QUAD) {
            T32 = -T32;
        }
    }
    if (colOffsetExists) {
        if (mode == RECTANGLE_T0_QUAD) {
            T31 = (DTYPE)rectROIPts[1];
        } else {
            T31 = -(DTYPE)rectROIPts[1];
        }
    }
    Af     = Aptr;
    AI     = Af + TRANSFORM_MATRIX_ELEMENTS;
    Af[8]  = 1.0;
    X1     = (DTYPE)outPts[1], X2 = (DTYPE)outPts[3], X3 = (DTYPE)outPts[5], X4 = (DTYPE)outPts[7];
    Y1     = (DTYPE)outPts[0], Y2 = (DTYPE)outPts[2], Y3 = (DTYPE)outPts[4], Y4 = (DTYPE)outPts[6];
    dx1    = X2 - X3, dx2 = X4 - X3, dx3 = X1-X2+X3-X4;
    dy1    = Y2 - Y3, dy2 = Y4 - Y3, dy3 = Y1-Y2+Y3-Y4;
    denom1 = width*(dx1*dy2 - dy1*dx2);
    denom2 = height*(dx1*dy2 - dy1*dx2);
    Af[6]  = (dx3*dy2 - dy3*dx2)/denom1;
    Af[7]  = (dx1*dy3 - dy1*dx3)/denom2;
    Af[0]  = Af[6]*X2 + (X2 - X1)/width;
    Af[1]  = Af[7]*X4 + (X4-X1)/height;
    Af[2]  = X1;
    Af[3]  = Af[6]*Y2 + (Y2 - Y1)/width ;
    Af[4]  = Af[7]*Y4 + (Y4-Y1)/height;
    Af[5]  = Y1;

    /*  Let's calculate coefficients for inverse of A *det(A), */
    AI[0] = Af[4]*Af[8] - Af[7]*Af[5];
    AI[1] = Af[7]*Af[2] - Af[1];
    AI[2] = Af[1]*Af[5] - Af[4]*Af[2];
    AI[3] = Af[6]*Af[5] - Af[3];
    AI[4] = Af[0] - Af[6]*Af[2];
    AI[5] = Af[3]*Af[2] - Af[0]*Af[5];
    AI[6] = Af[3]*Af[7] - Af[6]*Af[4];
    AI[7] = Af[6]*Af[1] - Af[0]*Af[7];
    AI[8] = Af[0]*Af[4] - Af[3]*Af[1];
    if (mode == RECTANGLE_T0_QUAD) {
        /* need to change AI also in QuadToRec mode if there are subdivisions*/
        if (colOffsetExists || rowOffsetExists) {
            if (colOffsetExists) {
                AI[0] += T31*AI[6];
                AI[1] += T31*AI[7];
                AI[2] += T31*AI[8];
            }
            if (rowOffsetExists) {
                AI[3] += T32*AI[6];
                AI[4] += T32*AI[7];
                AI[5] += T32*AI[8];
            }
        }
    } else {
        if (colOffsetExists || rowOffsetExists) {
            if (colOffsetExists) {
                Af[2] += T31*Af[0];
                Af[5] += T31*Af[3];
                Af[8] += T31*Af[6];
            }
            if (rowOffsetExists) {
                Af[2] += T32*Af[1];
                Af[5] += T32*Af[4];
                Af[8] += T32*Af[7];
            }
            if ((mode == QUAD_TO_RECTANGLE) && (numSubDivs > 0))  {
                if (colOffsetExists) {
                    AI[0] += -T31*AI[6];
                    AI[1] += -T31*AI[7];
                    AI[2] += -T31*AI[8];
                }
                if (rowOffsetExists) {
                    AI[3] += -T32*AI[6];
                    AI[4] += -T32*AI[7];
                    AI[5] += -T32*AI[8];
                }
            }
        }
    }

/* [EOF]  mwvip_calculate_xform_mtrx_tplt.c */

