% extrinsicsToCameraPose Convert extrinsics into camera pose
%   [orientation, location] = extrinsicsToCameraPose(rotationMatrix, translationVector)
%   returns a 3-by-3 camera orientation matrix and a 1-by-3 location vector 
%   in the world coordinates. rotationMatrix is a 3-by-3 matrix and 
%   translationVector is a 3-element vector representing rotation and 
%   translation from world coordinates into camera coordinates. The outputs
%   are computed as follows:
% 
%   orientation = rotationMatrix'
%   location    = -translationVector * rotationMatrix'
% 
%   Class Support
%   -------------
%   rotationMatrix and translationMatrix must be of the same class, and can be
%   double or single. orientation and location are the same class as 
%   rotationMatrix and translationMatrix.
% 
%   Example
%   -------
%   R = eye(3);
%   t = [0 0 -10];
%   [orientation, location] = extrinsicsToCameraPose(R, t)
% 
%   See also cameraPoseToExtrinsics, extrinsics, relativeCameraPose, 
%            estimateWorldCameraPose, plotCamera

% Copyright 2016 MathWorks, Inc

%#codegen

function [orientation, location] = extrinsicsToCameraPose(R, tIn)
validateInputs(R, tIn, 'rotationMatrix', 'translationVector');
t = tIn(:)';
orientation = R';
location = -t*orientation;

%--------------------------------------------------------------------------
function validateInputs(R, t, varNameR, varNameT)
vision.internal.inputValidation.validateRotationMatrix(R, mfilename, ...
    varNameR);
vision.internal.inputValidation.validateTranslationVector(t, mfilename, ...
    varNameT);

coder.internal.errorIf(~isa(R, class(t)), 'vision:points:ptsClassMismatch', ...
    varNameR, varNameT);

