function [t1,t2] = estimateUncalibratedRectification(...
  f,inlier_points1,inlier_points2,imageSize)
%estimateUncalibratedRectification Uncalibrated stereo rectification
%   [T1,T2] = estimateUncalibratedRectification(
%     F,INLIER_POINTS1,INLIER_POINTS2,IMAGESIZE) returns projective 
%   transformations for rectifying stereo images. This function does not
%   require either intrinsic nor extrinsic camera parameters.
% 
%     INLIER_POINTS1 and INLIER_POINTS2 specify the corresponding points in
%     the stereo images I1 and I2, respectively. INLIER_POINTS1 and
%     INLIER_POINTS2 can be cornerPoints objects, SURFPoints objects,
%     MSERRegions objects, BRISKPoints objects, or M-by-2 matrices of [x,y]
%     coordinates.
% 
%     F is a 3-by-3 fundamental matrix for the stereo images. If P1, a
%     point in I1, corresponds to P2, a point in I2, then 
%     [P2,1] * F * [P1,1]' = 0.
% 
%     IMAGESIZE is the size of I2, and is in the format returned by
%     the function SIZE. 
% 
%     T1 and T2 are 3-by-3 matrices describing the projective
%     transformations for I1 and I2, respectively.
% 
%   Note that applying T1 (or T2) to I1 (or I2) may result in an undesired
%   distortion, if the epipole is located within I1 (or I2). You can use
%   function isEpipoleInImage to check if the epipole is inside the image.
% 
%   Class Support
%   -------------
%   F must be double or single. IMAGESIZE must be double, single, or
%   integer. INLIER_POINTS1 and INLIER_POINTS2 can be cornerPoints objects,
%   SURFPoints objects, MSERRegions objects, BRISKPoints objects, or M-by-2
%   matrices of [x,y] coordinates. T1 and T2 have the same class as F.
% 
%   Example 1
%   ---------
%   % Load the stereo images and feature points which are already matched.
%   I1 = imread('yellowstone_left.png');
%   I2 = imread('yellowstone_right.png');
%   load yellowstone_inlier_points;
% 
%   % Display point correspondences. Notice that the inlier points are in
%   % different rows, indicating that the stereo pair is not rectified.
%   showMatchedFeatures(I1, I2, inlier_points1, inlier_points2, 'montage');
%   title('Original images and inlier feature points');
% 
%   % Compute the fundamental matrix from the corresponding points.
%   f = estimateFundamentalMatrix(inlier_points1, inlier_points2,...
%     'Method', 'Norm8Point');
% 
%   % Compute the rectification transformations.
%   [t1, t2] = estimateUncalibratedRectification(f, inlier_points1, ...
%                inlier_points2, size(I2));
%   
%   % Rectify the stereo images using projective transformations t1 and t2.
%   [I1Rect, I2Rect] = rectifyStereoImages(I1, I2, t1, t2);
%   
%   % Display the stereo anaglyph, which can be viewed with 3-D glasses.
%   figure;
%   imshow(stereoAnaglyph(I1Rect, I2Rect));
%
%   Example 2
%   ---------
%   % Automatically register and rectify stereo images. This example
%   % detects SURF features in stereo images, matches them, computes
%   % the fundamental matrix, and then rectifies the images. 
%   % <a href="matlab:web(fullfile(matlabroot,'toolbox','vision','visiondemos','html','UncalibratedStereoRectificationExample.html'))">View example</a>
% 
% See also estimateFundamentalMatrix, rectifyStereoImages,
%   detectHarrisFeatures, detectMinEigenFeatures, detectFASTFeatures,
%   detectSURFFeatures, detectMSERFeatures, detectBRISKFeatures,
%   extractFeatures, matchFeatures
% 
% References:
%   R. Hartley, A. Zisserman, "Multiple View Geometry in Computer Vision,"
%   Cambridge University Press, 2003.

% Copyright 2010 The MathWorks, Inc.

%#codegen

%--------------------------------------------------------------------------
% Check the inputs.
%--------------------------------------------------------------------------
[points1, points2] = checkInputs(f, inlier_points1, inlier_points2, ...
    imageSize);

%--------------------------------------------------------------------------
% Compute the projective transformations.
%--------------------------------------------------------------------------
[t1, t2] = cvalgEstimateUncalibratedRectification(f, points1, points2, ...
    imageSize);

%==========================================================================
function [points1, points2] = checkInputs(f, inlier_points1, ...
    inlier_points2, imageSize)
%--------------------------------------------------------------------------
% Check the Fundamental matrix
%--------------------------------------------------------------------------
validateattributes(f, {'double', 'single'}, ...
  {'2d', 'nonsparse', 'nonempty', 'real', 'size', [3,3]},...
  mfilename, 'F'); %#ok<EMCA>

%--------------------------------------------------------------------------
% Check the image size
%--------------------------------------------------------------------------
validateattributes(imageSize, {'single', 'double', 'int8', 'int16', ...
  'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}, ...
  {'vector', 'nonsparse', 'nonempty', 'real', 'positive', 'integer'},...
  mfilename, 'IMAGESIZE'); %#ok<EMCA>

coder.internal.errorIf(length(imageSize) < 2,...
  'vision:estimateUncalibratedRectification:invalidImageSize');

%--------------------------------------------------------------------------
% Check the points
%--------------------------------------------------------------------------
[points1, points2] = ...
    vision.internal.inputValidation.checkAndConvertMatchedPoints(...
    inlier_points1, inlier_points2, mfilename, 'INLIER_POINTS1','INLIER_POINTS2');
