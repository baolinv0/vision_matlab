function pts = detectFASTFeatures(I, varargin)
% detectFASTFeatures Find corners using the FAST algorithm on the GPU
%   points = detectFASTFeatures(I) returns a cornerPoints object,
%   points, containing information about the feature points detected in a
%   2-D grayscale image I. detectFASTFeatures uses the Features from
%   Accelerated Segment Test (FAST) algorithm to find feature points.
%   points.Location and points.Metric are gpuArrays.
%
%   points = detectFASTFeatures(I,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MinQuality'   A scalar Q, 0 <= Q <= 1, specifying the minimum accepted
%                  quality of corners as a fraction of the maximum corner
%                  metric value in the image. Larger values of Q can be
%                  used to remove erroneous corners.
% 
%                  Default: 0.1
%
%   'MinContrast'  A scalar T, 0 < T < 1, specifying the minimum intensity
%                  difference between a corner and its surrounding region,
%                  as a fraction of the maximum value of the image class.
%                  Increasing the value of T reduces the number of detected
%                  corners.
%
%                  Default: 0.2
%
%   'ROI'          A vector of the format [X Y WIDTH HEIGHT], specifying
%                  a rectangular region in which corners will be detected.
%                  [X Y] is the upper left corner of the region.
%
%                 Default: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% The input image I is a gpuArray with a datatype of logical, uint8, int16,
% uint16, single, or double, and it must be real and nonsparse.
%
% Example
% -------  
% % Find and plot corner points in the image.
% I = gpuArray(imread('cameraman.tif'));
% corners = detectFASTFeatures(I);
% imshow(I)
% hold on
% plot(corners.selectStrongest(50))
%
% See also detectFASTFeatures, cornerPoints, gpuArray/detectHarrisFeatures,
%          detectMinEigenFeatures, detectBRISKFeatures, detectSURFFeatures,
%          detectMSERFeatures, extractFeatures, matchFeatures

% Reference
% ---------
% E. Rosten and T. Drummond. "Fusing Points and Lines for High
% Performance Tracking." Proceedings of the IEEE International
% Conference on Computer Vision Vol. 2 (October 2005): pp. 1508?1511.

% Copyright 2015  The MathWorks, Inc.

% Check the input image and convert it to the range of uint8.
params = vision.internal.detector.fast.parseInputs(I, varargin{:});

I_u8 = im2uint8(I);

[I_u8c, expandedROI] = vision.internal.detector.fast.cropImage(I_u8, params);

% Convert the minContrast property to the range of uint8.
minContrast = im2uint8(params.MinContrast);

% Find corner locations by using OpenCV.
rawPts = ocvDetectFASTgpumex(I_u8c, minContrast);

[locations, metricValues] = vision.internal.detector.applyMinQuality(rawPts, params);

if params.usingROI
    % Because the ROI was expanded earlier, we need to exclude corners
    % which are outside the original ROI.
    [locations, metricValues] ...
        = vision.internal.detector.excludePointsOutsideROI(...
            params.ROI, expandedROI, locations, metricValues);
end

% Pack the output into a cornerPoints object.
pts = cornerPoints(locations, 'Metric', metricValues);
