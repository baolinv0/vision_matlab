function camMatrix = cameraMatrix(cameraParams, rotationMatrix, translationVector)
%cameraMatrix Compute camera projection matrix.
%  camMatrix = cameraMatrix(cameraParams, rotationMatrix, translationVector)
%  returns a 4-by-3 camera projection matrix, which projects a 3-D world point
%  in homogeneous coordinates into the image. cameraParams is a
%  cameraParameters or cameraIntrinsics object. rotationMatrix is a 3-by-3
%  rotation matrix and translationVector is a 3-element translation vector
%  describing the transformation from the world coordinates to the camera
%  coordinates. You can obtain rotationMatrix and translationVector using
%  the extrinsics function.
%
%  Notes
%  -----
%  The camera matrix is computed as follows:
%  camMatrix = [rotationMatrix; translationVector] * K
%  where K is the intrinsic matrix.
%
%  Class Support
%  -------------
%  cameraParams must be a cameraParameters or cameraIntrinsics object.
%  rotationMatrix and translationVector must be numeric arrays of the same
%  class, and must be real and nonsparse. camMatrix is of class double if
%  rotationMatrix and translationVector are double. Otherwise camMatrix is
%  of class single.
%
%   Example: Compute camera matrix
%   ------------------------------
%   % Create a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%       'calibration', 'slr'));
%  
%   % Detect the checkerboard corners in the images.
%   [imagePoints, boardSize] = detectCheckerboardPoints(images.Files);
%  
%   % Generate the world coordinates of the checkerboard corners in the
%   % pattern-centric coordinate system, with the upper-left corner at (0,0).
%   squareSize = 29; % in millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%  
%   % Calibrate the camera.
%   I = readimage(images,1); 
%   imageSize = [size(I, 1), size(I, 2)];
%   cameraParams = estimateCameraParameters(imagePoints, worldPoints, ...
%                                          'ImageSize', imageSize);
%  
%   % Load image at new location.
%   imOrig = imread(fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', ...
%         'calibration', 'slr', 'image9.jpg'));
%   figure; imshow(imOrig);
%   title('Input Image');
%  
%   % Undistort image.
%   im = undistortImage(imOrig, cameraParams);
%  
%   % Find reference object in new image.
%   [imagePoints, boardSize] = detectCheckerboardPoints(im);
%
%   % Compute new extrinsics.
%   [rotationMatrix, translationVector] = extrinsics(...
%       imagePoints, worldPoints, cameraParams);
%
%   % Calculate camera matrix
%   P = cameraMatrix(cameraParams, rotationMatrix, translationVector)
%
%  See also extrinsics, triangulate, cameraCalibrator, estimateCameraParameters
%    relativeCameraPose, estimateWorldCameraPose, cameraPoseToExtrinsics

%#codegen

[K, R, t] = parseInputs(cameraParams, rotationMatrix, translationVector);
camMatrix = [R; t] * K;

%--------------------------------------------------------------------------
function [K, R, t] = parseInputs(cameraParams, rotationMatrix, translationVector)

validateInputs(cameraParams, rotationMatrix, translationVector)

if isa(rotationMatrix, 'double')
    outputClass = 'double';
else
    outputClass = 'single';
end

if isa(cameraParams, 'cameraParameters')
    params = cameraParams;
else
    params = cameraParams.CameraParameters;
end

K = cast(params.IntrinsicMatrix, outputClass);
R = cast(rotationMatrix, outputClass);
if isrow(translationVector)
    t = cast(translationVector, outputClass);
else
    t = cast(translationVector', outputClass);
end

%--------------------------------------------------------------------------
function validateInputs(cameraParams, rotationMatrix, translationVector)
validateattributes(cameraParams, {'cameraParameters','cameraIntrinsics'}, ...
    {'scalar'}, mfilename, 'cameraParams');
vision.internal.inputValidation.validateRotationMatrix(...
    rotationMatrix, mfilename, 'rotationMatrix');
vision.internal.inputValidation.validateTranslationVector(...
    translationVector, mfilename, 'translationVector');

coder.internal.errorIf(~isequal(class(rotationMatrix), class(translationVector)),...
    'vision:calibrate:RandTClassMismatch');
