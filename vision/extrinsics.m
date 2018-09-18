%  EXTRINSICS Compute camera extrinsics from a planar calibration pattern
%     [rotationMatrix, translationVector] = EXTRINSICS(imagePoints,
%     worldPoints, cameraParams) returns the translation and rotation from
%     the world coordinate system defined by worldPoints into the camera-based
%     coordinate system.
%     
%     Inputs            Description
%     ------            -----------
%     imagePoints       M-by-2 array of undistorted [x,y] coordinates of 
%                       image points
%  
%     worldPoints       Coordinates of co-planar world points corresponding to 
%                       imagePoints, specified as an M-by-2 matrix of [x,y] coordinates 
%                       with z assumed to be 0 and M >= 4.
% 
%     cameraParams      cameraParameters, cameraIntrinsics or fisheyeIntrinsics object
%  
%     Outputs           Description
%     -------           -----------
%     rotationMatrix    3-by-3 matrix describing rotation from the world coordinates
%                       to the camera-based coordinates
%     translationVector 1-by-3 vector describing translation from the world coordinates
%                       to the camera-based coordinates
%  
%     Notes
%     -----
%     If cameraParams is a cameraParameters or cameraIntrinsics object, the
%     lens distortion is not taken into account. You can either undistort
%     the image using the undistortImage function before detecting the
%     points, or you can undistort the points using the undistortPoints
%     function.
%  
%     Class Support
%     -------------
%     imagePoints and worldPoints must both be double or both be single.
%     cameraParams must be a cameraParameters, cameraIntrinsics or
%     fisheyeIntrinsics object.
%  
%     If imagePoints and worldPoints are of class double, then rotationMatrix
%     and translationVector are also double. Otherwise, they are single.
%  
%     Example - Compute camera extrinsics
%     -----------------------------------
%     % Create a set of calibration images.
%     images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%         'calibration', 'slr'));
%  
%     % Detect the checkerboard corners in the images.
%     [imagePoints, boardSize] = detectCheckerboardPoints(images.Files);
%  
%     % Generate the world coordinates of the checkerboard corners in the
%     % pattern-centric coordinate system, with the upper-left corner at (0,0).
%     squareSize = 29; % in millimeters
%     worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%  
%     % Calibrate the camera.
%     I = readimage(images,1); 
%     imageSize = [size(I, 1), size(I, 2)];
%     cameraParams = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%  
%     % Load image at new location.
%     imOrig = imread(fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', ...
%           'calibration', 'slr', 'image9.jpg'));
%     figure 
%     imshow(imOrig);
%     title('Input Image');
%  
%     % Undistort image.
%     [im, newOrigin] = undistortImage(imOrig, cameraParams, 'OutputView', 'full');
%  
%     % Find reference object in new image.
%     [imagePoints, boardSize] = detectCheckerboardPoints(im);
%  
%     % Compensate for image coordinate system shift.
%     imagePoints = [imagePoints(:,1) + newOrigin(1), ...
%                    imagePoints(:,2) + newOrigin(2)];
%  
%     % Compute new extrinsics.
%     [rotationMatrix, translationVector] = EXTRINSICS(...
%       imagePoints, worldPoints, cameraParams);
%
%     % Compute camera pose.
%     [orientation, location] = extrinsicsToCameraPose(rotationMatrix, ...
%         translationVector);
%     figure
%     plotCamera('Location', location, 'Orientation', orientation, 'Size', 20);
%     hold on
%     pcshow([worldPoints, zeros(size(worldPoints,1), 1)], ...
%         'VerticalAxisDir', 'down', 'MarkerSize', 40);
%  
%     See also estimateCameraParameters, cameraCalibrator, cameraMatrix,
%         cameraParameters, undistortImage, undistortPoints, plotCamera, 
%         extrinsicsToCameraPose, cameraPoseToExtrinsics, worldToImage,
%         pointsToWorld, cameraIntrinsics, fisheyeIntrinsics

% Copyright 2013 MathWorks, Inc

% References:
% -----------
% [1] Z. Zhang. A flexible new technique for camera calibration. IEEE
% Transactions on Pattern Analysis and Machine Intelligence,
% 22(11):1330-1334, 2000.
%
% [2] Hartley, Richard, and Andrew Zisserman. Multiple View Geometry in
% Computer Vision. Vol. 2. Cambridge, 2000.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

function [rotationMatrix, translationVector] = extrinsics(...
    imagePoints, worldPoints, cameraParams)

checkInputs(imagePoints, worldPoints, cameraParams);

if ~isa(cameraParams, 'fisheyeIntrinsics')
    if isa(cameraParams, 'cameraParameters')
        intrinsicParams = cameraParams;
    else
        intrinsicParams = cameraParams.CameraParameters;
    end

    intrinsics = intrinsicParams.IntrinsicMatrix;

    if size(worldPoints,2) == 3
        if isempty(coder.target)
            warning(message('vision:extrinsics:deprecatedNonCoplanarPoints'));
        end
        [rotationMatrix, translationVector] = extrinsicsNonPlanar(...
            imagePoints, worldPoints, intrinsics);
    elseif size(worldPoints,2) == 2
        [rotationMatrix, translationVector] = extrinsicsPlanar(...
            imagePoints, worldPoints, intrinsics);
    end
else
    if ~isempty(coder.target) % codegen is not supported
        coder.internal.error('vision:vision_utils:CodegenUnsupported');
    end
        
    pts = imageToNormalizedVector(cameraParams, imagePoints);
    u = pts(:, 1) ./ pts(:, 3);
    v = pts(:, 2) ./ pts(:, 3);
    [rotationMatrix, translationVector] = extrinsicsPlanar(...
        [u, v], worldPoints, eye(3, 'like', pts));
end

%--------------------------------------------------------------------------
function checkInputs(imagePoints, worldPoints, cameraParams)
% image pts
validateattributes(imagePoints, {'double', 'single'}, ...
    {'real', 'finite', 'nonsparse','2d', 'ncols', 2}, ...
    mfilename, 'imagePoints');

% world pts
validateattributes(worldPoints, {'double', 'single'}, ...
    {'real', 'finite', 'nonsparse', '2d'}, ...
    mfilename, 'worldPoints');

coder.internal.errorIf( (size(worldPoints,2)~=2 && size(worldPoints,2)~=3),...
    'vision:calibrate:not2Dor3DWorldPoints');

% points must be of the same class
coder.internal.errorIf( ~strcmp(class(imagePoints), class(worldPoints)), ...
    'vision:calibrate:pointsClassMismatch');

% same number of points
coder.internal.errorIf( size(imagePoints, 1) ~= size(worldPoints, 1), ...
    'vision:calibrate:numberOfPointsMustMatch');

% min number of points
minNumberOfPoints3D = 6;
coder.internal.errorIf(...
    size(worldPoints, 2) == 3 && size(worldPoints, 1) < minNumberOfPoints3D, ...
    'vision:calibrate:minNumWorldPoints', minNumberOfPoints3D - 1);

minNumberOfPoints2D = 4;
coder.internal.errorIf(...
    size(worldPoints, 2) == 2 && size(worldPoints, 1) < minNumberOfPoints2D, ...
    'vision:calibrate:minNumWorldPoints', minNumberOfPoints2D - 1);

% camera parameters
validateattributes(cameraParams, ...
    {'cameraParameters', 'cameraIntrinsics', 'fisheyeIntrinsics'}, ...
    {'scalar'}, mfilename, 'cameraParams');

%--------------------------------------------------------------------------
function [R,T] = extrinsicsPlanar(imagePoints, worldPoints, intrinsics)

A = intrinsics';

% Compute homography.
H = fitgeotrans(worldPoints, imagePoints, 'projective');
H = H.T';
h1 = H(:, 1);
h2 = H(:, 2);
h3 = H(:, 3);

lambda = 1 / norm(A \ h1);

% Compute rotation
r1 = A \ (lambda * h1);
r2 = A \ (lambda * h2);
r3 = cross(r1, r2);
R = [r1'; r2'; r3'];

% R may not be a true rotation matrix because of noise in the data.
% Find the best rotation matrix to approximate R using SVD.
[U, ~, V] = svd(R);
R = U * V';

% Compute translation vector.
T = (A \ (lambda * h3))';

%--------------------------------------------------------------------------
function [R,T] = extrinsicsNonPlanar(imagePoints, worldPoints, intrinsics)
% Based on [2] "Gold Standard Algorithm" on page 181

%make input points homogeneous
worldPoints = cat(2, worldPoints, ones(size(worldPoints,1),1));
imagePoints = cat(2, imagePoints, ones(size(imagePoints,1),1));

M = size(imagePoints, 1);

[imagePoints, Timage] = vision.internal.normalizePoints(imagePoints', 2, ...
    class(imagePoints));
imagePoints = imagePoints';

[worldPoints, Tworld] = vision.internal.normalizePoints(worldPoints', 3, ...
    class(worldPoints));
worldPoints = worldPoints';

% DLT
A = [zeros(4,M),                           worldPoints(:,1:4)';
    -worldPoints(:,1:4)',                       zeros(4,M);
 bsxfun(@times,worldPoints(:,1:4)', imagePoints(:,2)'), -bsxfun(@times,worldPoints(:,1:4)',imagePoints(:,1)')];
[U,~,~] = svd(A);
P = reshape(U(:,end),4,3);

% Denormalize
P = Tworld' * P / Timage';

% Extract extrinsics using intrinsics
RT = P / intrinsics;
R = RT(1:3, 1:3);
[U,S,V] = svd(R);
R = U*V';
T = RT(4,:)/S(1,1); % Scale translation vector using correction
