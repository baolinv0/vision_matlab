%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>   
classdef FisheyeParametersImpl < vision.internal.EnforceScalarHandle &  matlab.mixin.Copyable
    
    properties (GetAccess=public, SetAccess=public)   
        % Intrinsics A fisheyeIntrinsics object for storing intrinsic camera parameters.
        %
        Intrinsics;
        
        % WorldPoints An M-by-2 array of [x,y] world coordinates of
        %   keypoints on the calibration pattern, where M is the number of
        %   keypoints in the pattern.  WorldPoints must be non-empty for
        %   showExtrinsics to work.
        %
        %   Default: []
        WorldPoints;
        
        % WorldUnits A character vector describing the units, in which the
        %   WorldPoints are specified.
        %
        %   Default: 'mm'
        WorldUnits;
                                
        % TranslationVectors An M-by-3 matrix containing M translation vectors.
        %   Each vector describes the translation of the camera's sensor plane
        %   relative to the corresponding calibration pattern in world units.
        %
        %   Default: []
        TranslationVectors;
        
        % RotationVectors An M-by-3 matrix containing M rotation vectors
        %   Each vector describes the 3-D rotation of the camera's sensor
        %   plane relative to the corresponding calibration pattern. The
        %   vector specifies the 3-D axis about which the camera is rotated,
        %   and its magnitude is the rotation angle in radians. The
        %   corresponding 3-D rotation matrices are given by the
        %   RotationMatrices property.
        %
        %   Default: []
        RotationVectors;
        
        % ReprojectionErrors An M-by-2-by-P array of [x,y] pairs representing
        %   the translation in x and y between the reprojected pattern
        %   keypoints and the detected pattern keypoints. These values
        %   indicate the accuracy of the estimated camera parameters. P is
        %   the number of pattern images used to estimate camera
        %   parameters, and M is the number of keypoints in each image.
        %
        %   Default: []
        ReprojectionErrors;
        
        % EstimateAlignment A logical scalar that specifies whether the
        %   axes alignment between the sensor plane and the image plane 
        %   should be estimated.
        %
        %   Default: false
        EstimateAlignment;
    end

    
    properties(Dependent)
        % NumPatterns The number of calibration patterns which were used to
        %   estimate the camera extrinsics. This is also the number of
        %   translation and rotation vectors.
        NumPatterns;
                                
        % MeanReprojectionError Average Euclidean distance between
        %   reprojected points and detected points.
        MeanReprojectionError;
        
        % ReprojectedPoints An M-by-2-by-NumPatterns array of [x,y] coordinates of
        %   world points re-projected onto calibration images. M is the
        %   number of points per image. NumPatterns is the number of
        %   patterns.
        ReprojectedPoints;
        
        % RotationMatrices A 3-by-3-by-P array containing P rotation matrices.
        %   Each 3-by-3 matrix represents the 3-D rotation of the camera's
        %   sensor plane relative to the corresponding calibration pattern.
        RotationMatrices;        
    end
        
    properties (Access=protected, Hidden)
        Version = ver('vision');
    end
    
    
    methods
        %----------------------------------------------------------------------
        function this = FisheyeParametersImpl(varargin)
            parser = inputParser;
            parser.addRequired('intrinsics', ...
                @(x)validateattributes(x, {'fisheyeIntrinsics'},{}));
            parser.addParameter('RotationVectors', zeros(0, 3), ...
                @vision.internal.calibration.FisheyeParametersImpl.checkRotationVectors);
            parser.addParameter('TranslationVectors', zeros(0, 3), ...
                @vision.internal.calibration.FisheyeParametersImpl.checkTranslationVectors);
            parser.addParameter('WorldPoints', zeros(0, 2), ...
                @vision.internal.calibration.FisheyeParametersImpl.checkWorldPoints);
            parser.addParameter('WorldUnits', 'mm',...
                @vision.internal.calibration.FisheyeParametersImpl.checkWorldUnits);
            parser.addParameter('ReprojectionErrors', zeros(0, 2), ...
                @vision.internal.calibration.FisheyeParametersImpl.checkReprojectionErrors);
            parser.addParameter('EstimateAlignment', false, ...
                @vision.internal.calibration.FisheyeParametersImpl.checkEstimateAlignment);
            parser.addParameter('Version', ver('vision'));

            parser.parse(varargin{:});
            paramStruct = parser.Results;
            this.Intrinsics = paramStruct.intrinsics;
            this.WorldPoints = paramStruct.WorldPoints;
            this.WorldUnits  = paramStruct.WorldUnits;
            this.RotationVectors = paramStruct.RotationVectors;
            this.TranslationVectors = paramStruct.TranslationVectors;
            if isempty(paramStruct.ReprojectionErrors)
                this.ReprojectionErrors = zeros(0, 2);
            else
                this.ReprojectionErrors = paramStruct.ReprojectionErrors;
            end
            this.EstimateAlignment = paramStruct.EstimateAlignment;
            
            coder.internal.errorIf((isempty(this.RotationVectors) && ...
                    ~isempty(this.TranslationVectors)) || ...
                    (isempty(this.TranslationVectors) && ...
                    ~isempty(this.RotationVectors)),... 
                'vision:calibrate:rotationAndTranslationVectorsMustBeSetTogether');
            
            coder.internal.errorIf(...
                any(size(this.RotationVectors) ~= size(this.TranslationVectors)),...
                'vision:calibrate:rotationAndTranslationVectorsNotSameSize');
            
            coder.internal.errorIf(~isempty(this.ReprojectionErrors) &&...
                size(this.ReprojectionErrors, 3) ~= size(this.TranslationVectors, 1),...
                'vision:calibrate:reprojectionErrorsSizeMismatch');            
        end        
    end
    
    methods
        
        %------------------------------------------------------------------
        function numPatterns = get.NumPatterns(this)
            numPatterns = size(this.RotationVectors, 1);
        end
                
        %------------------------------------------------------------------
        function meanError = get.MeanReprojectionError(this)
            meanError = computeMeanError(this);
        end
        
        %------------------------------------------------------------------
        function reprojectedPoints = get.ReprojectedPoints(this)
            reprojectedPoints = zeros([size(this.WorldPoints), this.NumPatterns]);
            for i = 1:this.NumPatterns
                reprojectedPoints(:, :, i) = ...
                    reprojectWorldPointsOntoPattern(this, i);
            end
        end
        
        %------------------------------------------------------------------
        function rotationMatrices = get.RotationMatrices(this)
            rotationMatrices = zeros(3, 3, this.NumPatterns);
            for i = 1:this.NumPatterns
                v = this.RotationVectors(i, :);
                R = vision.internal.calibration.rodriguesVectorToMatrix(v);
                rotationMatrices(:, :, i) = R';
            end
        end                
    end
    
    methods(Hidden, Access=public)
        %------------------------------------------------------------------
        % This method is different from the MeanReprojectionError property,
        % because it also computes the mean reprojection error per image.
        %------------------------------------------------------------------
        function [meanError, meanErrorsPerImage] = computeMeanError(this)
            errors = hypot(this.ReprojectionErrors(:, 1, :), ...
                this.ReprojectionErrors(:, 2, :));
            meanErrorsPerImage = squeeze(mean(errors, 1));
            meanError = mean(meanErrorsPerImage);
        end
            
    end
            
    %----------------------------------------------------------------------
    % constructor parameter validation
    %----------------------------------------------------------------------
    methods(Static, Hidden)
               
        %------------------------------------------------------------------                
        function checkRotationVectors(rotationVectors)
            if isempty(rotationVectors)
                return;
            end
            validateattributes(rotationVectors, {'double', 'single'},...
                {'2d', 'real', 'nonsparse', 'finite', 'ncols', 3},...
                'fisheyeParameters', 'RotationVectors');
        end
        
        %------------------------------------------------------------------                
        function checkTranslationVectors(translationVectors)
            if isempty(translationVectors)
                return;
            end
            validateattributes(translationVectors, {'double', 'single'},...
                {'2d', 'real', 'nonsparse', 'finite', 'ncols', 3},...
                'fisheyeParameters', 'TranslationVectors');
        end        
        
        %------------------------------------------------------------------                        
        function checkWorldPoints(worldPoints)
            if isempty(worldPoints)
                return;        
            end    
            validateattributes(worldPoints, {'double', 'single'},...
                {'2d', 'real', 'nonsparse', 'ncols', 2},...
                'fisheyeParameters', 'WorldPoints');
        end
        
        %------------------------------------------------------------------                        
        function checkWorldUnits(worldUnits)
            if isstring(worldUnits)
                validateattributes(worldUnits, {'string'}, ...
                    {'scalar'}, 'fisheyeParameters', 'WorldUnits');
            else
                validateattributes(worldUnits, {'char'}, ...
                    {'vector'}, 'fisheyeParameters', 'WorldUnits');
            end
        end
                
        %------------------------------------------------------------------                        
        function checkReprojectionErrors(reprojErrors)
            if ~isempty(reprojErrors)
                validateattributes(reprojErrors, {'double', 'single'},...
                    {'3d', 'real', 'nonsparse', 'ncols', 2},...
                    'fisheyeParameters', 'ReprojectionErrors');
            end
        end
        
        %------------------------------------------------------------------
        function checkEstimateAlignment(estimateAlignment)
            validateattributes(estimateAlignment, {'logical'}, {'scalar'},...
                'fisheyeParameters', 'EstimateAlignment');            
        end

    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        % Reproject world points using one set of extrinsics without
        % applying distortion
        %------------------------------------------------------------------
        function reprojectedPoints = ...
                reprojectWorldPointsOntoPattern(this, patternIdx)
            
            R = vision.internal.calibration.rodriguesVectorToMatrix(...
                this.RotationVectors(patternIdx, :))';
            t = this.TranslationVectors(patternIdx, :);
            
            points = this.WorldPoints * R(1:2, :);
            points = bsxfun(@plus, points, t);
                    
            coeffs = [this.Intrinsics.MappingCoefficients(1), ...
                      zeros(1, 'like', this.Intrinsics.MappingCoefficients), ...
                      this.Intrinsics.MappingCoefficients(2:end)];
            reprojectedPoints = vision.internal.calibration.computeImageProjection(...
                points, coeffs, this.Intrinsics.StretchMatrix, this.Intrinsics.DistortionCenter);
        end
    end
            
    methods (Hidden=true, Access=public)
        %------------------------------------------------------------------
        % Returns a fisheyeParameters object with updated reprojection
        % errors. 
        %------------------------------------------------------------------
        function computeReprojectionErrors(this, imagePoints)
            this.ReprojectionErrors = this.ReprojectedPoints - imagePoints;
        end
        
        %------------------------------------------------------------------
        % Returns a fisheyeParameters object with new extrinsics.
        %------------------------------------------------------------------
        function setExtrinsics(this, rvecs, tvecs)
            this.RotationVectors = rvecs;
            this.TranslationVectors = tvecs;
        end
    end
        
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of fisheyeParameters class changes
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
    
    
    %--------------------------------------------------------------------------
    
    methods (Static, Hidden)
        
        function this = loadobj(that)
            
            if isempty(that.ReprojectionErrors)
                reprojErrors = zeros(0, 2, 0);
            else
                reprojErrors = that.ReprojectionErrors;
            end
                        
            this = vision.FisheyeParametersImpl(that.Intrinsics,...
                'WorldPoints',           that.WorldPoints,...
                'WorldUnits',            that.WorldUnits,...
                'RotationVectors',       that.RotationVectors,...
                'TranslationVectors',    that.TranslationVectors,...
                'ReprojectionErrors',    reprojErrors, ...
                'EstimateAlignment',     that.EstimateAlignment);
        end
        
    end
end
