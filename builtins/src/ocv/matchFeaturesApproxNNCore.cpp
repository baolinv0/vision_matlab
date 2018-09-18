///////////////////////////////////////////////////////////////////////////////
// This file contains the shared library function calls used in codegen for
// matchFeatures's Approximate method.
///////////////////////////////////////////////////////////////////////////////
#ifndef COMPILE_FOR_VISION_BUILTINS
#include "matchFeaturesCore_api.hpp"
#include "flann/miniflann.hpp"
#include "opencv2/opencv.hpp"

///////////////////////////////////////////////////////////////////////////////
// Approximate NN search for floating point (single only) features. 
///////////////////////////////////////////////////////////////////////////////
void findApproximateNearestNeighbors_real32(const real32_T * features1, const
        real32_T * features2, const char * metric, const int32_T numFeatures1,
        const int32_T numFeatures2, const int32_T numelInFeatureVec, const
        int32_T knn, int32_T * indexPairs, real32_T * dist) 
{

    using namespace cv;

    std::string metricString(metric);

    cvflann::flann_distance_t distType; 

    if (metricString == "ssd") 
    {
        distType = cvflann::FLANN_DIST_L2;
    }
    else 
    {
        distType = cvflann::FLANN_DIST_L1;
    }

    // create Mat wrappers around input data buffers.
    Mat f1Mat(numFeatures1, numelInFeatureVec, CV_32F, (void *)features1);
    Mat f2Mat(numFeatures2, numelInFeatureVec, CV_32F, (void *)features2);

    // create Mat wrappers around output data buffers.
    Mat distMat (numFeatures1, knn, CV_32F, (void *)dist);
    Mat indexMat(numFeatures1, knn, CV_32S, (void *)indexPairs);
    // Index and search features
    flann::Index index(f2Mat, cv::flann::KDTreeIndexParams(), distType);
    index.knnSearch(f1Mat, indexMat, distMat, knn, flann::SearchParams());
}

///////////////////////////////////////////////////////////////////////////////
// Approximate NN search for binary features (uint8). 
///////////////////////////////////////////////////////////////////////////////
void findApproximateNearestNeighbors_uint8(const uint8_T * features1, 
        const uint8_T * features2, const char * metric, const int32_T
        numFeatures1, const int32_T numFeatures2, const int32_T
        numelInFeatureVec, const int32_T knn, int32_T * indexPairs,
        int32_T * dist) 
{

    using namespace cv;
	(void)metric;
    // create Mat wrappers around input data buffers.
    Mat f1Mat(numFeatures1, numelInFeatureVec, CV_8U, (void *)features1);
    Mat f2Mat(numFeatures2, numelInFeatureVec, CV_8U, (void *)features2);

    // create Mat wrappers around output data buffers.
    Mat distMat (numFeatures1, knn, CV_32S, (void *)dist);
    Mat indexMat(numFeatures1, knn, CV_32S, (void *)indexPairs);

    // Index and search binary features usig hierachical clustering.
    flann::Index index(f2Mat, cv::flann::HierarchicalClusteringIndexParams(), cvflann::FLANN_DIST_HAMMING);
    index.knnSearch(f1Mat, indexMat, distMat, knn, flann::SearchParams());
}
#endif
