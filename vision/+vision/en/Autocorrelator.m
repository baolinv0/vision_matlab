classdef Autocorrelator< matlab.system.SFunSystem
%Autocorrelator 2-D autocorrelation
%   HAC = vision.Autocorrelator returns a System object, HAC, that
%   performs two-dimensional auto-correlation of an input matrix.
%
%   HAC = vision.Autocorrelator('PropertyName', PropertyValue, ...)
%   returns a 2-D autocorrelation System object, HAC, with each specified
%   property set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HAC, X) returns the 2-D autocorrelation, Y, of input matrix
%   X.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Autocorrelator methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D autocorrelation object with same property values
%   isLocked - Locked status (logical)
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Autocorrelator.helpFixedPoint.
%
%   % EXAMPLE: Compute the 2D autocorrelation of a matrix.
%       hac2d = vision.Autocorrelator;
%       x = [1 2;2 1];
%       y = step(hac2d, x)
%
%   See also vision.Crosscorrelator, vision.Autocorrelator.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=Autocorrelator
            %Autocorrelator 2-D autocorrelation
            %   HAC = vision.Autocorrelator returns a System object, HAC, that
            %   performs two-dimensional auto-correlation of an input matrix.
            %
            %   HAC = vision.Autocorrelator('PropertyName', PropertyValue, ...)
            %   returns a 2-D autocorrelation System object, HAC, with each specified
            %   property set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HAC, X) returns the 2-D autocorrelation, Y, of input matrix
            %   X.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Autocorrelator methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D autocorrelation object with same property values
            %   isLocked - Locked status (logical)
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Autocorrelator.helpFixedPoint.
            %
            %   % EXAMPLE: Compute the 2D autocorrelation of a matrix.
            %       hac2d = vision.Autocorrelator;
            %       x = [1 2;2 1];
            %       y = step(hac2d, x)
            %
            %   See also vision.Crosscorrelator, vision.Autocorrelator.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Autocorrelator System object fixed-point information
            %   vision.Autocorrelator.helpFixedPoint displays information about
            %   fixed-point properties and operations of the
            %   vision.Autocorrelator System object.
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
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,30).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom'. The default value of this
        %   property is numerictype([],16,15).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,30).
        %
        %   See also numerictype.
        CustomProductDataType;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as
        %   input'} | 'Custom'].
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of [{'Same as
        %   input'} | 'Custom'].
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

    end
end
