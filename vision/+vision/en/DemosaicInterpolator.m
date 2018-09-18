classdef DemosaicInterpolator< matlab.system.SFunSystem
%DemosaicInterpolator Bayer-pattern image conversion to true color
%   HDEMOSAIC = vision.DemosaicInterpolator returns a System object,
%   HDEMOSAIC, that performs demosaic interpolation on an input image in
%   Bayer format with the specified alignment. The alignment is identified
%   as the sequence of R, G and B pixels in the top-left four pixels of the
%   image in row-wise order.
%
%   HDEMOSAIC = vision.DemosaicInterpolator('PropertyName', PropertyValue,
%   ...) returns a System object, HDEMOSAIC, with each specified property
%   set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HDEMOSAIC, X) performs the demosaic operation on the input X.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   DemosaicInterpolator methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create demosaic interpolation object with same property values
%   isLocked - Locked status (logical)
%
%   DemosaicInterpolator properties:
%
%   Method          - Interpolation algorithm
%   SensorAlignment - Alignment of the input image
%
%   This System object supports fixed-point operations. For more
%   information, type vision.DemosaicInterpolator.helpFixedPoint.
%
%   % EXAMPLE: Demosaic a Bayer pattern encoded-image photographed by a
%   %          camera with a sensor alignment of 'BGGR'.         
%       x = imread('mandi.tif');
%       hdemosaic = vision.DemosaicInterpolator('SensorAlignment', 'BGGR');
%       y = step(hdemosaic, x);
%       imshow(x,'InitialMagnification',20); 
%       title('Original Image');
%       figure, imshow(y,'InitialMagnification',20); 
%       title('RGB image after demosaic');
%
%   See also vision.GammaCorrector, vision.DemosaicInterpolator.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=DemosaicInterpolator
            %DemosaicInterpolator Bayer-pattern image conversion to true color
            %   HDEMOSAIC = vision.DemosaicInterpolator returns a System object,
            %   HDEMOSAIC, that performs demosaic interpolation on an input image in
            %   Bayer format with the specified alignment. The alignment is identified
            %   as the sequence of R, G and B pixels in the top-left four pixels of the
            %   image in row-wise order.
            %
            %   HDEMOSAIC = vision.DemosaicInterpolator('PropertyName', PropertyValue,
            %   ...) returns a System object, HDEMOSAIC, with each specified property
            %   set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HDEMOSAIC, X) performs the demosaic operation on the input X.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   DemosaicInterpolator methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create demosaic interpolation object with same property values
            %   isLocked - Locked status (logical)
            %
            %   DemosaicInterpolator properties:
            %
            %   Method          - Interpolation algorithm
            %   SensorAlignment - Alignment of the input image
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.DemosaicInterpolator.helpFixedPoint.
            %
            %   % EXAMPLE: Demosaic a Bayer pattern encoded-image photographed by a
            %   %          camera with a sensor alignment of 'BGGR'.         
            %       x = imread('mandi.tif');
            %       hdemosaic = vision.DemosaicInterpolator('SensorAlignment', 'BGGR');
            %       y = step(hdemosaic, x);
            %       imshow(x,'InitialMagnification',20); 
            %       title('Original Image');
            %       figure, imshow(y,'InitialMagnification',20); 
            %       title('RGB image after demosaic');
            %
            %   See also vision.GammaCorrector, vision.DemosaicInterpolator.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.DemosaicInterpolator System object 
            %               fixed-point information
            %   vision.DemosaicInterpolator.helpFixedPoint displays information
            %   about fixed-point properties and operations of the
            %   vision.DemosaicInterpolator System object.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function setPortDataTypeConnections(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %AccumulatorDataType Accumulator word- and fraction-length designations
        %   Specify the accumulator fixed-point data type as one of [{'Same as
        %   product'} | 'Same as input' | 'Custom'].
        AccumulatorDataType;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. This property is only applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomProductDataType;

        %Method Interpolation algorithm
        %   Specify the algorithm the object uses to calculate the missing
        %   color information as one of ['Bilinear' | {'Gradient-corrected
        %   linear'}].
        Method;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of ['Wrap' | {'Saturate'}].
        OverflowAction;

        %ProductDataType Product output word- and fraction-length designations
        %   Specify the product output fixed-point data type as one of ['Same
        %   as input' | {'Custom'}].
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %SensorAlignment Alignment of the input image
        %   Specify the sequence of R, G and B pixels that correspond to the
        %   2-by-2 block of pixels in the top left corner of the image. It can
        %   be set to one of [{'RGGB'} | 'GRBG' | 'GBRG' | 'BGGR']. The
        %   sequence should be specified in left-to-right, top-to-bottom order.
        SensorAlignment;

    end
end
