/*
* FILEREADFCLOSE_RT runtime function for VIPBLKS Read Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfileread_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API void MWVIP_FileReadFclose(void *fptrDW)
{
    FILE **fptr = (FILE **) fptrDW;
    fclose(fptr[0]);
}

/* [EOF] filereadfclose_rt.c */
