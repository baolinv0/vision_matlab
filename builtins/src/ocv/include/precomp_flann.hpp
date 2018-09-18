#ifndef _OPENCV_MWFLANN_PRECOMP_HPP_
#define _OPENCV_MWFLANN_PRECOMP_HPP_

#include <cstdio>
#include <cstdarg>
#include <sstream>

#ifdef COMPILE_FOR_VISION_BUILTINS
/* codegen does not need the following header */
#include "cvconfig.h"
#endif
#include "opencv2/core.hpp"

#include "flann/miniflann.hpp"
#include "flann/dist.h"
#include "flann/index_testing.h"
#include "flann/params.h"
#include "flann/saving.h"
#include "flann/general.h"
#include "flann/dummy.h"

// index types
#include "flann/all_indices.h"
#include "flann/flann_base.hpp"

#endif
