/*
 *  MM_2DPAD_SIM.H - simulation helper functions for 2D pad operations
 *
 *  Copyright 1995-2005 The MathWorks, Inc.
 */

#ifndef vip_2dpad_sim_h
#define vip_2dpad_sim_h

#include "dsp_rt.h"

/* DSPSIM_PadArgsCache is a structure used to contain parameters/arguments
 * for each of the individual simulation functions listed below.
 */
typedef struct {
    const void *u;        /* pointer to input array  (any data type, any complexity) */
    void       *y;        /* pointer to output array (any data type, any complexity) */
    const void *padValue; /* pointer to value to pad output array
                           * (complexity must match complexity of y)
                           */
    void       *zero;     /* pointer to data-typed "real zero" representation */

    int_T       bytesPerInpElmt; /* number of bytes in each sample in input matrix */
    int_T       bytesPerInpCol;  /* number of bytes in each column of input matrix */
	int_T       bytesCopyCol;
    int_T       numOutRows;      /* number of rows in the output matrix    */
    int_T       numOutCols;      /* number of columns in the output matrix */
    int_T       padAtLeft;       /* Pad size on the left side of the input matrix*/
    int_T       offsetFrmRight;  /* Pad size on the right side of the input matrix*/   
    int_T       padAtTop;        /* Pad size above (on top of) input matrix*/
    int_T       offsetFrmBottom; /* Pad size below (on bottom of) input matrix*/
    boolean_T   padValueIsComplex;

} VIPSIM_2dPadArgsCache;

/* Simulation helper functions to handle 2D Padding */

/* Pad with a constant value as specified by the user. */
/* Handle case when both input, output and pad value have same complexity*/

extern void VIPSIM_Pad2dConst(VIPSIM_2dPadArgsCache *args);
/* Handle case when input matrix is real but pad value is complex*/
extern  void VIPSIM_Pad2dConst_RC(VIPSIM_2dPadArgsCache *args);
/* Handle case when input matrix is complex but pad value is real (from input port) */
extern void VIPSIM_Pad2dConst_CR(VIPSIM_2dPadArgsCache *args);

/* Pad so that we repeat the boundary values as the pad values. */
extern void VIPSIM_Pad2dReplicate(VIPSIM_2dPadArgsCache *args);

/* Pad symmetrically about the boundary of the input matrix. */
extern void VIPSIM_Pad2dSymmetric(VIPSIM_2dPadArgsCache *args);

/* Pad circularly about the boundary of the input matrix. */
extern void VIPSIM_Pad2dCircular(VIPSIM_2dPadArgsCache *args);
extern void VIPSIM_Pad2dNopad(VIPSIM_2dPadArgsCache *args);
extern void VIPSIM_Pad2dReplicate_RC(VIPSIM_2dPadArgsCache *args);

/* Pad symmetrically about the boundary of the input matrix. */
extern void VIPSIM_Pad2dSymmetric_RC(VIPSIM_2dPadArgsCache *args);

/* Pad circularly about the boundary of the input matrix. */
extern void VIPSIM_Pad2dCircular_RC(VIPSIM_2dPadArgsCache *args);

#endif /* vip_2dpad_sim_h */

/* [EOF] vip_2dpad_sim.h */
