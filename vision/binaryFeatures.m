%binaryFeatures Object for storing binary feature vectors
%
%   binaryFeatures stores binary feature vectors extracted by algorithms
%   such as Fast Retina Keypoint (FREAK).
%
%   FEATURES = binaryFeatures(FEATURE_VECTORS) constructs a binaryFeatures
%   object from FEATURE_VECTORS, an M-by-N matrix of M binary feature 
%   vectors stored in N uint8 scalar containers.
%   
%   Notes:
%   ======
%   - The main purpose of this class is to pass the data between
%     extractFeatures and matchFeatures functions.
%
%   binaryFeatures public properties:
%      Features         - M-by-N matrix of M binary feature vectors
%      NumBits          - number of bits per feature vector
%      NumFeatures      - number of feature vectors held by the object
%
%   Example: Match two sets of binary feature vectors
%   -------------------------------------------------
%   features1 = binaryFeatures(uint8([1 8 7 2; 8 1 7 2]));
%   features2 = binaryFeatures(uint8([8 1 7 2; 1 8 7 2]));
%   % match the vectors using the Hamming distance
%   [indexPairs matchMetric] = matchFeatures(features1, features2)
%
% See also extractFeatures, matchFeatures

% Copyright 2012 The MathWorks, Inc.

%#codegen

classdef binaryFeatures < vision.internal.EnforceScalarValue
    
    properties (SetAccess='private', GetAccess='public')
        Features;
        NumBits;
        NumFeatures;
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = binaryFeatures(in)
            validateattributes(in, {'uint8'}, {'2d', 'real'}, ...
                'binaryFeatures', 'FEATURE_VECTORS'); %#ok
            
            numBitsInUint8 = 8;
            
            this.NumBits     = size(in, 2) * numBitsInUint8;
            this.NumFeatures = size(in, 1);           
            this.Features    = in;
        end             
    end
end
