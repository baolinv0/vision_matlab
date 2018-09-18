classdef GammaCorrector< matlab.system.SFunSystem
%GammaCorrector Gamma correction
%   HGAMMACORR = vision.GammaCorrector returns a System object, HGAMMACORR,
%   that applies or removes gamma correction from images or video streams.
%
%   HGAMMACORR = vision.GammaCorrector('PropertyName', PropertyValue, ...)
%   returns a gamma corrector System object, HGAMMACORR, with each
%   specified property set to the specified value.
%
%   HGAMMACORR = vision.GammaCorrector(GAMMA, 'PropertyName',
%   PropertyValue, ...) returns a gamma corrector System object,
%   HGAMMACORR, with the Gamma property set to GAMMA and other specified
%   properties set to the specified values.
%
%   Step method syntax:
%
%   Y = step(HGAMMACORR, X) applies or removes gamma correction from input
%   X and returns the gamma corrected or linearized output Y.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   GammaCorrector methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create gamma corrector object with same property values
%   isLocked - Locked status (logical)
%
%   GammaCorrector properties:
%
%   Correction    - Specify gamma correction or linearization
%   Gamma         - Gamma value of output or input
%   LinearSegment - Enables gamma curve to have linear portion near origin
%   BreakPoint    - I-axis value of the end of gamma correction linear
%                   segment
%
%   % EXAMPLE: Use GammaCorrector System object to improve image contrast.
%       hgamma = vision.GammaCorrector(2.0, 'Correction', 'De-gamma');
%       x = imread('pears.png');
%       y = step(hgamma, x);
%       imshow(x); title('Original Image');
%       figure, imshow(y); title('Enhanced Image after De-gamma Correction');
%
%   See also   

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=GammaCorrector
            %GammaCorrector Gamma correction
            %   HGAMMACORR = vision.GammaCorrector returns a System object, HGAMMACORR,
            %   that applies or removes gamma correction from images or video streams.
            %
            %   HGAMMACORR = vision.GammaCorrector('PropertyName', PropertyValue, ...)
            %   returns a gamma corrector System object, HGAMMACORR, with each
            %   specified property set to the specified value.
            %
            %   HGAMMACORR = vision.GammaCorrector(GAMMA, 'PropertyName',
            %   PropertyValue, ...) returns a gamma corrector System object,
            %   HGAMMACORR, with the Gamma property set to GAMMA and other specified
            %   properties set to the specified values.
            %
            %   Step method syntax:
            %
            %   Y = step(HGAMMACORR, X) applies or removes gamma correction from input
            %   X and returns the gamma corrected or linearized output Y.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   GammaCorrector methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create gamma corrector object with same property values
            %   isLocked - Locked status (logical)
            %
            %   GammaCorrector properties:
            %
            %   Correction    - Specify gamma correction or linearization
            %   Gamma         - Gamma value of output or input
            %   LinearSegment - Enables gamma curve to have linear portion near origin
            %   BreakPoint    - I-axis value of the end of gamma correction linear
            %                   segment
            %
            %   % EXAMPLE: Use GammaCorrector System object to improve image contrast.
            %       hgamma = vision.GammaCorrector(2.0, 'Correction', 'De-gamma');
            %       x = imread('pears.png');
            %       y = step(hgamma, x);
            %       imshow(x); title('Original Image');
            %       figure, imshow(y); title('Enhanced Image after De-gamma Correction');
            %
            %   See also   
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function setPortDataTypeConnections(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %BreakPoint I-axis value of the end of gamma correction linear segment
        %   Specify the I-axis value of the end of the gamma correction linear
        %   segment as a scalar numeric value between 0 and 1. This property is
        %   applicable when the LinearSegment property is true. The default
        %   value of this property is 0.018.
        BreakPoint;

        %Correction Specify gamma correction or linearization
        %   Specify the object's operation as one of [{'Gamma'} | 'De-gamma'].
        Correction;

        %Gamma Gamma value of output or input
        %   If the Correction property is 'Gamma', this property gives the
        %   desired gamma value of the output video stream. If the Correction
        %   property is 'De-gamma', this property indicates the gamma value of
        %   the input video stream. This property must be a numeric scalar
        %   value greater than or equal to 1. The default value of this
        %   property is 2.2.
        Gamma;

        %LinearSegment Enables gamma curve to have linear portion near origin
        %   Set this property to true to make the gamma curve have a linear
        %   portion near the origin. The default value of this property is
        %   true.
        LinearSegment;

    end
end
