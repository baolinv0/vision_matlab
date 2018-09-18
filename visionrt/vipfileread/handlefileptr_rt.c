/*
* HANDLEFILEPTR_RT runtime function for VIPBLKS Read Binary File block
*
*  Copyright 1995-2007 The MathWorks, Inc.
*/
#include "vipfileread_rt.h"
#include <stdio.h>

LIBMWVISIONRT_API boolean_T MWVIP_handleFilePtr(void *fptrDW,
							  int32_T   *numLoops,
							  boolean_T *eofflag, 
							  int_T cols)
{
    FILE **fptr = (FILE **) fptrDW;
	fseek(fptr[0], cols, SEEK_CUR);
    if (feof(fptr[0])) {
        numLoops[0]--;
        rewind(fptr[0]);
        eofflag[0] = 1;
        return 0;
    }
	return 1;
}

/* [EOF] handlefileptr_rt.c */
