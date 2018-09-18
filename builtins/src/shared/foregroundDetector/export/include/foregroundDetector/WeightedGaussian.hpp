////////////////////////////////////////////////////////////////////////////////
//  This header contains the WeightedGaussianNew class used to implement the
//  Stauffer-Grimson background subtraction algorithm [1,2]. This implementation
//  is used in vision.ForegroundDetector system object. 
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

#ifndef WEIGHTED_GAUSSIAN_HPP
#define WEIGHTED_GAUSSIAN_HPP

// local includes
#include "ForegroundDetectorUtil.hpp"

#ifdef __arm__
#include <cmath>
#else
// export includes
#include <mfl_scalar/exp.hpp>
#include <mfl_scalar/basic_math.hpp>
#endif

// system includes
#include <vector>
#include <algorithm>
#include <numeric>

namespace vision
{

    ///////////////////////////////////////////////////////////////////////////
    //
    // The WeightedGaussianNew class defines one of the weighted gaussians used in
    // a gaussian mixture model. The class provides methods needed to update
    // it's statistics and weight.
    //
    ///////////////////////////////////////////////////////////////////////////  
    template <typename stat_type>
    class WeightedGaussian
    {        
      public:
        
        // holds multi-channel mean and variance values
        typedef std::vector<stat_type> stat_vec;
        
        ////////////////////////////////////////////////////////////////////////      
        // 
        // Create WeightedGaussianNew given a weight, a mean vector, and a
        // variance.
        // 
        ////////////////////////////////////////////////////////////////////////      
        WeightedGaussian(mwSize nChannels, const stat_type weight, 
                         const stat_vec & mean, const stat_type variance)
        {
            initialize(nChannels, weight, mean, variance);

        }            

        ////////////////////////////////////////////////////////////////////////      
        //
        // Create WeightedGaussianNew given scalar weight, means, and variances.
        //
        ////////////////////////////////////////////////////////////////////////      
        WeightedGaussian(mwSize nChannels, const stat_type weight, const
                         stat_type mean, const stat_type variance) 
        {
            initialize(nChannels, weight, stat_vec(nChannels,mean),variance);
        }

        ////////////////////////////////////////////////////////////////////////    
        //
        // Create WeightedGaussianNew given pointers to weight, means, and
        // variances.
        //
        ////////////////////////////////////////////////////////////////////////      
        WeightedGaussian(mwSize numChannels, 
                         mwSize numPixels,
                         const stat_type * weight, 
                         const stat_type * mean, 
                         const stat_type * variance)
        {
            // mean and variance are expected to be pointers to RGB column-major
            // arrays.  So we need to offset by numPixels to get the right
            // channel data for a pixel.
            stat_vec m(numChannels),v(numChannels);
            mwSize offset(0);

            for (mwSize i = 0; i < numChannels; ++i, offset += numPixels)
            {
                m[i] = mean[offset];
                v[i] = variance[offset];
            }
            
            initialize(numChannels, *weight, m, v);
        }            
        
        ////////////////////////////////////////////////////////////////////////   
        //
        // isMatch : returns true if the distance from the pixel value to the
        // gaussian mean is below the threshold. 
        //
        ////////////////////////////////////////////////////////////////////////      
        template <typename pixel_type>
        inline bool isMatch(const pixel_type * pixel, 
                            const stat_type threshold, 
                            const mwSize numPixels )
        {
            // compute the distance to gaussian and return true if distance <
            // threshold                     
            typename stat_vec::iterator currentIter,endIter;

            stat_type distance, sumDistance(0);           
            
            currentIter = mMean.begin();
            endIter = mMean.end();
            
            for(mwSize offset = 0; currentIter != endIter; ++currentIter, offset += numPixels)
            {                
                distance = static_cast<stat_type>(pixel[offset]) - *currentIter; 
                sumDistance += distance * distance;                
            }

            stat_type sumV = std::accumulate(mVariance.begin(),mVariance.end(),(stat_type)0.0);
            return sumDistance < (threshold * sumV);

        }

        ////////////////////////////////////////////////////////////////////////   
        //
        // isMatchRowMajor : Row major version of isMatch function
        //
        ////////////////////////////////////////////////////////////////////////      
        template <typename pixel_type>
        inline bool isMatchRowMajor(const pixel_type * pixel, 
                            const stat_type threshold, 
                            const mwSize numPixels )
        {
            // compute the distance to gaussian and return true if distance <
            // threshold                     
            typename stat_vec::iterator currentIter,endIter;

            stat_type distance, sumDistance(0);           
            
            currentIter = mMean.begin();
            endIter = mMean.end();
            
            for(mwSize offset = 0; currentIter != endIter; ++currentIter, offset++)
            {
                distance = static_cast<stat_type>(pixel[offset]) - *currentIter; 
                sumDistance += distance * distance;                
            }

            stat_type sumV = std::accumulate(mVariance.begin(),mVariance.end(),(stat_type)0.0);
            return sumDistance < (threshold * sumV);

        }               

        ////////////////////////////////////////////////////////////////////////
        //
        // update : updates the weight, means, and variances of a gaussian based
        // on a pixel value and learningRate. The update equations are from:
        // 
        //      P. Kaewtrakulpong, R. Bowden, "An Improved Adaptive Background 
        //      Mixture Model for Realtime Tracking with Shadow Detection". In Proc. 
        //      2nd European Workshop on Advanced Video Based Surveillance Systems, 
        //      AVBS01, VIDEO BASED SURVEILLANCE SYSTEMS: Computer Vision and 
        //      Distributed Processing (September 2001)
        //
        ////////////////////////////////////////////////////////////////////////      
        template <typename pixel_type>
        void update(const pixel_type * pixel, stat_type learningRate, 
                    const mwSize numChannels, const mwSize numPixels)
        {
            // update mean and variance
            mwSize offset(0);
            for(mwSize i = 0; i < numChannels; ++i, offset += numPixels)
            {                
                stat_type d = static_cast<stat_type>(pixel[offset]) - mMean[i];                
                mMean[i] = mMean[i] + learningRate * d;                
                mVariance[i] = mVariance[i] + learningRate * (d*d - mVariance[i]);
            }

            // update weight
            mWeight = mWeight + learningRate * (1 - mWeight);

        }

        ////////////////////////////////////////////////////////////////////////
        // updateRowMajor: Row major version of update function
        ////////////////////////////////////////////////////////////////////////
        template <typename pixel_type>
        void updateRowMajor(const pixel_type * pixel, stat_type learningRate, 
                    const mwSize numChannels, const mwSize numPixels)
        {
            // update mean and variance
            for(mwSize i = 0; i < numChannels; ++i)
            {                
                stat_type d = static_cast<stat_type>(pixel[i]) - mMean[i];                
                mMean[i] = mMean[i] + learningRate * d;                
                mVariance[i] = mVariance[i] + learningRate * (d*d - mVariance[i]);
            }

            // update weight
            mWeight = mWeight + learningRate * (1 - mWeight);

        }
        
        ////////////////////////////////////////////////////////////////////////    
        //
        // rank: return the rank of the gaussian as mWeight/sqrt(sum(mVariance))
        //
        ////////////////////////////////////////////////////////////////////////      
        inline stat_type rank() const
        {                        
            stat_type sumV = std::accumulate(mVariance.begin(),
                                             mVariance.end(),
                                             static_cast<stat_type>(0.0));
            stat_type rankV;

#ifdef __arm__
            rankV = mWeight/(std::sqrt(sumV));
#else
            rankV = mWeight/(mfl_scalar::Sqrt(sumV));
#endif
            return rankV;
        }
        
        ////////////////////////////////////////////////////////////////////////      
        //
        // scaleWeight - scales the weight by the specified factor and returns
        //               the updated value.
        //
        ////////////////////////////////////////////////////////////////////////      
        inline stat_type scaleWeight(stat_type factor)
        {
            // scales weight and returns scaled value
            return (mWeight *= factor);
        }
           
        ////////////////////////////////////////////////////////////////////////   
        //
        // operator > : overload greater than such that G1 > G2 returns true
        // when the rank of G1 is greater than the rank of G2. This is used to
        // sort the gaussians in a mixture model.
        //
        ////////////////////////////////////////////////////////////////////////      
        inline bool operator>(const WeightedGaussian<stat_type> &other) const
        {

            // return true when the rank of one gaussian is greater than another
            return this->rank() > other.rank();
        }
          
        
      public: // getters and setters
        ////////////////////////////////////////////////////////////////////////      
        //
        // Set mean value
        //
        ////////////////////////////////////////////////////////////////////////      
        void setMean(const stat_vec & mean)
        {            
            mMean = mean;
        }
        
        ////////////////////////////////////////////////////////////////////////      
        //
        // Set variance value
        //
        ////////////////////////////////////////////////////////////////////////      
        void setVariance(const stat_vec & variance)
        {            
            mVariance = variance;
        }
        
        ////////////////////////////////////////////////////////////////////////      
        //
        // Set weight value
        //
        ////////////////////////////////////////////////////////////////////////      
        void setWeight(const stat_type weight)
        {
            mWeight = weight;
        }
        
        ////////////////////////////////////////////////////////////////////////      
        //
        // Copy mMean into an array. This is for serializing the object.
        //
        ////////////////////////////////////////////////////////////////////////      
        void copyMeanInto(stat_type * meanDst, const mwSize offset) const
        {
            // copies mean into mxArray style matrix
            copyStat(mMean, meanDst, offset);
        }

        ////////////////////////////////////////////////////////////////////////  
        //
        // Copy mVariance into an array. This is for serializing the object.
        //
        ////////////////////////////////////////////////////////////////////////      
        void copyVarianceInto(stat_type * varDst, const mwSize offset) const
        {
            // copies variance into mxArray style matrix
            copyStat(mVariance, varDst, offset);
        }
      
        //////////////////////////////////////////////////////////////////////// 
        //
        // Get weight value
        //
        ////////////////////////////////////////////////////////////////////////      
        inline stat_type getWeight() const
        {
            return mWeight;  
        }

        ////////////////////////////////////////////////////////////////////////      
        //
        // Get mean values
        //
        ////////////////////////////////////////////////////////////////////////      
        const stat_vec getMean() const
        {
            return mMean;
        }

        ////////////////////////////////////////////////////////////////////////      
        // 
        // get variance values
        //
        ////////////////////////////////////////////////////////////////////////      
        const stat_vec getVariance() const
        {
            return mVariance;
        }
        
      private: // member functions
        ////////////////////////////////////////////////////////////////////////      
        //
        // copies vector content into array.  Used to serialize object data.
        //
        ////////////////////////////////////////////////////////////////////////      
        void inline copyStat(const stat_vec & src, stat_type * dst, 
                             const mwSize offset) const
        {
            mwSize nChannels = src.size();
            for (mwSize i = 0; i < nChannels; ++i, dst += offset)
            {
                *dst = src[i];                
            }
        }
        
        ////////////////////////////////////////////////////////////////////////      
        //
        // initialize the gaussian parameters
        //
        ////////////////////////////////////////////////////////////////////////      
        void initialize(mwSize nChannels, const stat_type weight, 
                        const stat_vec & mean, const stat_type variance)
        {
            VISION_ASSERT(variance > (stat_type)0.0);
            setWeight(weight);          
            setMean(mean);
            setVariance(stat_vec(nChannels, variance));
        }

        ////////////////////////////////////////////////////////////////////////      
        //
        // initialize the gaussian parameters
        //
        ////////////////////////////////////////////////////////////////////////      
        void initialize(mwSize nChannels, const stat_type weight, 
                        const stat_vec & mean, const stat_vec & variance)
        {
            setWeight(weight);          
            setMean(mean);
            setVariance(variance);
        }

      private: // data members
        stat_type mWeight;
        stat_vec mMean;
        stat_vec mVariance; 

    };
	

    
}// end vision namespace


#endif
