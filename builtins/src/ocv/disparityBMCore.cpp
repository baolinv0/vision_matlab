//////////////////////////////////////////////////////////////////////////////
// OpenCV StereoBM function 
//
// Copyright 2010-2017 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
#include "disparityBMCore_api.hpp"

#include "opencv2/opencv.hpp"

#include "disparityBM.hpp"

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvDisparityBM
//////////////////////////////////////////////////////////////////////////////

void disparityBM_compute(const uint8_T* inImg1, const uint8_T* inImg2, 
    int nRows, int nCols, real32_T* dis, cvstDBMStruct_T *params)
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

    cv::Mat matTemp((int)numRows, (int)numCols, CV_16SC1);
    int16_T* outData = (int16_T *)matTemp.data;
    
	static cv::Ptr<cv::StereoBM> bm = cv::StereoBM::create((int)params->numberOfDisparities, (int)params->SADWindowSize);

    bm->setPreFilterCap((int)params->preFilterCap);
    bm->setMinDisparity((int)params->minDisparity);
    bm->setTextureThreshold((int)params->textureThreshold);
    bm->setUniquenessRatio((int)params->uniquenessRatio);
    bm->setDisp12MaxDiff((int)params->disp12MaxDiff);
    bm->setPreFilterType((int)params->preFilterType);
    bm->setPreFilterSize((int)params->preFilterSize);
    bm->setSpeckleWindowSize((int)params->speckleWindowSize);
    bm->setSpeckleRange((int)params->speckleRange);

    // Invoke StereoBM function in OpenCV
	bm->compute(mat1, mat2, matTemp);

    // Transpose the image from row major to column major and clip
    // it if the image was padded earlier.
    int16_T invalidValue = (int16_T)(bm->getMinDisparity() - 1);
    mwSize borderWidth = bm->getBlockSize() / 2;
	transposeClipAndCastBM(outData, dis, numInCols, numRows, numInCols, numRows, 
        numCols, invalidValue, borderWidth);
}


void disparityBM_computeRM(const uint8_T* inImg1, const uint8_T* inImg2,
	int nRows, int nCols, real32_T* dis, cvstDBMStruct_T *params)
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

	cv::Mat matTemp((int)numRows, (int)numCols, CV_16SC1);
	int16_T* outData = (int16_T *)matTemp.data;

	static cv::Ptr<cv::StereoBM> bm = cv::StereoBM::create((int)params->numberOfDisparities, (int)params->SADWindowSize);

	bm->setPreFilterCap((int)params->preFilterCap);
	bm->setMinDisparity((int)params->minDisparity);
	bm->setTextureThreshold((int)params->textureThreshold);
	bm->setUniquenessRatio((int)params->uniquenessRatio);
	bm->setDisp12MaxDiff((int)params->disp12MaxDiff);
	bm->setPreFilterType((int)params->preFilterType);
	bm->setPreFilterSize((int)params->preFilterSize);
	bm->setSpeckleWindowSize((int)params->speckleWindowSize);
	bm->setSpeckleRange((int)params->speckleRange);

	// Invoke StereoBM function in OpenCV
	bm->compute(mat1, mat2, matTemp);

	// Transpose the image from row major to column major and clip
	// it if the image was padded earlier.
	int16_T invalidValue = (int16_T)(bm->getMinDisparity() - 1);
	mwSize borderWidth = bm->getBlockSize() / 2;
	copyClipAndCastBMRM(outData, dis, numInCols, numRows, numInCols, numRows,
		numCols, invalidValue, borderWidth);
}

#endif


