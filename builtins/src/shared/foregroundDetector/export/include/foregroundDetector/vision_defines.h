#ifndef vision_defines_h
#define vision_defines_h

/* All symbols in this module are intentionally exported. */

#ifndef __arm__
#include "version.h"
#endif

#if defined(BUILDING_LIBMWFOREGROUNDDETECTOR)
    #define LIBMWFOREGROUNDDETECTOR_API DLL_EXPORT_SYM
#else

#ifdef __arm__
    #define LIBMWFOREGROUNDDETECTOR_API
#else
    #define LIBMWFOREGROUNDDETECTOR_API DLL_IMPORT_SYM
#endif

#endif

#ifndef EXTERN_C
#  ifdef __cplusplus
#    define EXTERN_C extern "C"
#  else
#    define EXTERN_C extern
#  endif
#endif

#ifdef MATLAB_MEX_FILE
    #include "tmwtypes.h" /* mwSize is defined here */
#else
   #include "stddef.h"
   typedef size_t mwSize;  /* unsigned pointer-width integer */

   #include "rtwtypes.h"
#endif

#endif
