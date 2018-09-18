classdef Deinterlacer< matlab.system.SFunSystem
%Deinterlacer Remove motion artifacts by deinterlacing input video signal
%   HDINT = vision.Deinterlacer returns a deinterlacing System object,
%   HDINT, that removes motion artifacts from images composed of weaved top
%   and bottom fields of an interlaced signal.
%
%   HDINT = vision.Deinterlacer('PropertyName', PropertyValue, ...) returns
%   a deinterlacing System object, HDINT, with each specified property set
%   to the specified value.
%
%   Step method syntax:
%
%   Y = step(HDINT, X) deinterlaces input X according to the algorithm set
%   in the Method property.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Deinterlacer methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create deinterlacing object with same property values
%   isLocked - Locked status (logical)
%
%   Deinterlacer properties:
%
%   Method          - Method used to deinterlace input video
%   TransposedInput - Indicate if input data is in row-major order
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Deinterlacer.helpFixedPoint.
%
%   % EXAMPLE: Use Deinterlacer to remove motion artifacts from
%   %          input image.
%      hdint = vision.Deinterlacer;
%      x = imread('vipinterlace.png');
%      y = step(hdint, x);
%      imshow(x); title('Original Image');
%      figure, imshow(y); title('Image after deinterlacing');
%
%   See also vision.Deinterlacer.helpFixedPoint.

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=Deinterlacer
            %Deinterlacer Remove motion artifacts by deinterlacing input video signal
            %   HDINT = vision.Deinterlacer returns a deinterlacing System object,
            %   HDINT, that removes motion artifacts from images composed of weaved top
            %   and bottom fields of an interlaced signal.
            %
            %   HDINT = vision.Deinterlacer('PropertyName', PropertyValue, ...) returns
            %   a deinterlacing System object, HDINT, with each specified property set
            %   to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HDINT, X) deinterlaces input X according to the algorithm set
            %   in the Method property.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Deinterlacer methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create deinterlacing object with same property values
            %   isLocked - Locked status (logical)
            %
            %   Deinterlacer properties:
            %
            %   Method          - Method used to deinterlace input video
            %   TransposedInput - Indicate if input data is in row-major order
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Deinterlacer.helpFixedPoint.
            %
            %   % EXAMPLE: Use Deinterlacer to remove motion artifacts from
            %   %          input image.
            %      hdint = vision.Deinterlacer;
            %      x = imread('vipinterlace.png');
            %      y = step(hdint, x);
            %      imshow(x); title('Original Image');
            %      figure, imshow(y); title('Image after deinterlacing');
            %
            %   See also vision.Deinterlacer.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Deinterlacer System object fixed-point 
            %               information
            %   vision.Deinterlacer.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Deinterlacer
            %   System object.
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
        %   Specify the accumulator fixed-point data type as one of ['Same as
        %   input' | {'Custom'}].
        AccumulatorDataType;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],12,3).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom'. The default value of this
        %   property is numerictype([],8,0).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %Method Method used to deinterlace input video
        %   Specify how the object deinterlaces the input video as one of
        %   [{'Line repetition'} | 'Linear interpolation' | 'Vertical temporal
        %   median filtering'].
        Method;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as
        %   input'} | 'Custom'].
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %TransposedInput Indicate if input data is in row-major order
        %   Set this property to true to assume that the input buffer contains
        %   data elements from the first row first, then data elements from the
        %   second row second, and so on through the last row. The default
        %   value of this property is false.
        TransposedInput;

    end
end
