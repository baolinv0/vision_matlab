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

#include "precomp_mw.hpp"
#include "features2d_surf_mw.hpp" // added MK to get definition of MWSURF

namespace cv
{

///////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
CV_INIT_ALGORITHM(MWSURF, "Feature2D.MWSURF",
                  obj.info()->addParam(obj, "hessianThreshold", obj.hessianThreshold);
                  obj.info()->addParam(obj, "nOctaves", obj.nOctaves);
                  obj.info()->addParam(obj, "nOctaveLayers", obj.nOctaveLayers);
                  obj.info()->addParam(obj, "extended", obj.extended);
                  obj.info()->addParam(obj, "upright", obj.upright))
*/
///////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
bool initModule_mwsurf(void)
{
    //Ptr<Algorithm> sift2 = createSIFT2(), surf = createSURF2();
	Ptr<Algorithm> surf = createMWSURF();
    //return sift2->info() != 0 && surf2->info() != 0;
	return surf->info() != 0;	
}
*/
}
