////////////////////////////////////////////////////////////////////////////////
//  This header contains common traits used in the ForegroundDetector* classes
//
////////////////////////////////////////////////////////////////////////////////


#ifndef FOREGROUND_DETECTOR_TRAITS
#define FOREGROUND_DETECTOR_TRAITS

// local includes
#include "WeightedGaussian.hpp"

#ifndef __arm__
//
#include <tbb/tbb.h>
#include <tbb/scalable_allocator.h>
#endif

namespace vision
{

    
    template <typename stat_type>
    struct ForegroundDetectorTraits
    {        

      public: // typedefs
       
        ///////////////////////////////////////////////////////////////////////
        //
        // Dims - this is used to hold dimensions info
        //
        ///////////////////////////////////////////////////////////////////////
        typedef std::vector<mwSize> Dims;                
                        
        ///////////////////////////////////////////////////////////////////////
        // GaussianMixtureModel - this is used to model a gaussian mixture model
        ///////////////////////////////////////////////////////////////////////
#ifdef __arm__  
        typedef typename std::vector<WeightedGaussian<stat_type> > GaussianMixtureModel;  
#else
        typedef typename std::vector<WeightedGaussian<stat_type>, tbb::scalable_allocator< WeightedGaussian<stat_type> > > GaussianMixtureModel;
#endif
        
        ///////////////////////////////////////////////////////////////////////
        //
        // PixelModel - this associates a pixel ID to a gaussian mixture model.
        // This is how we know which model belongs to which pixel. Needed for
        // multicore processing where the order in which pixels get processed is
        // not defined.
        //
        ///////////////////////////////////////////////////////////////////////
        typedef std::pair<GaussianMixtureModel, mwSize> PixelModel;      
        

        ///////////////////////////////////////////////////////////////////////
        //
        // GMMVector: holds all the gaussian mixture models (for every pixel) in
        // an image
        //
        ///////////////////////////////////////////////////////////////////////      
#ifdef __arm__
        typedef typename std::vector< PixelModel> GMMVector;       
#else
        typedef typename std::vector< PixelModel, tbb::scalable_allocator<PixelModel> > GMMVector;
#endif
        
        ///////////////////////////////////////////////////////////////////////
        //
        // GaussianIterator, ConstGaussianIterator 
        //            - iterators for GaussianMixtureModel
        //
        ///////////////////////////////////////////////////////////////////////
        typedef typename GaussianMixtureModel::iterator GaussianIterator;
        typedef typename GaussianMixtureModel::const_iterator ConstGaussianIterator;
        
    };
	

} // end namespace vision
#endif

