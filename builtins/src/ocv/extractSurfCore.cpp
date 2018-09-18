//////////////////////////////////////////////////////////////////////////////
// OpenCV SURF detector wrapper
//
// Copyright 2010-2016 The MathWorks, Inc.
//
//////////////////////////////////////////////////////////////////////////////
#ifndef COMPILE_FOR_VISION_BUILTINS
#include "opencv2/opencv.hpp"

#include "extractSurfCore_api.hpp"
#include "surfCommon.hpp" // for initModule_mwsurf
#include "cgCommon.hpp"

// common defines
#define SURF_SIZE_TO_SCALE_FACTOR (1.2f/9.0f)

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
void keyPoints2Fields(vector<KeyPoint> &in, bool isOrientationIncluded,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	int8_T *outSignOfLap, real32_T *outOrientation)
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
	char *laplacian = (char *)outSignOfLap;

	// orientation
	float *dir(0);
	if(isOrientationIncluded)
	{
		// dir (float)
		dir = (float *)outOrientation;
	}

	if (m > 0)
	{
		for(mwSize i = 0; i < m; i++ )
		{
			// OpenCV point info
			points[i]     = in[i].pt.x+1;     // Convert to MATLAB's 1 based indexing
			points[m+i]   = in[i].pt.y+1;
			scale[i]      = in[i].size*SURF_SIZE_TO_SCALE_FACTOR; // convert to SURF's scale
			hessian[i]    = in[i].response;  // hessian (float)
			laplacian[i]  = (char)in[i].class_id;  // laplacian

			if(isOrientationIncluded)       // dir
			{
				// convert OpenCV's degrees to radians
				dir[i] = in[i].angle * (float)(CV_PI/180.0);
			}
		}
	}
}

void keyPoints2FieldsRM(vector<KeyPoint> &in, bool isOrientationIncluded,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric,
	int8_T *outSignOfLap, real32_T *outOrientation)
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
	char *laplacian = (char *)outSignOfLap;

	// orientation
	float *dir(0);
	if (isOrientationIncluded)
	{
		// dir (float)
		dir = (float *)outOrientation;
	}

	int k = 0;
	if (m > 0)
	{
		for (mwSize i = 0; i < m; i++)
		{
			// OpenCV point info
			points[k++] = in[i].pt.x + 1;     // Convert to MATLAB's 1 based indexing
			points[k++] = in[i].pt.y + 1;
			scale[i] = in[i].size*SURF_SIZE_TO_SCALE_FACTOR; // convert to SURF's scale
			hessian[i] = in[i].response;  // hessian (float)
			laplacian[i] = (char)in[i].class_id;  // laplacian

			if (isOrientationIncluded)       // dir
			{
				// convert OpenCV's degrees to radians
				dir[i] = in[i].angle * (float)(CV_PI / 180.0);
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
void struct2KeyPoints(real32_T *inLoc, real32_T *inScale,
	real32_T *inMetric, int8_T *inSignOfLap,
	vector<KeyPoint> &keypoints, int_T numel)
{
	// get pointers to all the fields
	float *pt        = (float *)inLoc;
	float *scale     = (float *)inScale;
	float *hessian   = (float *)inMetric;
	char  *laplacian = (char  *)inSignOfLap;

	for (mwSize i=0; i< (mwSize)numel; i++)
	{
		// convert points back to 0 based indexing
		float x(pt[i]-1.0f),y(pt[numel+i]-1.0f);

		// orientation is always 0 until this extractor determines it
		float dir(0);

		// convert back from scale to the units used by OpenCV
		int size = cvRound(scale[i]/SURF_SIZE_TO_SCALE_FACTOR);

		// OpenCV will error out when size <= 0 (makes sense)
		bool isValidPoint = (size >= 0.0f);

		int octave(0);

		if (isValidPoint)
		{
			KeyPoint kpt(x, y, (float)size, dir, hessian[i], octave, laplacian[i]);
			keypoints.push_back(kpt);
		}
	}
}

void struct2KeyPointsRM(real32_T *inLoc, real32_T *inScale,
	real32_T *inMetric, int8_T *inSignOfLap,
	vector<KeyPoint> &keypoints, int_T numel)
{
	// get pointers to all the fields
	float *pt = (float *)inLoc;
	float *scale = (float *)inScale;
	float *hessian = (float *)inMetric;
	char  *laplacian = (char  *)inSignOfLap;

	int k = 0;
	for (mwSize i = 0; i< (mwSize)numel; i++)
	{
		// convert points back to 0 based indexing
		float x(pt[k++] - 1.0f), y(pt[k++] - 1.0f);

		// orientation is always 0 until this extractor determines it
		float dir(0);

		// convert back from scale to the units used by OpenCV
		int size = cvRound(scale[i] / SURF_SIZE_TO_SCALE_FACTOR);

		// OpenCV will error out when size <= 0 (makes sense)
		bool isValidPoint = (size >= 0.0f);

		int octave(0);

		if (isValidPoint)
		{
			KeyPoint kpt(x, y, (float)size, dir, hessian[i], octave, laplacian[i]);
			keypoints.push_back(kpt);
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvExtractSURF
//////////////////////////////////////////////////////////////////////////////

int32_T extractSurf_compute(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int8_T *inSignOfLap,
	int32_T numel, boolean_T isExtended, boolean_T isUpright,
	void **outKeypoints, void **outDescriptors)
{
	cv::Mat img = cv::Mat(nRows, (int)nCols, CV_8UC1, inImg);
	(void)nDims;
	// keypoints
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoints = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;

	struct2KeyPoints(inLoc,inScale,inMetric,inSignOfLap,refKeypoints, numel);

	// output
	// Note: OpenCV extractor does not reduce the number of feature points.
	//       It keeps all of them.

	Ptr<MWSURF> surfExtractor = cv::makePtr<MWSURF>();
    if( surfExtractor.empty() )
        CV_Error(CV_StsNotImplemented, "OpenCV was built without SURF support");

    // Update MWSURF with upright and extended flags;
    // To avoid C4800 on MSVC: make bool != 0 to force bool type.
    surfExtractor->setUpright(isUpright != 0);
    surfExtractor->setExtended(isExtended != 0);

	// run the extractor
	cv::Mat *ptrDescriptors = (cv::Mat *)new cv::Mat();
	*outDescriptors = ptrDescriptors;
	cv::Mat &refDescriptors = *ptrDescriptors;
	surfExtractor->compute(img, refKeypoints, refDescriptors);

	return ((int32_T)(refKeypoints.size())); //actual_numel
}

int32_T extractSurf_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T nDims,
	real32_T *inLoc, real32_T *inScale, real32_T *inMetric, int8_T *inSignOfLap,
	int32_T numel, boolean_T isExtended, boolean_T isUpright,
	void **outKeypoints, void **outDescriptors)
{
	cv::Mat img = cv::Mat(nRows, (int)nCols, CV_8UC1, inImg);
	(void)nDims;
	// keypoints
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoints = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;

	struct2KeyPointsRM(inLoc, inScale, inMetric, inSignOfLap, refKeypoints, numel);

	// output
	// Note: OpenCV extractor does not reduce the number of feature points.
	//       It keeps all of them.

	Ptr<MWSURF> surfExtractor = cv::makePtr<MWSURF>();
	if (surfExtractor.empty())
		CV_Error(CV_StsNotImplemented, "OpenCV was built without SURF support");

	// Update MWSURF with upright and extended flags;
	// To avoid C4800 on MSVC: make bool != 0 to force bool type.
	surfExtractor->setUpright(isUpright != 0);
	surfExtractor->setExtended(isExtended != 0);

	// run the extractor
	cv::Mat *ptrDescriptors = (cv::Mat *)new cv::Mat();
	*outDescriptors = ptrDescriptors;
	cv::Mat &refDescriptors = *ptrDescriptors;
	surfExtractor->compute(img, refKeypoints, refDescriptors);

	return ((int32_T)(refKeypoints.size())); //actual_numel
}

void extractSurf_assignOutput(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap,
	real32_T *outOrientation, real32_T *outFeatures)
{
	vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];
	cv::Mat descriptors = ((cv::Mat *)ptrDescriptors)[0];

	// Populate the outputs
	keyPoints2Fields(keypoints, true, outLoc, outScale, outMetric, outSignOfLap, outOrientation);
	cArrayFromMat<real32_T>(outFeatures, descriptors);

	delete((vector<KeyPoint> *)ptrKeypoints);
	delete((cv::Mat *)ptrDescriptors);
}


void extractSurf_assignOutputRM(void *ptrKeypoints, void *ptrDescriptors,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap,
	real32_T *outOrientation, real32_T *outFeatures)
{
	vector<KeyPoint> keypoints = ((vector<KeyPoint> *)ptrKeypoints)[0];
	cv::Mat descriptors = ((cv::Mat *)ptrDescriptors)[0];

	// Populate the outputs
	keyPoints2FieldsRM(keypoints, true, outLoc, outScale, outMetric, outSignOfLap, outOrientation);
	cArrayFromMat_RowMaj<real32_T>(outFeatures, descriptors);

	delete((vector<KeyPoint> *)ptrKeypoints);
	delete((cv::Mat *)ptrDescriptors);
}

#endif
