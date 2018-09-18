classdef Crosscorrelator< matlab.system.SFunSystem
%Crosscorrelator 2-D cross-correlation
%   HCORR = vision.Crosscorrelator returns a correlation2D System object,
%   HCORR, that performs two-dimensional cross-correlation between two
%   inputs.
%
%   HCORR = vision.Crosscorrelator('PropertyName', PropertyValue, ...)
%   returns a 2-D cross-correlation System object, HCORR, with each
%   specified property set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HCORR, X1, X2) computes 2D correlation of input matrices X1
%   and X2.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Crosscorrelator methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D cross-correlation object with same property values
%   isLocked - Locked status (logical)
%
%   Crosscorrelator properties:
%
%   OutputSize - Dimensions of output
%   Normalize  - Whether to normalize the output
%
%   This System object supports fixed-point operations when the property
%   Normalize is set to false. For more information, type
%   vision.Crosscorrelator.helpFixedPoint.
%
%   % EXAMPLE: Compute the 2D correlation of two matrices.
%      hcorr2d = vision.Crosscorrelator;
%      x1 = [1 2;2 1];
%      x2 = [1 -1;-1 1];
%      y = step(hcorr2d, x1, x2);
%
%   See also vision.Autocorrelator, vision.Crosscorrelator.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=Crosscorrelator
            %Crosscorrelator 2-D cross-correlation
            %   HCORR = vision.Crosscorrelator returns a correlation2D System object,
            %   HCORR, that performs two-dimensional cross-correlation between two
            %   inputs.
            %
            %   HCORR = vision.Crosscorrelator('PropertyName', PropertyValue, ...)
            %   returns a 2-D cross-correlation System object, HCORR, with each
            %   specified property set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HCORR, X1, X2) computes 2D correlation of input matrices X1
            %   and X2.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Crosscorrelator methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D cross-correlation object with same property values
            %   isLocked - Locked status (logical)
            %
            %   Crosscorrelator properties:
            %
            %   OutputSize - Dimensions of output
            %   Normalize  - Whether to normalize the output
            %
            %   This System object supports fixed-point operations when the property
            %   Normalize is set to false. For more information, type
            %   vision.Crosscorrelator.helpFixedPoint.
            %
            %   % EXAMPLE: Compute the 2D correlation of two matrices.
            %      hcorr2d = vision.Crosscorrelator;
            %      x1 = [1 2;2 1];
            %      x2 = [1 -1;-1 1];
            %      y = step(hcorr2d, x1, x2);
            %
            %   See also vision.Autocorrelator, vision.Crosscorrelator.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Crosscorrelator System object fixed-point information
            %   vision.Crosscorrelator.helpFixedPoint displays information about
            %   fixed-point properties and operations of the
            %   vision.Crosscorrelator System object.
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

        %Normalize Whether to normalize the output
        %   Set this property to true to normalize the output. The default
        %   value of this property is false.
        Normalize;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as first
        %   input'} | 'Custom'].
        OutputDataType;

        %OutputSize Specify dimensions of output
        %   This property controls the size of the output scalar, vector, or
        %   matrix produced as a result of the cross-correlation between the
        %   two inputs. This property can be set to one of [{'Full'} | 'Same as
        %   first input' | 'Valid']. If this property is set to 'Full', the
        %   output is the full two-dimensional cross-correlation of two
        %   matrices of size M1xN1 and M2xN2, which will have dimensions
        %   (M1+M2-1, N1+N2-1). If this property is set to 'same as first
        %   input', the output is the central part of the cross-correlation
        %   with the same dimensions as the first input. If this property is
        %   set to 'valid', the output consists of those parts of the
        %   cross-correlation that are computed without the zero-padded edges
        %   of any input. Hence, when this property is set to 'valid' and the
        %   two input matrices are of size M1xN1 and M2xN2, the output has
        %   dimensions (M1-M2+1, N1-N2+1).
        OutputSize;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of [{'Same as
        %   first input'} | 'Custom'].
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

    end
end
