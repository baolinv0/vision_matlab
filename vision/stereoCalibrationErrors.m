classdef stereoCalibrationErrors
% stereoCalibrationErrors Object for storing standard errors of estimated stereo parameters    
%
%   stereoCalibrationErrors methods:
%   displayErrors - Print standard errors of camera parameters estimates
%
%   stereoCalibrationErrors properties:
%   Camera1IntrinsicsErrors   - standard errors of intrinsic parameters
%                               estimate of camera 1
%   Camera1ExtrinsicsErrors   - standard errors of extrinsic parameters
%                               estimate of camera 1
%   Camera2IntrinsicsErrors   - standard errors of intrinsic parameters
%                               estimate of camera 2
%   RotationOfCamera2Error    - standard errors of rotation vector of camera
%                               2 relative to camera 1
%   TranslationOfCamera2Error - standard errors of translation of camera 2 
%                               relative to camera 1
%
% Example - Display stereo camera calibration errors
% --------------------------------------------------
%
% % Specify calibration images.
% imageDir = fullfile(toolboxdir('vision'), 'visiondata', ...
%     'calibration', 'stereo');
% leftImages = imageDatastore(fullfile(imageDir, 'left'));
% rightImages = imageDatastore(fullfile(imageDir, 'right'));
%
% % Detect the checkerboards.
% [imagePoints, boardSize] = detectCheckerboardPoints(...
%     leftImages.Files, rightImages.Files);
%
% % Specify world coordinates of checkerboard keypoints.
% squareSize = 108; % in millimeters
% worldPoints = generateCheckerboardPoints(boardSize, squareSize);
%
% % Calibrate the stereo camera system. Here both cameras have the same
% % resolution.
% I = readimage(leftImages,1); 
% imageSize = [size(I, 1), size(I, 2)];
% [params, ~, errors] = estimateCameraParameters(imagePoints, worldPoints, ...
%                                     'ImageSize', imageSize);
%
% % Display standard errors.
% displayErrors(errors, params);
%
% See also stereoParameters, cameraParameters, estimateCameraParameters
%   intrinsicsEstimationErrors, extrinsicsEstimationErrors

%   Copyright 2014 MathWorks, Inc.

% References:
% [1] Draper, Norman R., and Smith, Harry. Applied Regression Analysis, 
% Third Edition. New York: Wiley-Interscience, 1998.
%
% [2] Seber, G.A.F., and Wild, C.J. Nonlinear Regression, 
% New York: Wiley-Interscience, 2003.

    properties(GetAccess=public, SetAccess=private)
        % Camera1IntrinsicsErrors An intrinsicEstimationErrors object
        %   containing the standard errors of the estimated camera 1 intrinsics
        %   and distortion coefficients.
        Camera1IntrinsicsErrors;
        
        % Camera1ExtrinsicsErrors An extrinsicsEstimationErrors object
        %   containing the standard errors of the estimated camera 1 extrinsics. 
        Camera1ExtrinsicsErrors;
        
        % Camera2IntrinsicsErrors An intrinsicEstimationErrors object
        %   containing the standard errors of the estimated camera 2 intrinsics
        %   and distortion coefficients.
        Camera2IntrinsicsErrors;
                
        % RotationOfCamera2Error a 3-element vector containing the standard
        %   error of the estimated rotation vector of camera 2 relative to
        %   camera 1.
        RotationOfCamera2Error;
        
        % TranslationOfCamera2Error a 3-element vector containing the
        %   standard error of the estimated translation vector of camera 2
        %   relative to camera 1.
        TranslationOfCamera2Error;
        
    end
    
    properties (Access=private, Hidden)
        Version = ver('vision');
    end
    
    methods
        function this = stereoCalibrationErrors(errors)
            % stereo camera geometry
            this.RotationOfCamera2Error = errors.r;
            this.TranslationOfCamera2Error = errors.t;
            
            % camera 1
            this.Camera1IntrinsicsErrors = ...
                intrinsicsEstimationErrors(errors.camera1);
            this.Camera1ExtrinsicsErrors = ...
                extrinsicsEstimationErrors(errors.camera1);
            
            % camera 2
            this.Camera2IntrinsicsErrors = ...
                intrinsicsEstimationErrors(errors.camera2);
        end
        
        %------------------------------------------------------------------
        function displayErrors(this, stereoParams)
            % displayErrors Print standard errors of stereo parameters estimates
            %
            %  displayErrors(estimationErrors, stereoParams) prints the values
            %  of stereo parameters together with the corresponding standard
            %  errors to the screen. estimationErrors is a stereoCalibrationErrors
            %  object. stereoParams is a stereoParameters object.
            
            checkDisplayErrorsInputs(this, stereoParams);
            
            displayMainHeading();
            
            displayIntrinsics1Heading();
            displayErrors(this.Camera1IntrinsicsErrors, stereoParams.CameraParameters1);
            
            displayExtrinsics1Heading();
            displayErrors(this.Camera1ExtrinsicsErrors, stereoParams.CameraParameters1);
            
            displayIntrinsics2Heading();            
            displayErrors(this.Camera2IntrinsicsErrors, stereoParams.CameraParameters2);
            
            displayInterCameraGeometryHeading();
            displayInterCameraGeometry(this, stereoParams);
        end
           
    end
    
    methods(Access=private)
         %------------------------------------------------------------------
        function checkDisplayErrorsInputs(this, stereoParams)
            
            checkCameraParamsDataType(this, stereoParams);
            checkSkew(this, stereoParams);
            checkRadialDistortion(this, stereoParams);
            checkTangentialDistortion(this, stereoParams);                                                
        end
        
        %------------------------------------------------------------------
        function checkCameraParamsDataType(~, stereoParams)
            % Check data type
            validateattributes(stereoParams, {'stereoParameters'}, {}, ...
                'displayErrors', 'stereoParams');
        end
        
        %------------------------------------------------------------------
        function checkSkew(this, stereoParams)
            if ~stereoParams.CameraParameters1.EstimateSkew && ...
                    this.Camera1IntrinsicsErrors.SkewError ~= 0
                error(message(...
                    'vision:cameraCalibrationErrors:errorsStereoParametersMismatch'));
            end
        end
        
        %------------------------------------------------------------------
        function checkRadialDistortion(this, stereoParams)
            % Check that the number of radial distortion coefficients is the
            % same as the number of radial distortion errors
            if stereoParams.CameraParameters1.NumRadialDistortionCoefficients ~= ...
                    numel(this.Camera1IntrinsicsErrors.RadialDistortionError)
                
                error(message(...
                    'vision:cameraCalibrationErrors:errorsStereoParametersMismatch'));
            end
        end
        
        %------------------------------------------------------------------
        function checkTangentialDistortion(this, stereoParams)
            % Check that if tangential distortion is not estimated,
            % tangential distortion errors are set to 0
            if ~stereoParams.CameraParameters1.EstimateTangentialDistortion && ...
                    any(this.Camera1IntrinsicsErrors.TangentialDistortionError ~= 0)
                 error(message(...
                    'vision:cameraCalibrationErrors:errorsStereoParametersMismatch'));
            end
        end
        
        %------------------------------------------------------------------
        function displayInterCameraGeometry(this, stereoParams)
                        frameFormat = '%-30s[%23s%25s%25s]\n';
            entryFormat = '%8.4f +/- %-8.4f';
            rotVector = rotationMatrixToVector(stereoParams.RotationOfCamera2);
            rotationVectorsString{1} = sprintf(entryFormat,...
                rotVector(1), this.RotationOfCamera2Error(1));
            
            rotationVectorsString{2} = sprintf(entryFormat,...
                rotVector(2), this.RotationOfCamera2Error(2));
            
            rotationVectorsString{3} = sprintf(entryFormat,...
                rotVector(3), this.RotationOfCamera2Error(3));
            
            fprintf(frameFormat, ...
                vision.getMessage('vision:cameraCalibrationErrors:roationOfCamera2'), ...
                rotationVectorsString{1}, ...
                rotationVectorsString{2}, ...
                rotationVectorsString{3});
            
            translationVectorsString{1} = sprintf(entryFormat,...
                stereoParams.TranslationOfCamera2(1), ...
                this.TranslationOfCamera2Error(1));
            
            translationVectorsString{2} = sprintf(entryFormat,...
                stereoParams.TranslationOfCamera2(2), ...
                this.TranslationOfCamera2Error(2));
            
            translationVectorsString{3} = sprintf(entryFormat,...
                stereoParams.TranslationOfCamera2(3), ...
                this.TranslationOfCamera2Error(3));
                        
            fprintf(frameFormat, ...
                getString(message(...
                    'vision:cameraCalibrationErrors:translationOfCamera2', ...
                    stereoParams.WorldUnits)), ...
                translationVectorsString{1}, ...
                translationVectorsString{2}, ...
                translationVectorsString{3});
        end
    end
    
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of this class changes
    methods (Hidden)
        
        function that = saveobj(this)
           % version
            that.version = this.Version;
            
            % camera 1 intrinsics
            that.camera1.skew                 = this.Camera1IntrinsicsErrors.SkewError;
            that.camera1.focalLength          = this.Camera1IntrinsicsErrors.FocalLengthError;
            that.camera1.principalPoint       = this.Camera1IntrinsicsErrors.PrincipalPointError;
            that.camera1.radialDistortion     = this.Camera1IntrinsicsErrors.RadialDistortionError;
            that.camera1.tangentialDistortion = this.Camera1IntrinsicsErrors.TangentialDistortionError;
           
            % camera 1 extrinsics
            that.camera1.rotationVectors    = this.Camera1ExtrinsicsErrors.RotationVectorsError;
            that.camera1.translationVectors = this.Camera1ExtrinsicsErrors.TranslationVectorsError; 
            
            % camera 2 intrinsics
            that.camera2.skew                 = this.Camera2IntrinsicsErrors.SkewError;
            that.camera2.focalLength          = this.Camera2IntrinsicsErrors.FocalLengthError;
            that.camera2.principalPoint       = this.Camera2IntrinsicsErrors.PrincipalPointError;
            that.camera2.radialDistortion     = this.Camera2IntrinsicsErrors.RadialDistortionError;
            that.camera2.tangentialDistortion = this.Camera2IntrinsicsErrors.TangentialDistortionError;
            
            % inter-camera geometry
            that.r = this.RotationOfCamera2Error;
            that.t = this.TranslationOfCamera2Error;
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
        
        function this = loadobj(that)                       
            if isa(that, 'stereoCalibrationErrors')
                this = that;
            else            
                this = stereoCalibrationErrors(that);
                this.Version = that.version;            
            end
        end
        
    end
end

%--------------------------------------------------------------------------
function displayMainHeading()
headingFormat = '\n\t\t\t%s\n\t\t\t%s\n';
mainHeading = vision.getMessage(...
    'vision:cameraCalibrationErrors:stereoCameraHeading');
headingUnderline = getUnderlineString(mainHeading);
fprintf(headingFormat, mainHeading, headingUnderline);
end

%--------------------------------------------------------------------------
function displayIntrinsics1Heading()
heading = vision.getMessage('vision:cameraCalibrationErrors:intrinsics1Heading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function displayExtrinsics1Heading()
heading = vision.getMessage('vision:cameraCalibrationErrors:extrinsics1Heading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function displayIntrinsics2Heading()
heading = vision.getMessage('vision:cameraCalibrationErrors:intrinsics2Heading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function displayInterCameraGeometryHeading()
heading = vision.getMessage('vision:cameraCalibrationErrors:interCameraGeometryHeading');
fprintf('\n%s\n%s\n', heading, getUnderlineString(heading));
end

%--------------------------------------------------------------------------
function underline = getUnderlineString(header)
underline = repmat('-', [1, numel(header)]);
end
