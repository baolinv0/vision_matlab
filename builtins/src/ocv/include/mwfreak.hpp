
#include "opencv2/features2d.hpp"

//! @addtogroup xfeatures2d_experiment
//! @{

/** @brief Class implementing the FREAK (*Fast Retina Keypoint*) keypoint descriptor, described in @cite AOV12 .

The algorithm propose a novel keypoint descriptor inspired by the human visual system and more
precisely the retina, coined Fast Retina Key- point (FREAK). A cascade of binary strings is
computed by efficiently comparing image intensities over a retinal sampling pattern. FREAKs are in
general faster to compute with lower memory load and also more robust than SIFT, SURF or BRISK.
They are competitive alternatives to existing keypoints in particular for embedded applications.

@note
   -   An example on how to use the FREAK descriptor can be found at
        opencv_source_code/samples/cpp/freak_demo.cpp
 */

namespace cv
{
    
class CV_EXPORTS_W MWFREAK : public Feature2D
{
public:

    enum
    {
        NB_SCALES = 64, NB_PAIRS = 512, NB_ORIENPAIRS = 45
    };

    /**
    @param orientationNormalized Enable orientation normalization.
    @param scaleNormalized Enable scale normalization.
    @param patternScale Scaling of the description pattern.
    @param nOctaves Number of octaves covered by the detected keypoints.
    @param selectedPairs (Optional) user defined selected pairs indexes,
     */
    CV_WRAP static Ptr<MWFREAK> create(bool orientationNormalized = true,
                             bool scaleNormalized = true,
                             float patternScale = 22.0f,
                             int nOctaves = 4,
                             const std::vector<int>& selectedPairs = std::vector<int>());
};

} // namespace cv