//////////////////////////////////////////////////////////////////////////////
// OpenCV BRISK detector wrapper 
//
// Copyright 2010-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
// vision_builtins does not need this source file

#include "detectBRISKCore_api.hpp"
#include "features2d_other_mw.hpp"

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

////////////////////////////////////////////////////////////////////////////////
// copy BRISK keyPoints to struct
////////////////////////////////////////////////////////////////////////////////
void briskKeyPointToStruct(std::vector<cv::KeyPoint> &keypoints,
                           real32_T * location,real32_T * metric,
                           real32_T * scale, real32_T * orientation)
{
    size_t m = keypoints.size();

    for(size_t i = 0; i < m; i++ ) {
        const cv::KeyPoint& kp = keypoints[i];
        location[i]    = kp.pt.x+1;     // Convert to 1 based indexing
        location[m+i]  = kp.pt.y+1;
        metric[i]      = kp.response; 
        scale[i]       = kp.size;
        orientation[i] = 0.0F; // detector does not compute angle
    }
}

void briskKeyPointToStructRM(std::vector<cv::KeyPoint> &keypoints,
	real32_T * location, real32_T * metric,
	real32_T * scale, real32_T * orientation)
{
	size_t m = keypoints.size();

	for (size_t i = 0; i < m; i++) {
		const cv::KeyPoint& kp = keypoints[i];
		/* location = Mx2 */
		*location++ = kp.pt.x + 1;     // Convert to 1 based indexing
		*location++ = kp.pt.y + 1;
		metric[i] = kp.response;
		scale[i] = kp.size;
		orientation[i] = 0.0F; // detector does not compute angle
	}
}

////////////////////////////////////////////////////////////////////////////////
// call BRISK::detect, assign keypoints to outKeypoints, and return the number
// detected KeyPoints.
////////////////////////////////////////////////////////////////////////////////
int32_T detectBRISK_detect(uint8_T *img, int nRows, int nCols,
                           int threshold, int numOctaves, void **outKeyPoints)
{

    using namespace cv;

    const bool isRGB = false; // only grayscale images are supported for BRISK
   
    Ptr<Mat> mat = new Mat;
    
    cArrayToMat<uint8_T>(img, nRows, nCols, isRGB, *mat);

    // create keypoint container
    std::vector<KeyPoint> *ptrKeypoints = new std::vector<KeyPoint>();
    *outKeyPoints = (void *)ptrKeypoints;

    float patternScale = 1.0f;
	Ptr<MWBRISK> brisk = cv::MWBRISK::create(threshold, numOctaves, patternScale);

	if (brisk.empty()) {
		CV_Error(CV_StsNotImplemented, "OpenCV was built without BRISK support");
	}

    // detect keypoints
    std::vector<KeyPoint> &refKeypoints = *ptrKeypoints;
    brisk->detect(*mat, refKeypoints, cv::Mat());

    return static_cast<int32_T>(refKeypoints.size());
}

int32_T detectBRISK_detectRM(uint8_T *img, int nRows, int nCols,
	int threshold, int numOctaves, void **outKeyPoints)
{

	using namespace cv;

	const bool isRGB = false; // only grayscale images are supported for BRISK

	Ptr<Mat> mat = new Mat;

	cArrayToMat_RowMaj<uint8_T>(img, nRows, nCols, isRGB, *mat);

	// create keypoint container
	std::vector<KeyPoint> *ptrKeypoints = new std::vector<KeyPoint>();
	*outKeyPoints = (void *)ptrKeypoints;

	// construct BRISK object. Assign to static variable because
	// construction costs are high due to one-time look-up table creation.
	float patternScale = 1.0f;
	static Ptr<MWBRISK> brisk = cv::MWBRISK::create(threshold, numOctaves, patternScale);

	if (brisk.empty()) {
		CV_Error(CV_StsNotImplemented, "OpenCV was built without BRISK support");
	}

	// detect keypoints
	std::vector<KeyPoint> &refKeypoints = *ptrKeypoints;
	brisk->detect(*mat, refKeypoints, cv::Mat());

	return static_cast<int32_T>(refKeypoints.size());
}

////////////////////////////////////////////////////////////////////////////////
// Copy keypoints to struct and delete keypoint data 
////////////////////////////////////////////////////////////////////////////////
void detectBRISK_assignOutputs(void *ptrKeypoints,
                               real32_T * location,real32_T * metric,
                               real32_T * scale, real32_T * orientation)
{
    
    // Populate the outputs
    briskKeyPointToStruct(*((std::vector<cv::KeyPoint> *)ptrKeypoints),
                          location, metric, scale, orientation);
    
    delete((std::vector<cv::KeyPoint> *)ptrKeypoints);
}

void detectBRISK_assignOutputsRM(void *ptrKeypoints,
	real32_T * location, real32_T * metric,
	real32_T * scale, real32_T * orientation)
{

	// Populate the outputs
	briskKeyPointToStructRM(*((std::vector<cv::KeyPoint> *)ptrKeypoints),
		location, metric, scale, orientation);

	delete((std::vector<cv::KeyPoint> *)ptrKeypoints);
}
#endif