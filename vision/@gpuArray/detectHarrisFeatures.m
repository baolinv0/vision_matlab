function pts = detectHarrisFeatures(I,varargin)
%detectHarrisFeatures Find corners using the Harris-Stephens algorithm
%   points = detectHarrisFeatures(I) returns a cornerPoints object, points,
%   containing information about the feature points detected in a 2-D
%   grayscale gpuArray image I.
%
%   points = detectHarrisFeatures(I,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'MinQuality'  A scalar Q, 0 <= Q <= 1, specifying the minimum accepted
%                 quality of corners as a fraction of the maximum corner
%                 metric value in the image. Larger values of Q can be used
%                 to remove erroneous corners.
% 
%                 Default: 0.01
%
%   'FilterSize'  An odd integer, S >= 3, specifying a Gaussian filter 
%                 which is used to smooth the gradient of the image.
%                 The size of the filter is S-by-S and the standard
%                 deviation of the filter is (S/3).
%
%                 Default: 5
%
%   'ROI'         A vector of the format [X Y WIDTH HEIGHT], specifying
%                 a rectangular region in which corners will be detected.
%                 [X Y] is the upper left corner of the region.
%
%                 Default: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% The input image I can be a gpuArray with underlying types of logical,
% uint8, int16, uint16, single, or double, and it must be real.
%
% Example
% -------  
% % Find and plot corner points in an image.
% I = gpuArray(imread('cameraman.tif'));
% cornersGPU = detectHarrisFeatures(I);
% imshow(I); hold on;
% plot(cornersGPU.selectStrongest(50));
%
% % copy the corner points back off the GPU for further processing.
% cornersCPU = gather(cornersGPU);
%
% See also cornerPoints, detectMinEigenFeatures, detectFASTFeatures,
%          detectBRISKFeatures, detectSURFFeatures, detectMSERFeatures,
%          extractFeatures, matchFeatures, gpuArray

% Reference
% ---------
% C. Harris and M. Stephens. "A Combined Corner and Edge Detector."
% Proceedings of the 4th Alvey Vision Conference. August 1988, pp. 147-151.

% Copyright 2014-2015 The MathWorks, Inc.

pts = vision.internal.detector.harrisMinEigen('Harris', I, varargin{:});