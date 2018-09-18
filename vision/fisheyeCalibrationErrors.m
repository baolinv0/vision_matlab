classdef fisheyeCalibrationErrors
% fisheyeCalibrationErrors Object for storing standard errors of estimated
% fisheye camera parameters
%
%   fisheyeCalibrationErrors methods:
%   displayErrors - Print standard errors of camera parameters estimates
%
%   fisheyeCalibrationErrors properties:
%   IntrinsicsErrors - Standard errors of estimated camera intrinsics
%   ExtrinsicsErrors - Standard errors of estimated camera extrinsics
%
% Example - Display fisheye camera calibration errors
% ---------------------------------------------------
% % Gather a set of calibration images.
% images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%    'calibration', 'gopro'));
%  
% % Detect calibration pattern.
% [imagePoints, boardSize] = detectCheckerboardPoints(images.Files);
%  
% % Generate world coordinates of the corners of the squares.
% squareSize = 29; % in millimeters
% worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%  
% % Calibrate the camera.
% I = readimage(images,1); 
% imageSize = [size(I, 1), size(I, 2)];
% [params, ~, errors] = estimateFisheyeParameters(imagePoints, ...
%                                    worldPoints, imageSize);
%
% % Display the standard errors.
% displayErrors(errors, params);
%
% See also fisheyeParameters, estimateFisheyeParameters,
%   fisheyeIntrinsicsEstimationErrors, extrinsicsEstimationErrors

%   Copyright 2017 MathWorks, Inc.

% References:
% [1] Draper, Norman R., and Smith, Harry. Applied Regression Analysis, 
% Third Edition. New York: Wiley-Interscience, 1998.
%
% [2] Seber, G.A.F., and Wild, C.J. Nonlinear Regression, 
% New York: Wiley-Interscience, 2003.
  
    properties(GetAccess=public, SetAccess=private)
        % IntrinsicsErrors A fisheyeIntrinsicsEstimationErrors object 
        %   containing the standard error of the estimated camera
        %   intrinsics.
        IntrinsicsErrors;
        
        % ExtrinsicsErrors An extrinsicsEstimationErrors object 
        %   containing the standard error for the estimated camera rotations
        %   and translations relative to the calibration pattern.
        ExtrinsicsErrors;
    end
    
    properties (Access=private, Hidden)
        Version = ver('vision');
    end
    
    methods
        function this = fisheyeCalibrationErrors(errors)
            this.IntrinsicsErrors = fisheyeIntrinsicsEstimationErrors(errors);
            this.ExtrinsicsErrors = extrinsicsEstimationErrors(errors);
        end
        
        %------------------------------------------------------------------
        function displayErrors(this, fisheyeParams)
            % displayErrors Print standard errors of camera parameters estimates
            %
            %  displayErrors(estimationErrors, fisheyeParams) prints the values
            %  of camera parameters together with the corresponding standard 
            %  errors to the screen. estimationErrors is a fisheyeCalibrationErrors 
            %  object. fisheyeParams is a fisheyeParameters object.
            
            checkDisplayErrorsInputs(this, fisheyeParams);
            
            displayMainHeading();
            
            % Intrinsics
            displayIntrinsicsHeading();           
            displayErrors(this.IntrinsicsErrors, fisheyeParams);
            
            % Extrinsics
            displayExtrinsicsHeading();            
            displayErrors(this.ExtrinsicsErrors, fisheyeParams);
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function checkDisplayErrorsInputs(~, fisheyeParams)
            % Check data type
            validateattributes(fisheyeParams, {'fisheyeParameters'}, {}, ...
                'displayErrors', 'fisheyeParams');
        end
    end
    
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of this class changes
    methods (Hidden)
        
        function that = saveobj(this)
            % version
            that.version = this.Version;
            
            % intrinsics            
            that.stretchMatrix = [this.IntrinsicsErrors.StretchMatrixError, 1];
            that.distortionCenter = this.IntrinsicsErrors.DistortionCenterError;
            that.mappingCoefficients = this.IntrinsicsErrors.MappingCoefficientsError;
           
            % extrinsics
            that.rotationVectors = this.ExtrinsicsErrors.RotationVectorsError;
            that.translationVectors = this.ExtrinsicsErrors.TranslationVectorsError;
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        
        function this = loadobj(that)            
            this = fisheyeCalibrationErrors(that);
            this.Version = that.version;            
        end
        
    end
end

%--------------------------------------------------------------------------
function displayMainHeading()
headingFormat = '\n\t\t\t%s\n\t\t\t%s\n';
mainHeading = vision.getMessage(...
    'vision:cameraCalibrationErrors:singleCameraHeading');
headingUnderline = getUnderlineString(mainHeading);
fprintf(headingFormat, mainHeading, headingUnderline);
end

%--------------------------------------------------------------------------
function displayIntrinsicsHeading()
heading = vision.getMessage('vision:cameraCalibrationErrors:intrinsicsHeading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function displayExtrinsicsHeading()
heading = vision.getMessage('vision:cameraCalibrationErrors:extrinsicsHeading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function underline = getUnderlineString(header)
underline = repmat('-', [1, numel(header)]);
end
