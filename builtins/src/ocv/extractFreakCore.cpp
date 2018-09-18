//////////////////////////////////////////////////////////////////////////////
// OpenCV FREAK extractor wrapper
//
// Copyright 2010-2016 The MathWorks, Inc.
//
//////////////////////////////////////////////////////////////////////////////
#ifndef COMPILE_FOR_VISION_BUILTINS
#include "extractFreakCore_api.hpp"
#include "mwfreak.hpp" // for MWFREAK

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

// common defines
#define SURF_SIZE_TO_SCALE_FACTOR (1.2f/9.0f)

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
template <typename T_MiscOrSignOfLap> // int8_T (=char) or int32_T
void keyPointsToFields_freak(vector<KeyPoint> &in, bool isOrientationIncluded, bool isSurf,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	T_MiscOrSignOfLap *outMiscOrSignOfLap, real32_T *outOrientation)
{
	const mwSize m = in.size();

	//Allocate individual fields of the structure
	//////////////////////////////////////////////

	// point [x;y]
	float  *points = (float *)outLoc;
	// size
	float  *scale = (float *)outScale;
	// hessian (float)
	float  *hessian = (float *)outMetric;
	// laplacian
	T_MiscOrSignOfLap *laplacian = (T_MiscOrSignOfLap *)outMiscOrSignOfLap;

	// orientation
	float *dir(0);
	if(isOrientationIncluded)
	{
		// dir (float)
		dir = (float *)outOrientation;
	}

	if (m > 0)
	{
		float deg2rad = (float)(CV_PI/180.0);
		for(mwSize i = 0; i < m; i++ )
		{
			// OpenCV point info
			points[i]     = in[i].pt.x+1;     // Convert to MATLAB's 1 based indexing
			points[m+i]   = in[i].pt.y+1;
			scale[i]      = isSurf ? in[i].size*SURF_SIZE_TO_SCALE_FACTOR : in[i].size; // convert to FREAK's scale
			hessian[i]    = in[i].response;  // hessian (float)
			laplacian[i]  = in[i].class_id;  // laplacian

			if(isOrientationIncluded)       // dir
			{
				// convert OpenCV's degrees to radians
				dir[i] = in[i].angle * deg2rad;
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
template <typename T_MiscOrSignOfLap> // int8_T (=char) or int32_T
void keyPointsToFields_freakRM(vector<KeyPoint> &in, bool isOrientationIncluded, bool isSurf,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	T_MiscOrSignOfLap *outMiscOrSignOfLap, real32_T *outOrientation)
{
	const mwSize m = in.size();

	//Allocate individual fields of the structure
	//////////////////////////////////////////////

	// point [x;y]
	float  *points = (float *)outLoc;
	// size
	float  *scale = (float *)outScale;
	// hessian (float)
	float  *hessian = (float *)outMetric;
	// laplacian
	T_MiscOrSignOfLap *laplacian = (T_MiscOrSignOfLap *)outMiscOrSignOfLap;

	// orientation
	float *dir(0);
	if (isOrientationIncluded)
	{
		// dir (float)
		dir = (float *)outOrientation;
	}

	if (m > 0)
	{
		float deg2rad = (float)(CV_PI / 180.0);
		int k = 0;
		for (mwSize i = 0; i < m; i++)
		{
			// OpenCV point info
			points[k++] = in[i].pt.x + 1;     // Convert to MATLAB's 1 based indexing
			points[k++] = in[i].pt.y + 1;
			scale[i] = isSurf ? in[i].size*SURF_SIZE_TO_SCALE_FACTOR : in[i].size; // convert to FREAK's scale
			hessian[i] = in[i].response;  // hessian (float)
			laplacian[i] = in[i].class_id;  // laplacian

			if (isOrientationIncluded)       // dir
			{
				// convert OpenCV's degrees to radians
				dir[i] = in[i].angle * deg2rad;
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

template <typename T_MiscOrSignOfLap> // int8_T (=char) or int32_T
void struct2KeyPoints(real32_T *inLoc, real32_T *inScale, real32_T *inMetric,
	T_MiscOrSignOfLap *inMiscOrSignOfLap,
	vector<KeyPoint> &keypoints, int_T numel, boolean_T isSurf)
{
	// get pointers to all the fields
	float *pt        = (float *)inLoc;
	float *scale     = (float *)inScale;
	float *hessian   = (float *)inMetric;
	T_MiscOrSignOfLap *laplacian = (T_MiscOrSignOfLap *)inMiscOrSignOfLap;

	for (mwSize i=0; i< (mwSize)numel; i++)
	{
		// convert points back to 0 based indexing
		float x(pt[i]-1.0f),y(pt[numel+i]-1.0f);

		// orientation is always 0 until this extractor determines it
		float dir(0);

		// convert back from scale to the units used by OpenCV
		float size = isSurf? cvRound(scale[i]/SURF_SIZE_TO_SCALE_FACTOR) : scale[i];

		// OpenCV will error out when size <= 0 (makes sense)
		bool isValidPoint = (size >= 0.0f);

		int octave(0);

		if (isValidPoint)
		{
			cv::KeyPoint kpt(x, y, (float)size, dir, hessian[i], octave, laplacian[i]);
			keypoints.push_back(kpt);
		}
	}
}

template <typename T_MiscOrSignOfLap> // int8_T (=char) or int32_T
void struct2KeyPointsRM(real32_T *inLoc, real32_T *inScale, real32_T *inMetric,
	T_MiscOrSignOfLap *inMiscOrSignOfLap,
	vector<KeyPoint> &keypoints, int_T numel, boolean_T isSurf)
{
	// get pointers to all the fields
	float *pt = (float *)inLoc;
	float *scale = (float *)inScale;
	float *hessian = (float *)inMetric;
	T_MiscOrSignOfLap *laplacian = (T_MiscOrSignOfLap *)inMiscOrSignOfLap;

	int k = 0;
	for (mwSize i = 0; i< (mwSize)numel; i++)
	{
		// convert points back to 0 based indexing
		float x(pt[k++] - 1.0f), y(pt[k++] - 1.0f);

		// orientation is always 0 until this extractor determines it
		float dir(0);

		// convert back from scale to the units used by OpenCV
		float size = isSurf ? cvRound(scale[i] / SURF_SIZE_TO_SCALE_FACTOR) : scale[i];

		// OpenCV will error out when size <= 0 (makes sense)
		bool isValidPoint = (size >= 0.0f);

		int octave(0);

		if (isValidPoint)
		{
			cv::KeyPoint kpt(x, y, (float)size, dir, hessian[i], octave, laplacian[i]);
			keypoints.push_back(kpt);
		}
	}
}


//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvExtractFREAK
//////////////////////////////////////////////////////////////////////////////

int32_T extractFreak_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int32_T *inMiscOrSignOfLap,
	int32_T numel, int32_T nbOctave,
	boolean_T orientationNormalized, boolean_T scaleNormalized, real32_T patternScale,
	void **outKeypoints, void **outDescriptors)
{
	cv::Mat img = cv::Mat(nRows, (int)nCols, CV_8UC1, inImg);
	// transpose matrix
	// https://code.ros.org/trac/opencv/ticket/1090
	// cv::transpose(img, img);
	(void)nDims;
	// keypoints
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoints = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;

	struct2KeyPoints<int32_T>(inLoc,inScale,inMetric,inMiscOrSignOfLap,refKeypoints, numel, false);// isSurf = false

	// output
	// Note: OpenCV extractor does not reduce the number of feature points.
	//       It keeps all of them.

	// To avoid C4800 on MSVC: make bool != 0 to force bool type.
	Ptr<MWFREAK> freakExtractor = cv::MWFREAK::create(orientationNormalized  != 0,
                                                      scaleNormalized != 0,
                                                      patternScale,
                                                      nbOctave);

    if( freakExtractor.empty() )
        CV_Error(CV_StsNotImplemented, "OpenCV was built without FREAK support");

	// run the extractor
	cv::Mat *ptrDescriptors = (cv::Mat *)new cv::Mat();
	*outDescriptors = ptrDescriptors;
	cv::Mat &refDescriptors = *ptrDescriptors;
	freakExtractor->compute(img, refKeypoints, refDescriptors);

        // OpenCV Freak returns angles between [-180 180].  This is not correct behavior
        // as documented for OpenCV Keypoints, which should have angle values between
        // 0 and 360.  Apply the correction here so that we can send the correct angle
        // value to MATLAB. If this is not done, conversion to a struct in keyPointsToStruct
        // will force angle values < 0 to 0, and we will loose the orientation information.
        for (size_t i = 0; i < refKeypoints.size(); ++i)
        {
            if (refKeypoints[i].angle < 0)
                refKeypoints[i].angle += 360.f;
        }

	return ((int32_T)(refKeypoints.size())); //actual_numel
}

int32_T extractFreak_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int32_T *inMiscOrSignOfLap,
	int32_T numel, int32_T nbOctave,
	boolean_T orientationNormalized, boolean_T scaleNormalized, real32_T patternScale,
	void **outKeypoints, void **outDescriptors)
{
	cv::Mat img = cv::Mat(nRows, (int)nCols, CV_8UC1, inImg);
	// transpose matrix
	// https://code.ros.org/trac/opencv/ticket/1090
	// cv::transpose(img, img);
	(void)nDims;
	// keypoints
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoints = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;

	struct2KeyPointsRM<int32_T>(inLoc, inScale, inMetric, inMiscOrSignOfLap, refKeypoints, numel, false);// isSurf = false

	// output
	// Note: OpenCV extractor does not reduce the number of feature points.
	//       It keeps all of them.

	// To avoid C4800 on MSVC: make bool != 0 to force bool type.
	Ptr<MWFREAK> freakExtractor = cv::MWFREAK::create(orientationNormalized != 0,
		scaleNormalized != 0,
		patternScale,
		nbOctave);

	if (freakExtractor.empty())
		CV_Error(CV_StsNotImplemented, "OpenCV was built without FREAK support");

	// run the extractor
	cv::Mat *ptrDescriptors = (cv::Mat *)new cv::Mat();
	*outDescriptors = ptrDescriptors;
	cv::Mat &refDescriptors = *ptrDescriptors;
	freakExtractor->compute(img, refKeypoints, refDescriptors);

	// OpenCV Freak returns angles between [-180 180].  This is not correct behavior
	// as documented for OpenCV Keypoints, which should have angle values between
	// 0 and 360.  Apply the correction here so that we can send the correct angle
	// value to MATLAB. If this is not done, conversion to a struct in keyPointsToStruct
	// will force angle values < 0 to 0, and we will loose the orientation information.
	for (size_t i = 0; i < refKeypoints.size(); ++i)
	{
		if (refKeypoints[i].angle < 0)
			refKeypoints[i].angle += 360.f;
	}

	return ((int32_T)(refKeypoints.size())); //actual_numel
}

void extractFreak_assignOutput(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	int32_T *outMiscOrSignOfLap, real32_T *outOrientation, uint8_T *outFeatures)
{
	vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];
	cv::Mat descriptors = ((cv::Mat *)ptrDescriptors)[0];

	// Populate the outputs
	keyPointsToFields_freak<int32_T>(keypoints, true, false, outLoc, outScale,
		outMetric, outMiscOrSignOfLap, outOrientation);
	cArrayFromMat<uint8_T>(outFeatures, descriptors);

	delete((vector<KeyPoint> *)ptrKeypoints);
	delete((cv::Mat *)ptrDescriptors);
}

void extractFreak_assignOutputRM(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	int32_T *outMiscOrSignOfLap, real32_T *outOrientation, uint8_T *outFeatures)
{
	vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];
	cv::Mat descriptors = ((cv::Mat *)ptrDescriptors)[0];

	// Populate the outputs
	keyPointsToFields_freakRM<int32_T>(keypoints, true, false, outLoc, outScale,
		outMetric, outMiscOrSignOfLap, outOrientation);
	cArrayFromMat_RowMaj<uint8_T>(outFeatures, descriptors);

	delete((vector<KeyPoint> *)ptrKeypoints);
	delete((cv::Mat *)ptrDescriptors);
}

#endif
