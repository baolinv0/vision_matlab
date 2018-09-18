//////////////////////////////////////////////////////////////////////////////
// OpenCV HOGDescriptor wrapper 
//
// Copyright 2013-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
#include "HOGDescriptorCore_api.hpp"

#include "precomp_objdetect.hpp"
#include "mwobjdetect.hpp" // for MWHOGDescriptor

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvHOGDescriptor
//////////////////////////////////////////////////////////////////////////////

void HOGDescriptor_detectMultiScale(void *ptrClass, 
    void **ptr2ptrDetectedObj, void **ptr2ptrDetectionScores,
    uint8_T *inImg, int32_T nRows, int32_T nCols, boolean_T isRGB,
    double scaleFactor, double svmThreshold, double mergeThreshold,	
    int32_T *ptrMinSize, int32_T *ptrMaxSize, int32_T *ptrWinStride,
    boolean_T useMeanShiftMerging,
    int32_T *numDetectedObj, int32_T *numDetectionScores)
{       
    cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (isRGB != 0);
    cArrayToMat<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

    cv::Size minSize        = cv::Size((int)ptrMinSize[1], (int)ptrMinSize[0]);
    cv::Size maxSize        = cv::Size((int)ptrMaxSize[1], (int)ptrMaxSize[0]);
    cv::Size winStride      = cv::Size((int)ptrWinStride[0], (int)ptrWinStride[1]);

    // Hard code other algorithm inputs
    cv::Size padding(16,16); // used to pad input prior to gradient computations

    // Define output vectors
    std::vector<cv::Rect> *ptrDetectedObj = (std::vector<cv::Rect> *)new std::vector<cv::Rect>();
    *ptr2ptrDetectedObj = ptrDetectedObj;
    std::vector<cv::Rect> &refDetectedObj = *ptrDetectedObj;

    std::vector<double> *ptrDetectionScores = (std::vector<double> *)new std::vector<double>();
    *ptr2ptrDetectionScores = ptrDetectionScores;
    std::vector<double> &refDetectionScores = *ptrDetectionScores;

    // call OpenCV HOGDescriptor::detectMultiScale
    cv::MWHOGDescriptor *ptrClass_ = (cv::MWHOGDescriptor *)ptrClass;
	bool useMeanShiftMerging_ = (useMeanShiftMerging != 0);
    ptrClass_->detectMultiScale(*inImage, 
        refDetectedObj, refDetectionScores, 
        svmThreshold, winStride, padding, scaleFactor, mergeThreshold, 
        useMeanShiftMerging_, minSize, maxSize);  		

    numDetectedObj[0] = (int32_T)(refDetectedObj.size());
    numDetectionScores[0] = (int32_T)(refDetectionScores.size());
}

void HOGDescriptor_detectMultiScaleRM(void *ptrClass,
	void **ptr2ptrDetectedObj, void **ptr2ptrDetectionScores,
	uint8_T *inImg, int32_T nRows, int32_T nCols, boolean_T isRGB,
	double scaleFactor, double svmThreshold, double mergeThreshold,
	int32_T *ptrMinSize, int32_T *ptrMaxSize, int32_T *ptrWinStride,
	boolean_T useMeanShiftMerging,
	int32_T *numDetectedObj, int32_T *numDetectionScores)
{
	cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (isRGB != 0);
	cArrayToMat_RowMaj<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

	cv::Size minSize = cv::Size((int)ptrMinSize[1], (int)ptrMinSize[0]);
	cv::Size maxSize = cv::Size((int)ptrMaxSize[1], (int)ptrMaxSize[0]);
	cv::Size winStride = cv::Size((int)ptrWinStride[0], (int)ptrWinStride[1]);

	// Hard code other algorithm inputs
	cv::Size padding(16, 16); // used to pad input prior to gradient computations

	// Define output vectors
	std::vector<cv::Rect> *ptrDetectedObj = (std::vector<cv::Rect> *)new std::vector<cv::Rect>();
	*ptr2ptrDetectedObj = ptrDetectedObj;
	std::vector<cv::Rect> &refDetectedObj = *ptrDetectedObj;

	std::vector<double> *ptrDetectionScores = (std::vector<double> *)new std::vector<double>();
	*ptr2ptrDetectionScores = ptrDetectionScores;
	std::vector<double> &refDetectionScores = *ptrDetectionScores;

	// call OpenCV HOGDescriptor::detectMultiScale
	cv::MWHOGDescriptor *ptrClass_ = (cv::MWHOGDescriptor *)ptrClass;
	bool useMeanShiftMerging_ = (useMeanShiftMerging != 0);
	ptrClass_->detectMultiScale(*inImage,
		refDetectedObj, refDetectionScores,
		svmThreshold, winStride, padding, scaleFactor, mergeThreshold,
		useMeanShiftMerging_, minSize, maxSize);

	numDetectedObj[0] = (int32_T)(refDetectedObj.size());
	numDetectionScores[0] = (int32_T)(refDetectionScores.size());
}

void HOGDescriptor_deleteObj(void *ptrClass)
{
    delete((cv::HOGDescriptor *)ptrClass);    
}

///////////////////////////////////////////////////////////////////////////////
// Setup SVM people classifier - this method is called to setup the 
// classification model. 
// 
//    IN0: Input is a scalaMWr uint32. To keep things simple and avoid the need
//         for this internal function to throw errors, any value besides
//         1 selects the Diamler model.          
///////////////////////////////////////////////////////////////////////////////
void HOGDescriptor_setup(void *ptrClass, int whichModel)
{
    cv::HOGDescriptor *obj = (cv::HOGDescriptor *)ptrClass;
    //double whichModel = prhs[0];
    if ((int)whichModel == 1)        
    {
        // uses default HOG parameters
        obj->winSize = cv::Size(64,128);
        obj->setSVMDetector(cv::HOGDescriptor::getDefaultPeopleDetector());    
    }
    else 
    {
        // select Diamler model and adjust window size
        obj->winSize = cv::Size(48,96);
        obj->setSVMDetector(cv::HOGDescriptor::getDaimlerPeopleDetector());
    }  
}

void HOGDescriptor_construct(void **ptr2ptrClass)
{
    cv::HOGDescriptor *ptrClass_ = (cv::HOGDescriptor *)new MWHOGDescriptor();
    *ptr2ptrClass = ptrClass_;
}

void HOGDescriptor_assignOutputDeleteVectors(void *ptrDetectedObj, void *ptrDetectionScores, 
    int32_T *outBBox, double *outScore)
{
    std::vector<cv::Rect> detectedObj   = ((std::vector<cv::Rect> *)ptrDetectedObj)[0];
    std::vector<double> detectionScores = ((std::vector<double> *)ptrDetectionScores)[0];

    cvRectToBoundingBox(detectedObj, outBBox);

    std::copy(detectionScores.begin(),detectionScores.end(), outScore);

    delete((std::vector<cv::Rect> *)ptrDetectedObj);
    delete((std::vector<double> *)ptrDetectionScores);
}

void HOGDescriptor_assignOutputDeleteVectorsRM(void *ptrDetectedObj, void *ptrDetectionScores,
	int32_T *outBBox, double *outScore)
{
	std::vector<cv::Rect> detectedObj = ((std::vector<cv::Rect> *)ptrDetectedObj)[0];
	std::vector<double> detectionScores = ((std::vector<double> *)ptrDetectionScores)[0];

	cvRectToBoundingBoxRowMajor(detectedObj, outBBox);

	std::copy(detectionScores.begin(), detectionScores.end(), outScore);

	delete((std::vector<cv::Rect> *)ptrDetectedObj);
	delete((std::vector<double> *)ptrDetectionScores);
}
#endif
