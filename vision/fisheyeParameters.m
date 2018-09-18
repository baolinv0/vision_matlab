classdef fisheyeParameters < vision.internal.calibration.FisheyeParametersImpl & matlab.mixin.CustomDisplay
%fisheyeParameters Object for storing fisheye camera parameters
%
%   fisheyeParams = fisheyeParameters(intrinsics) returns an object that
%   contains intrinsic and extrinsic parameters of a fisheye camera.
%   intrinsics must be a fisheyeIntrinsics object.
%   See <a href="matlab:doc('fisheyeIntrinsics')">fisheyeIntrinsics</a> for more details.
%
%   fisheyeParams = fisheyeParameters(..., Name, Value) configures the
%   camera parameters object properties, specified as one or more
%   name-value pair arguments. Unspecified properties have default values.
%   The available parameters are:
% 
%    'EstimateAlignment'    A logical scalar that specifies whether to
%                           estimate the axes alignment between the sensor
%                           plane and the image plane, described by the
%                           stretch matrix.
%
%                           Default: false
% 
%    'RotationVectors'      An M-by-3 matrix containing M rotation vectors
%                           Each vector describes the 3-D rotation of the
%                           camera's sensor plane relative to the corresponding
%                           calibration pattern. The vector specifies the
%                           3-D axis about which the camera is rotated, and
%                           its magnitude is the rotation angle in radians.
% 
%                           Default: []
% 
%    'TranslationVectors'   An M-by-3 matrix containing M translation vectors.
%                           Each vector describes the translation of the
%                           camera's sensor plane relative to the corresponding
%                           calibration pattern in world units.
% 
%                           Default: []
% 
%    'WorldPoints'          An M-by-2 array of [x,y] world coordinates of
%                           keypoints on the calibration pattern, where M is
%                           the number of keypoints in the pattern.
%                           WorldPoints must be non-empty for showExtrinsics
%                           to work.
% 
%                           Default: []
% 
%    'WorldUnits'           A character vector describing the units, in
%                           which the WorldPoints are specified.
% 
%                           Default: 'mm'
% 
%    'ReprojectionErrors'   An M-by-2-by-P array of [x,y] pairs representing
%                           the translation in x and y between the reprojected 
%                           pattern keypoints and the detected pattern keypoints.    
%
%                           Default: []
%
%   fisheyeParameters public properties (read only):
%   -----------------------------------
%   
%      Intrinsic camera parameters:
%      ----------------------------
%      Intrinsics           - A fisheyeIntrinsics object for storing 
%                             intrinsic camera parameters. It includes
%                             mapping coefficients, stretch matrix,
%                             distortion center and image size.
%
%      Extrinsic camera parameters:
%      ----------------------------------------
%      RotationVectors      - Rotation of the calibration patterns
%      TranslationVectors   - Translation of the calibration patterns
%
%      Accuracy of estimated camera parameters:
%      ----------------------------------------
%      ReprojectionErrors   - Translation between projected and detected points
%
%      Settings used to estimate camera parameters:
%      --------------------------------------------
%      NumPatterns          - Number of patterns used to estimate extrinsics 
%      WorldPoints          - World coordinates of pattern keypoints
%      WorldUnits           - Units of the world coordinates
%      EstimateAlignment    - True if axis alignment was estimated
%
%   Notes:
%   ------
%   RotationVectors and TranslationVectors must be set together in the
%   constructor to ensure that the number of translation and rotation 
%   vectors is the same. Setting one but not the other will result in an 
%   error.
%
%   Example
%   -------
%    % Create a fisheyeParameters object manually.
%    % In practice use estimateFisheyeParameters.
%    mappingCoefficients = rand(1, 4);
%    distortionCenter = [320, 240];
%    imageSize = [480, 640];
%    intrinsics = fisheyeIntrinsics(mappingCoefficients, imageSize, distortionCenter);
%    params = fisheyeParameters(intrinsics);
%
%   See also estimateFisheyeParameters, undistortFisheyeImage, 
%            fisheyeIntrinsics, showExtrinsics, showReprojectionErrors

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

    methods(Access=protected)
        %------------------------------------------------------------------
        % Group properties into meaningful categories for display
        %------------------------------------------------------------------
        function group = getPropertyGroups(~)
            group1 = 'Camera Intrinsics';
            list1 = {'Intrinsics'};

            group2 = 'Camera Extrinsics';
            list2 = {'RotationMatrices', 'TranslationVectors'};

            group3 = 'Accuracy of Estimation';
            list3 = {'MeanReprojectionError', 'ReprojectionErrors', ...
                'ReprojectedPoints'};

            group4 = 'Calibration Settings';
            list4 = {'NumPatterns', 'WorldPoints', 'WorldUnits', ...
                'EstimateAlignment'};

            group(1) = matlab.mixin.util.PropertyGroup(list1, group1);
            group(2) = matlab.mixin.util.PropertyGroup(list2, group2);
            group(3) = matlab.mixin.util.PropertyGroup(list3, group3);
            group(4) = matlab.mixin.util.PropertyGroup(list4, group4);
        end
    end
    
    methods
        %----------------------------------------------------------------------
        function this = fisheyeParameters(varargin)
             this@vision.internal.calibration.FisheyeParametersImpl(varargin{:});                        
        end               
    end
        
    methods(Hidden)
        %------------------------------------------------------------------        
        function hAxes = showReprojectionErrorsImpl(this, view, hAxes, highlightIndex)
            % showReprojectionErrors Visualize calibration errors.
            %   showReprojectionErrors(fisheyeParams) displays a bar 
            %   graph that represents the accuracy of camera calibration. 
            %   The bar graph displays the mean reprojection error per image. 
            %   The fisheyeParams input is returned from the 
            %   estimateFisheyeParameters function.
            % 
            %   showReprojectionErrors(fisheyeParams, view) displays the 
            %   errors using the visualization style specified by the view 
            %   input. 
            %   'BarGraph'    - Displays mean error per image as a bar graph.
            %
            %   'ScatterPlot' - Displays the error for each point as a scatter plot.
            %
            %   ax = showReprojectionErrors(...) returns the plot's axes handle.
            %
            %   showReprojectionErrors(...,Name,Value) specifies additional 
            %   name-value pair arguments described below:
            %
            %   'HighlightIndex'  - Indices of selected images, specified
            %                       as a vector of integers. For the
            %                       'BarGraph' view, bars corresponding to
            %                       the selected images are highlighted.
            %                       For 'ScatterPlot' view, points
            %                       corresponding to the selected images
            %                       are displayed with circle markers.
            %
            %                       Default: []
            %
            %   'Parent'          - Axes for displaying plot.
            %
            %   Class Support
            %   -------------
            %   fisheyeParams must be a fisheyeParameters object.
            %
            
            if isempty(this.ReprojectionErrors)
                error(message('vision:calibrate:cannotShowEmptyErrors'));
            end
            hAxes = newplot(hAxes);
            
            if strcmpi(view, 'bargraph')
                % compute mean errors per image
                [meanError, meanErrors] = computeMeanError(this);
                vision.internal.calibration.plotMeanErrorPerImage(...
                    hAxes, meanError, meanErrors, highlightIndex);
            else % 'scatterPlot'
                errors = this.ReprojectionErrors;                                  
                vision.internal.calibration.plotAllErrors(...
                    hAxes, errors, highlightIndex);
            end
        end        
    end
    

    
    methods (Hidden=true, Access=public)
        function errors = refine(this, imagePoints, shouldComputeErrors)
            % refine Estimate fisheye camera parameters.
            %
            % params = refine(this, imagePoints) numerically refines an
            % initial estimates of fisheye camera parameter values.
            %
            % this is a fisheyeParameters object containing the initial
            % estimates of the parameter values.
            %
            % imagePoints is an M x 2 x P array containing the [x y] 
            % coordinates of the points detected in images, in pixels. M is
            % the number of points in the pattern and P is the number of images.

            x0 = serialize(this);            
            numImages = size(this.RotationVectors, 1);
            xdata = repmat(this.WorldPoints, [numImages, 1]);            
            ydata = arrangeImagePointsIntoMatrix(imagePoints);    
               
            options = optimset('Display', 'off', ...
                               'TolX', 1e-5, ...
                               'TolFun', 1e-4, ...
                               'MaxIter', 100);
            
            worldPointsXYZ = [this.WorldPoints, zeros(size(this.WorldPoints, 1), 1)];
                        
            if shouldComputeErrors
                [x, ~, residual, ~, ~, ~, jacobian] = ...
                    lscftsh(@reprojectWrapper, x0, xdata, ydata, [], [], options);

                % Remove the column corresponding to the constant variable
                jacobian(:, 7) = [];
                standardError = ...
                    vision.internal.calibration.computeStandardError(jacobian, ...
                    residual, false);

                % Be careful with memory
                clear jacobian;
                
                standardError = [standardError(1:6); 0; standardError(7:end)];
                errorsStruct = unpackSerializedParams(this, standardError);
                if ~this.EstimateAlignment
                    errorsStruct.stretchMatrix = [0 0 0];
                end
                errors = fisheyeCalibrationErrors(errorsStruct);
            else
                x = lscftsh(@reprojectWrapper, x0, xdata, ydata, [], [], options);
                errors = [];
            end
            
            deserialize(this, x);
            computeReprojectionErrors(this, imagePoints); 
                                                
            %----------------------------------------------------------------------
            function reprojectedPoints = reprojectWrapper(paramsVector, ~)
                paramStruct = unpackSerializedParams(this, paramsVector);
                % Nx2xP
                reprojectedPoints = zeros([size(this.WorldPoints), this.NumPatterns]);
                
                % add the constant zero a1, so the full set is [a0 a1 a2 a3 a4]
                coeffs = [paramStruct.mappingCoefficients(1), ...
                          zeros(1, 'like', paramStruct.mappingCoefficients), ...
                          paramStruct.mappingCoefficients(2:end)];
                      
                for i = 1:this.NumPatterns
                    tvec = paramStruct.translationVectors(i, :);
                    rvec = paramStruct.rotationVectors(i, :);
                    R = vision.internal.calibration.rodriguesVectorToMatrix(rvec)';
                    points = worldPointsXYZ * R;
                    points(:, 1) = points(:, 1) + tvec(1);
                    points(:, 2) = points(:, 2) + tvec(2);
                    points(:, 3) = points(:, 3) + tvec(3);
                    
                    reprojectedPoints(:,:,i) = vision.internal.calibration.computeImageProjection(...
                            points, coeffs, paramStruct.stretchMatrix, paramStruct.distortionCenter);
                end
                reprojectedPoints = arrangeImagePointsIntoMatrix(reprojectedPoints);
            end
            
            %----------------------------------------------------------------------
            function pointMatrix = arrangeImagePointsIntoMatrix(imagePoints)
                pointMatrix = reshape(permute(imagePoints, [2, 1, 3]), ...
                    [2, size(imagePoints, 1) * size(imagePoints, 3)])';
            end
        end
        
        %------------------------------------------------------------------
        % Convert the parameter object into a flat parameter vector
        % to be used in optimization.
        %------------------------------------------------------------------
        function x = serialize(this)
            if this.EstimateAlignment
                x = [1; 1; this.Intrinsics.StretchMatrix(1:3)'];
            else
                x = [1; 1];
            end
            % Adding a constant 'dummy' variable a1 may speed up the
            % interior point algorithm here.
            x = [x; ones(length(this.Intrinsics.MappingCoefficients)+1,1)];
            for i = 1:size(this.RotationVectors,1)
                x = [x; this.RotationVectors(i, :)'];
                x = [x; this.TranslationVectors(i, :)'];
            end
        end
        
        
        %------------------------------------------------------------------
        % Initialize the parameter object from a flat parameter vector
        %------------------------------------------------------------------
        function deserialize(this, x)
            paramStruct = unpackSerializedParams(this, x);
            this.Intrinsics = fisheyeIntrinsics(...
                paramStruct.mappingCoefficients, ...
                this.Intrinsics.ImageSize, ...
                paramStruct.distortionCenter, ...
                paramStruct.stretchMatrix);            
            this.RotationVectors = paramStruct.rotationVectors;
            this.TranslationVectors = paramStruct.translationVectors;
        end
        
    end
    
    methods(Hidden)
        function paramStruct = unpackSerializedParams(this, x)

            paramStruct.distortionCenter = this.Intrinsics.DistortionCenter(:) .* x(1:2);
            if this.EstimateAlignment
                numAlignmentEntries = 5;
                paramStruct.stretchMatrix = [x(3) x(5); ...
                                             x(4)  1];
            else
                numAlignmentEntries = 2;
                paramStruct.stretchMatrix = this.Intrinsics.StretchMatrix;
            end            
            x = x(numAlignmentEntries+1:end);
            
            % Adding a constant 'dummy' variable a1 may speed up the
            % interior point algorithm here.
            numCoefficients = length(this.Intrinsics.MappingCoefficients)+1;
            paramStruct.mappingCoefficients = ...
                ([this.Intrinsics.MappingCoefficients(1);...
                  0; ...
                  this.Intrinsics.MappingCoefficients(2:4)'].*x(1:numCoefficients))';
            paramStruct.mappingCoefficients(2) = [];
            
            x = x(numCoefficients+1:end);
            
            if isempty(x)
                paramStruct.rotationVectors = [];
                paramStruct.translationVectors = [];
            else
                sizeVecs = length(x) / 2;
                numImages = sizeVecs / 3;
                rvecs = zeros(numImages, 3);
                tvecs = rvecs;
                for i = 1:numImages
                    a = x(i*6-5 : i*6);
                    rvecs(i, :) = a(1:3);
                    tvecs(i, :) = a(4:6);
                end
                paramStruct.rotationVectors = rvecs;
                paramStruct.translationVectors = tvecs;
            end
        end
        
        
    end
    
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of the class changes
    methods (Hidden)
       
        function that = saveobj(this)
            that.Intrinsics           = this.Intrinsics;
            that.WorldPoints          = this.WorldPoints;
            that.WorldUnits           = this.WorldUnits;  
            that.RotationVectors      = this.RotationVectors;
            that.TranslationVectors   = this.TranslationVectors;
            that.ReprojectionErrors   = this.ReprojectionErrors;
            that.EstimateAlignment    = this.EstimateAlignment;
            that.Version              = this.Version;
        end
        
    end
    
    
    %----------------------------------------------------------------------    
    methods (Static, Hidden)
        
        function this = loadobj(that)                        
            if isempty(that.ReprojectionErrors)
                reprojErrors = zeros(0, 2, 0);
            else
                reprojErrors = that.ReprojectionErrors;
            end
            
            this = fisheyeParameters(that.Intrinsics, ...
                'WorldPoints',       that.WorldPoints,...
                'WorldUnits',        that.WorldUnits,...
                'RotationVectors',   that.RotationVectors,...
                'TranslationVectors',that.TranslationVectors,...
                'ReprojectionErrors',reprojErrors, ...
                'EstimateAlignment', that.EstimateAlignment);
        end
        
    end
    

end