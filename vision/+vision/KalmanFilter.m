classdef KalmanFilter < vision.internal.EnforceScalarHandle
%KalmanFilter Kalman filter for object tracking
%   This Kalman filter is designed for tracking. You can use it to predict
%   object's future location, to reduce noise in the detected location, or
%   to help associate multiple objects with their tracks. To use the Kalman
%   filter, the object must be moving based on a linear motion model, for
%   example, constant velocity or constant acceleration.
%
%   The Kalman filter algorithm implements a discrete time, linear
%   State-Space System described as follows.
% 
%      x(k) = A * x(k-1) + B * u(k-1) + w(k-1)    (state equation)
%      z(k) = H * x(k) + v(k)                     (measurement equation)
% 
%   <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'vision.KalmanFilter.StateSpaceModel')">See the documentation for the detailed description of all variables.</a>
%
%   The Kalman filter algorithm involves two steps.
%      - Predict: Using the previous states to predict the current state.
%      - Correct, also known as update: Using the current measurement, 
%           such as the detected object location, to correct the state.
%
%   obj = vision.KalmanFilter returns a Kalman filter object for a discrete
%   time, constant velocity system. In this system, the state transition
%   model, A, is [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1] and the measurement
%   model, H, is [1 0 0 0; 0 0 1 0].
% 
%   obj = vision.KalmanFilter(StateTransitionModel, MeasurementModel)
%   lets you specify the state transition model, A, and the measurement
%   model, H. 
% 
%   obj = vision.KalmanFilter(StateTransitionModel, MeasurementModel,
%   ControlModel) additionally, lets you specify the control model, B.
% 
%   obj = vision.KalmanFilter(..., Name, Value) configures the Kalman
%   filter object properties, specified as one or more name-value pair
%   arguments. Unspecified properties have default values.
%
%   predict method syntax:
% 
%   [z_pred, x_pred, P_pred] = predict(obj) returns the prediction of
%   measurement, state, and state estimation error covariance at the next
%   time step (e.g., next video frame). The internal state and covariance
%   of Kalman filter are overwritten by the prediction results.
% 
%   [z_pred, x_pred, P_pred] = predict(obj, u) additionally, lets you
%   specify the control input, u, an L-element vector. This syntax applies
%   if you have set the control model B.
%
%   correct method syntax:
% 
%   [z_corr, x_corr, P_corr] = correct(obj, z) returns the correction of
%   measurement, state, and state estimation error covariance based on the
%   current measurement z, an N-element vector. The internal state and
%   covariance of Kalman filter are overwritten by the corrected values.
% 
%   distance method syntax:
% 
%   d = distance(obj, z_matrix) computes a distance between one or more
%   measurements supplied by the z_matrix and the measurement predicted by
%   the Kalman filter object. This computation takes into account the
%   covariance of the predicted state and the process noise. Each row of
%   the input z_matrix must contain a measurement vector of length N. The
%   distance method returns a row vector where each element is a distance
%   associated with the corresponding measurement input. The distance
%   method can only be called after the predict method.
%
%   Notes:
%   ======
%   - If the measurement exists, e.g., the object has been detected, you
%     can call the predict method and the correct method together. If the
%     measurement is missing, you can call the predict method but not the
%     correct method. 
%
%       If the object is detected
%           predict(kalmanFilter);
%           trackedLocation = correct(kalmanFilter, objectLocation);
%        Else
%           trackedLocation = predict(kalmanFilter);
%        End
%
%   - You can use the distance method to compute distances that describe
%     how a set of measurements matches the Kalman filter. You can thus
%     find a measurement that best fits the filter. This strategy can be
%     used for matching object detections against object tracks in a
%     multi-object tracking problem.
%
%   - You can use configureKalmanFilter to create a Kalman filter for
%     object tracking.
%
%   KalmanFilter methods:
% 
%   predict  - Predicts the measurement, state, and state estimation error covariance
%   correct  - Corrects the measurement, state, and state estimation error covariance
%   distance - Computes distances between measurements and the Kalman filter
%   clone    - Creates a tracker object with the same property values
% 
%   KalmanFilter properties:
% 
%   StateTransitionModel - Model describing state transition between time steps (A)
%   MeasurementModel     - Model describing state to measurement transformation (H)
%   ControlModel         - Model describing control input to state transformation (B)
%   State                - State (x)
%   StateCovariance      - State estimation error covariance (P)
%   ProcessNoise         - Process noise covariance (Q)
%   MeasurementNoise     - Measurement noise covariance (R)
% 
%   Example: Track an occluded object
%   ---------------------------------
% 
%   % Create required System objects
%   videoReader = vision.VideoFileReader('singleball.mp4');
%   videoPlayer = vision.VideoPlayer('Position', [100, 100, 500, 400]);
%   foregroundDetector = vision.ForegroundDetector(...
%     'NumTrainingFrames', 10, 'InitialVariance', 0.05);
%   blobAnalyzer = vision.BlobAnalysis('AreaOutputPort', false, ...
%     'MinimumBlobArea', 70);
% 
%   % Process each video frame to detect and track the object
%   kalmanFilter = []; isTrackInitialized = false;
%   while ~isDone(videoReader)
%     colorImage  = step(videoReader); % get the next video frame
% 
%     % Detect the object in a gray scale image
%     foregroundMask = step(foregroundDetector, rgb2gray(colorImage));
%     detectedLocation = step(blobAnalyzer, foregroundMask);
%     isObjectDetected = size(detectedLocation, 1) > 0;
% 
%     if ~isTrackInitialized
%       if isObjectDetected % First detection.
%         kalmanFilter = configureKalmanFilter('ConstantAcceleration', ...
%           detectedLocation(1,:), [1 1 1]*1e5, [25, 10, 10], 25);
%         isTrackInitialized = true;
%       end
%       label = ''; circle = zeros(0,3); % initialize annotation properties
%     else  % A track was initialized and therefore Kalman filter exists
%       if isObjectDetected % Object was detected
%         % Reduce the measurement noise by calling predict, then correct
%         predict(kalmanFilter);
%         trackedLocation = correct(kalmanFilter, detectedLocation(1,:));
%         label = 'Corrected';
%       else % Object is missing
%         trackedLocation = predict(kalmanFilter);  % Predict object location
%         label = 'Predicted';
%       end
%       circle = [trackedLocation, 5];
%     end
% 
%     colorImage = insertObjectAnnotation(colorImage, 'circle', ...
%       circle, label, 'Color', 'red'); % mark the tracked object
%     step(videoPlayer, colorImage);    % play video
%   end % while
% 
%   release(videoPlayer); % Release resources
%   release(videoReader);
%
%  See also configureKalmanFilter, assignDetectionsToTracks 

%   Copyright  The MathWorks, Inc.
%   Date: 2013/03/31 00:10:03 $
% 
%   References:
% 
%   [1] Greg Welch and Gary Bishop, "An Introduction to the Kalman Filter," 
%       TR95-041, University of North Carolina at Chapel Hill.
%   [2] Samuel Blackman, "Multiple-Target Tracking with Radar
%       Applications," Artech House, 1986.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
  
  %------------------------------------------------------------------------
  % Private properties which can only be set in the constructor
  %------------------------------------------------------------------------
  properties(SetAccess=private)
    %StateTransitionModel Model describing state transition between time steps (A)
    %   Specify the transition of state between times as an M-by-M
    %   matrix. This property cannot be changed once the object is
    %   constructed.
    %
    %   Default: [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1]
    StateTransitionModel;
    %MeasurementModel Model describing state to measurement transformation (H)
    %   Specify the transition from state to measurement as an N-by-M
    %   matrix. This property cannot be changed once the object is
    %   constructed.
    %
    %   Default: [1 0 0 0; 0 0 1 0]
    MeasurementModel;
    %ControlModel Model describing control input to state transformation (B)
    %   Specify the transition from control input to state as an M-by-L
    %   matrix. This property cannot be changed once the object is
    %   constructed.
    %
    %   Default: []
    ControlModel;
  end
  
  %------------------------------------------------------------------------
  % Dependent properties whose values are stored in other hidden properties
  %------------------------------------------------------------------------
  properties(Dependent=true)
    %State State (x)
    %   Specify the state as a scalar or an M-element vector.
    %   If you specify it as a scalar it will be extended to an M-element
    %   vector.
    % 
    %   Default: 0
    State;
    %StateCovariance State estimation error covariance (P)
    %   Specify the covariance of the state estimation error as a scalar or
    %   an M-by-M matrix. If you specify it as a scalar it will be extended
    %   to an M-by-M diagonal matrix.
    %
    %   Default: 1
    StateCovariance;
    %ProcessNoise Process noise covariance (Q)
    %   Specify the covariance of process noise as a scalar or an M-by-M
    %   matrix. If you specify it as a scalar it will be extended to an
    %   M-by-M diagonal matrix.
    % 
    %   Default: 1
    ProcessNoise;
    %MeasurementNoise Measurement noise covariance (R)
    %   Specify the covariance of measurement noise as a scalar or
    %   an N-by-N matrix. If you specify it as a scalar it will be extended
    %   to an N-by-N diagonal matrix.
    % 
    %   Default: 1
    MeasurementNoise;
  end
 
  %------------------------------------------------------------------------
  % Hidden properties used by the object
  %------------------------------------------------------------------------
  properties(Hidden, Access=private)
    pM;   % Length of state
    pN;   % Length of measurement
    pL;   % Length of control input
    pHasControlInput;
    pState;
    pStateCovariance;
    pProcessNoise;
    pMeasurementNoise;
    pHasPrediction;
    pMeasurement;
    pControlInput;
  end
  
  %------------------------------------------------------------------------
  % Constant properties which store the default values
  %------------------------------------------------------------------------
  properties(Hidden, Access=private, Constant=true)
    cStateTransitionModel = [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1];
    cMeasurementModel     = [1 0 0 0; 0 0 1 0];
    cControlModel         = [];
    cState                = 0;
    cStateCovariance      = 1;
    cProcessNoise         = 1;
    cMeasurementNoise     = 1;
  end
  
  methods

    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    function obj = KalmanFilter(varargin)
      % Parse the inputs.
      if isempty(coder.target)  % Simulation
        [stateTransitionModel, measurementModel, controlModel, ...
        state, stateCovariance, processNoise, measurementNoise, ...
        hasControlInput] ...
        = parseInputsSimulation(obj, varargin{:});
      else                      % Code generation
        [stateTransitionModel, measurementModel, controlModel, ...
        state, stateCovariance, processNoise, measurementNoise, ...
        hasControlInput] ...
        = parseInputsCodegen(obj, varargin{:});
      end

      % Get the size of the models.
      M = size(stateTransitionModel, 1);
      N = size(measurementModel, 1);
      if hasControlInput
        L = size(controlModel, 2);
      else
        L = 1;
      end
      
      % Check whether the inputs start with 0, 2, or 3 numerical arguments.
      firstNVIndex = findFirstNVPair(varargin{:});
      
      coder.internal.errorIf(firstNVIndex==2 || firstNVIndex>4, ...
        'vision:KalmanFilter:invalidInputsToConstructor');
      
      % Check StateTransitionModel and MeasurementModel.
      validateDataAttributes('StateTransitionModel', stateTransitionModel);
      validateDataAttributes('MeasurementModel',     measurementModel);
      coder.internal.errorIf(size(stateTransitionModel, 1)...
        ~= size(stateTransitionModel, 2), ...
        'vision:KalmanFilter:nonSquareStateModel');
      coder.internal.errorIf(size(measurementModel, 2) ~= M, ...
        'vision:KalmanFilter:nonmatchingMeasurementState');
            
      % Check ControlModel if it has been specified.
      if hasControlInput
        validateDataAttributes('ControlModel', controlModel);
        coder.internal.errorIf(size(controlModel, 1) ~= M, ...
          'vision:KalmanFilter:nonmatchingControlState');
      end
      
      % Rules for data classes.
      % - All of the properties can be either double or single. Mixture
      %   of double and single is allowed.
      % - All of the inputs, including z, z_matrix, and u, can be double,
      %   single, or integer. 
      % - The outputs have the same class as stateTransitionModel.
      classToUse = class(stateTransitionModel);
  
      % Copy StateTransitionModel, MeasurementModel, and ControlModel.
      obj.StateTransitionModel = stateTransitionModel;
      obj.MeasurementModel     = cast(measurementModel, classToUse);
      obj.ControlModel         = cast(controlModel, classToUse);
      obj.pHasControlInput     = hasControlInput;

      % Copy and check State, StateCovariance, ProcessNoise, and
      % MeasurementNoise. These parameters will be expanded to vectors or
      % matrices if they were scalars. Note that checking is done in the
      % set method.
      obj.pState            = expandScalarValue(cast(state, classToUse), [M, 1]);
      
      
      stateCovarianceE  = expandScalarValue(cast(stateCovariance, classToUse), [M, M]);
      processNoiseE     = expandScalarValue(cast(processNoise, classToUse), [M, M]);
      measurementNoiseE = expandScalarValue(cast(measurementNoise, classToUse), [N, N]);      
      
      % Check the sizes of the coveriance matrices
      checkCovariance('StateCovariance', stateCovarianceE, [M, M]);
      checkCovariance('ProcessNoise', processNoiseE, [M, M]);
      checkCovariance('MeasurementNoise', measurementNoiseE, [N, N]);
      
      obj.pStateCovariance  = stateCovarianceE;
      obj.pProcessNoise     = processNoiseE;
      obj.pMeasurementNoise = measurementNoiseE;

      % Copy the sizes.
      obj.pM = M;
      obj.pN = N;
      obj.pL = L;
      
      obj.pHasPrediction = false;
      
      obj.pMeasurement = ones(N, 1, classToUse);
      obj.pControlInput = ones(L, 1, classToUse);
    end
    
    %----------------------------------------------------------------------
    % Predict method
    %----------------------------------------------------------------------
    function [z_pred, x_pred, P_pred] = predict(obj, varargin)
      % predict Predicts the measurement, state, and state estimation error covariance
      %   [z_pred, x_pred, P_pred] = predict(obj) returns the prediction of
      %   measurement, state, and state estimation error covariance at the
      %   next time step (e.g., next video frame). The internal state and
      %   covariance of Kalman filter are overwritten by the prediction
      %   results.
      % 
      %   [z_pred, x_pred, P_pred] = predict(obj, u) additionally, lets
      %   you specify the control input, u, in the prediction. This syntax
      %   applies if you have set the control model B.
      coder.internal.errorIf(nargin>2, ...
        'vision:KalmanFilter:invalidNumInputsToPredict');
      coder.internal.errorIf(nargin==2 && ~obj.pHasControlInput, ...
        'vision:KalmanFilter:needControlModel');
      coder.internal.errorIf(nargin==1 && obj.pHasControlInput, ...
        'vision:KalmanFilter:needControlInput');
      
      if nargin == 2
        validateInputSizeAndType('u', varargin{1}, obj.pL);
        % Input u can be a row vector or a column vector. Internally, it is
        % always a column vector.
        obj.pControlInput(:) = varargin{1};
      else
        obj.pControlInput(:) = 0;  % Value of 0 means it is not used.
      end
      
      x = obj.StateTransitionModel * obj.pState;
      if obj.pHasControlInput
        x = x + obj.ControlModel * obj.pControlInput;
      end
      P_pred = obj.StateTransitionModel * obj.pStateCovariance ...
         * obj.StateTransitionModel' + obj.pProcessNoise;

      % State is a column vector internally; but it is a row vector for
      % output.
      x_pred = x';
      z_pred = (obj.MeasurementModel * x)';
      obj.pState(:) = x;
      obj.pStateCovariance(:) = P_pred;
      obj.pHasPrediction = true;
    end
    
    %----------------------------------------------------------------------
    % Correct method
    %----------------------------------------------------------------------
    function [z_corr, x_corr, P_corr] = correct(obj, z)
      % correct Corrects the measurement, state, and state estimation error covariance
      %   [z_corr, x_corr, P_corr] = correct(obj, z) returns the correction
      %   of measurement, state, and state estimation error covariance
      %   based on the current measurement z, an N-element vector. The
      %   internal state and covariance of Kalman filter are overwritten by
      %   the corrected values.
      
      % Input z_input can be a row vector or a column vector. Internally,
      % it is always a column vector.
      validateInputSizeAndType('z', z, obj.pN);
      obj.pMeasurement(:) = z;

      gain_numerator = obj.pStateCovariance * obj.MeasurementModel';
      residualCovariance = obj.MeasurementModel * obj.pStateCovariance ...
        * obj.MeasurementModel' + obj.pMeasurementNoise;
      gain = gain_numerator / residualCovariance;
      x = obj.pState + gain * (obj.pMeasurement - obj.MeasurementModel * obj.pState);
      P_corr = obj.pStateCovariance...
        - gain * obj.MeasurementModel * obj.pStateCovariance;
      x_corr = x';
      z_corr = (obj.MeasurementModel * x)';
      obj.pState(:) = x;
      obj.pStateCovariance(:) = P_corr;
      obj.pHasPrediction = false;
    end
    
    %----------------------------------------------------------------------
    % Distance method
    %----------------------------------------------------------------------
    function d = distance(obj, z_matrix)
      % distance Computes distances between measurements and the Kalman filter
      %   d = distance(obj, z_matrix) computes a distance between one or
      %   more measurements supplied by the z_matrix and the measurement
      %   predicted by the Kalman filter object. This computation takes
      %   into account the covariance of the predicted state and the
      %   process noise. Each row of the input z_matrix must contain a
      %   measurement vector of length N. The distance method returns a row
      %   vector where each element is a distance associated with the
      %   corresponding measurement input. The distance method can only be
      %   called after the predict method.
      
      % The procedure for computing the distance is described in Page 93 of
      % "Multiple-Target Tracking with Radar Applications" by Samuel
      % Blackman.
      
      coder.internal.errorIf(~obj.pHasPrediction, ...
        'vision:KalmanFilter:notPredictedDistance');
      
      validateMeasurementMatrix(z_matrix, obj.pN);
      
      residualCovariance = obj.MeasurementModel * obj.pStateCovariance ...
        * obj.MeasurementModel' + obj.pMeasurementNoise;
      z_e = obj.MeasurementModel * obj.pState;

      N = size(obj.MeasurementModel, 1);
      z_in = zeros(N, 1, 'like', obj.StateTransitionModel);
      isNColumnMatrix = (size(z_matrix, 2) == N);
      if isNColumnMatrix
        len = size(z_matrix, 1);
        d = zeros(1, len, 'like', obj.StateTransitionModel);
        for idx = 1:len
          z_in(:) = z_matrix(idx,:)';
          d(idx) = normalizedDistance(z_in, z_e, residualCovariance);
        end
      elseif(numel(z_matrix) > 0) % N-by-1 matrix
        z_in(:) = z_matrix;
        d = normalizedDistance(z_in, z_e, residualCovariance);
      else
        d = [];
      end
    end  
    
    %----------------------------------------------------------------------
    % Clone method
    %----------------------------------------------------------------------
    function newObj = clone(obj)
      if isempty(obj.ControlModel)
        newObj = vision.KalmanFilter(obj.StateTransitionModel, ...
          obj.MeasurementModel);
      else
        newObj = vision.KalmanFilter(obj.StateTransitionModel, ...
          obj.MeasurementModel, obj.ControlModel);
      end
      newObj.pState            = obj.pState;
      newObj.pStateCovariance  = obj.pStateCovariance;
      newObj.pProcessNoise     = obj.pProcessNoise;
      newObj.pMeasurementNoise = obj.pMeasurementNoise;
    end        
  end
  
  methods
    %----------------------------------------------------------------------
    function set.State(obj, value)
      validateState(value, obj.pM);
      if numel(value) == 1
        for idx = 1:obj.pM
          obj.pState(idx, 1) = value;
        end
      else
        obj.pState = value(:);
      end
    end
    
    %----------------------------------------------------------------------
    function value = get.State(obj)
      value = obj.pState;
    end
    
    %----------------------------------------------------------------------
    function set.StateCovariance(obj, value)
      checkCovariance('StateCovariance', value, [obj.pM, obj.pM]);
      
      if numel(value) == 1
        for idx = 1:obj.pM
          obj.pStateCovariance(idx, idx) = value;
        end
      else
        obj.pStateCovariance(:) = value(:);
      end
    end
    
    %----------------------------------------------------------------------
    function value = get.StateCovariance(obj)
      value = obj.pStateCovariance;
    end
    
    %----------------------------------------------------------------------
    function set.ProcessNoise(obj, value)
      checkCovariance('ProcessNoise', value, [obj.pM, obj.pM]);
      
      if numel(value) == 1
        for idx = 1:obj.pM
          obj.pProcessNoise(idx, idx) = value;
        end
      else
        obj.pProcessNoise(:) = value(:);
      end
    end
    
    %----------------------------------------------------------------------
    function value = get.ProcessNoise(obj)
      value = obj.pProcessNoise;
    end

    %----------------------------------------------------------------------
    function set.MeasurementNoise(obj, value)
      checkCovariance('MeasurementNoise', value, [obj.pN, obj.pN]);
      
      if numel(value) == 1
        for idx = 1:obj.pN
          obj.pMeasurementNoise(idx, idx) = value;
        end
      else
        obj.pMeasurementNoise(:) = value(:);
      end
    end
    
    %----------------------------------------------------------------------
    function value = get.MeasurementNoise(obj)
      value = obj.pMeasurementNoise;
    end
  end
  
  methods(Access=private)
    %----------------------------------------------------------------------
    % Parse inputs for simulation
    %----------------------------------------------------------------------
    function [stateTransitionModel, measurementModel, controlModel, ...
        state, stateCovariance, processNoise, measurementNoise, ...
        hasControlInput] ...
        = parseInputsSimulation(obj, varargin)
      
      % Instantiate an input parser
      parser = inputParser;
      parser.FunctionName = mfilename;
      
      % Specify the optional parameters
      parser.addOptional('StateTransitionModel', obj.cStateTransitionModel);
      parser.addOptional('MeasurementModel',     obj.cMeasurementModel);
      parser.addOptional('ControlModel',         obj.cControlModel);

      parser.addParameter('State',               obj.cState);
      parser.addParameter('StateCovariance',     obj.cStateCovariance);
      parser.addParameter('ProcessNoise',        obj.cProcessNoise);
      parser.addParameter('MeasurementNoise',    obj.cMeasurementNoise);
      
      % Parse parameters
      parse(parser, varargin{:});
      r = parser.Results;
      
      stateTransitionModel =  r.StateTransitionModel;
      measurementModel     =  r.MeasurementModel;
      controlModel         =  r.ControlModel;
      state                =  r.State;
      stateCovariance      =  r.StateCovariance;
      processNoise         =  r.ProcessNoise;
      measurementNoise     =  r.MeasurementNoise;
      
      if isempty(controlModel)
        hasControlInput = false;
      else
        hasControlInput = true;
      end
    end
    
    %----------------------------------------------------------------------
    % Parse inputs for code generation
    %----------------------------------------------------------------------
    function [stateTransitionModel, measurementModel, controlModel, ...
        state, stateCovariance, processNoise, measurementNoise, ...
        hasControlInput] ...
        = parseInputsCodegen(obj, varargin)

      % Find the position of the first name-property pair, firstPNIndex
      firstNVIndex = findFirstNVPair(varargin{:});
      
      parms = struct( ...
        'State',            uint32(0), ...
        'StateCovariance',  uint32(0), ...
        'ProcessNoise',     uint32(0), ...
        'MeasurementNoise', uint32(0));
      
      popt = struct( ...
        'CaseSensitivity', false, ...
        'StructExpand',    true, ...
        'PartialMatching', false);
      
      optarg           = eml_parse_parameter_inputs(parms, popt, ...
        varargin{firstNVIndex:end});
      state            = eml_get_parameter_value(optarg.State, ...
        obj.cState, varargin{firstNVIndex:end});
      stateCovariance  = eml_get_parameter_value(optarg.StateCovariance,...
        obj.cStateCovariance, varargin{firstNVIndex:end});
      processNoise     = eml_get_parameter_value(optarg.ProcessNoise,...
        obj.cProcessNoise, varargin{firstNVIndex:end});
      measurementNoise = eml_get_parameter_value(optarg.MeasurementNoise,...
        obj.cMeasurementNoise, varargin{firstNVIndex:end});
      
      if firstNVIndex == 1
        stateTransitionModel = obj.cStateTransitionModel;
        measurementModel     = obj.cMeasurementModel;
      elseif firstNVIndex == 2
        stateTransitionModel = varargin{1};
        measurementModel     = obj.cMeasurementModel;
      else
        stateTransitionModel = varargin{1};
        measurementModel     = varargin{2};
      end
      
      M = size(stateTransitionModel, 1);
      if firstNVIndex < 4
        controlModel = zeros(M, 1);
        hasControlInput = false;
      else
        controlModel = varargin{3};
        hasControlInput = true;
      end
    end
  end
end

%--------------------------------------------------------------------------
function checkCovariance(name, value, dims)
  validateDataAttributes(name, value);
  validateDataDims(name, value, dims);
    
  % Use the technique similar to that in cholcov() to test symmetricity and
  % positive semi-definitness.
  tol = 100 * eps(max(abs(diag(value))));
  notSymmetric = ~all(all(abs(value - value') < tol));

  [~, D] = eig((value + value')/2);
  d = diag(D);
  notPositiveSemidefinite = any(d < -tol);
  
  coder.internal.errorIf(notPositiveSemidefinite || notSymmetric, ...
    'vision:KalmanFilter:invalidCovarianceValues', name);
end

%--------------------------------------------------------------------------
function validateInputSizeAndType(name, value, len)
  validateattributes(value, ...
    {'numeric'}, ...
    {'real', 'finite', 'nonsparse', 'vector', 'numel', len},...
    'KalmanFilter', name);
end

%--------------------------------------------------------------------------
function validateState(value, len)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', 'vector'},...
    'KalmanFilter', 'State');
  
  isInvalid = ~isscalar(value) && numel(value)~=len;
  coder.internal.errorIf(isInvalid, ...
    'vision:KalmanFilter:invalidStateDims', len);
end

%--------------------------------------------------------------------------
function validateMeasurementMatrix(value, len)
  validateattributes(value, ...
    {'numeric'}, ...
    {'real', 'finite', 'nonsparse', '2d'},...
    'KalmanFilter', 'z_matrix');

  isInvalidZSize = ~(isempty(value) || size(value, 2) == len ...
    || all(size(value) == [len, 1]));
  coder.internal.errorIf(isInvalidZSize, ...
    'vision:KalmanFilter:invalidZSize', len, len);
end

%--------------------------------------------------------------------------
function validateDataAttributes(name, value)
  validateattributes(value, ...
    {'single', 'double'}, ...
    {'real', 'finite', 'nonsparse', '2d', 'nonempty'},...
    'KalmanFilter', name);
end

%--------------------------------------------------------------------------
function validateDataDims(name, value, dims)
  isInvalidCovariance = ~isscalar(value) && any(size(value) ~= dims);
  coder.internal.errorIf(isInvalidCovariance, ...
    'vision:KalmanFilter:invalidCovarianceDims', name, dims(1), dims(2));
end

%--------------------------------------------------------------------------
function val = expandScalarValue(value, dims)
  if dims(2) == 1
    if isscalar(value)
      val = value * ones(dims);
    else
      val = value(:);
    end
  else
    if isscalar(value)
      val = value * eye(dims);
    else
      val = value;
    end
  end
end
    
%--------------------------------------------------------------------------
function f = normalizedDistance(z, mu, sigma)
  zd = z - mu;
  mahalanobisDistance = zd' / sigma * zd;
  determinant = det(sigma);
  f = mahalanobisDistance + log(determinant);
end

%--------------------------------------------------------------------------
function idx = findFirstNVPair(varargin)
  % The returned value is (nargin+1) if there is no name-value pair in the
  % inputs.
  idx = nargin+1;
  for k = coder.unroll(1:nargin)
    if ischar(varargin{k}) || isstruct(varargin{k})
      idx = k;
      return
    end
  end
end
