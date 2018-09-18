//////////////////////////////////////////////////////////////////////////////
// OpenCV MSER detector wrapper 
//
// Copyright 2010-2016 The MathWorks, Inc.
//  
//////////////////////////////////////////////////////////////////////////////

#ifndef COMPILE_FOR_VISION_BUILTINS
#include "detectMserCore_api.hpp"

#include "opencv2/opencv.hpp"
#include "cgCommon.hpp"

using namespace cv;
using namespace std;

//////////////////////////////////////////////////////////////////////////////
// Convert ouput of the MSER algorithm to a Points array. 
//////////////////////////////////////////////////////////////////////////////
void regionsToPointsArray(vector< vector<Point> > &in, int32_T numTotalPts, 
    int32_T *outPts, int32_T *outLengths)
{
    const mwSize n_regions = in.size();

    //////////////////////////////////////////////
    //Allocate individual cells in the cell array
    //////////////////////////////////////////////

    int32_T *points_x = outPts;
    int32_T *points_y = outPts + numTotalPts;

    mwSize k = 0;
    for(mwSize i = 0; i < n_regions ; i++)
    {
        // Allocate memory for points: (total number of points x 2 matrix)

        // Assign values for points: Xpoint and Ypoint
        outLengths[i] = (int32_T)in[i].size();
        for(mwSize j = 0; j < in[i].size(); j++)
        {
            points_x[k]   = in[i][j].x+1;    
            points_y[k++] = in[i][j].y+1;
        }   
        /*
        outPts         outLengths  
        [ax1  ay1;     3
        ax2  ay2;
        ax3  ay3;

        bx1  by1;     2
        bx2  by2;

        cx1  cy1;     .
        .	  .        
        .	  .        
        .    . ]
        */
    }  
}

void regionsToPointsArrayRM(vector< vector<Point> > &in, int32_T numTotalPts,
	int32_T *outPts, int32_T *outLengths)
{
	const mwSize n_regions = in.size();

	//////////////////////////////////////////////
	//Allocate individual cells in the cell array
	//////////////////////////////////////////////

	mwSize k = 0;
	for (mwSize i = 0; i < n_regions; i++)
	{
		// Allocate memory for points: (total number of points x 2 matrix)

		// Assign values for points: Xpoint and Ypoint
		outLengths[i] = (int32_T)in[i].size();
		for (mwSize j = 0; j < in[i].size(); j++)
		{
			outPts[k++] = in[i][j].x + 1;
			outPts[k++] = in[i][j].y + 1;
		}
		/*
		outPts         outLengths
		[ax1  ay1;     3
		ax2  ay2;
		ax3  ay3;

		bx1  by1;     2
		bx2  by2;

		cx1  cy1;     .
		.	  .
		.	  .
		.    . ]
		*/
	}
}

//////////////////////////////////////////////////////////////////////////////
// Invoke OpenCV cvDetectMser
//////////////////////////////////////////////////////////////////////////////

void detectMser_compute(uint8_T *inImg, 
    int32_T nRows, int32_T nCols, int32_T isRGB, 
    int delta,
    int minArea,
    int maxArea,
    float maxVariation,
    float minDiversity,
    int maxEvolution,
    double areaThreshold,
    double minMargin,
    int edgeBlurSize,
    int32_T *numTotalPts,
    int32_T *numRegions,
    void **outRegions)
{
    // Use OpenCV smart pointer to manage image 
    cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (bool)(isRGB != 0);
	cArrayToMat<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

    // comute the regions
    Ptr<MSER> mser = cv::MSER::create(delta, minArea, maxArea, maxVariation,
                     minDiversity, maxEvolution, 
                     areaThreshold, minMargin, 
                     edgeBlurSize);
    
    // keypoints
    vector< vector<Point> > *ptrRegions = (vector< vector<Point> > *)new vector< vector<Point> >();
    *outRegions = ptrRegions;
    vector< vector<Point> > &refRegions = *ptrRegions;
    
    std::vector<Rect> bboxes;
    mser->detectRegions(*inImage, refRegions, bboxes);

    numTotalPts[0] = 0;
    numRegions[0] = (int)refRegions.size();
    for(int i = 0; i < numRegions[0]; i++){
        numTotalPts[0] += (int)refRegions[i].size();
    }
}

void detectMser_computeRM(uint8_T *inImg,
	int32_T nRows, int32_T nCols, int32_T isRGB,
	int delta,
	int minArea,
	int maxArea,
	float maxVariation,
	float minDiversity,
	int maxEvolution,
	double areaThreshold,
	double minMargin,
	int edgeBlurSize,
	int32_T *numTotalPts,
	int32_T *numRegions,
	void **outRegions)
{
	// Use OpenCV smart pointer to manage image 
	cv::Ptr<cv::Mat> inImage = new cv::Mat;
	bool isRGB_ = (bool)(isRGB != 0);
	cArrayToMat_RowMaj<uint8_T>(inImg, nRows, nCols, isRGB_, *inImage);

	// comute the regions
	Ptr<MSER> mser = cv::MSER::create(delta, minArea, maxArea, maxVariation,
		minDiversity, maxEvolution,
		areaThreshold, minMargin,
		edgeBlurSize);

	// keypoints
	vector< vector<Point> > *ptrRegions = (vector< vector<Point> > *)new vector< vector<Point> >();
	*outRegions = ptrRegions;
	vector< vector<Point> > &refRegions = *ptrRegions;

	std::vector<Rect> bboxes;
	mser->detectRegions(*inImage, refRegions, bboxes);

	numTotalPts[0] = 0;
	numRegions[0] = (int)refRegions.size();
	for (int i = 0; i < numRegions[0]; i++){
		numTotalPts[0] += (int)refRegions[i].size();
	}
}

void detectMser_assignOutput(void *ptrRegions,
    int32_T numTotalPts, int32_T *outPts, int32_T *outLengths)
{
    vector< vector<Point> > regions = ((vector< vector<Point> > *)ptrRegions)[0];

    // Populate the outputs
    regionsToPointsArray(regions, numTotalPts, outPts, outLengths);

    delete((vector< vector<Point> > *)ptrRegions);
}

void detectMser_assignOutputRM(void *ptrRegions,
	int32_T numTotalPts, int32_T *outPts, int32_T *outLengths)
{
	vector< vector<Point> > regions = ((vector< vector<Point> > *)ptrRegions)[0];

	// Populate the outputs
	regionsToPointsArrayRM(regions, numTotalPts, outPts, outLengths);

	delete((vector< vector<Point> > *)ptrRegions);
}
#endif


