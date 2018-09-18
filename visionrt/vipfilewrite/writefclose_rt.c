/*
*  WRITEFCLOSE_RT runtime function for VIPBLKS Write Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfilewrite_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API void MWVIP_WriteFclose(void *fptrDW)
{
    FILE **fptr = (FILE **) fptrDW;
    fclose(fptr[0]);
}
/* [EOF] writefclose_rt.c */
