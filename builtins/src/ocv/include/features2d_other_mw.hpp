/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
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

#ifndef __OPENCV_FEATURES_2D_OTHER_HPP__
#define __OPENCV_FEATURES_2D_OTHER_HPP__

#include "opencv2/core.hpp"
#include "opencv2/flann/miniflann.hpp"
#include "opencv2/features2d.hpp" // for Feature2D

#include <string>

#ifdef __cplusplus
#include <limits>

namespace cv
{

using std::vector;
    
void makeAgastOffsets(int pixel[16], int row_stride, int type);

template<int type>
int agast_cornerScore(const uchar* ptr, const int pixel[], int threshold);

/*!
  MWBRISK implementation
*/

/** @brief Class implementing the BRISK keypoint detector and descriptor extractor, described in @cite LCS11 .
 */
class CV_EXPORTS_W MWBRISK : public Feature2D
{
public:
    /** @brief The BRISK constructor
    @param thresh AGAST detection threshold score.
    @param octaves detection octaves. Use 0 to do single scale.
    @param patternScale apply this scale to the pattern used for sampling the neighbourhood of a
    keypoint.
     */
    CV_WRAP static Ptr<MWBRISK> create(int thresh=30, int octaves=3, float patternScale=1.0f);

    /** @brief The BRISK constructor for a custom pattern
    @param radiusList defines the radii (in pixels) where the samples around a keypoint are taken (for
    keypoint scale 1).
    @param numberList defines the number of sampling points on the sampling circle. Must be the same
    size as radiusList..
    @param dMax threshold for the short pairings used for descriptor formation (in pixels for keypoint
    scale 1).
    @param dMin threshold for the long pairings used for orientation determination (in pixels for
    keypoint scale 1).
    @param indexChange index remapping of the bits. */
    CV_WRAP static Ptr<MWBRISK> create(const std::vector<float> &radiusList, const std::vector<int> &numberList,
        float dMax=5.85f, float dMin=8.2f, const std::vector<int>& indexChange=std::vector<int>());
    
    // TMW Edit: virtual methods, implemented in MWBRISK_Impl modify upright.
    CV_WRAP virtual void setUpright( bool) = 0;
    
};
#endif /* __cplusplus */
}
#endif

/* End of file. */
