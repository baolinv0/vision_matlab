/*
* OPENANDCHECKIFFILEEXISTS_RT runtime function for VIPBLKS Read Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfileread_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API boolean_T MWVIP_OpenAndCheckIfFileExists(void *fptrDW, 
											   const char *FileName)
{
    FILE **fptr = (FILE **) fptrDW;
	fptr[0] = (FILE *)fopen(FileName, "rb");
	return (fptr[0] == NULL);
}

/* [EOF] openandcheckiffileexists_rt.c */
