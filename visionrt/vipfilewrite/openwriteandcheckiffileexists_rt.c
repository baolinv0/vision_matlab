/*
*  OPENWRITEANDCHECKIFFILEEXISTS_RT runtime function for VIPBLKS Write Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfilewrite_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API boolean_T MWVIP_OpenWriteAndCheckIfFileExists(void *fptrDW, const char *FileName)
{
    FILE **fptr = (FILE **) fptrDW;
	fptr[0] = (FILE *)fopen(FileName, "wb");
	return (fptr[0] == NULL);
}
/* [EOF] openwriteandcheckiffileexists_rt.c */
