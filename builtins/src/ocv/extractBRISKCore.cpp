//////////////////////////////////////////////////////////////////////////////
// OpenCV BRISK detector wrapper
//
// Copyright 2010-2016 The MathWorks, Inc.
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
// vision_builtins does not need this source file

#include "extractBRISKCore_api.hpp"
#include "features2d_other_mw.hpp"

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

////////////////////////////////////////////////////////////////////////////////
// struct to keypoints - convert keypoint struct from M to cv::KeyPoints
////////////////////////////////////////////////////////////////////////////////
void structToBRISKKeyPoints(const real32_T * location, const real32_T * metric,
                            const real32_T * scale, const real32_T * orientation,
                            const int32_T * misc, const int32_T numKeyPoints,
                            std::vector<cv::KeyPoint> & keypoints)
{
    keypoints.reserve(numKeyPoints);
    const int32_T octave = 0;
    for (int32_T i = 0; i < numKeyPoints; ++i)
    {
        keypoints.push_back(cv::KeyPoint(location[i] - 1.0f,
                                         location[i+numKeyPoints] - 1.0f,
                                         scale[i], orientation[i], metric[i],
                                         octave, misc[i]));
    }
}

void structToBRISKKeyPointsRM(const real32_T * location, const real32_T * metric,
	const real32_T * scale, const real32_T * orientation,
	const int32_T * misc, const int32_T numKeyPoints,
	std::vector<cv::KeyPoint> & keypoints)
{
	keypoints.reserve(numKeyPoints);
	const int32_T octave = 0;
	int k = 0;
	for (int32_T i = 0; i < numKeyPoints; ++i)
	{
		real32_T x1 = location[k++];
		real32_T y1 = location[k++];
		keypoints.push_back(cv::KeyPoint(x1 - 1.0f,
			y1 - 1.0f,
			scale[i], orientation[i], metric[i],
			octave, misc[i]));
	}
}
////////////////////////////////////////////////////////////////////////////////
// keypoints to struct - return keypoint struct to M after extracting features
////////////////////////////////////////////////////////////////////////////////
void briskKeyPointsToStruct(const std::vector<cv::KeyPoint> & keypoints,
                            real32_T * location,  real32_T * metric,
                            real32_T * scale,  real32_T * orientation,
                            int32_T * misc)
{
    const real32_T piOver180 = (real32_T)(CV_PI/180.0f);
    const int num = (int)keypoints.size();
    for (int32_T i = 0; i < num; ++i)
    {
        location[i]     = keypoints[i].pt.x + 1;
        location[i+num] = keypoints[i].pt.y + 1;
        metric[i]       = keypoints[i].response;
        scale[i]        = keypoints[i].size;
        orientation[i]  = keypoints[i].angle * piOver180;
        misc[i]         = keypoints[i].class_id;  // for determining valid points
    }
}

void briskKeyPointsToStructRM(const std::vector<cv::KeyPoint> & keypoints,
	real32_T * location, real32_T * metric,
	real32_T * scale, real32_T * orientation,
	int32_T * misc)
{
	const real32_T piOver180 = (real32_T)(CV_PI / 180.0f);
	const int num = (int)keypoints.size();
	int k = 0;
	for (int32_T i = 0; i < num; ++i)
	{
		location[k++] = keypoints[i].pt.x + 1;
		location[k++] = keypoints[i].pt.y + 1;
		metric[i] = keypoints[i].response;
		scale[i] = keypoints[i].size;
		orientation[i] = keypoints[i].angle * piOver180;
		misc[i] = keypoints[i].class_id;  // for determining valid points
	}
}
////////////////////////////////////////////////////////////////////////////////
// Invoke BRISK compute method to extract BRISK Features
////////////////////////////////////////////////////////////////////////////////
int32_T extractBRISK_compute(const uint8_T * img, const int32_T nRows, const int32_T nCols,
                             real32_T * location, real32_T * metric,
                             real32_T * scale, real32_T * orientation, int32_T * misc,
                             const int32_T numKeyPoints, const boolean_T upright,
                             void ** features, void ** keypoints)
{

    using namespace cv;
    using namespace std;

	const bool isRGB = false; // only grayscale images are supported for BRISK

    Ptr<Mat> mat = new Mat;
    cArrayToMat<uint8_T>(img, nRows, nCols, isRGB, *mat);

    // create KeyPoint vector
    vector<KeyPoint> * keypointPtr = new vector<KeyPoint>();
    *keypoints = (void *)keypointPtr;

    // copy keypoint data
    structToBRISKKeyPoints(location, metric, scale, orientation, misc,
                           numKeyPoints,*keypointPtr);

	// construct BRISK object.
	Ptr<MWBRISK> brisk = cv::MWBRISK::create();
  // To avoid C4800 on MSVC: make bool != 0 to force bool type.
    brisk->setUpright(upright != 0);

    if(brisk.empty()) {
        CV_Error(CV_StsNotImplemented, "OpenCV was built without BRISK support");
    }

    Mat * descriptors = new Mat();
    *features = (void *)descriptors;
    brisk->compute(*mat, *keypointPtr, *descriptors);

    return static_cast<int32_T>(keypointPtr->size());
}

int32_T extractBRISK_computeRM(const uint8_T * img, const int32_T nRows, const int32_T nCols,
	real32_T * location, real32_T * metric,
	real32_T * scale, real32_T * orientation, int32_T * misc,
	const int32_T numKeyPoints, const boolean_T upright,
	void ** features, void ** keypoints)
{

	using namespace cv;
	using namespace std;

	const bool isRGB = false; // only grayscale images are supported for BRISK

	Ptr<Mat> mat = new Mat;
	cArrayToMat_RowMaj<uint8_T>(img, nRows, nCols, isRGB, *mat);

	// create KeyPoint vector
	vector<KeyPoint> * keypointPtr = new vector<KeyPoint>();
	*keypoints = (void *)keypointPtr;

	// copy keypoint data
	structToBRISKKeyPointsRM(location, metric, scale, orientation, misc,
		numKeyPoints, *keypointPtr);

	// construct BRISK object.
	Ptr<MWBRISK> brisk = cv::MWBRISK::create();
	// To avoid C4800 on MSVC: make bool != 0 to force bool type.
	brisk->setUpright(upright != 0);

	if (brisk.empty()) {
		CV_Error(CV_StsNotImplemented, "OpenCV was built without BRISK support");
	}

	Mat * descriptors = new Mat();
	*features = (void *)descriptors;
	brisk->compute(*mat, *keypointPtr, *descriptors);

	return static_cast<int32_T>(keypointPtr->size());
}

////////////////////////////////////////////////////////////////////////////////
// Copy data
////////////////////////////////////////////////////////////////////////////////
void extractBRISK_assignOutput(void *ptrDescriptors, void *ptrKeyPoints,
                               real32_T * location, real32_T * metric,
                               real32_T * scale, real32_T * orientation,
                               int32_T * misc, uint8_T * features)
{

    // copy feature data
    const cv::Mat & descriptors = *((cv::Mat *)ptrDescriptors);
    cArrayFromMat<uint8_T>(features, descriptors);

    // copy key point data
    const std::vector<cv::KeyPoint> & keypoints = *((std::vector<cv::KeyPoint> *)ptrKeyPoints);
    briskKeyPointsToStruct(keypoints, location, metric, scale, orientation, misc);

    // free memory
    delete((std::vector<cv::KeyPoint> *)ptrKeyPoints);
    delete((cv::Mat *)ptrDescriptors);

}

void extractBRISK_assignOutputRM(void *ptrDescriptors, void *ptrKeyPoints,
	real32_T * location, real32_T * metric,
	real32_T * scale, real32_T * orientation,
	int32_T * misc, uint8_T * features)
{

	// copy feature data
	const cv::Mat & descriptors = *((cv::Mat *)ptrDescriptors);
	cArrayFromMat_RowMaj<uint8_T>(features, descriptors);

	// copy key point data
	const std::vector<cv::KeyPoint> & keypoints = *((std::vector<cv::KeyPoint> *)ptrKeyPoints);
	briskKeyPointsToStructRM(keypoints, location, metric, scale, orientation, misc);

	// free memory
	delete((std::vector<cv::KeyPoint> *)ptrKeyPoints);
	delete((cv::Mat *)ptrDescriptors);

}

#endif
