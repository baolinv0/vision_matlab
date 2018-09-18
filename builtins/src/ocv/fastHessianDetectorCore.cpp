//////////////////////////////////////////////////////////////////////////////
// OpenCV SURF detector wrapper 
//
// Copyright 2010-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////
#ifndef COMPILE_FOR_VISION_BUILTINS
#include "opencv2/opencv.hpp"

#include "fastHessianDetectorCore_api.hpp"
#include "surfCommon.hpp" // for initModule_mwsurf

// common defines
#define SURF_SIZE_TO_SCALE_FACTOR (1.2f/9.0f)

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
// Check inputs
//////////////////////////////////////////////////////////////////////////////

// nothing to be done here

//////////////////////////////////////////////////////////////////////////////
// There is no point in selecting an Octave which has the first filter
// size larger than the input image.  Limit the number of Octaves so that
// the selection makes sense. OpenCV can seg-v with an excessive number of
// octaves, so this routine provides protection against a seg-v and a silly
// user input.
//////////////////////////////////////////////////////////////////////////////
int limitNumOctavesCore(int inOctaves, mwSize rows, mwSize cols)
{

    mwSize firstFSize(3+3*(2<<(inOctaves-1)));
    int outOctaves(inOctaves);

    if (firstFSize > rows || firstFSize > cols) // need to limit num octaves
    {
        int i;
        for (i=0; i<inOctaves; i++)
        {
            mwSize fsize = 3+3*(2<<i);
            if (rows < fsize || cols < fsize)
            {
                break;
            }
        }
        outOctaves = i+1;
    }
    
    return outOctaves;
}

//////////////////////////////////////////////////////////////////////////////
// Configures extractor's properties
//////////////////////////////////////////////////////////////////////////////
void configureSURFDetectorCore(Ptr<MWSURF> surfDetector, 
                           int nOctaveLayers, int nOctaves, int hessianThreshold, 
						   mwSize imgRows,  mwSize imgCols)
{
    // refine user specified number of octaves; user can specify a large
    // number which will not impact the results while wasting memory and
    // computation time
    nOctaves = limitNumOctavesCore(nOctaves, imgRows, imgCols);

    // Configure only the properies which are pertinent to the detector
    surfDetector->setThreshold(hessianThreshold);
    surfDetector->setNOctaves(nOctaves);
    surfDetector->setNOctaveLayers(nOctaveLayers);
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
void fastHessianDetector_keyPoints2field(void *ptrKeypoints, 
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap)
{
	vector<KeyPoint> &in = ((vector<KeyPoint> *)ptrKeypoints)[0];

	const mwSize m = in.size();

    if (m > 0) 
    {
        for(mwSize i = 0; i < m; i++ )
        {
            // OpenCV point info
            outLoc[i]       = in[i].pt.x+1;     // Convert to MATLAB's 1 based indexing
            outLoc[m+i]     = in[i].pt.y+1;
            outScale[i]     = in[i].size*SURF_SIZE_TO_SCALE_FACTOR; // convert to SURF's scale
            outMetric[i]    = in[i].response;  // hessian (float)
			outSignOfLap[i] = (int8_T)in[i].class_id;  // laplacian
        }
    }
}

void fastHessianDetector_keyPoints2fieldRM(void *ptrKeypoints,
	real32_T *outLoc, real32_T *outScale, real32_T *outMetric, int8_T *outSignOfLap)
{
	vector<KeyPoint> &in = ((vector<KeyPoint> *)ptrKeypoints)[0];

	const mwSize m = in.size();

	if (m > 0)
	{
		for (mwSize i = 0; i < m; i++)
		{
			// OpenCV point info
			*outLoc++ = in[i].pt.x + 1;     // Convert to MATLAB's 1 based indexing
			*outLoc++ = in[i].pt.y + 1;
			outScale[i] = in[i].size*SURF_SIZE_TO_SCALE_FACTOR; // convert to SURF's scale
			outMetric[i] = in[i].response;  // hessian (float)
			outSignOfLap[i] = (int8_T)in[i].class_id;  // laplacian
		}
	}
}
//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////
int32_T fastHessianDetector_uint8(uint8_T *inImg, 
	int32_T nRows, int32_T nCols, int32_T nDims, 
	int32_T nOctaveLayers, int32_T nOctaves, int32_T hessianThreshold, void **outKeypoint)
{ 
	(void)nDims;
	// inImg: column major
	cv::Mat img = cv::Mat(nRows, (int)nCols, CV_8UC1, inImg);

	Ptr<MWSURF> surfDetector = cv::makePtr<MWSURF>();
    if( surfDetector.empty() )
        CV_Error(CV_StsNotImplemented, "OpenCV was built without SURF support");
    
    // set the detector's properties
    configureSURFDetectorCore(surfDetector, nOctaveLayers, nOctaves,
		hessianThreshold, img.rows, img.cols);

    // run the detector
	vector<KeyPoint> *ptrKeypoints = (vector<KeyPoint> *)new vector<KeyPoint>();
	*outKeypoint = ptrKeypoints;
	vector<KeyPoint> &refKeypoints = *ptrKeypoints;
	surfDetector->detect(img, refKeypoints);
	return ((int32_T)(refKeypoints.size()));
}

void fastHessianDetector_deleteKeypoint(void *ptrKeypoints)
{
 	delete((vector<KeyPoint> *)ptrKeypoints);
}

#endif