classdef Convolver< matlab.system.SFunSystem
%Convolver 2-D convolution
%   HCONV = vision.Convolver returns a System object, HCONV, that
%   performs two-dimensional convolution on two inputs.
%
%   HCONV = vision.Convolver('PropertyName', PropertyValue, ...) returns
%   a 2-D convolution System object, HCONV, with each specified property
%   set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HCONV, X1, X2) computes 2-D convolution of input matrices X1
%   and X2.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Convolver methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D convolution object with same property values
%   isLocked - Locked status (logical)
%
%   Convolver properties:
%
%   OutputSize - Specify dimensions of output
%   Normalize  - Whether to normalize the output
%
%   This System object supports fixed-point operations when the property
%   Normalize is set to false. For more information, type
%   vision.Convolver.helpFixedPoint.
%
%   % EXAMPLE: Compute the 2D convolution of two matrices.
%      hconv2d = vision.Convolver;
%      x1 = [1 2;2 1];
%      x2 = [1 -1;-1 1];
%      y = step(hconv2d, x1, x2)
%
%   See also vision.Crosscorrelator, vision.AutoCorrelator,
%            vision.Convolver.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=Convolver
            %Convolver 2-D convolution
            %   HCONV = vision.Convolver returns a System object, HCONV, that
            %   performs two-dimensional convolution on two inputs.
            %
            %   HCONV = vision.Convolver('PropertyName', PropertyValue, ...) returns
            %   a 2-D convolution System object, HCONV, with each specified property
            %   set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HCONV, X1, X2) computes 2-D convolution of input matrices X1
            %   and X2.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Convolver methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D convolution object with same property values
            %   isLocked - Locked status (logical)
            %
            %   Convolver properties:
            %
            %   OutputSize - Specify dimensions of output
            %   Normalize  - Whether to normalize the output
            %
            %   This System object supports fixed-point operations when the property
            %   Normalize is set to false. For more information, type
            %   vision.Convolver.helpFixedPoint.
            %
            %   % EXAMPLE: Compute the 2D convolution of two matrices.
            %      hconv2d = vision.Convolver;
            %      x1 = [1 2;2 1];
            %      x2 = [1 -1;-1 1];
            %      y = step(hconv2d, x1, x2)
            %
            %   See also vision.Crosscorrelator, vision.AutoCorrelator,
            %            vision.Convolver.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Convolver System object fixed-point information
            %   vision.Convolver.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Convolver
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
        %   Specify the accumulator fixed-point data type as one of [{'Same as
        %   product'} | 'Same as first input' | 'Custom'].
        AccumulatorDataType;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths               
        %   Specify the output fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,12).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomProductDataType;

        %Normalize Whether to normalize the output
        %   Set to true to normalize the output. The default value of this
        %   property is false.
        Normalize;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of ['Same as first
        %   input' | {'Custom'}].
        OutputDataType;

        %OutputSize Specify dimensions of output
        %   This property controls the size of the output scalar, vector, or
        %   matrix produced as a result of the convolution between the two
        %   inputs. This property can be set to one of [{'Full'} | 'Same as
        %   first input' | 'Valid']. If this property is set to 'Full', the
        %   output is the full two-dimensional convolution with (Ma+Mb-1,
        %   Na+Nb-1). If this property is set to 'Same as first input', the
        %   output is the central part of the convolution with the same
        %   dimensions as the first input. If this property is set to 'Valid',
        %   the output is only those parts of the convolution that are computed
        %   without the zero-padded edges of any input. This output has
        %   dimensions (Ma-Mb+1, Na-Nb+1). (Ma, Na) is the size of the first
        %   input matrix and (Mb, Nb) is the size of the second input matrix.
        OutputSize;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as first
        %   input' | {'Custom'}].
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

    end
end
