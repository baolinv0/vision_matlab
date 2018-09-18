function [isIn,epipole] = isEpipoleInImage(f,imageSize)
%isEpipoleInImage Determine whether the epipole is inside the image.
%   Assuming F is a 3-by-3 fundamental matrix computed from stereo images
%   I1 and I2, i.e., if P1, a point in I1, corresponds to P2, a point in
%   I2, then [P2,1] * F * [P1,1]' = 0.
%
%   ISIN = isEpipoleInImage(F,IMAGESIZE) determines whether the epipole
%   is inside I1. IMAGESIZE is the size of I1 and is in the format returned
%   by the function SIZE.
% 
%   ISIN = isEpipoleInImage(F',IMAGESIZE) determines whether the epipole
%   is inside I2. IMAGESIZE is the size of I2 and is in the format returned
%   by the function SIZE.
% 
%   [ISIN,EPIPOLE] = isEpipoleInImage(...) also returns the epipole.
%
%   Class Support
%   -------------
%   F must be double or single. IMAGESIZE must be double, single, or
%   integer. 
%
%   Example 1
%   ---------
%   load stereoPointPairs
%   f = estimateFundamentalMatrix(matchedPoints1, matchedPoints2, ...
%     'NumTrials', 2000);
%   imageSize = [200 300];
%   [isIn,epipole] = isEpipoleInImage(f,imageSize)
%   
%   Example 2
%   ---------
%   f = [0 0 1; 0 0 0; -1 0 0];
%   imageSize = [200, 300];
%   [isIn,epipole] = isEpipoleInImage(f',imageSize)
%
% See also estimateFundamentalMatrix, estimateUncalibratedRectification.

% Copyright 2010 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

% Parse and check inputs
checkInputs(f, imageSize);

[isIn,epipole] = algIsEpipoleInImage(f,imageSize);

%========================================================================== 
% Compute the epipole and determine whether it is inside the image
%--------------------------------------------------------------------------
function [isIn,epipole] = algIsEpipoleInImage(f,imageSize)
[~, ~, v] = svd(f);

epipoleHomogeneous = v(:, 3)';

outputClass = class(f);
if epipoleHomogeneous(3) ~= 0
  % Compute the Cartesian coordinates for the epipole and check if the
  % epipole is inside the image.
  epipole = epipoleHomogeneous(1:2) / epipoleHomogeneous(3);
  imageOrigin = cast([0.5, 0.5], outputClass);
  imageEnd = imageOrigin + cast([imageSize(2),imageSize(1)],outputClass);
  
  isIn = all(epipole >= imageOrigin & epipole <= imageEnd);
else
  % The epipole is at the location of infinity. 
  epipole = sign(epipoleHomogeneous(1:2)) * realmax(outputClass);
  isIn = false;
end

%========================================================================== 
function checkInputs(f, imageSize)
%--------------------------------------------------------------------------
% Check F
%--------------------------------------------------------------------------
validateattributes(f, {'double', 'single'}, ...
  {'2d', 'nonsparse', 'real', 'size', [3,3]},...
  'isEpipoleInImage', 'F');

%--------------------------------------------------------------------------
% Check IMAGESIZE
%--------------------------------------------------------------------------
validateattributes(imageSize, {'single', 'double', 'int8', 'int16', ...
  'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}, ...
  {'vector', 'nonsparse', 'nonempty', 'real', 'positive', 'integer'},...
  'isEpipoleInImage', 'IMAGESIZE');

coder.internal.errorIf(length(imageSize) < 2, ...
  'vision:isEpipoleInImage:invalidImageSize');
