function [undistortedPoints, camIntrinsics, reprojectionErrors] = ...
    undistortFisheyePoints(points, intrinsics, varargin)
%undistortFisheyePoints Correct point coordinates for fisheye lens distortion.
%  undistortedPoints = undistortFisheyePoints(points, intrinsics)
%  returns point coordinates corrected for fisheye lens distortion. points
%  and undistortedPoints are an M-by-2 matrix of [x,y] coordinates.
%  intrinsics is a fisheyeIntrinsics object.
%
%  undistortedPoints = undistortFisheyePoints(..., scaleFactor) returns
%  corrected point coordinates using scaleFactor, specified as a scalar
%  or [sx, sy]. The default value is 1. Increase this value to zoom in the
%  perspective camera view.
%
%  [..., camIntrinsics] = undistortFisheyePoints(...) additionally returns
%  a cameraIntrinsics object, camIntrinsics, which corresponds to a virtual
%  pespective camera that produces undistorted points.
%
%  [..., reprojectionErrors] = undistortFisheyePoints(...) additionally
%  returns reprojectionErrors, an M-by-1 vector, used to evaluate the
%  accuracy of undistorted points. The function computes the reprojection
%  errors by applying distortion to the undistorted points, and taking the
%  distances between the result and the corresponding input points.
%  Reprojection errors are expressed in pixels.
%
%  Class Support
%  -------------
%  points must be a real and nonsparse numeric matrix. undistortedPoints is
%  double if points is a double. Otherwise undistortedPoints is single.
%  reprojectionErrors are the same class as undistortedPoints.
%
%  Example - Undistort Checkerboard Points
%  ---------------------------------------
%  % Create an imageDatastore object containing calibration images
%  images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%      'calibration', 'gopro'));
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
%  params = estimateFisheyeParameters(imagePoints, worldPoints, imageSize);
%
%  % Load an image and detect the checkerboard points
%  points = detectCheckerboardPoints(I);
%
%  % Undistort the points
%  [undistortedPoints, intrinsics1] = undistortFisheyePoints(points, params.Intrinsics);
%
%  % Undistort the image
%  [J, intrinsics2] = undistortFisheyeImage(I, params.Intrinsics, 'OutputView', 'full');
%
%  % Translate undistorted points
%  newOrigin = intrinsics2.PrincipalPoint - intrinsics1.PrincipalPoint;
%  undistortedPoints = [undistortedPoints(:,1) + newOrigin(1), ...
%                       undistortedPoints(:,2) + newOrigin(2)];
%
%  % Display the results
%  figure 
%  imshow(I) 
%  hold on
%  plot(points(:, 1), points(:, 2), 'r*-')
%  title('Detected Points') 
%  hold off
%
%  figure 
%  imshow(J) 
%  hold on
%  plot(undistortedPoints(:, 1), undistortedPoints(:, 2), 'g*-')
%  title('Undistorted Points') 
%  hold off
%
%  See also undistortFisheyeImage, fisheyeIntrinsics

%   Copyright 2017 The MathWorks, Inc.

[pointsDouble, outputClass, scaleFactor] = validateAndParseInputs(points, ...
    intrinsics, varargin{:});

imageSize = intrinsics.ImageSize;
if isempty(imageSize)
    error(message('vision:calibrate:emptyImageSize'));
end
principalPoint = imageSize([2 1]) / 2;
f = min(imageSize) / 2;
focalLength = f .* scaleFactor(:)';
camIntrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize);

undistortedPointsDouble = undistortPointsImpl(intrinsics, pointsDouble, camIntrinsics);
undistortedPoints = cast(undistortedPointsDouble, outputClass);

if nargout > 2
    redistortedPoints = distortPoints(intrinsics, undistortedPointsDouble, camIntrinsics);
    errorsDouble = sqrt(sum((pointsDouble - redistortedPoints).^ 2 , 2));
    reprojectionErrors = cast(errorsDouble, outputClass);
end

%--------------------------------------------------------------------------
function [pointsDouble, outputClass, scaleFactor] = ...
    validateAndParseInputs(points, intrinsics, varargin)
validateattributes(points, {'numeric'}, ...
    {'2d', 'nonsparse', 'real', 'size', [NaN, 2]}, mfilename, 'points');

validateattributes(intrinsics, {'fisheyeIntrinsics'}, {}, mfilename, 'intrinsics');

if isa(points, 'double')
    outputClass = 'double';
else
    outputClass = 'single';
end

pointsDouble = double(points);

if isempty(varargin)
    scaleFactor = [1 1];
else
    scaleFactor = varargin{1};
    if isscalar(scaleFactor)
        validateattributes(scaleFactor, {'single', 'double'}, ...
            {'scalar', 'nonsparse', 'real', 'positive'},...
            mfilename, 'scaleFactor');
        scaleFactor = [scaleFactor, scaleFactor];
    else
        validateattributes(scaleFactor, {'single', 'double'}, ...
            {'vector', 'nonsparse', 'real', 'numel', 2, 'positive'},...
            mfilename, 'scaleFactor');
    end
end
