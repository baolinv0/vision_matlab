/*
 *  is_little_endian_rt.c
 *
 *  Copyright 1995-2011 The MathWorks, Inc.
 */
#include "vipendian_rt.h"

LIBMWVISIONRT_API int_T isLittleEndian(void)
{
	int16_T  endck  = 1;
	int8_T  *pendck = (int8_T *)&endck;
	return(pendck[0] == (int8_T)1);
}
