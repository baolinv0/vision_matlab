% CameraParameters Object for storing camera parameters.
%
%   -----------------------------------------------------------------------
%   The class vision.CameraParameters will be removed in a future release. 
%   Please use class cameraParameters instead.
%   -----------------------------------------------------------------------
%
% See also cameraParameters

% Copyright 2013 MathWorks, Inc

classdef CameraParameters     
    
    methods(Access=private)
        function this = CameraParameters()
        end
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
       
        function this = loadobj(that)
            this = cameraParameters(...
                'IntrinsicMatrix', that.IntrinsicMatrix,...
                'RadialDistortion', that.RadialDistortion,...
                'TangentialDistortion', that.TangentialDistortion,...
                'WorldPoints', that.WorldPoints,...
                'WorldUnits',  that.WorldUnits,...
                'EstimateSkew', that.EstimateSkew,...
                'NumRadialDistortionCoefficients', that.NumRadialDistortionCoefficients,...
                'EstimateTangentialDistortion', that.EstimateTangentialDistortion,...
                'RotationVectors', that.RotationVectors,...
                'TranslationVectors', that.TranslationVectors, ...                 
                'ReprojectionErrors', that.ReprojectionErrors);
        end
        
    end    
end            

