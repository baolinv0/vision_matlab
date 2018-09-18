//////////////////////////////////////////////////////////////////////////////
// OpenCV FAST detector wrapper 
//
// Copyright 2010-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
// vision_builtins doe not need this source file

#include "detectFASTCore_api.hpp"

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
void fastKeyPointToFields(vector<KeyPoint> &keypoints,
    real32_T *points, real32_T *metric)
{
    size_t m = keypoints.size();

    for(size_t i = 0; i < m; i++ ) {
        cv::KeyPoint& kp = keypoints[i];
        points[i]     = kp.pt.x+1;     // Convert to MATLAB's 1 based indexing
        points[m+i]   = kp.pt.y+1;
        metric[i]     = kp.response;   // Copy corner metric
    }
}

void fastKeyPointToFieldsRM(vector<KeyPoint> &keypoints,
	real32_T *points, real32_T *metric)
{
	size_t m = keypoints.size();

	for (size_t i = 0; i < m; i++) {
		cv::KeyPoint& kp = keypoints[i];
		*points++ = kp.pt.x + 1;     // Convert to MATLAB's 1 based indexing
		*points++ = kp.pt.y + 1;
		metric[i] = kp.response;   // Copy corner metric
	}
}
//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvDetectFAST
//////////////////////////////////////////////////////////////////////////////

int32_T detectFAST_compute(uint8_T *inImg, 
    int32_T nRows, int32_T nCols, int32_T isRGB, 
    int threshold,
    void **outKeypoints)
{
    // Use OpenCV smart pointer to manage image 
    cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (bool)(isRGB != 0);
	cArrayToMat<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

    // keypoints
    vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
    *outKeypoints = ptrKeypoints;
    vector<KeyPoint> &refKeypoints = *ptrKeypoints;

    try
    {
        cv::FAST(*inImage, refKeypoints, threshold);
    }
    catch (...)
    {
        CV_Error(CV_StsNotImplemented, "OpenCV was built without FAST support");
    }

    return ((int32_T)(refKeypoints.size())); //actual_numel
}

int32_T detectFAST_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB,
	int threshold,
	void **outKeypoints)
{
	// Use OpenCV smart pointer to manage image 
	cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (bool)(isRGB != 0);
	cArrayToMat_RowMaj<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

	// keypoints
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoints = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;

	try
	{
		cv::FAST(*inImage, refKeypoints, threshold);
	}
	catch (...)
	{
		CV_Error(CV_StsNotImplemented, "OpenCV was built without FAST support");
	}

	return ((int32_T)(refKeypoints.size())); //actual_numel
}

void detectFAST_assignOutput(void *ptrKeypoints,
    real32_T *outLoc, real32_T *outMetric)
{
    vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];

    // Populate the outputs
    fastKeyPointToFields(keypoints, outLoc, outMetric);

    delete((vector<KeyPoint> *)ptrKeypoints);
}

void detectFAST_assignOutputRM(void *ptrKeypoints,
	real32_T *outLoc, real32_T *outMetric)
{
	vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];

	// Populate the outputs
	fastKeyPointToFieldsRM(keypoints, outLoc, outMetric);

	delete((vector<KeyPoint> *)ptrKeypoints);
}

#endif