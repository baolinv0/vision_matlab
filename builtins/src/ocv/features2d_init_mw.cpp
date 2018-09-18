/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                          License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#include "precomp_f2d_mw.hpp"
#include "fast_score_mw.hpp" // defines FastFeatureDetector2MW
#include "features2d_other_mw.hpp"

//using namespace cv;
namespace cv
{
    
using std::string;
/*    
#ifdef COMPILE_FOR_VISION_BUILTINS
Ptr<Feature2D> Feature2D::create( const std::string& feature2DType )
{
    return Algorithm::create<Feature2D>("Feature2D." + feature2DType);
}
#endif
*/

/////////////////////// AlgorithmInfo for various detector & descriptors ////////////////////////////

/* NOTE!!!
   All the AlgorithmInfo-related stuff should be in the same file as initModule_features2d().
   Otherwise, linker may throw away some seemingly unused stuff.
*/

/*
CV_INIT_ALGORITHM(MWBRISK, "Feature2D.MWBRISK",
                   obj.info()->addParam(obj, "thres", obj.threshold);
                   obj.info()->addParam(obj, "octaves", obj.octaves);
                   obj.info()->addParam(obj, "upright", obj.upright))

CV_INIT_ALGORITHM(FastFeatureDetector, "Feature2D.FAST",
                  obj.info()->addParam(obj, "threshold", obj.threshold);
                  obj.info()->addParam(obj, "nonmaxSuppression", obj.nonmaxSuppression))

CV_INIT_ALGORITHM(FastFeatureDetector2MW, "Feature2D.FASTX",
                  obj.info()->addParam(obj, "threshold", obj.threshold);
                  obj.info()->addParam(obj, "nonmaxSuppression", obj.nonmaxSuppression);
                  obj.info()->addParam(obj, "type", obj.type))
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
bool initModule_features2dMW(void)
{
	bool all = true;
	//all &= !BriefDescriptorExtractor_info_auto.name().empty();
	all &= !MWBRISK_info_auto.name().empty();
	all &= !FastFeatureDetector_info_auto.name().empty();
	all &= !FastFeatureDetector2MW_info_auto.name().empty();
	
    //all &= !StarDetector_info_auto.name().empty();
	//all &= !MSER_info_auto.name().empty();
	//all &= !FREAK_info_auto.name().empty();
	//all &= !ORB_info_auto.name().empty();
	//all &= !GFTTDetector_info_auto.name().empty();
	//all &= !HarrisDetector_info_auto.name().empty();
	//all &= !DenseFeatureDetector_info_auto.name().empty();
	//all &= !GridAdaptedFeatureDetector_info_auto.name().empty();
	//all &= !BFMatcher_info_auto.name().empty();
	//all &= !FlannBasedMatcher_info_auto.name().empty();
	
	return all;
}
*/
}