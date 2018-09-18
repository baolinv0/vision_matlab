classdef fisheyeIntrinsicsEstimationErrors
% fisheyeIntrinsicsEstimationErrors Object for storing standard errors of
%   estimated fisheye camera intrinsics
%
%   intrinsicsEstimationErrors properties:
%   MappingCoefficientsError - standard error of mapping coefficients estimate
%   DistortionCenterError    - standard error of distortion center estimate
%   StretchMatrixError       - standard error of stretch matrix estimate
%
%   See also cameraCalibrationErrors, stereoCalibrationErrors

%   Copyright 2017 MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        % MappingCoefficientsError A 4-element vector containing the
        %   standard error of the estimated mapping coefficients.
        MappingCoefficientsError;
                
        % DistortionCenterError A 2-element vector containing the standard
        %   error of the center of distortion.
        DistortionCenterError;
        
        % StretchMatrixError A 3-element vector containing
        %   the standard error of the estimated stretch matrix. Note, the
        %   last element in the 2-by-2 stretch matrix is a constant.
        StretchMatrixError;        
    end
    
    methods
        function this = fisheyeIntrinsicsEstimationErrors(errors)
            this.MappingCoefficientsError = errors.mappingCoefficients(:)';
            this.DistortionCenterError    = errors.distortionCenter(:)';
            this.StretchMatrixError       = errors.stretchMatrix(1:3);
        end
        
        %------------------------------------------------------------------
        function displayErrors(this, fisheyeParams)
            % Display standard error of intrinsics
            frameFormat2 = '%-25s[%23s%25s]\n';
            frameFormat3 = '%-25s[%23s%25s%25s]\n'; 
            frameFormat4 = '%-25s[%23s%25s%25s%25s]\n';
            entryFormat = '%8.4f +/- %-8.4f';

            stretchMatrixString = cell(1, 3);
            for n = 1:3
                stretchMatrixString{n} = sprintf(entryFormat,...
                    fisheyeParams.Intrinsics.StretchMatrix(n), ...
                    this.StretchMatrixError(n));
            end

            distortionCenterString = cell(1, 2);
            for n = 1:2
                distortionCenterString{n} = sprintf(entryFormat,...
                    fisheyeParams.Intrinsics.DistortionCenter(n), ...
                    this.DistortionCenterError(n));
            end
            
            mappingCoefficientsString = cell(1, 4);
            for n = 1:4
                mappingCoefficientsString{n} = sprintf(entryFormat,...
                    fisheyeParams.Intrinsics.MappingCoefficients(n), ...
                    this.MappingCoefficientsError(n));
            end
            
            fprintf(frameFormat4, ...
                    vision.getMessage('vision:cameraCalibrationErrors:mappingCoefficients'),...
                    mappingCoefficientsString{1}, ...
                    mappingCoefficientsString{2}, ...
                    mappingCoefficientsString{3}, ...
                    mappingCoefficientsString{4});                

            fprintf(frameFormat2,...
                vision.getMessage('vision:cameraCalibrationErrors:distortionCenter'),...
                distortionCenterString{1}, ...
                distortionCenterString{2});
            
            fprintf(frameFormat3,...
                vision.getMessage('vision:cameraCalibrationErrors:stretchMatrix'),...
                stretchMatrixString{1}, ...
                stretchMatrixString{2}, ...
                stretchMatrixString{3});
        end
    end
end