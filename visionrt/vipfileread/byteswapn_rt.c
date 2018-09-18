/*
*  BYTESWAPN_RT runtime function for VIPBLKS Read Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfileread_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API void MWVIP_byteSwapN(int_T N, byte_T *data)
{
    int_T f=0, r=N-1;
	int_T count = N>>1; /* divide by 2 */
	while(count-- >0)
	{
		byte_T temp;
		temp = data[f];
		data[f] = data[r];
		data[r] = temp;
		f++;
		r--;
	}
}

/* [EOF] byteswapn_rt.c */
