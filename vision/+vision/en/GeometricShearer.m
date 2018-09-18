classdef GeometricShearer< matlab.system.SFunSystem
%GeometricShearer Shift rows or columns of image by linearly varying offset
%   H = vision.GeometricShearer returns a System object, H, that shifts the
%   rows or columns of an image by gradually increasing distance left or
%   right or up or down.
%
%   H = vision.GeometricShearer('PropertyName', PropertyValue, ...) returns
%   a geometric shear object, H, with each specified property set to the
%   specified value.
%
%   Step method syntax:
%
%   Y = step(H, IMG) shifts the input, IMG, and returns the shifted image,
%   Y, with the shear values specified by the Values property.
%
%   Y = step(H, IMG, S) uses the two-element vector, S, as the number of
%   pixels by which to shift the first and last rows or columns of IMG,
%   when the ValuesSource property is 'Input port'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   GeometricShearer methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create geometric shear object with same property values
%   isLocked - Locked status (logical)
%
%   GeometricShearer properties:
%
%   Direction           - Direction of applying offset
%   OutputSize          - Output size as full or same as input image size
%   ValuesSource        - Source of shear values
%   Values              - Shear values in pixels
%   MaximumValue        - Maximum number of pixels by which to shear image
%   BackgroundFillValue - Value of pixels outside image
%   InterpolationMethod - Interpolation method used to shear image
%
%   This System object supports fixed-point operations. For more
%   information, type vision.GeometricShearer.helpFixedPoint.
%
%   % EXAMPLE #1: Apply a horizontal shear to an image.
%      hshear = vision.GeometricShearer('Values',[0 20]);
%      img = im2single(checkerboard);
%      outimg = step(hshear,img);
%      subplot(2,1,1), imshow(img);
%      title('Original image');
%      subplot(2,1,2), imshow(outimg);
%      title('Output image');
%
%   See also imwarp, imresize 

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=GeometricShearer
            %GeometricShearer Shift rows or columns of image by linearly varying offset
            %   H = vision.GeometricShearer returns a System object, H, that shifts the
            %   rows or columns of an image by gradually increasing distance left or
            %   right or up or down.
            %
            %   H = vision.GeometricShearer('PropertyName', PropertyValue, ...) returns
            %   a geometric shear object, H, with each specified property set to the
            %   specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(H, IMG) shifts the input, IMG, and returns the shifted image,
            %   Y, with the shear values specified by the Values property.
            %
            %   Y = step(H, IMG, S) uses the two-element vector, S, as the number of
            %   pixels by which to shift the first and last rows or columns of IMG,
            %   when the ValuesSource property is 'Input port'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   GeometricShearer methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create geometric shear object with same property values
            %   isLocked - Locked status (logical)
            %
            %   GeometricShearer properties:
            %
            %   Direction           - Direction of applying offset
            %   OutputSize          - Output size as full or same as input image size
            %   ValuesSource        - Source of shear values
            %   Values              - Shear values in pixels
            %   MaximumValue        - Maximum number of pixels by which to shear image
            %   BackgroundFillValue - Value of pixels outside image
            %   InterpolationMethod - Interpolation method used to shear image
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.GeometricShearer.helpFixedPoint.
            %
            %   % EXAMPLE #1: Apply a horizontal shear to an image.
            %      hshear = vision.GeometricShearer('Values',[0 20]);
            %      img = im2single(checkerboard);
            %      outimg = step(hshear,img);
            %      subplot(2,1,1), imshow(img);
            %      title('Original image');
            %      subplot(2,1,2), imshow(outimg);
            %      title('Output image');
            %
            %   See also imwarp, imresize 
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.GeometricShearer System object
            %               fixed-point information
            %   vision.GeometricShearer.helpFixedPoint displays information
            %   about fixed-point properties and operations of the
            %   vision.GeometricShearer System object.
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

        %BackgroundFillValue Value of pixels outside image
        %   Specify the value of pixels that are outside the image as a numeric
        %   scalar, or a numeric vector of same length as the third dimension of
        %   the input image. The default value of this property is 0. This
        %   property is tunable.
        BackgroundFillValue;

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
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   InterpolationMethod property is either 'Bilinear' or 'Bicubic', and
        %   the ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomProductDataType;

        %CustomValuesDataType Shear values word and fraction lengths
        %   Specify the shear values fixed-point type as an auto-signed
        %   numerictype object. This property is applicable when the ValuesSource
        %   property is 'Property' and the ValuesDataType property is 'Custom'.
        %   The default value of this property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomValuesDataType;

        %Direction Direction of applying offset
        %   Specify the direction of linearly increasing the offset as one of
        %   [{'Horizontal'} | 'Vertical']. Set this property to 'Horizontal' to
        %   linearly increase the offset of the rows, or 'Vertical' to linearly
        %   increase the offset of the columns.
        Direction;

        %InterpolationMethod Interpolation method used to shear image
        %   Specify the interpolation method used to shear the image as one of
        %   ['Nearest neighbor' | {'Bilinear'} | 'Bicubic']. If this property is
        %   set to 'Nearest neighbor', the object uses the value of one nearby
        %   pixel for the new pixel value. If it is set to 'Bilinear', the new
        %   pixel value is the weighted average of the two nearest pixel values.
        %   If it is set to 'Bicubic', the new pixel value is the weighted
        %   average of the four nearest pixel values.
        InterpolationMethod;

        %MaximumValue Maximum number of pixels by which to shear image
        %   Specify the maximum number of pixels by which to shear the image as a
        %   real numeric scalar. This property is applicable when the
        %   ValuesSource property is 'Input port'. The default value of this
        %   property is 20.
        MaximumValue;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as first
        %   input'} | 'Custom'].
        OutputDataType;

        %OutputSize Output size as full or same as input image size
        %   Specify the size of output image as one of [{'Full'} | 'Same as input
        %   image']. If this property is set to 'Full', the object outputs a
        %   matrix that contains the sheared image values. If it is set to 'Same
        %   as input image', the object outputs a matrix that is the same size as
        %   the input image and contains a portion of the sheared image.
        OutputSize;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of ['Wrap' | {'Saturate'}].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as first
        %   input' | {'Custom'}]. This property is applicable when the
        %   InterpolationMethod property is either 'Bilinear' or 'Bicubic'.
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   'Floor' | {'Nearest'} | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %Values Shear values in pixels
        %  Specify the shear values as a two-element vector that represents the
        %  number of pixels by which to shift the first and last rows or columns
        %  of the input. This property is applicable when the ValuesSource
        %  property is 'Property'. The default value of this property is [0 3].
        Values;

        %ValuesDataType Shear values word- and fraction-length designations
        %   Specify the shear values fixed-point data type as one of [{'Same word
        %   length as input'} | 'Custom']. This property is applicable when the
        %   ValuesSource property is 'Property'.
        ValuesDataType;

        %ValuesSource Source of shear values
        %   Specify the source of shear values as one of [{'Property'} | 'Input
        %   port'].
        ValuesSource;

    end
end
