classdef KalmanFilter< vision.internal.EnforceScalarHandle
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

    methods
        function out=KalmanFilter
            % Parse the inputs.
        end

        function clone(in) %#ok<MANU>
        end

        function correct(in) %#ok<MANU>
            % correct Corrects the measurement, state, and state estimation error covariance
            %   [z_corr, x_corr, P_corr] = correct(obj, z) returns the correction
            %   of measurement, state, and state estimation error covariance
            %   based on the current measurement z, an N-element vector. The
            %   internal state and covariance of Kalman filter are overwritten by
            %   the corrected values.
        end

        function distance(in) %#ok<MANU>
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
        end

        function predict(in) %#ok<MANU>
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
        end

    end
    methods (Abstract)
    end
    properties
        %ControlModel Model describing control input to state transformation (B)
        %   Specify the transition from control input to state as an M-by-L
        %   matrix. This property cannot be changed once the object is
        %   constructed.
        %
        %   Default: []
        ControlModel;

        %MeasurementModel Model describing state to measurement transformation (H)
        %   Specify the transition from state to measurement as an N-by-M
        %   matrix. This property cannot be changed once the object is
        %   constructed.
        %
        %   Default: [1 0 0 0; 0 0 1 0]
        MeasurementModel;

        %MeasurementNoise Measurement noise covariance (R)
        %   Specify the covariance of measurement noise as a scalar or
        %   an N-by-N matrix. If you specify it as a scalar it will be extended
        %   to an N-by-N diagonal matrix.
        % 
        %   Default: 1
        MeasurementNoise;

        %ProcessNoise Process noise covariance (Q)
        %   Specify the covariance of process noise as a scalar or an M-by-M
        %   matrix. If you specify it as a scalar it will be extended to an
        %   M-by-M diagonal matrix.
        % 
        %   Default: 1
        ProcessNoise;

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

        %StateTransitionModel Model describing state transition between time steps (A)
        %   Specify the transition of state between times as an M-by-M
        %   matrix. This property cannot be changed once the object is
        %   constructed.
        %
        %   Default: [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1]
        StateTransitionModel;

    end
end
