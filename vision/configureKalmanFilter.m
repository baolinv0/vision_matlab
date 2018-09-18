function kalmanFilter = configureKalmanFilter(varargin)
%configureKalmanFilter Create a Kalman filter for object tracking
%  This function configures the vision.KalmanFilter object for object
%  tracking. It sets up the filter for tracking an object in a Cartesian
%  coordinate system, moving with constant velocity or constant
%  acceleration. The statistics are the same along all dimensions.
%
%  If you need to configure a Kalman filter with different assumptions, use
%  the vision.KalmanFilter object directly.
%
%  Syntax
%  ------
%  kalmanFilter = configureKalmanFilter(MotionModel, InitialLocation,
%          InitialEstimateError, MotionNoise, MeasurementNoise)
%  returns a vision.KalmanFilter object configured to track an object
%  which moves with constant velocity or constant acceleration.
%
%  Inputs
%  ------
%  MotionModel is set to either 'ConstantVelocity' or
%    'ConstantAcceleration'.
%
%  InitialLocation is a numeric vector which specifies the initial location 
%    of the object and determines the number of dimensions. For example, a
%    two-element vector assumes a 2-D coordinate system.
%
%  InitialEstimateError specifies the variance in uncertainty of the
%    initial estimates of location, velocity, and acceleration of the
%    tracked object. The function assumes zero initial velocity and
%    acceleration of the tracked object. You can specify the error as a two
%    or three-element vector.
%
%    MotionModel              InitialEstimateError
%    ----------------------   ------------------------------------------
%    'ConstantVelocity'       [LocationVariance, VelocityVariance]
%    'ConstantAcceleration'   [LocationVariance, VelocityVariance,
%                              AccelerationVariance]
%                               
%  MotionNoise specifies the variance of the difference between the actual 
%    motion of the object and the motion of the model you selected. You can
%    specify the motion noise as a two or three-element vector. 
%
%    MotionModel              MotionNoise
%    ----------------------   ------------------------------------------
%    'ConstantVelocity'       [LocationVariance, VelocityVariance]
%    'ConstantAcceleration'   [LocationVariance, VelocityVariance,
%                              AccelerationVariance]  
%
%  MeasurementNoise specifies the variance of inaccuracy of the detected
%  location. Specify the measurement noise as a scalar.
%  
%  Class Support
%  -------------
%  InitialLocation must be numeric. InitialEstimateError, MotionNoise, and
%  MeasurementNoise must be of the same class, which can be double or
%  single. 
%
%  Example: Track an occluded object
%  ---------------------------------
% 
%  % Create required System objects
%  videoReader = vision.VideoFileReader('singleball.mp4');
%  videoPlayer = vision.VideoPlayer('Position', [100, 100, 500, 400]);
%  foregroundDetector = vision.ForegroundDetector(...
%    'NumTrainingFrames', 10, 'InitialVariance', 0.05);
%  blobAnalyzer = vision.BlobAnalysis('AreaOutputPort', false, ...
%    'MinimumBlobArea', 70);
% 
%  % Process each video frame to detect and track the object
%  kalmanFilter = []; isTrackInitialized = false;
%  while ~isDone(videoReader)
%    colorImage  = step(videoReader); % get the next video frame
% 
%    % Detect the object in a gray scale image
%    foregroundMask = step(foregroundDetector, rgb2gray(colorImage));
%    detectedLocation = step(blobAnalyzer, foregroundMask);
%    isObjectDetected = size(detectedLocation, 1) > 0;
% 
%    if ~isTrackInitialized
%      if isObjectDetected % First detection.
%        kalmanFilter = configureKalmanFilter('ConstantAcceleration', ...
%          detectedLocation(1,:), [1 1 1]*1e5, [25, 10, 10], 25);
%        isTrackInitialized = true;
%      end
%      label = ''; circle = zeros(0,3); % initialize annotation properties
%    else  % A track was initialized and therefore Kalman filter exists
%      if isObjectDetected % Object was detected
%        % Reduce the measurement noise by calling predict, then correct
%        predict(kalmanFilter);
%        trackedLocation = correct(kalmanFilter, detectedLocation(1,:));
%        label = 'Corrected';
%      else % Object is missing
%        trackedLocation = predict(kalmanFilter);  % Predict object location
%        label = 'Predicted';
%      end
%      circle = [trackedLocation, 5];
%    end
% 
%    colorImage = insertObjectAnnotation(colorImage, 'circle', ...
%      circle, label, 'Color', 'red'); % mark the tracked object
%    step(videoPlayer, colorImage);    % play video
%  end % while
% 
%  release(videoPlayer); % Release resources
%  release(videoReader);
%
%  See also vision.KalmanFilter, assignDetectionsToTracks 

%  Copyright The MathWorks, Inc.

% Parse the inputs
r = parseInputs(varargin{:});
classToUse = class(r.InitialEstimateError);

% Determine the elementary components of A and H, and the sizes
if strcmp(r.MotionModel, 'ConstantVelocity')
  lenSubState = 2;
  As = [1, 1; 0 1];
  Hs = [1, 0];
else
  lenSubState = 3;
  % As is derived from state-transition matrix,
  % [1 dt 0.5*(dt)^2 ; 0 1  dt ; 0 0  1]; assuming dt=1 we have:
  As = [1, 1, 0.5; 0, 1, 1; 0, 0, 1];
  Hs = [1, 0, 0];
end
numDims = length(r.InitialLocation);
lenState = numDims * lenSubState;

% Create StateTransitionModel and MeasurementModel matrices
kalman.StateTransitionModel = zeros(lenState, lenState, classToUse);
kalman.MeasurementModel     = zeros(numDims,  lenState, classToUse);
for iDim = 1: numDims
  iFirst = (iDim - 1) * lenSubState + 1;
  iLast = iDim * lenSubState;
  kalman.StateTransitionModel(iFirst:iLast, iFirst:iLast) = As;
  kalman.MeasurementModel(iDim, iFirst:iLast) = Hs;
end

% Create State vector
kalman.State = zeros(lenState, 1, classToUse);
kalman.State(1: lenSubState: lenState) = r.InitialLocation;

% Create StateCovariance, ProcessNoise, and MeasurementNoise matrices
kalman.StateCovariance  = diag(repmat(r.InitialEstimateError, [1, numDims]));
kalman.ProcessNoise     = diag(repmat(r.MotionNoise,          [1, numDims]));
kalman.MeasurementNoise = diag(repmat(r.MeasurementNoise,     [1, numDims]));

% Create a KalmanFilter object
kalmanFilter = vision.KalmanFilter(kalman);
end

%--------------------------------------------------------------------------
function r = parseInputs(varargin)

  % Instantiate an input parser
  parser = inputParser;
  parser.FunctionName = mfilename;

  % Specify the required parameters
  parser.addRequired('MotionModel',          @validateMotionModel);
  parser.addRequired('InitialLocation',      @validateInitialLocation);
  parser.addRequired('InitialEstimateError');
  parser.addRequired('MotionNoise');
  parser.addRequired('MeasurementNoise',     @validateMeasurementNoise);
  
  % Parse the inputs
  parse(parser, varargin{:});
  r = parser.Results;
  
  % Get full string for motion model
  r.MotionModel = validatestring(r.MotionModel, ...
    {'ConstantVelocity', 'ConstantAcceleration'});

  % Check InitialEstimateError and MotionNoise. The length of these
  % parameters depends on MotionModel.
  validateCovariance(r.InitialEstimateError, ...
                      'InitialEstimateError', 3, r.MotionModel);
  validateCovariance(r.MotionNoise,...
                      'MotionNoise',          4, r.MotionModel);

  classToUse = class(r.InitialEstimateError);
  areClassesMatching = strcmp(classToUse, class(r.MotionNoise))...
    && strcmp(classToUse, class(r.MeasurementNoise));
  coder.internal.errorIf(~areClassesMatching, ...
    'vision:configureKalmanFilter:classNotMatching');
end

%--------------------------------------------------------------------------
function tf = validateMotionModel(str)
  validatestring(str, {'ConstantVelocity', 'ConstantAcceleration'}, ...
    'configureKalmanFilter', 'MotionModel', 1);
  tf = true;
end

%--------------------------------------------------------------------------
function tf = validateInitialLocation(value)
  validateattributes(value, ...
    {'numeric'}, ...
    {'real', 'finite', 'nonsparse', 'vector', 'nonempty'},...
    'configureKalmanFilter', 'InitialLocation', 2);
  tf = true;
end

%--------------------------------------------------------------------------
function tf = validateMeasurementNoise(value)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', 'nonempty', 'positive', 'scalar'},...
    'configureKalmanFilter', 'MeasurementNoise', 5);
  tf = true;
end

%--------------------------------------------------------------------------
function tf = validateCovariance(value, name, idx, motionModel)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', 'vector', 'nonempty', 'positive'},...
    'configureKalmanFilter', name, idx);
  
  if strcmp(motionModel, 'ConstantVelocity')
    coder.internal.errorIf(numel(value) ~= 2, ...
      'vision:configureKalmanFilter:invalidCovarianceLengthForVelocity', name);
  else
    coder.internal.errorIf(numel(value) ~= 3, ...
      'vision:configureKalmanFilter:invalidCovarianceLengthForAcceleration', name);
  end
  
  tf = true;
end
