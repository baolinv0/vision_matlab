/*
 * Copyright 1984-2005 The MathWorks, Inc.
 *
 * MEX code using the comparison functions in compare_fcn.c should
 * #include this file.
 */

#ifndef lexicmp_h
#define lexicmp_h

#include "dsp_rt.h"
#include <stdlib.h>

/* #include <stdlib.h> */

#define S1_IS_GREATER   ( 1)
#define S2_IS_GREATER   (-1)
#define S1_S2_ARE_EQUAL ( 0)

typedef int (*compare_function)(const void *, const void *);
typedef int (*tiebreak_function)(const void *, const void *);

typedef struct sort_item
{
    void *data;
    int length;
    int stride;
    int index;
    tiebreak_function tiebreak_fcn;
    void *user_data;
} sort_item;

int lexi_compare_uint8(const void *, const void *);
int lexi_compare_uint16(const void *, const void *);
int lexi_compare_uint32(const void *, const void *);
int lexi_compare_uint64(const void *, const void *);
int lexi_compare_int8(const void *, const void *);
int lexi_compare_int16(const void *, const void *);
int lexi_compare_int32(const void *, const void *);
int lexi_compare_int64(const void *, const void *);
int lexi_compare_single(const void *, const void *);
int lexi_compare_double(const void *, const void *);

#endif

