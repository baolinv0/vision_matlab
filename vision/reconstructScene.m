% reconstructScene Reconstructs a 3-D scene from a disparity map.
%   xyzPoints = reconstructScene(disparityMap, stereoParams)  
%   returns an M-by-N-by-3 array of [X,Y,Z] coordinates of world points 
%   corresponding to pixels in disparityMap, an M-by-N array of disparity 
%   values. stereoParams is a stereoParameters object. The 3-D world 
%   coordinates are relative to the optical center of camera 1 of the stereo
%   system represented by stereoParams.
% 
%   Notes
%   -----
%   disparity function uses -realmax('single') to mark pixels for which
%   disparity estimate is unreliable. For such pixels reconstructScene
%   sets the world coordinates to NaN. For pixels with zero disparity,
%   the world coordinates are set to Inf.
% 
%   Class Support
%   -------------
%   disparityMap can be double or single. xyzPoints is double if 
%   disparityImage is double, otherwise it is single. stereoParams must be
%   a stereoParameters object.
% 
%   Example:
%   --------
%   % Load stereoParams
%   load('webcamsSceneReconstruction.mat');
%
%   % Read in the stereo pair of images.
%   I1 = imread('sceneReconstructionLeft.jpg');
%   I2 = imread('sceneReconstructionRight.jpg');
%
%   % Rectify the images.
%   [J1, J2] = rectifyStereoImages(I1, I2, stereoParams);
%
%   % Display the images after rectification.
%   figure 
%   imshow(stereoAnaglyph(J1, J2), 'InitialMagnification', 50);
%
%   % Compute disparity
%   disparityMap = disparity(rgb2gray(J1), rgb2gray(J2));
%   figure
%   imshow(disparityMap, [0, 64], 'InitialMagnification', 50);
% 
%   % Reconstruct the 3-D world coordinates of points corresponding to each
%   % pixel from the disparity map.
%   xyzPoints = reconstructScene(disparityMap, stereoParams);
%
%   % Segment out a person located between 3.2 and 3.7 meters away from the
%   % camera.
%   Z = xyzPoints(:, :, 3);
%   mask = repmat(Z > 3200 & Z < 3700, [1, 1, 3]);
%   J1(~mask) = 0;
%   figure
%   imshow(J1, 'InitialMagnification', 50);
%
%   See also estimateCameraParameters, rectifyStereoImages, disparity,
%     stereoParameters

% Copyright 2013 MathWorks, Inc.

% References:
%
% G. Bradski and A. Kaehler, "Learning OpenCV : Computer Vision with
% the OpenCV Library," O'Reilly, Sebastopol, CA, 2008.

%#codegen

function xyzPoints = reconstructScene(disparityMap, stereoParams)

validateattributes(disparityMap, {'double', 'single'}, ...
    {'2d', 'real', 'nonsparse'}, ...
    mfilename, 'disparityImage');

validateattributes(stereoParams, {'stereoParameters'}, {}, ...
    mfilename, 'stereoParams');

xyzPoints = reconstructSceneImpl(stereoParams, disparityMap);


