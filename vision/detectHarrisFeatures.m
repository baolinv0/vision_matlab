function pts = detectHarrisFeatures(I,varargin)
% detectHarrisFeatures Find corners using the Harris-Stephens algorithm
%   points = detectHarrisFeatures(I) returns a cornerPoints object,
%   points, containing information about the feature points detected in a
%   2-D grayscale image I. detectHarrisFeatures uses the Harris-Stephens
%   algorithm to find feature points.
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
% The input image I can be logical, uint8, int16, uint16, single, or
% double, and it must be real and nonsparse.
%
% Example
% -------  
% % Find and plot corner points in an image.
% I = imread('cameraman.tif');
% corners = detectHarrisFeatures(I);
% imshow(I); hold on;
% plot(corners.selectStrongest(50));
%
% See also cornerPoints, detectMinEigenFeatures, detectFASTFeatures,
%          detectBRISKFeatures, detectSURFFeatures, detectMSERFeatures,
%          extractFeatures, matchFeatures

% Reference
% ---------
% C. Harris and M. Stephens. "A Combined Corner and Edge Detector."
% Proceedings of the 4th Alvey Vision Conference. August 1988, pp. 147-151.

% Copyright  The MathWorks, Inc.

%#codegen
pts = vision.internal.detector.harrisMinEigen('Harris', I, varargin{:});
