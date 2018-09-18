classdef cameraCalibrationErrors
% cameraCalibrationErrors Object for storing standard errors of estimated camera parameters    
%
%   cameraCalibrationErrors methods:
%   displayErrors - Print standard errors of camera parameters estimates
%
%   cameraCalibrationErrors properties:
%   IntrinsicsErrors - Standard errors of estimated camera intrinsics and 
%                      distortion coefficients
%   ExtrinsicsErrors - Standard errors of estimated camera extrinsics
%
% Example - Display single camera calibration errors
% --------------------------------------------
% % Create a set of calibration images.
% images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
%    'calibration', 'mono'));
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
% [params, ~, errors] = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
% % Display the standard errors.
% displayErrors(errors, params);
%
% See also cameraParameters, cameraCalibrator, estimateCameraParameters,
%   intrinsicsEstimationErrors, extrinsicsEstimationErrors

%   Copyright 2013 MathWorks, Inc.

% References:
% [1] Draper, Norman R., and Smith, Harry. Applied Regression Analysis, 
% Third Edition. New York: Wiley-Interscience, 1998.
%
% [2] Seber, G.A.F., and Wild, C.J. Nonlinear Regression, 
% New York: Wiley-Interscience, 2003.
  
    properties(GetAccess=public, SetAccess=private)
        % IntrinsicsErrors An intrinsicsEstimationErrors object 
        %   containing the standard error of the estimated camera intrinsics
        %   and distortion coefficients.
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
        function this = cameraCalibrationErrors(errors)
            this.IntrinsicsErrors = intrinsicsEstimationErrors(errors);
            this.ExtrinsicsErrors = extrinsicsEstimationErrors(errors);
        end
        
        %------------------------------------------------------------------
        function displayErrors(this, cameraParams)
            % displayErrors Print standard errors of camera parameters estimates
            %
            %  displayErrors(estimationErrors, cameraParams) prints the values
            %  of camera parameters together with the corresponding standard 
            %  errors to the screen. estimationErrors is a cameraCalibrationErrors 
            %  object. cameraParams is a cameraParameters object.
            
            checkDisplayErrorsInputs(this, cameraParams);
            
            displayMainHeading();
            
            % Intrinsics
            displayIntrinsicsHeading();           
            displayErrors(this.IntrinsicsErrors, cameraParams);
            
            % Extrinsics
            displayExtrinsicsHeading();            
            displayErrors(this.ExtrinsicsErrors, cameraParams);
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function checkDisplayErrorsInputs(this, cameraParams)
            
            checkCameraParamsDataType(this, cameraParams);
            checkSkew(this, cameraParams);
            checkRadialDistortion(this, cameraParams);
            checkTangentialDistortion(this, cameraParams);                                                
        end
        
        %------------------------------------------------------------------
        function checkCameraParamsDataType(~, cameraParams)
            % Check data type
            validateattributes(cameraParams, {'cameraParameters'}, {}, ...
                'displayErrors', 'cameraParams');
        end
        
        %------------------------------------------------------------------
        function checkSkew(this, cameraParams)
            if ~cameraParams.EstimateSkew && this.IntrinsicsErrors.SkewError ~= 0
                error(message(...
                    'vision:cameraCalibrationErrors:errorsParametersMismatch'));
            end
        end
        
        %------------------------------------------------------------------
        function checkRadialDistortion(this, cameraParams)
            % Check that the number of radial distortion coefficients is the
            % same as the number of radial distortion errors
            if cameraParams.NumRadialDistortionCoefficients ~= ...
                    numel(this.IntrinsicsErrors.RadialDistortionError)
                
                error(message(...
                    'vision:cameraCalibrationErrors:errorsParametersMismatch'));
            end
        end
        
        %------------------------------------------------------------------
        function checkTangentialDistortion(this, cameraParams)
            % Check that if tangential distortion is not estimated,
            % tangential distortion errors are set to 0
            if ~cameraParams.EstimateTangentialDistortion && ...
                    any(this.IntrinsicsErrors.TangentialDistortionError ~= 0)
                 error(message(...
                    'vision:cameraCalibrationErrors:errorsParametersMismatch'));
            end
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
            that.skew = this.IntrinsicsErrors.SkewError;
            that.focalLength = this.IntrinsicsErrors.FocalLengthError;
            that.principalPoint = this.IntrinsicsErrors.PrincipalPointError;
            that.radialDistortion = this.IntrinsicsErrors.RadialDistortionError;
            that.tangentialDistortion = this.IntrinsicsErrors.TangentialDistortionError;
           
            % extrinsics
            that.rotationVectors = this.ExtrinsicsErrors.RotationVectorsError;
            that.translationVectors = this.ExtrinsicsErrors.TranslationVectorsError;
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        
        function this = loadobj(that)            
            this = cameraCalibrationErrors(that);
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
