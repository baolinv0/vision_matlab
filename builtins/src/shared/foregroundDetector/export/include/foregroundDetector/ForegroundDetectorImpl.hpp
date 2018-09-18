////////////////////////////////////////////////////////////////////////////////
//  This header contains the ForegroundDetectorImpl class which invokes the
//  ForegroundDetectorFunctor object using TBB.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef _FOREGROUND_DETECTOR_IMPL_
#define _FOREGROUND_DETECTOR_IMPL_

// local includes
#include "vision_defines.h"
#include "ForegroundDetectorTraits.hpp"
#include "ForegroundDetectorFunctor.hpp"


#ifndef __arm__
// 3rd party includes
#include <tbb/tbb.h>
#include <tbb/parallel_for.h>
#include <tbb/partitioner.h>
#include <tbb/concurrent_vector.h>
#include <tbb/cache_aligned_allocator.h>
#include <tbb/scalable_allocator.h>
#include <tbb/blocked_range.h>
#endif

// system includes
#include <vector>
#include <algorithm>
#include <numeric>

namespace vision
{
    
    ///////////////////////////////////////////////////////////////////////////
    //
    //  ForegroundDetectorImpl contains the templatized implementation.  This
    //  class's methods are called through the ForegroundDetectorMImpl. 
    //
    ///////////////////////////////////////////////////////////////////////////    
    template <typename image_type, typename stat_type>
    class LIBMWFOREGROUNDDETECTOR_API ForegroundDetectorImpl
    {
      public:
        
        typedef typename ForegroundDetectorTraits<stat_type>::Dims Dims;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GaussianMixtureModel GaussianMixtureModel;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GaussianIterator GaussianIterator;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GMMVector GMMVector;
		

        ///////////////////////////////////////////////////////////////////////
        //
        // Constructor 
        // 
        ///////////////////////////////////////////////////////////////////////
        ForegroundDetectorImpl();
                        
        ///////////////////////////////////////////////////////////////////////
        //
        // Destructor
        //
        ///////////////////////////////////////////////////////////////////////
        ~ForegroundDetectorImpl(){}
        
        
        ///////////////////////////////////////////////////////////////////////
        //
        // initializeImpl: sets up the algorithm functor and the internal states
        // 
        /////////////////////////////////////////////////////////////////////// 
        void initializeImpl(Dims dims,
                            mwSize numGaussians, 
                            stat_type initialVariance,
                            stat_type initialWeight, 
                            stat_type varianceThreshold,
                            stat_type minBGRatio);
							
        
        ////////////////////////////////////////////////////////////////////////
        //
        // setOutputBuffer 
        //     - sets up the output buffer for step.
        //
        ////////////////////////////////////////////////////////////////////////  
        void setOutputBuffer(boolean_T * fgMask);
      
		
        ////////////////////////////////////////////////////////////////////////
        //
        //  Step implementation 
        //     - sets up the algorithm input data and invokes the algorithm 
        //       functor.  The functor is run on multiple cores using TBB.
        //
        ////////////////////////////////////////////////////////////////////////  
        void stepImpl(const image_type * image, 
                      stat_type learningRate);
       

        void stepImplRowMajor(const image_type * image, 
                      stat_type learningRate);        
        ////////////////////////////////////////////////////////////////////////
        //
        //  getStates implementation 
        //     - Implemenation of getStates
        //       
        //
        ////////////////////////////////////////////////////////////////////////  	
        void getStatesImpl(stat_type* weights, stat_type* means, stat_type* variances, int * numActive);

	
        ///////////////////////////////////////////////////////////////////////
        //
        // getGMMStates: Extracts the state information from a specific gaussian  
        // mixture model.
        // 
        ///////////////////////////////////////////////////////////////////////        

        void getGMMStates(GaussianMixtureModel & gmm, 
                          stat_type * weights, 
                          stat_type * means,
                          stat_type * variances,
                          int * numActive);					  
		
        ///////////////////////////////////////////////////////////////////////       
        // 
        // setStatesImpl: 
        // 	- Implemenation of setStates
        //
        ///////////////////////////////////////////////////////////////////////             
        void setStatesImpl(stat_type* weights, stat_type* means, stat_type* variances, int * numActive);

		
        ///////////////////////////////////////////////////////////////////////       
        // 
        // setGMMStates: used to set internal detector states for a specific 
        // gaussian mixture model. Used for save/load/clone.
        //
        ///////////////////////////////////////////////////////////////////////    
        void setGMMStates(GaussianMixtureModel & gmm, 
                          int numActiveGaussians,
                          const stat_type * weights, 
                          const stat_type * means,
                          const stat_type * vars);
						  

		
        ////////////////////////////////////////////////////////////////////////
        //
        //  Reset implementation - resets the internal gaussian mixture model back
        //                         to initial values (in our case empty).
        // 
        ////////////////////////////////////////////////////////////////////////
        void resetImpl();
        

        ////////////////////////////////////////////////////////////////////////
        //
        //  Release implementation - releases the internal model 
        // 
        //////////////////////////////////////////////////////////////////////// 
        void releaseImpl()        
        {
            mGMMVec.clear();
        }
  

        mwSize getMFtorNumGaussians()
        {
            return mFtor.getNumGaussians();
        }
  
		
		
        mwSize getMFtorNumChannels()
        {
            return mFtor.getNumChannels();
        }

      private:// data members
        ////////////////////////////////////////////////////////////////////////        
        //
        // mFtor: a functor that contains the actual algorithm implementation
        //
        ////////////////////////////////////////////////////////////////////////
        ForegroundDetectorFunctor<image_type, stat_type> mFtor;

        ////////////////////////////////////////////////////////////////////////
        //
        // mGMMVec: A vector of gaussian mixture models.  Holds the GMM models
        // for all pixels.
        //
        ////////////////////////////////////////////////////////////////////////
        GMMVector mGMMVec;              
       
    };  


}// end vision namespace


#endif //_FOREGROUND_DETECTOR_IMPL_


