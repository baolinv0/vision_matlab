classdef Pyramid< matlab.system.SFunSystem
%Pyramid Gaussian pyramid decomposition
%   gaussPyramid = vision.Pyramid returns a System object, gaussPyramid,
%   that computes a Gaussian pyramid reduction or expansion of an image.
%
%   gaussPyramid = vision.Pyramid('PropertyName', PropertyValue, ...)
%   configures the System object properties,  specified as one or more
%   name-value pair arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   J = step(gaussPyramid, I) computes J, the Gaussian pyramid
%   decomposition of input I.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Pyramid methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create gaussian pyramid object with same property values
%   isLocked - Locked status (logical)
%
%   Pyramid properties:
%
%   Operation             - Reduce or expand the input image
%   PyramidLevel          - Decomposition level
%   SeparableFilter       - Choose between default or custom filter
%   CoefficientA          - Coefficient 'a' of default separable filter
%                           [1/4-a/2 1/4 a 1/4 1/4-a/2]
%   CustomSeparableFilter - Separable filter coefficients
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Pyramid.helpFixedPoint.
%
%   Example: Use Pyramid System object for image decomposition. 
%   -----------------------------------------------------------
%   % vision.Pyramid reduces the image by default
%   gaussPyramid = vision.Pyramid('PyramidLevel', 2);
%
%   % Cast to single, otherwise returned J will be a fixed point object
%   I = im2single(imread('cameraman.tif'));                  
%   J = step(gaussPyramid, I);
%
%   figure, imshow(I); title('Original Image');
%   figure, imshow(J); title('Reduced Image');
%
%   See also imresize, vision.Pyramid.helpFixedPoint, impyramid

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=Pyramid
            %Pyramid Gaussian pyramid decomposition
            %   gaussPyramid = vision.Pyramid returns a System object, gaussPyramid,
            %   that computes a Gaussian pyramid reduction or expansion of an image.
            %
            %   gaussPyramid = vision.Pyramid('PropertyName', PropertyValue, ...)
            %   configures the System object properties,  specified as one or more
            %   name-value pair arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   J = step(gaussPyramid, I) computes J, the Gaussian pyramid
            %   decomposition of input I.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Pyramid methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create gaussian pyramid object with same property values
            %   isLocked - Locked status (logical)
            %
            %   Pyramid properties:
            %
            %   Operation             - Reduce or expand the input image
            %   PyramidLevel          - Decomposition level
            %   SeparableFilter       - Choose between default or custom filter
            %   CoefficientA          - Coefficient 'a' of default separable filter
            %                           [1/4-a/2 1/4 a 1/4 1/4-a/2]
            %   CustomSeparableFilter - Separable filter coefficients
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Pyramid.helpFixedPoint.
            %
            %   Example: Use Pyramid System object for image decomposition. 
            %   -----------------------------------------------------------
            %   % vision.Pyramid reduces the image by default
            %   gaussPyramid = vision.Pyramid('PyramidLevel', 2);
            %
            %   % Cast to single, otherwise returned J will be a fixed point object
            %   I = im2single(imread('cameraman.tif'));                  
            %   J = step(gaussPyramid, I);
            %
            %   figure, imshow(I); title('Original Image');
            %   figure, imshow(J); title('Reduced Image');
            %
            %   See also imresize, vision.Pyramid.helpFixedPoint, impyramid
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Pyramid System object fixed-point 
            %               information
            %   vision.Pyramid.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Pyramid
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
        %   product'} | 'Same as input' | 'Custom'].
        AccumulatorDataType;

        %CoefficientA  Coefficient 'a' of default separable filter
        %   Specify the coefficients in the default separable filter [1/4-a/2
        %   1/4 a 1/4 1/4-a/2] as a scalar value. This property is applicable
        %   when the SeparableFilter property is 'Default'. The default value
        %   of this property is 0.375.
        CoefficientA;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,0).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
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

        %CustomSeparableFilter Separable filter coefficients
        %   Specify separable filter coefficients as a vector. This property is
        %   applicable when the SeparableFilter property is 'Custom'. The
        %   default value of this property is [0.0625 0.25 0.375 0.25 0.0625].
        CustomSeparableFilter;

        %CustomSeparableFilterDataType CustomSeparableFilter word and fraction lengths
        %   Specify the coefficients fixed-point type as an auto-signed
        %   numerictype object. This property is applicable when the
        %   SeparableFilterDataType property is 'Custom'. The default value of
        %   this property is numerictype([],16,14).
        %
        %   See also numerictype.
        CustomSeparableFilterDataType;

        %Operation Reduce or expand the input image
        %   Specify whether to reduce or expand the input image as one of
        %   [{'Reduce'} | 'Expand']. If this property is set to 'Reduce', the
        %   object applies a lowpass filter and then downsamples the input
        %   image. If this property is set to 'Expand', the object upsamples
        %   and then applies a lowpass filter to the input image.
        Operation;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of ['Same as input'
        %   | {'Custom'}].
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as
        %   input' | {'Custom'}].
        ProductDataType;

        %PyramidLevel Level of decomposition
        %   Specify the number of times the object upsamples or downsamples
        %   each dimension of the image by a factor of 2. The default value of
        %   this property is 1.
        PyramidLevel;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %SeparableFilter How to specify the coefficients of low pass filter
        %   Indicate how to specify the coefficients of the lowpass filter as
        %   one of [{'Default'} | 'Custom'}].
        SeparableFilter;

        %SeparableFilterDataType CustomSeparableFilter word- and fraction-length designations
        %   Specify the coefficients fixed-point data type as one of ['Same
        %   word length as input' | {'Custom'}].
        SeparableFilterDataType;

    end
end
