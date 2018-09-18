////////////////////////////////////////////////////////////////////////////////
//  This header contains the ForegroundDetectorFunctor class, which implements the
//  Stauffer-Grimson background subtraction algorithm [1,2]. This implementation 
//  is used in the vision.ForegroundDetector system object.
//
//  References:
//
//  [1] Stauffer, C. and Grimson, W.E.L, "Adaptive Background Mixture Models 
//      for Real-Time Tracking". Computer Vision and Pattern Recognition, 
//      IEEE Computer Society Conference on, Vol. 2 (06 August 1999), 
//      pp. 2246-252 Vol. 2.
//
//  [2] P. Kaewtrakulpong, R. Bowden, "An Improved Adaptive Background 
//      Mixture Model for Realtime Tracking with Shadow Detection". In Proc. 
//      2nd European Workshop on Advanced Video Based Surveillance Systems, 
//      AVBS01, VIDEO BASED SURVEILLANCE SYSTEMS: Computer Vision and 
//      Distributed Processing (September 2001)
//
////////////////////////////////////////////////////////////////////////////////

#ifndef FOREGROUND_DETECTOR_FTOR
#define FOREGROUND_DETECTOR_FTOR

// local includes
#include "ForegroundDetectorTraits.hpp"
#include "ForegroundDetectorUtil.hpp"

#ifdef __arm__
#include <limits>
#else
// export includes
#include <mfl_scalar/exp.hpp>

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
    
    template <typename image_type, typename stat_type>
    class ForegroundDetectorFunctor 
    {
      public:      
        
        typedef typename ForegroundDetectorTraits<stat_type>::Dims Dims;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GaussianMixtureModel GaussianMixtureModel;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GaussianIterator GaussianIterator;
        
        typedef typename ForegroundDetectorTraits<stat_type>::ConstGaussianIterator ConstGaussianIterator;
        
        typedef typename ForegroundDetectorTraits<stat_type>::GMMVector GMMVector;
        
        ///////////////////////////////////////////////////////////////////////
        // 
        // Constructor
        //
        ///////////////////////////////////////////////////////////////////////
        ForegroundDetectorFunctor()
        {
            mGMMPtr = NULL; // this gets initialized in setupImpl
        }
                    
                
        ///////////////////////////////////////////////////////////////////////
        //
        // Setup dimension info.
        //
        ///////////////////////////////////////////////////////////////////////
        void setup(Dims dims)
        {
            
            // should always have at least 2 dims
            VISION_ASSERT(dims.size() >= 2);
            mNumPixels   = dims[0] * dims[1];
            
            if (dims.size() > 2)                
                mNumChannels = dims[2];
            else
                mNumChannels = 1;

            mDims = dims;
                                    
        }     
     
        ////////////////////////////////////////////////////////////////////////
        //
        // TBB loop body operator() executes the foreground detection algorithm
        // on a range of pixels. 
        //
        ////////////////////////////////////////////////////////////////////////
#ifdef __arm__
        void operator()(mwSize rangeBegin, mwSize rangeEnd) const
#else
        void operator()(tbb::blocked_range<mwSize> & range) const
#endif
        {

            VISION_ASSERT_MSG(mGMMPtr != NULL,
                              "model pointer is NULL, you forgot to call setGMMVec first");
#ifdef __arm__            
            mwSize id = rangeBegin;
            mwSize end = rangeEnd;  
#else
            mwSize id  = range.begin();
            mwSize end = range.end();
#endif
            
            runAlgorithm(id, end);
        }

        ////////////////////////////////////////////////////////////////////////
        //
        // TBB loop body operator() executes the foreground detection algorithm
        // on a range of pixels.
        //
        ////////////////////////////////////////////////////////////////////////
#ifdef __arm__
        void operator()(unsigned long rangeBegin, unsigned long rangeEnd) const
#else
        void operator()(tbb::blocked_range<unsigned int> & range) const
#endif
        {
            
            VISION_ASSERT_MSG(mGMMPtr != NULL,
                              "model pointer is NULL, you forgot to call setGMMVec first");
#ifdef __arm__
            unsigned int id = rangeBegin;
            unsigned int end = rangeEnd;
#else
            unsigned int id  = range.begin();
            unsigned int end = range.end();
#endif

            runAlgorithmRowMajor(id, end);
        }
        
        ////////////////////////////////////////////////////////////////////////
        //
        // runAlgorithm and runAlgorithmRowMajor functions implement the loop to
        // run the foreground detector algorithm in row major or column major format.
        //
        ////////////////////////////////////////////////////////////////////////        
        void runAlgorithm(mwSize id, mwSize end) const
        {
            // loop over each pixel in the range
            for (; id != end; ++id)            
            {
                // extract gaussian mixture model and pixel
                const image_type * pixel = mImage+id;                
                GaussianMixtureModel & gmm = (mGMMPtr->at(id)).first;
                                               
                // run the algorithm 
                mForegroundMask[id] = detectForeground(gmm, pixel);
            }
        }

        void runAlgorithmRowMajor(mwSize id, mwSize end) const
        {
            // loop over each pixel in the range

            for (id = (id * mNumChannels); id < (end * mNumChannels); id = id + mNumChannels)
            {
                // extract gaussian mixture model and pixel
                const image_type * pixel = mImage+id;   
                mwSize indexValue = (id/mNumChannels);
                
                GaussianMixtureModel & gmm = (mGMMPtr->at(indexValue)).first;
                                               
                // run the algorithm 
                mForegroundMask[indexValue] = detectForegroundRowMajor(gmm, pixel);
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //
        // detectForeground  and detectForegroundRowMajor implements the
        // Stauffer-Grimson algorithm.  It returns true if the input pixel is
        // part of the foreground.
        //
        ////////////////////////////////////////////////////////////////////////
        bool detectForeground(GaussianMixtureModel & gmm,
                              const image_type * pixel) const
        {

            GaussianIterator matchingGaussian;
            
            // scan gaussian mixture model and return matching gaussian
            matchingGaussian = findMatchAndUpdate(gmm, pixel);
                
            // determine if current pixel is foreground or background
            return isForeground(gmm, matchingGaussian); 
                
        }

        bool detectForegroundRowMajor(GaussianMixtureModel & gmm,
                              const image_type * pixel) const
        {
            
            GaussianIterator matchingGaussian;
            
            // scan gaussian mixture model and return matching gaussian
            matchingGaussian = findMatchAndUpdateRowMajor(gmm, pixel);
            
            // determine if current pixel is foreground or background
            return isForeground(gmm, matchingGaussian);
            
        }
        
        ////////////////////////////////////////////////////////////////////////
        //
        // findMatchAndUpdate and findMatchAndUpdateRowMajor returns an iterator
        // to the gaussian to which the pixel belongs. The matching gaussian
        // statistics are updated based on the Stauffer-Grimsom update equations.
        // If the pixel does not belong to any existing gaussian then a
        // new gaussian is created for the pixel.
        //
        ////////////////////////////////////////////////////////////////////////
        GaussianIterator findMatchAndUpdate(GaussianMixtureModel & gmm, 
                                            const image_type * pixel) const
        {
            GaussianIterator matchingGaussian;

            // find a match for the pixel
            matchingGaussian = findMatch(gmm, pixel);
            stat_type scaleFactor;
            const stat_type one(1.0);
            const bool foundMatch = matchingGaussian != gmm.end();
            if (foundMatch)
            {                

                // optimization - instead of summing weights to calculate the
                // scale factor, use the fact that the sum of the weights is
                // always 1 and just use the weight update rule to figure out
                // what the scale factor should be after the weight is updated.
                stat_type weight = matchingGaussian->getWeight();               
                scaleFactor = one/(one + mLearningRate * (one - weight));

                // update matching gaussian parameters
                matchingGaussian->update(pixel, mLearningRate,
                                         mNumChannels, mNumPixels);
                
                // sort gaussians in mixture model from highest to lowest
                matchingGaussian = sortGaussians(gmm, matchingGaussian);
            }
            else // No match found for pixel.
            {
                stat_type weight = mInitialWeight;
                // When there is no match we need to add a new gaussian or
                // remove the lowest rank gaussian and replace it with a new
                // one.                                          
                if (!gmm.empty())
                {                    
                    // remove the lowest ranked gaussian if not yet reached
                    // mNumGaussians
                    if (gmm.size() == mNumGaussians)
                    {
                        weight -= gmm.back().getWeight(); // adjust for the popped weight
                        gmm.pop_back();                         
                    }
                }                                               
                                            
                // set pixel value as initial gaussian mean
                mwSize offset(0);
                typename WeightedGaussian<stat_type>::stat_vec mean(mNumChannels);
                for(mwSize i = 0; i < mNumChannels; ++i, offset += mNumPixels)
                {
                    mean[i] = static_cast<stat_type>(pixel[offset]);
                }
                gmm.push_back(WeightedGaussian<stat_type>(mNumChannels,mInitialWeight,
                                                              mean,mInitialVariance));

                // set the matchingGaussian to the end;  
                matchingGaussian = --(gmm.end());

                VISION_ASSERT(matchingGaussian->getWeight() == mInitialWeight);
                // optimization - compute scale factor without having to sum weights
                if (gmm.size() == 1)
                    scaleFactor = one/weight ;
                else
                    scaleFactor = one/(one + weight);
               
            }
                
            normalizeWeights(gmm, scaleFactor);
            return matchingGaussian;
        }

        ////////////////////////////////////////////////////////////////////////
        //
        // findMatchAndUpdate returns an iterator to the gaussian to which the
        // pixel belongs. The matching gaussian statistics are updated based on
        // the Stauffer-Grimsom update equations.  If the pixel does not belong
        // to any existing gaussian then a new gaussian is created for the
        // pixel.
        //
        ////////////////////////////////////////////////////////////////////////
        GaussianIterator findMatchAndUpdateRowMajor(GaussianMixtureModel & gmm,
                                            const image_type * pixel) const
        {
            GaussianIterator matchingGaussian;
            
            // find a match for the pixel
            matchingGaussian = findMatchRowMajor(gmm, pixel);
            
            stat_type scaleFactor;
            const stat_type one(1.0);
            const bool foundMatch = matchingGaussian != gmm.end();
            if (foundMatch)
            {
                
                // optimization - instead of summing weights to calculate the
                // scale factor, use the fact that the sum of the weights is
                // always 1 and just use the weight update rule to figure out
                // what the scale factor should be after the weight is updated.
                stat_type weight = matchingGaussian->getWeight();
                scaleFactor = one/(one + mLearningRate * (one - weight));
                
                // update matching gaussian parameters
                matchingGaussian->updateRowMajor(pixel, mLearningRate,
                                         mNumChannels, mNumPixels);
                // sort gaussians in mixture model from highest to lowest
                matchingGaussian = sortGaussians(gmm, matchingGaussian);
            }
            else // No match found for pixel.
            {
                stat_type weight = mInitialWeight;
                // When there is no match we need to add a new gaussian or
                // remove the lowest rank gaussian and replace it with a new
                // one.
                if (!gmm.empty())
                {
                    // remove the lowest ranked gaussian if not yet reached
                    // mNumGaussians
                    if (gmm.size() == mNumGaussians)
                    {
                        weight -= gmm.back().getWeight(); // adjust for the popped weight
                        gmm.pop_back();
                    }
                }
                
                // set pixel value as initial gaussian mean
                typename WeightedGaussian<stat_type>::stat_vec mean(mNumChannels);

                for(mwSize i = 0; i < mNumChannels; ++i)
                {
                    mean[i] = static_cast<stat_type>(pixel[i]);
                }
                
                gmm.push_back(WeightedGaussian<stat_type>(mNumChannels,mInitialWeight,
                                                          mean,mInitialVariance));
                
                // set the matchingGaussian to the end;
                matchingGaussian = --(gmm.end());
                
                VISION_ASSERT(matchingGaussian->getWeight() == mInitialWeight);
                // optimization - compute scale factor without having to sum weights
                if (gmm.size() == 1)
                    scaleFactor = one/weight ;
                else
                    scaleFactor = one/(one + weight);
                
            }
            
            normalizeWeights(gmm, scaleFactor);
            return matchingGaussian;
        }

        ///////////////////////////////////////////////////////////////////////
        //
        // isForeground return true if the pixel is found to be part of the 
        // foreground.
        //
        ///////////////////////////////////////////////////////////////////////
        bool isForeground(const GaussianMixtureModel & gmm, 
                          const GaussianIterator matchingGaussian) const
        {
           
            bool isForeground = true;
            ConstGaussianIterator start = gmm.begin();

            // quick exit if matchingGaussian is highest rank
            if (matchingGaussian == start) 
                return !isForeground;

            ConstGaussianIterator stop = gmm.end();
            
            // there should always be gaussians in the model
            VISION_ASSERT(start != stop);
            // Sum up the weights and compare against threshold                       
            stat_type wSum(0.0);
            for( ; start != stop; ++start)
            {
                wSum += start->getWeight();
                // we must meet the minimum background ratio to decide whether
		// or not pixel is foreground
#ifdef __arm__
                if ((mMinimumBackgroundRatio - wSum) <= std::numeric_limits<stat_type>::epsilon() )

#else
                if ((mMinimumBackgroundRatio - wSum) <=
                    mfl_scalar::Eps<stat_type>(1.0))
#endif
                {
                    if (matchingGaussian == start)
                        return !isForeground;
                    else
                        return isForeground;
                    // this means matchingGaussian has to be foreground
                    
                }
                if (matchingGaussian == start)
                {
                    // reached matching gaussian but did not reach min
                    // means this has to be part of background because
                    // gaussians are sorted and the wSum is increasing.
                    return !isForeground;
                }
            }

            // Sanity check: make sure we go no further if we've reached end of
            // the list, Return false to indicate matchingGaussian has to be
            // part of background model if we've reached the end of the list.
            VISION_ASSERT(false);
            return !isForeground; // must be background
            
        }               

        ///////////////////////////////////////////////////////////////////////
        //
        // sortGaussians sorts the gaussians in a mixture model from the
        // matching gaussian to the highest ranked gaussian and returns a
        // pointer to the same element that the input matchingGaussian pointed
        // to prior to sorting.
        //
        ///////////////////////////////////////////////////////////////////////
        GaussianIterator sortGaussians(GaussianMixtureModel & gmm, 
                                       GaussianIterator matchingGaussian) const
        {
            // get the index of the matching gaussian            
            typename GaussianIterator::difference_type matchID;

            matchID = matchingGaussian - gmm.begin();

            // move the matching gaussian up the model vector if it has higher rank
            while (matchID > 0)
            {
                // percolate up if ranked higher
                if( gmm[matchID] > gmm[matchID-1])
                {
                    std::swap(gmm[matchID],gmm[matchID-1]);
                    matchID--; // update match index
                }
                else // in correct position
                {                    
                    break;
                }
            }
            return gmm.begin() + matchID;
            
        }
        
        ///////////////////////////////////////////////////////////////////////
        //
        // findMatch and findMatchRowMajor returns an iterator to the gaussian
        // which is closest to the pixel. If there is no match, the returned
        // iterator will equal last.
        //
        ///////////////////////////////////////////////////////////////////////
        GaussianIterator findMatch(GaussianMixtureModel & gmm, 
                                   const image_type * pixel ) const
        {
         
            GaussianIterator first = gmm.begin();
            GaussianIterator last  = gmm.end();

            // follow same semantics as std::find: returns the one-past-the-last
            // iterator when there is no match.

            // loop over gaussians in mixture model
            for( ; first != last; ++first)
            {
                
                if (first->isMatch(pixel, mVarianceThreshold,
                                   mNumPixels))
                {
                    break; // first to match wins
                }                
                
            }
            return first;
        }

        GaussianIterator findMatchRowMajor(GaussianMixtureModel & gmm, 
                                   const image_type * pixel ) const
        {
         
            GaussianIterator first = gmm.begin();
            GaussianIterator last  = gmm.end();

            // follow same semantics as std::find: returns the one-past-the-last
            // iterator when there is no match.
    
            // loop over gaussians in mixture model
            for( ; first != last; ++first)
            {
                if (first->isMatchRowMajor(pixel, mVarianceThreshold,
                                   mNumPixels))
                {
                    break; // first to match wins
                }                
                
            }
            return first;
        }        
             
        ///////////////////////////////////////////////////////////////////////
        // 
        // normalizeWeights - normalizes the weights of the gaussians in the
        // mixture model
        ///////////////////////////////////////////////////////////////////////        
        void normalizeWeights(GaussianMixtureModel & gmm, 
                              stat_type scaleFactor) const
        {

            GaussianIterator start = gmm.begin();
            GaussianIterator stop  = gmm.end();
                        
            for( ; start != stop; ++start)
            {
                start->scaleWeight(scaleFactor);    
            }
        }
      
        ///////////////////////////////////////////////////////////////////////
        //
        // set mGMMPtr to the gaussian mixture model vector. 
        //
        ///////////////////////////////////////////////////////////////////////
        void setGMMVec(GMMVector * gmm)
        {
            mGMMPtr = gmm;
        }

        ///////////////////////////////////////////////////////////////////////
        // 
        // Set input data for functor. 
        //
        ///////////////////////////////////////////////////////////////////////
        inline void setStepInput(const image_type * image, stat_type learningRate)
        {
            mImage = image;
            mLearningRate = learningRate;
        }

        ///////////////////////////////////////////////////////////////////////
        //
        // Set the output location for the functor
        //
        ///////////////////////////////////////////////////////////////////////
        inline void setStepOutput(boolean_T * output)
        {
            mForegroundMask = output;
        }
        
        ///////////////////////////////////////////////////////////////////////
        //
        // Set runtime properties. These properties need to be set right before
        // the algorithm is run (stepped).
        //
        ///////////////////////////////////////////////////////////////////////        
        void setProperties(mwSize numGaussians, 
                           stat_type initialVariance,
                           stat_type initialWeight,
                           stat_type varianceThreshold,
                           stat_type minBGRatio)
        {
            mNumGaussians    = numGaussians;
            mInitialVariance = initialVariance;
            mInitialWeight   = initialWeight;
            mVarianceThreshold = varianceThreshold;
            mMinimumBackgroundRatio = minBGRatio;            
        }
        
        ///////////////////////////////////////////////////////////////////////
        Dims getDims()
        {
            return mDims;
        }
        
        ///////////////////////////////////////////////////////////////////////
        mwSize getNumGaussians()
        {
            return mNumGaussians;
        }

        ///////////////////////////////////////////////////////////////////////
        mwSize getNumChannels()
        {
            return mNumChannels;
        }

        ///////////////////////////////////////////////////////////////////////
        mwSize getNumPixels()
        {
            return mNumPixels;
        }
        
        
      private: // data members
     
        GMMVector * mGMMPtr; // pointer to contain holding every mixture model
        Dims mDims;          // dimension info 
        const image_type * mImage; // pointer to input image
        stat_type mLearningRate;   // learning rate
        boolean_T * mForegroundMask;     // pointer to output mask        
        mwSize mNumGaussians;
        mwSize mNumPixels;
        mwSize mNumChannels;
        stat_type mInitialWeight;
        stat_type mInitialVariance;
        stat_type mVarianceThreshold;
        stat_type mMinimumBackgroundRatio;
    };

} // end vision namespace


#endif
