classdef extrinsicsEstimationErrors
% extrinsicsEstimationErrors Object for storing standard errors of
%   estimated camera extrinsics
%
%   extrinsicsEstimationErrors properties:
%   RotationVectorsError      - standard error of camera rotations estimate
%   TranslationVectorsError   - standard error of camera translations estimate
%
%   See also cameraCalibrationErrors, stereoCalibrationErrors

%   Copyright 2013 MathWorks, Inc.
    
    properties(GetAccess=public, SetAccess=private)
        % RotationVectorsError An M-by-3 matrix containing the standard
        %   error of the estimated rotation vectors.
        RotationVectorsError;
        
        % TranslationVectorsError An M-by-3 matrix containing the standard
        %   error of the estimated translation vectors.
        TranslationVectorsError;
    end
    
    methods
        function this = extrinsicsEstimationErrors(errors)
            this.RotationVectorsError    = errors.rotationVectors;
            this.TranslationVectorsError = errors.translationVectors;
        end
        
        %------------------------------------------------------------------
        function displayErrors(this, cameraParams)
            frameFormat = '%-25s[%23s%25s%25s]\n';
            entryFormat = '%8.4f +/- %-8.4f';
            
            fprintf('%s\n', ...
                vision.getMessage('vision:cameraCalibrationErrors:rotationVectors'));
            for i = 1:cameraParams.NumPatterns
                
                rotationVectorsFormat{1} = sprintf(entryFormat,...
                    cameraParams.RotationVectors(i,1), ...
                    this.RotationVectorsError(i,1));
                
                rotationVectorsFormat{2} = sprintf(entryFormat,...
                    cameraParams.RotationVectors(i,2), ...
                    this.RotationVectorsError(i,2));
                
                rotationVectorsFormat{3} = sprintf(entryFormat,...
                    cameraParams.RotationVectors(i,3), ...
                    this.RotationVectorsError(i,3));
                
                fprintf(frameFormat, ...
                    '', ...
                    rotationVectorsFormat{1}, ...
                    rotationVectorsFormat{2}, ...
                    rotationVectorsFormat{3});
            end
            
            fprintf('\n%s\n', ...
                getString(...
                     message('vision:cameraCalibrationErrors:translationVectors', ...
                             cameraParams.WorldUnits)));
            for i = 1:cameraParams.NumPatterns                
                TranslationVectorsFormat{1} = sprintf(entryFormat,...
                    cameraParams.TranslationVectors(i,1), ...
                    this.TranslationVectorsError(i,1));
                
                TranslationVectorsFormat{2} = sprintf(entryFormat,...
                    cameraParams.TranslationVectors(i,2), ...
                    this.TranslationVectorsError(i,2));
                
                TranslationVectorsFormat{3} = sprintf(entryFormat,...
                    cameraParams.TranslationVectors(i,3), ...
                    this.TranslationVectorsError(i,3));
                
                fprintf(frameFormat, ...
                    '', ...
                    TranslationVectorsFormat{1}, ...
                    TranslationVectorsFormat{2}, ...
                    TranslationVectorsFormat{3});
            end
        end
    end
end