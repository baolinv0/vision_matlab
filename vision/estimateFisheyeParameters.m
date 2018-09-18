function [fisheyeParams, imagesUsed, estimationErrors] = estimateFisheyeParameters(varargin)
%estimateFisheyeParameters Calibrate a fisheye camera
%
%   [fisheyeParams, imagesUsed, estimationErrors] =
%   estimateFisheyeParameters(imagePoints, worldPoints, imageSize)
%   estimates intrinsic and extrinsic parameters of a fisheye camera.
% 
%   Inputs:
%   -------
%   imagePoints - an M-by-2-by-P array of [x,y] intrinsic image coordinates 
%                 of keypoints on the calibration pattern. M > 3 is the
%                 number of keypoints in the pattern. P > 2 is the number
%                 of images containing the calibration pattern.
%
%   worldPoints - an M-by-2 array of [x,y] world coordinates of keypoints 
%                 on the calibration pattern. The pattern must be planar,
%                 so all z-coordinates are assumed to be 0.
%
%   imageSize   - Image size produced by the camera and specified as [mrows, ncols].
%   
%   Outputs:
%   --------
%   fisheyeParams    - a fisheyeParameters object containing the
%                      fisheye camera parameters.
%
%   imagesUsed       - a P-by-1 logical array indicating which images were 
%                      used to estimate the camera parameters. P is the
%                      number of images containing the calibration pattern. 
%
%   estimationErrors - a fisheyeCalibrationErrors object containing
%                      the standard errors of the estimated camera
%                      parameters.
% 
%   fisheyeParams = estimateFisheyeParameters(..., Name, Value)  
%   specifies additional name-value pair arguments described below.
% 
%   Parameters include:
%   -------------------
%   'EstimateAlignment' A logical scalar that specifies whether the axes
%                       alignment between the sensor plane and the image
%                       plane should be estimated. Set to true if the
%                       optical axis of fisheye lens is not perpendicular
%                       to the image plane.
%
%                       Default: false
%
%   'WorldUnits'        A character vector that describes the units in
%                       which worldPoints are specified.
%
%                       Default: 'mm'
%
%   Class Support
%   -------------
%   worldPoints and imagePoints must be double or single.
%
%   Example: Fisheye Camera Calibration
%   ------------------------------------
%   % Gather a set of calibration images.
%   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%     'calibration', 'gopro'));
%   imageFileNames = images.Files;
%
%   % Detect calibration pattern.
%   [imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
%
%   % Generate world coordinates of the corners of the squares.
%   squareSize = 29; % millimeters
%   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
%   % Calibrate the camera.
%   I = readimage(images, 1); 
%   imageSize = [size(I, 1), size(I, 2)];
%   params = estimateFisheyeParameters(imagePoints, worldPoints, imageSize);
%
%   % Visualize calibration accuracy.
%   figure
%   showReprojectionErrors(params);
%
%   % Visualize camera extrinsics.
%   figure
%   showExtrinsics(params);
%   drawnow
%
%   % Plot detected and reprojected points.
%   figure 
%   imshow(I); 
%   hold on
%   plot(imagePoints(:, 1, 1), imagePoints(:, 2, 1), 'go');
%   plot(params.ReprojectedPoints(:, 1, 1), params.ReprojectedPoints(:, 2, 1), 'r+');
%   legend('Detected Points', 'ReprojectedPoints');
%   hold off
%
%   See also detectCheckerboardPoints, fisheyeParameters,
%     fisheyeIntrinsics, generateCheckerboardPoints, showExtrinsics, 
%     showReprojectionErrors, undistortFisheyeImage, fisheyeCalibrationErrors

%   Copyright 2017 MathWorks, Inc.

% References:
%
% [1] Scaramuzza, D., Martinelli, A. and Siegwart, R., "A Toolbox for Easy
% Calibrating Omnidirectional Cameras", Proceedings to IEEE International
% Conference on Intelligent Robots and Systems (IROS 2006), Beijing China,
% October 7-15, 2006.
%
% [2] Steffen Urban, Jens Leitloff and Stefan Hinz, "Improved wide-angle,
% fisheye and omnidirectional camera calibration", ISPRS Journal of
% Photogrammetry and Remote Sensing (108), October 72-79, 2015.

[imagePoints, worldPoints, imageSize, worldUnits, estimateAlignment, ...
    calibrationParams] = parseInputs(varargin{:});
calibrationParams.shouldComputeErrors = (nargout >= 2);

progressBar = vision.internal.calibration.createSingleCameraProgressBar(calibrationParams.showProgressBar);

% Compute the initial "guess" of intrinsic and extrinsic camera parameters
[fisheyeParams, imagesUsed] = computeInitialParameters(worldPoints, ...
            imagePoints, imageSize, worldUnits, estimateAlignment);

progressBar.update();

% Refine the initial estimate using non-linear least squares minimization
estimationErrors = refine(fisheyeParams, imagePoints, ...
    calibrationParams.shouldComputeErrors);

progressBar.update();
progressBar.delete();

%--------------------------------------------------------------------------
function [imagePoints, worldPoints, imageSize, worldUnits, ...
    estimateAlignment, calibrationParams] = parseInputs(varargin)
parser = inputParser;
parser.addRequired('imagePoints', @checkImagePoints);
parser.addRequired('worldPoints', @checkWorldPoints);
parser.addRequired('ImageSize', @vision.internal.calibration.CameraParametersImpl.checkImageSize);
parser.addParameter('WorldUnits', 'mm', @checkWorldUnits);
parser.addParameter('EstimateAlignment', false, @checkEstimateAlignment);
parser.addParameter('ShowProgressBar', false, @checkShowProgressBar);

parser.parse(varargin{:});

imagePoints = parser.Results.imagePoints;
worldPoints = parser.Results.worldPoints;
if size(imagePoints, 1) ~= size(worldPoints, 1)
    error(message('vision:calibrate:numberOfPointsMustMatch'));
end

imageSize = parser.Results.ImageSize;
worldUnits  = parser.Results.WorldUnits;
estimateAlignment = parser.Results.EstimateAlignment;
calibrationParams.showProgressBar = parser.Results.ShowProgressBar;

%--------------------------------------------------------------------------
function checkImagePoints(imagePoints)
vision.internal.inputValidation.checkImagePoints(imagePoints, mfilename);


%--------------------------------------------------------------------------
function checkWorldPoints(worldPoints)
vision.internal.inputValidation.checkWorldPoints(worldPoints, mfilename);

%--------------------------------------------------------------------------
function checkWorldUnits(worldUnits)
if isstring(worldUnits)
    validateattributes(worldUnits, {'string'}, ...
        {'scalar'}, mfilename, 'WorldUnits');
else
    validateattributes(worldUnits, {'char'}, ...
        {'vector'}, mfilename, 'WorldUnits');
end

%--------------------------------------------------------------------------
function checkEstimateAlignment(estimateAlignment)
validateattributes(estimateAlignment, {'logical'}, {'scalar'}, ...
                    mfilename, 'EstimateAlignment');

%--------------------------------------------------------------------------
function checkShowProgressBar(showProgressBar)
vision.internal.inputValidation.validateLogical(showProgressBar, 'ShowProgressBar');

%--------------------------------------------------------------------------
function [params, imagesUsed] = computeInitialParameters(worldPoints, ...
        imagePoints, imageSize, worldUnits, estimateAlignment)
% Find partial extrinsics, r1, r2, tx, ty
[extrinsics, imagesUsed] = computeInitialExtrinsics(imagePoints, ...
                                                worldPoints, imageSize);
imagePoints = imagePoints(:, :, imagesUsed);
extrinsics = extrinsics(:, :, imagesUsed);

% Find intrinsics and partial extrinsics tz
[intrinsics, extrinsics] = estimateIntrinsicsAndTranslationOfZ(...
    worldPoints, imagePoints, imageSize, extrinsics);

% Find r3
[rvecs, tvecs] = computeFullExtrinsics(extrinsics);

numImages = numel(imagesUsed);
allrvecs = zeros(numImages, 3);
alltvecs = allrvecs;
allrvecs(imagesUsed, :) = rvecs;
alltvecs(imagesUsed, :) = tvecs;

obj = fisheyeIntrinsics(intrinsics, imageSize, imageSize([2, 1])/2);
params = fisheyeParameters(obj, ...
    'RotationVectors', allrvecs, ...
    'TranslationVectors', alltvecs, ...
    'WorldPoints', worldPoints, ...
    'WorldUnits', worldUnits, ...
    'EstimateAlignment', estimateAlignment);

%--------------------------------------------------------------------------
function [Es, imagesUsed] = computeInitialExtrinsics(imagePoints, worldPoints, imageSize)
% Initial estimation of camera extrinsics
cx = imageSize(2)/2;
cy = imageSize(1)/2;
X = worldPoints(:, 1);
Y = worldPoints(:, 2);
numImages = size(imagePoints, 3);
Es = zeros(3, 3, numImages);
imagesUsed = true(numImages, 1);
for k = 1 : numImages
    u = imagePoints(:, 1, k) - cx;
    v = imagePoints(:, 2, k) - cy;
    
    % Build the system of linear equations (Scaramuzza et al, eq. 11)
    M = [X.*v, Y.*v, -X.*u, -Y.*u, v, -u];
    [~,~,V] = svd(M);
    
    % Solve the rotation and translation
    r11 = V(1, end);
    r12 = V(2, end);
    r21 = V(3, end);
    r22 = V(4, end);
    t1 = V(5, end);
    t2 = V(6, end);

    % r1, r2 are orthonormal so we can have three equations as follows:
    % |r1| = |r2| = lambda, and r1' * r2 = 0
    % To solve r3, we solve the derived equation:
    % r32^4 + (CC - BB) r32^2 - AA = 0, 
    % where AA = ((r11*r12)+(r21*r22))^2, BB = r11^2 + r21^2, CC = r12^2 + r22^2.
    A = (r11*r12+r21*r22);
    AA = A^2;
    BB = r11^2 + r21^2;
    CC = r12^2 + r22^2;
    
    r32_2 = roots([ 1, CC-BB, -AA]);
    r32_2 = r32_2(r32_2>=0);

    % r3 may have multiple numeric solutions
    r31 = [];
    r32 = [];
    for i = 1 : length(r32_2)
        if r32_2(i) == 0
            temp = sqrt(CC-BB);
            r31 = [r31; temp; -temp];
            r32 = [r32; 0; 0];
        else
            temp = sqrt(r32_2(i));
            r32 = [r32; temp; -temp];
            r31 = [r31; -A/temp; A/temp];
        end        
    end
    
    % Solve lambda: r31^2 + BB = lambda^2
    E = zeros(3, 3, length(r32)*2);
    for i = 1:length(r32)
        lambda = sqrt(BB+r31(i)^2)\1;
        R = lambda * [  r11     r12     t1; ...
                        r21     r22     t2; ...
                        r31(i)  r32(i)  0];
        E(:,:,2*i-1) = R; 
        E(:,:,2*i) = -R; 
    end
    
    % Pick the extrinsics that place the calibration points in front of
    % the camera
    bestE = chooseExtrinsics(E, X, Y, u, v);
    if ~isempty(bestE)
        Es(:,:,k) = bestE;
    else
        imagesUsed(k) = false;
    end
end

%--------------------------------------------------------------------------
function bestE = chooseExtrinsics(E, X, Y, Xp, Yp)
% Among multiple ambiguous solutions, choose the one that places the
% checkerboard in front of the camera, where the last (highest degree)
% polynomial coefficient is negative.

% Pick t1, t2 that are pointing to calibration points.
tt = squeeze(E(1:2,3,:));
% The first image point corresponds to the origin of the world coordinate
% system.
d = tt - [Xp(1); Yp(1)]; 
d = sum(d.*d);
[~, ind] = min(d);

indices = [];
for i = 1 : size(tt, 2)
    if sign(tt(1, i))==sign(tt(1, ind)) && sign(tt(2, i))==sign(tt(2, ind))
        indices = [indices; i];
    end
end

E = E(:, :, indices);
bestE = [];
for i = 1 : size(E, 3)
    e = E(:,:,i);
    % Use only quadratic polynomial to validate coefficients.
    % (Scaramuzza et al, eq. 13)
    r11 = e(1,1);
    r21 = e(2,1);
    r31 = e(3,1);
    r12 = e(1,2);
    r22 = e(2,2);
    r32 = e(3,2);
    t1  = e(1,3);
    t2  = e(2,3);
    
    A = r21.*X + r22.*Y + t2;
    B = Yp.*( r31.*X + r32.*Y );
    C = r11.*X + r12.*Y + t1;
    D = Xp.*( r31.*X + r32.*Y );
    rho = sqrt(Xp.^2 + Yp.^2);
    rho2 = (Xp.^2 + Yp.^2);
    
    P = [A, A.*rho, A.*rho2, -Yp; ...
         C, C.*rho, C.*rho2, -Xp];        
    Q = [B; D];
    
    s = pinv(P) * Q;
    if s(3) <= 0 % Check the sign of the quadratic polynomial.
        bestE = e;
    end
end

%--------------------------------------------------------------------------
function [intrinsics, extrinsics] = estimateIntrinsicsAndTranslationOfZ(...
    worldPoints, imagePoints, imageSize, extrinsics)
cx = imageSize(2)/2;
cy = imageSize(1)/2;
X = worldPoints(:, 1);
Y = worldPoints(:, 2);
numImages = size(imagePoints, 3);

numPoints = numel(X);
P = zeros(numPoints*numImages*2, 4+numImages);
Q = zeros(numPoints*numImages*2, 1);
% Solve for intrinsics (Scaramuzza et al, eq. 13)
for k = 1 : numImages
    E = extrinsics(:,:,k);
    r11 = E(1,1);
    r21 = E(2,1);
    r31 = E(3,1);
    r12 = E(1,2);
    r22 = E(2,2);
    r32 = E(3,2);
    t1  = E(1,3);
    t2  = E(2,3);

    u = imagePoints(:, 1, k) - cx;
    v = imagePoints(:, 2, k) - cy;

    A = r21.*X + r22.*Y + t2;
    B = v.*( r31.*X + r32.*Y );
    C = r11.*X + r12.*Y + t1;
    D = u.*( r31.*X + r32.*Y );
    rho = sqrt(u.^2 + v.^2);
    rho2 = rho.*rho;
    rho3 = rho.^3;
    rho4 = rho.^4;
    
    M = [A, A.*rho2, A.*rho3, A.*rho4; ...
         C, C.*rho2, C.*rho3, C.*rho4];        
    
    firstRow = numPoints*2*(k-1)+1;
    lastRow = numPoints*2*k;
    P(firstRow:lastRow, 1:4) = M;
    P(firstRow:lastRow, 4+k) = [-v; -u];
    Q(firstRow:lastRow) = [B; D];
end

% Set the constraints to make the radial distortion function monotonically
% increasing, and convex. This ensures the distortion gets larger for the
% pixels that are far away from the center of distortion.
numSkips = 5;
rhoSamples = 1:numSkips:round(max(imagePoints(:)));
numSamples = numel(rhoSamples);
rhoMono = [rhoSamples; rhoSamples.^2; rhoSamples.^3]';

% The first derivative is non-negative
% 0*a0 + a1(not needed) + 2*a2*rho + 3*a3*rho^2 + 4*a4*rho^3 >= 0
mono = [zeros(numSamples, 1), 2 * rhoMono(:, 1), 3 * rhoMono(:, 2), 4 * rhoMono(:, 3)];

% The second derivative is non-negative
% 0*a0 + 0*a1(not needed) + 2*a2 + 6*a3*rho + 12*a4*rho^2 >= 0
mono = [mono; zeros(numSamples, 1), 2 * ones(numSamples, 1), 6 * rhoMono(:, 1), 12 * rhoMono(:, 2)]; 

% Set the constraints
A = [mono, zeros(size(mono,1),size(P,2)-size(mono,2))];
b = zeros(size(mono,1),1);   

options = optimset('Display','off');
x = ilslnsh(P,Q,A,b,[],[],[],[],[],options);

intrinsics = x(1:4);
for k = 1 : numImages
    extrinsics(3,3,k) = x(4+k);
end    

%--------------------------------------------------------------------------
function [rotationVectors, translationVectors] = computeFullExtrinsics(extrinsics)
% Compute translation and rotation vectors for all images

numImages = size(extrinsics, 3);
rotationVectors = zeros(numImages, 3);
translationVectors = zeros(numImages, 3); 
for i = 1:numImages
    E = extrinsics(:, :, i);
    t  = E(:, 3);
    
    % 3D rotation matrix
    r1 = E(:, 1);
    r2 = E(:, 2);
    r3 = cross(r1, r2);    
    R = [r1, r2, r3];
    
    rotationVectors(i, :) = vision.internal.calibration.rodriguesMatrixToVector(R);
    
    translationVectors(i, :) = t;
end



