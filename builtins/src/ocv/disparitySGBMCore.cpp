//////////////////////////////////////////////////////////////////////////////
// OpenCV StereoBM function 
//
// Copyright 2010-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
#include "disparitySGBMCore_api.hpp"

#include "opencv2/opencv.hpp"

#include "disparityBM.hpp"

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvDisparitySGBM
//////////////////////////////////////////////////////////////////////////////

void disparitySGBM_compute(const uint8_T* inImg1, const uint8_T* inImg2, 
    int nRows, int nCols, real32_T* dis, cvstDSGBMStruct_T *params)
{
    uchar* image1    = (uchar*)inImg1;
    uchar* image2    = (uchar*)inImg2;
    mwSize numRows   = (mwSize)nRows;
    mwSize numInCols = (mwSize)nCols;

    // OpenCV requires the number of column to be divisible by 4, in order to 
    // use fast computation. So, if the input image does not meet this 
    // requirement, extra columns are padded to the image.
    mwSize numCols = numInCols;
    mwSize numColsDivBy4 = numInCols / 4;
    if(numCols > numColsDivBy4 * 4)
    {
        numCols = (numColsDivBy4 + 1) * 4;
    }

    // Allocate buffer to be used in OpenCV and transpose the image from
    // column major to row major.
    cv::Mat mat1((int)numRows, (int)numCols, CV_8UC1);
    transposeAndPad(image1, mat1.data, numRows, numInCols, numRows, numCols, numRows);

    cv::Mat mat2((int)numRows, (int)numCols, CV_8UC1);
    transposeAndPad(image2, mat2.data, numRows, numInCols, numRows, numCols, numRows);

    cv::Mat matTemp;
    
    cv::Mat matOut((int)numRows, (int)numCols, CV_32FC1);
    real32_T* outData = (real32_T *)matOut.data;

    int preFilterCap = (int)params->preFilterCap;
    int SADWindowSize = (int)params->SADWindowSize;
    int minDisparity = (int)params->minDisparity;
    int numberOfDisparities = (int)params->numberOfDisparities;
    int uniquenessRatio = (int)params->uniquenessRatio;
    int disp12MaxDiff = (int)params->disp12MaxDiff;
    int speckleWindowSize = (int)params->speckleWindowSize;
    int speckleRange = (int)params->speckleRange;
    int P1 = (int)params->P1;    
    int P2 = (int)params->P2;
    
	cv::Ptr<cv::StereoSGBM> sgbm = cv::StereoSGBM::create(minDisparity, numberOfDisparities, SADWindowSize, 
                                                          P1, P2, disp12MaxDiff, preFilterCap, uniquenessRatio,
                                                          speckleWindowSize, speckleRange);    
    
    // Invoke StereoSGBM function in OpenCV
    sgbm->compute(mat1, mat2, matTemp);
    
    // For class support, int becomes float
    matTemp.convertTo(matOut, CV_32FC1, 1/16.);

    // Transpose the image from row major to column major and clip
    // it if the image was padded earlier.
    real32_T invalidValue = (real32_T)(sgbm->getMinDisparity() - 1);
    mwSize borderWidth = 0;
    transposeAndClip(outData, dis, numInCols, numRows, numInCols, numRows, 
        numCols, invalidValue, borderWidth);
}

void disparitySGBM_computeRM(const uint8_T* inImg1, const uint8_T* inImg2,
	int nRows, int nCols, real32_T* dis, cvstDSGBMStruct_T *params)
{
	uchar* image1 = (uchar*)inImg1;
	uchar* image2 = (uchar*)inImg2;
	mwSize numRows = (mwSize)nRows;
	mwSize numInCols = (mwSize)nCols;

	// OpenCV requires the number of column to be divisible by 4, in order to 
	// use fast computation. So, if the input image does not meet this 
	// requirement, extra columns are padded to the image.
	mwSize numCols = numInCols;
	mwSize numColsDivBy4 = numInCols / 4;
	if (numCols > numColsDivBy4 * 4)
	{
		numCols = (numColsDivBy4 + 1) * 4;
	}

	// Allocate buffer to be used in OpenCV and transpose the image from
	// column major to row major.
	cv::Mat mat1((int)numRows, (int)numCols, CV_8UC1);
	copyAndPadRM(image1, mat1.data, numRows, numInCols, numRows, numCols, numRows);

	cv::Mat mat2((int)numRows, (int)numCols, CV_8UC1);
	copyAndPadRM(image2, mat2.data, numRows, numInCols, numRows, numCols, numRows);

	cv::Mat matTemp;

	cv::Mat matOut((int)numRows, (int)numCols, CV_32FC1);
	real32_T* outData = (real32_T *)matOut.data;

	int preFilterCap = (int)params->preFilterCap;
	int SADWindowSize = (int)params->SADWindowSize;
	int minDisparity = (int)params->minDisparity;
	int numberOfDisparities = (int)params->numberOfDisparities;
	int uniquenessRatio = (int)params->uniquenessRatio;
	int disp12MaxDiff = (int)params->disp12MaxDiff;
	int speckleWindowSize = (int)params->speckleWindowSize;
	int speckleRange = (int)params->speckleRange;
	int P1 = (int)params->P1;
	int P2 = (int)params->P2;

	cv::Ptr<cv::StereoSGBM> sgbm = cv::StereoSGBM::create(minDisparity, numberOfDisparities, SADWindowSize,
		P1, P2, disp12MaxDiff, preFilterCap, uniquenessRatio,
		speckleWindowSize, speckleRange);

	// Invoke StereoSGBM function in OpenCV
	sgbm->compute(mat1, mat2, matTemp);

	// For class support, int becomes float
	matTemp.convertTo(matOut, CV_32FC1, 1 / 16.);

	// Transpose the image from row major to column major and clip
	// it if the image was padded earlier.
	real32_T invalidValue = (real32_T)(sgbm->getMinDisparity() - 1);
	mwSize borderWidth = 0;
	copyAndClipRM(outData, dis, numInCols, numRows, numInCols, numRows,
		numCols, invalidValue, borderWidth);
}

#endif


