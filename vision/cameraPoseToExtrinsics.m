% cameraPoseToExtrinsics Convert camera pose to extrinsics
%   [rotationMatrix, translationVector] = cameraPoseToExtrinsics(orientation, location)
%   returns a 3-by-3 rotation matrix and a 1-by-3 translation vector from 
%   world coordinates into camera coordinates. orientation is a 3-by-3 
%   matrix and location is a 3-element vector representing the orientation 
%   and location of the camera in world coordinates. The outputs are 
%   computed as follows:
%   
%   rotationMatrix    = orientation'
%   translationVector = -location * orientation'
% 
%   Class Support
%   -------------
%   orientation and location must be of the same class, and can be double or single. 
%   rotationMatrix and translationMatrix are the same class as orientation and location.
% 
%   Example
%   -------
%   orientation = eye(3);
%   location = [0 0 10];
%   [R, t] = cameraPoseToExtrinsics(orientation, location)
% 
%   See also extrinsicsToCameraPose, extrinsics, relativeCameraPose, 
%            estimateWorldCameraPose

% Copyright 2016 MathWorks, Inc

%#codegen

function [R, t] = cameraPoseToExtrinsics(orientation, locationIn)
validateInputs(orientation, locationIn, 'orientation', 'location');
location = locationIn(:)';
R = orientation';
t = -location * R;

%--------------------------------------------------------------------------
function validateInputs(R, t, varNameR, varNameT)
vision.internal.inputValidation.validateRotationMatrix(R, mfilename, ...
    varNameR);
vision.internal.inputValidation.validateTranslationVector(t, mfilename, ...
    varNameT);

coder.internal.errorIf(~isa(R, class(t)), 'vision:points:ptsClassMismatch',...
    varNameR, varNameT);



