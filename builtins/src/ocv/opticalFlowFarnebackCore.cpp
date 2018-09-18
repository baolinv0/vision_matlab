//////////////////////////////////////////////////////////////////////////////
// OpenCV wrapper for Farneback algorithm for optical flow estimation  
//
// Copyright 2015 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
#include "opencv2/opencv.hpp"

#include "opticalFlowFarnebackCore_api.hpp"
#include "cgCommon.hpp"

using namespace cv;
using namespace std;


//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV calcOpticalFlowFarneback
//////////////////////////////////////////////////////////////////////////////

void opticalFlowFarneback_compute(uint8_T *inImgPrev, uint8_T *inImgCurr,
    float *inFlowXY, float *outFlowXY,
    cvstFarnebackStruct_T *params,
    int32_T nRows, int32_T nCols)
{
    cv::Mat imgPrev = cv::Mat(nRows, (int)nCols, CV_8UC1, inImgPrev);
    cv::Mat imgCurr = cv::Mat(nRows, (int)nCols, CV_8UC1, inImgCurr);

    cv::Mat inflowXYmat = cv::Mat(nRows, (int)nCols, CV_32FC2);

    // Call OpenCV Farneback algorithm
    cv::calcOpticalFlowFarneback(imgPrev, imgCurr, inflowXYmat,
        params->pyr_scale, params->levels, params->winsize,
        params->iterations, params->poly_n, params->poly_sigma,
        params->flags);

    // copy to output
    cArrayFromMat<real32_T>(outFlowXY, inflowXYmat);
}

void opticalFlowFarneback_computeRM(uint8_T *inImgPrev, uint8_T *inImgCurr,
	float *inFlowXY, float *outFlowXY,
	cvstFarnebackStruct_T *params,
	int32_T nRows, int32_T nCols)
{
	cv::Mat imgPrev = cv::Mat(nRows, (int)nCols, CV_8UC1, inImgPrev);
	cv::Mat imgCurr = cv::Mat(nRows, (int)nCols, CV_8UC1, inImgCurr);

	cv::Mat inflowXYmat = cv::Mat(nRows, (int)nCols, CV_32FC2);

	// Call OpenCV Farneback algorithm
	cv::calcOpticalFlowFarneback(imgPrev, imgCurr, inflowXYmat,
		params->pyr_scale, params->levels, params->winsize,
		params->iterations, params->poly_n, params->poly_sigma,
		params->flags);

	// copy to output
	cArrayFromMat_RowMaj<real32_T>(outFlowXY, inflowXYmat);
}

#endif