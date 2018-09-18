///////////////////////////////////////////////////////////////////////////
//
//  ForegroundDetectorImpl contains the templatized implementation.  This
//  class's methods are called through the ForegroundDetectorMImpl. 
//
///////////////////////////////////////////////////////////////////////////    


// module includes
#ifdef __arm__
#include "ForegroundDetectorImpl.hpp"
#else
#include <foregroundDetector/ForegroundDetectorImpl.hpp>
#endif

namespace vision
{
    
    ///////////////////////////////////////////////////////////////////////
    //
    // Constructor 
    // 
    ///////////////////////////////////////////////////////////////////////
    template <typename image_type, typename stat_type>
    ForegroundDetectorImpl<image_type,stat_type>::ForegroundDetectorImpl()
    {                       
        mFtor = ForegroundDetectorFunctor<image_type, stat_type>();            
    }
		
    ///////////////////////////////////////////////////////////////////////
    //
    // initializeImpl: sets up the algorithm functor and the internal states
    // 
    /////////////////////////////////////////////////////////////////////// 
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::initializeImpl(Dims dims,
                                                                      mwSize numGaussians, 
                                                                      stat_type initialVariance,
                                                                      stat_type initialWeight, 
                                                                      stat_type varianceThreshold,
                                                                      stat_type minBGRatio)
    {
            
        // setup functor dims and properties            
        mFtor.setup(dims);
        mFtor.setProperties(numGaussians, initialVariance, initialWeight,
                            varianceThreshold, minBGRatio);
    
        // pre-allocate during setup to avoid dynamic allocation
        // while processing           
        mGMMVec = GMMVector(mFtor.getNumPixels(), 
                            std::pair<GaussianMixtureModel, mwSize>());

        // initialize pixel index and reserve numGaussians for GMM
        for (mwSize i = 0; i < mFtor.getNumPixels(); ++i)
        {
            mGMMVec[i].first.reserve(numGaussians);
            mGMMVec[i].second = i;
        }
            
        // set pointer to GMMVec model for the implementation 
        mFtor.setGMMVec(&mGMMVec);
            
    }       

    ////////////////////////////////////////////////////////////////////////
    //
    // setOutputBuffer 
    //     - sets up the output buffer for step.
    //
    ////////////////////////////////////////////////////////////////////////  
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::setOutputBuffer(boolean_T * fgMask)
    { 	
        // setup buffer for the output mask
        mFtor.setStepOutput(fgMask);				
    }
		
    ////////////////////////////////////////////////////////////////////////
    //
    //  Step implementation 
    //     - sets up the algorithm input data and invokes the algorithm 
    //       functor.  The functor is run on multiple cores using TBB.
    //
    ////////////////////////////////////////////////////////////////////////  
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::stepImpl(const image_type * image, 
                                                                      stat_type    learningRate)
    {
        mFtor.setStepInput(image,learningRate);
		
#ifdef __arm__
        mFtor(0,mFtor.getNumPixels());
#else
        tbb::blocked_range<mwSize> range(0,mFtor.getNumPixels(),1);
        tbb::auto_partitioner ap;
        tbb::parallel_for(range, mFtor, ap );
#endif
            
    }

    ////////////////////////////////////////////////////////////////////////
    //
    //  Step implementation (Row Major version)
    //     - sets up the algorithm input data and invokes the algorithm 
    //       functor.  The functor is run on multiple cores using TBB.
    //
    ////////////////////////////////////////////////////////////////////////  
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::stepImplRowMajor(const image_type * image, 
                                                                      stat_type    learningRate)
    {
        mFtor.setStepInput(image,learningRate);
		
#ifdef __arm__
        mFtor(static_cast<unsigned long>(0),static_cast<unsigned long>(mFtor.getNumPixels()));
#else
        //typename GMMVector::range_type range = mGMMVec.range(1);
        tbb::blocked_range<unsigned int> range(0,mFtor.getNumPixels(),1);
        tbb::auto_partitioner ap;
        tbb::parallel_for(range, mFtor, ap );
#endif
            
    }
    
    ////////////////////////////////////////////////////////////////////////
    //
    //  getStates implementation 
    //     - Implemenation of getStates
    //       
    //
    ////////////////////////////////////////////////////////////////////////  	
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::getStatesImpl(stat_type* weights, 
                                                                     stat_type* means,
                                                                     stat_type* variances, 
                                                                     int *      numActive)
    {
        typename GMMVector::iterator currentIter,endIter;
        currentIter = mGMMVec.begin();
        endIter     = mGMMVec.end();              
            
        // loop over all pixels model
        for ( ;currentIter != endIter; ++currentIter)
        {
            getGMMStates(currentIter->first, weights++, means++, variances++, numActive++);
        }
    }
	
    ///////////////////////////////////////////////////////////////////////
    //
    // getGMMStates: Extracts the state information from a specific gaussian  
    // mixture model.
    // 
    ///////////////////////////////////////////////////////////////////////  
    template <typename image_type, typename stat_type>		
    void ForegroundDetectorImpl<image_type,stat_type>::getGMMStates(GaussianMixtureModel & gmm, 
                                                                    stat_type * weights, 
                                                                    stat_type * means,
                                                                    stat_type * variances,
                                                                    int *       numActive)
    {

        // This is expected to be called only after initialize!!!

        // Copy model information into weights, means, variances and numActive
            
        *numActive = static_cast<int>(gmm.size());
            
        // Copy weights
            
        mwSize weight_offset = 0;
        mwSize stat_offset   = 0;

        GaussianIterator currentGaussian,endGaussian;     

        currentGaussian = gmm.begin();
        endGaussian     = gmm.end();
            
        mwSize numPixels   = mFtor.getNumPixels();
        mwSize numChannels = mFtor.getNumChannels();
        mwSize statOffset  = numPixels * numChannels;
        for ( ; currentGaussian != endGaussian; 
              ++currentGaussian, weight_offset += numPixels)
        {
            weights[weight_offset] = currentGaussian->getWeight();

            currentGaussian->copyMeanInto(means, numPixels);
            currentGaussian->copyVarianceInto(variances, numPixels);

            // increment to for next gaussian
            means     += statOffset;
            variances += statOffset;
        }
    }
		
    ///////////////////////////////////////////////////////////////////////       
    // 
    // setStatesImpl: 
    // 	- Implemenation of setStates
    //
    ///////////////////////////////////////////////////////////////////////    
    template <typename image_type, typename stat_type>		
    void ForegroundDetectorImpl<image_type,stat_type>::setStatesImpl(stat_type* weights,
                                                                     stat_type* means,
                                                                     stat_type* variances,
                                                                     int *      numActive)
    {
        // We need to copy the saved state information from 
        // mxArrays into the model format used in the implementation.
        typename GMMVector::iterator currentIter,endIter;
        currentIter = mGMMVec.begin();
        endIter     = mGMMVec.end();              
            
        // loop over all pixels in image
        for (int i = 0 ; currentIter != endIter; ++currentIter, ++i)
        {
            setGMMStates(currentIter->first, numActive[i], 
                         weights++, means++, variances++);           
        }
    }
		
    ///////////////////////////////////////////////////////////////////////       
    // 
    // setGMMStates: used to set internal detector states for a specific 
    // gaussian mixture model. Used for save/load/clone.
    //
    ///////////////////////////////////////////////////////////////////////    
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::setGMMStates(GaussianMixtureModel & gmm, 
                                                                    int numActiveGaussians,
                                                                    const stat_type * weights, 
                                                                    const stat_type * means,
                                                                    const stat_type * vars)
    {
                               
        // setGMM is used during de-serialization and only should 
        // be called if the system object was saved in an locked state

        // weights is pointer to [M N numGaussian] matrix
        // means and vars is a pointer to [M N numChannels numGaussians] matrix
            
        // weights should already be pointing to the starting pixel

        mwSize numPixels     = mFtor.getNumPixels();
        mwSize numChannels   = mFtor.getNumChannels();
        mwSize weight_offset = numPixels;
        mwSize stat_offset   = numPixels * numChannels;
        for (int n = 0; n < numActiveGaussians; ++n)
        {
            // add WeightedGaussian
            gmm.push_back(WeightedGaussian<stat_type>(numChannels, 
                                                      numPixels, 
                                                      weights, 
                                                      means, vars ));
            weights += weight_offset;
            means   += stat_offset;
            vars    += stat_offset;
        }
    }
	
    ////////////////////////////////////////////////////////////////////////
    //
    //  Reset implementation - resets the internal gaussian mixture model back
    //                         to initial values (in our case empty).
    // 
    ////////////////////////////////////////////////////////////////////////
    template <typename image_type, typename stat_type>
    void ForegroundDetectorImpl<image_type,stat_type>::resetImpl()
    {
        //set or reset states to initial value
        typename GMMVector::iterator currentIter, endIter;
			
        currentIter = mGMMVec.begin();
        endIter = mGMMVec.end();
        for(; currentIter != endIter; ++currentIter)
        {
            currentIter->first.clear();
        }
    } 
	
    // instantiate templates <image_type, stat_type>
    template class  ForegroundDetectorImpl<float,float>;
    template class  ForegroundDetectorImpl<double,double>;	
    template class  ForegroundDetectorImpl<uint8_T,float>;
    //template class  ForegroundDetectorImpl<double,float>; //this is not supported
    //template class  ForegroundDetectorImpl<uint8_T,double>; //this is not supported
    //template class  ForegroundDetectorImpl<float,double>; //this is not supported

		
}// end vision namespace

