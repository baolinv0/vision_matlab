////////////////////////////////////////////////////////////////////////////////
//  This header contains assertion macro for ForegroundDetector module
//
////////////////////////////////////////////////////////////////////////////////

#ifndef FOREGROUND_DETECTOR_UTIL_HPP
#define FOREGROUND_DETECTOR_UTIL_HPP

#include <assert.h>
#include <stdio.h>
#include "tmwtypes.h"

#if defined(NDEBUG)
#define VISION_ASSERT(EXPR) (void)0
#else
#define VISION_ASSERT(EXPR) assert(EXPR)
#endif

#if defined(NDEBUG)
#define VISION_ASSERT_MSG(EXPR, MSG) (void)0
#else
#define VISION_ASSERT_MSG(EXPR, MSG)            \
    do {                                        \
        if (! (EXPR)) {                         \
            printf("%s \n",MSG);                \
            assert((EXPR));                     \
        }                                       \
    } while (false)	
#endif
#endif
