/*
* SET4THBYTEFOR24BITS_LE_RT runtime function for VIPBLKS Read Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfileread_rt.h"

LIBMWVISIONRT_API void MWVIP_set4thBytefor24Bits_LE(void *yO, 
								  int_T N, 
								  boolean_T signedData, 
								  int_T inc)
{
    int_T i;
	byte_T *y = (byte_T *)yO;
    if (signedData) {
        for (i=0; i < N; i++) {
            /* Fill 0x00 or 0xFF based on sign */
            y[3] = 0xFF * ((y[2] & 0x80)>>7);
            y += inc;
        }
    } else {
        for (i=0; i < N; i++) {
            y[3] = 0x00;
            y += inc;
        }
    }
}

/* [EOF] set4thbytefor24bits_le_rt.c */
