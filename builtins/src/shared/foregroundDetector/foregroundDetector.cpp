///////////////////////////////////////////////////////////////////////////
//
//  ForegroundDetector contains 
//  implementation of foregroundDetector_published_c_api.
//
///////////////////////////////////////////////////////////////////////////    
#ifdef __arm__
#include "vision_defines.h"
#include "foregroundDetector_published_c_api.hpp"
#include "ForegroundDetectorImpl.hpp"
#else
#include <foregroundDetector/vision_defines.h>
#include <foregroundDetector/foregroundDetector_published_c_api.hpp>
#include <foregroundDetector/ForegroundDetectorImpl.hpp>
#endif

///////////////////////////////////////////////////////////////////////////    
//Constructor for different classes
///////////////////////////////////////////////////////////////////////////    
void foregroundDetector_construct_double_double(void **ptr2fgObjPtr)
{
    vision::ForegroundDetectorImpl<double,double>  *fgObjPtr =    
        (vision::ForegroundDetectorImpl<double,double> *)new vision::ForegroundDetectorImpl<double,double>;
    *ptr2fgObjPtr = fgObjPtr;
}

void foregroundDetector_construct_uint8_float(void **ptr2fgObjPtr)
{
    vision::ForegroundDetectorImpl<uint8_T,float>  *fgObjPtr =
        (vision::ForegroundDetectorImpl<uint8_T,float> *)new vision::ForegroundDetectorImpl<uint8_T,float>;
    *ptr2fgObjPtr = fgObjPtr;
}

void foregroundDetector_construct_float_float(void **ptr2fgObjPtr)
{
    vision::ForegroundDetectorImpl<float,float>  *fgObjPtr = 
        (vision::ForegroundDetectorImpl<float,float> *)new vision::ForegroundDetectorImpl<float,float>;
    *ptr2fgObjPtr = fgObjPtr;
}

///////////////////////////////////////////////////////////////////////////    
//Step for different classes
///////////////////////////////////////////////////////////////////////////    
void foregroundDetector_step_double_double(void *fgObjPtr, 
                                           const double * inImage, 
                                           boolean_T *mask, 
                                           double learningRate)
{

    vision::ForegroundDetectorImpl<double,double> *fgObj = 
        (vision::ForegroundDetectorImpl<double,double> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImpl(inImage, learningRate);
		
}

void foregroundDetector_step_uint8_float(void *fgObjPtr, 
                                         const uint8_T * inImage, 
                                         boolean_T *mask, 
                                         float learningRate)
{

    vision::ForegroundDetectorImpl<uint8_T,float> *fgObj =
        (vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImpl(inImage,learningRate);
		
}

void foregroundDetector_step_float_float(void *fgObjPtr, 
                                         const float * inImage, 
                                         boolean_T *mask, 
                                         float learningRate)
{
    vision::ForegroundDetectorImpl<float,float> *fgObj =
        (vision::ForegroundDetectorImpl<float,float> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImpl(inImage,learningRate);
		
}


///////////////////////////////////////////////////////////////////////////    
//Step for different classes (Row Major Versions)
///////////////////////////////////////////////////////////////////////////    
void foregroundDetector_step_rowMaj_double_double(void *fgObjPtr, 
                                           const double * inImage, 
                                           boolean_T *mask, 
                                           double learningRate)
{

    vision::ForegroundDetectorImpl<double,double> *fgObj = 
        (vision::ForegroundDetectorImpl<double,double> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImplRowMajor(inImage, learningRate);
		
}

void foregroundDetector_step_rowMaj_uint8_float(void *fgObjPtr, 
                                         const uint8_T * inImage, 
                                         boolean_T *mask, 
                                         float learningRate)
{

    vision::ForegroundDetectorImpl<uint8_T,float> *fgObj =
        (vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImplRowMajor(inImage,learningRate);
		
}

void foregroundDetector_step_rowMaj_float_float(void *fgObjPtr, 
                                         const float * inImage, 
                                         boolean_T *mask, 
                                         float learningRate)
{
    vision::ForegroundDetectorImpl<float,float> *fgObj =
        (vision::ForegroundDetectorImpl<float,float> *)fgObjPtr;
    // call shared library functions
    fgObj->setOutputBuffer(mask);
    fgObj->stepImplRowMajor(inImage,learningRate);
		
}

///////////////////////////////////////////////////////////////////////////    
//Initialize for different classes
///////////////////////////////////////////////////////////////////////////    
void foregroundDetector_initialize_double_double(
    void *fgObjPtr,
    int32_T numberOfDims,	
    int32_T *dims,
    int32_T numGaussians, 
    double initialVariance,
    double initialWeight, 
    double varianceThreshold,
    double minBGRatio)
{
							
							
    std::vector<mwSize> dVec((mwSize)numberOfDims);
    std::copy(dims, dims+numberOfDims, dVec.begin());	
    vision::ForegroundDetectorImpl<double,double> *fgObj = 
        (vision::ForegroundDetectorImpl<double,double> *)fgObjPtr;
    fgObj->initializeImpl(dVec, 
                          (mwSize)numGaussians,
                          initialVariance,
                          initialWeight,
                          varianceThreshold,
                          minBGRatio);					
		
}
							
void foregroundDetector_initialize_uint8_float(
    void *fgObjPtr,
    int32_T numberOfDims,	
    int32_T *dims,
    int32_T numGaussians, 
    float initialVariance,
    float initialWeight, 
    float varianceThreshold,
    float minBGRatio)
{
							
    std::vector<mwSize> dVec((mwSize)numberOfDims);
    std::copy(dims, dims+numberOfDims, dVec.begin());							
    vision::ForegroundDetectorImpl<uint8_T,float> *fgObj =
        (vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr;
    fgObj->initializeImpl(dVec,
                          (mwSize)numGaussians,
                          initialVariance,
                          initialWeight,
                          varianceThreshold,
                          minBGRatio);								
							
}
							
void foregroundDetector_initialize_float_float(
    void *fgObjPtr,
    int32_T numberOfDims,	
    int32_T *dims,
    int32_T numGaussians, 
    float initialVariance,
    float initialWeight, 
    float varianceThreshold,
    float minBGRatio)
{
							
    std::vector<mwSize> dVec((mwSize)numberOfDims);
    std::copy(dims, dims+numberOfDims, dVec.begin());	
    vision::ForegroundDetectorImpl<float,float> *fgObj =
        (vision::ForegroundDetectorImpl<float,float> *)fgObjPtr;
    fgObj->initializeImpl(dVec,
                          (mwSize)numGaussians,
                          initialVariance,
                          initialWeight,
                          varianceThreshold,
                          minBGRatio);
}		

///////////////////////////////////////////////////////////////////////////    
//Reset for different classes
///////////////////////////////////////////////////////////////////////////    
void foregroundDetector_reset_double_double(void *fgObjPtr){

    vision::ForegroundDetectorImpl<double,double> *fgObj =
        (vision::ForegroundDetectorImpl<double,double> *)fgObjPtr;
    fgObj->resetImpl();

}
void foregroundDetector_reset_uint8_float(void *fgObjPtr){
    vision::ForegroundDetectorImpl<uint8_T,float> *fgObj = 
        (vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr;
    fgObj->resetImpl();
 
}
void foregroundDetector_reset_float_float(void *fgObjPtr){
    vision::ForegroundDetectorImpl<float,float> *fgObj =
        (vision::ForegroundDetectorImpl<float,float> *)fgObjPtr;
    fgObj->resetImpl();

}

						
							
     
///////////////////////////////////////////////////////////////////////////    
//Release for different classes
///////////////////////////////////////////////////////////////////////////                     
void foregroundDetector_release_double_double(void *fgObjPtr){
    vision::ForegroundDetectorImpl<double,double> *fgObj = 
        (vision::ForegroundDetectorImpl<double,double> *)fgObjPtr;
    fgObj->releaseImpl();
				
}

void foregroundDetector_release_uint8_float(void *fgObjPtr){

    vision::ForegroundDetectorImpl<uint8_T,float> *fgObj = 
        (vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr;
    fgObj->releaseImpl();

}

void foregroundDetector_release_float_float(void *fgObjPtr){
 
    vision::ForegroundDetectorImpl<float,float> *fgObj =
        (vision::ForegroundDetectorImpl<float,float> *)fgObjPtr;
    fgObj->releaseImpl();
}
 
///////////////////////////////////////////////////////////////////////////    
//Delete for different classes
///////////////////////////////////////////////////////////////////////////   
void foregroundDetector_deleteObj_float_float(void *fgObjPtr){ 
    delete((vision::ForegroundDetectorImpl<float,float> *)fgObjPtr);

}
void foregroundDetector_deleteObj_uint8_float(void *fgObjPtr){ 
    delete((vision::ForegroundDetectorImpl<uint8_T,float> *)fgObjPtr);

}
void foregroundDetector_deleteObj_double_double(void *fgObjPtr){ 
    delete((vision::ForegroundDetectorImpl<double,double> *)fgObjPtr);

}
 
