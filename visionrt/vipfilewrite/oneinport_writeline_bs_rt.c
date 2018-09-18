/*
*  ONEINPORT_WRITELINE_BS_RT runtime function for VIPBLKS Write Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfilewrite_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API void MWVIP_oneInport_WriteLine_BS(void *fptrDW,
							 const void *portAddr_0,
							 int_T rows, 
							 int_T cols,
							 int_T bpe)
{
    int_T j;
    FILE **fptr = (FILE **) fptrDW;
	byte_T temp[4];
	const byte_T *portAddr0 = (const byte_T *)portAddr_0;

	int_T rowsj = 0;
    for (j=0; j < cols; j++) {
		MWVIP_WriteByteSwapN(bpe, &portAddr0[rowsj], temp);  
        fwrite(temp, 1, bpe, fptr[0]);
        rowsj  += rows;
    }
}

/* [EOF] oneinport_writeline_bs_rt.c */
