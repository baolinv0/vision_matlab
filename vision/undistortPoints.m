function [undistortedPoints, reprojectionErrors] = undistortPoints(points, cameraParams)
%undistortPoints Correct point coordinates for lens distortion.
%  undistortedPoints = undistortPoints(points, cameraParams) returns point
%  coordinates corrected for lens distortion. points and undistortedPoints 
%  are M-by-2 matrices of [x,y] coordinates. cameraParams is either
%  cameraParameters or cameraIntrinsics object.
%
%  [undistortedPoints, reprojectionErrors] = undistortPoints(...) 
%  additionally returns reprojectionErrors, an M-by-1 vector, used to 
%  evaluate the accuracy of undistorted points. The function computes the 
%  reprojection errors by applying distortion to the undistorted points, 
%  and taking the distances between the result and the corresponding input 
%  points. Reprojection errors are expressed in pixels.
%
%  Class Support
%  -------------
%  points must be a real and nonsparse numeric matrix. undistortedPoints is
%  of class double if points is a double. Otherwise undistortedPoints is of
%  class single. reprojectionErrors are the same class as
%  undistortedPoints.
%
%  Notes
%  -----
%  undistortPoints function uses numeric non-linear least-squares
%  optimization. If the number of points is large, it may be faster to
%  undistort the entire image using the undistortImage function.
%
%  Example - Undistort Checkerboard Points
%  ---------------------------------------
%  % Create an imageDatastore object containing calibration images
%  images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%      'calibration', 'mono'));
%  imageFileNames = images.Files;
%
%  % Detect calibration pattern
%  [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
%
%  % Generate world coordinates of the corners of the squares
%  squareSize = 29; % in millimeters
%  worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%  % Calibrate the camera
%  I = readimage(images, 10); 
%  imageSize = [size(I, 1), size(I, 2)];
%  params = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
%  % Load an image and detect the checkerboard points
%  points = detectCheckerboardPoints(I);
%
%  % Undistort the points
%  undistortedPoints = undistortPoints(points, params);
%
%  % Undistort the image
%  [J, newOrigin] = undistortImage(I, params, 'OutputView', 'full');
%
%  % Translate undistorted points
%  undistortedPoints = [undistortedPoints(:,1) - newOrigin(1), ...
%                       undistortedPoints(:,2) - newOrigin(2)];
%
%  % Display the results
%  figure; 
%  imshow(I); 
%  hold on;
%  plot(points(:, 1), points(:, 2), 'r*-');
%  title('Detected Points'); 
%  hold off;
%
%  figure; 
%  imshow(J); 
%  hold on;
%  plot(undistortedPoints(:, 1), undistortedPoints(:, 2), 'g*-');
%  title('Undistorted Points'); 
%  hold off;
%
%  See also undistortImage, extrinsics, triangulate, estimateCameraParameters,
%    cameraCalibrator, cameraParameters, cameraIntrinsics, imageDatastore

%   Copyright 2014 The MathWorks, Inc.


validateInputs(points, cameraParams);

if isa(points, 'double')
    outputClass = 'double';
else
    outputClass = 'single';
end

pointsDouble = double(points);

if isa(cameraParams, 'cameraParameters')
    intrinsicParams = cameraParams;
else
    intrinsicParams = cameraParams.CameraParameters;
end

undistortedPointsDouble = undistortPointsImpl(intrinsicParams, pointsDouble);
undistortedPoints = cast(undistortedPointsDouble, outputClass);

if nargout > 1
    redistortedPoints = distortPoints(intrinsicParams, undistortedPointsDouble);
    errorsDouble = sqrt(sum((pointsDouble - redistortedPoints).^ 2 , 2));
    reprojectionErrors = cast(errorsDouble, outputClass);
end

%--------------------------------------------------------------------------
function validateInputs(points, cameraParams)
validateattributes(points, {'numeric'}, ...
    {'2d', 'nonsparse', 'real', 'size', [NaN, 2]}, mfilename, 'points');

validateattributes(cameraParams, {'cameraParameters', 'cameraIntrinsics'}, ...
    {}, mfilename, 'cameraParams');