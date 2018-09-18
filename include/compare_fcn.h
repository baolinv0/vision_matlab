/*
 * Copyright 1984-2008 The MathWorks, Inc.
 */

/*
 * This file contains the function body for a lexicographic comparison function
 * suitable for use with the standard C library function qsort().  To
 * instantiate this function, define TYPE to be the desired data type
 * and then #include this file.  Optionally, you can define DO_NAN_CHECK,
 * in which case additional checks are performed to guarantee that
 * NaN's are considered to be equal to each other, and that they are sorted 
 * greater than all other values, including +Inf.
 *
 * The two input void pointers to this function must be castable to valid
 * sort_item pointers.
 *
 * See compare_fcn.c for instantiations of this function.
 *
 * See lexicmp.h for the definition of sort_item.
 */
(const void *ptr1, const void *ptr2)
{
    const sort_item *item1;
    const sort_item *item2;
    TYPE *s1;
    TYPE *s2;
    int length1;
    int length2;
    int shorter_length;
    boolean_T same_length;
    int stride1;
    int stride2;
    int k = 0;
    
    item1 = (const sort_item *) ptr1;
    item2 = (const sort_item *) ptr2;
    
    s1 = (TYPE *) item1->data;
    s2 = (TYPE *) item2->data;
    
    length1 = item1->length;
    length2 = item2->length;
    
    stride1 = item1->stride;
    stride2 = item2->stride;
    
    shorter_length = (length1 < length2) ? length1 : length2;
    same_length = (boolean_T)(length1 == length2);

    /*
     * Loop until we find elements that differ, or until we get to
     * the end of the shorter item.
     */
    while (k < shorter_length)
    {
            if (*s1 == *s2)
            {
                s1 += stride1;
                s2 += stride2;
                k++;
            }
            else
            {
                /*
                 * s1 and s2 differ
                 */
                return(*s1 > *s2 ? S1_IS_GREATER : S2_IS_GREATER);
            }
    }
    
    if (same_length)
    {
        /*
         * Two items are the same.  Use the tiebreaker if provided;
         * otherwise return equal.
         * use index value as tiebreaker
         * to achieve a stable sort.
         */
        if (item1->tiebreak_fcn != NULL)
        {
            return((*item1->tiebreak_fcn)(ptr1, ptr2));
        }
        else
        {
            return(S1_S2_ARE_EQUAL);
        }
    }
    else
    {
        /*
         * Two items are the same up the shorter length; make the
         * longer item sort higher.
         */
        return(length1 > length2 ? S1_IS_GREATER : S2_IS_GREATER);
    }
}

#undef TYPE

