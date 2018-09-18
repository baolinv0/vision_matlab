/*
*  WRITEBYTESWAPN_RT runtime function for VIPBLKS Write Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfilewrite_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API void MWVIP_WriteByteSwapN(int_T N, const byte_T *data, byte_T *out)
{
    int_T f=0, r=N-1;
	int_T count = N; 
	while(count-- >0)
	{
		out[r] = data[f];
		f++;
		r--;
	}
}

/* [EOF] writebyteswapn_rt.c */
