classdef AlphaBlender< matlab.system.SFunSystem
%AlphaBlender Combine images, overlay images, or highlight selected pixels
%   HALPHABLEND = vision.AlphaBlender returns an alpha blending System
%   object, HALPHABLEND, that combines the pixel values of two images,
%   overlays one image over another, or highlights selected pixels.
%
%   HALPHABLEND = vision.AlphaBlender('PropertyName', PropertyValue, ...)
%   returns an alpha blending object, HALPHABLEND, with each specified
%   property set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HALPHABLEND, I1, I2) blends images I1 and I2.
%
%   Y = step(HALPHABLEND, I1, I2, OPACITY) uses OPACITY input to combine
%   pixel values of I1 and I2 when the Operation property is 'Blend' and
%   the OpacitySource property is 'Input port'.
%
%   Y = step(HALPHABLEND, I1, I2, MASK) uses MASK input to overlay I2 over
%   I1 when the Operation property is 'Binary mask' and the MaskSource
%   property is 'Input port'.
%
%   Y = step(HALPHABLEND, I1, MASK) uses MASK input to determine which
%   pixels in I1 are set to the maximum value supported by their data type
%   when the Operation property is 'Highlight selected pixels' and the
%   MaskSource property is 'Input port'.
%
%   Y = step(HALPHABLEND, I1, I2, ..., LOCATION) uses LOCATION input to
%   specify the upper-left corner position of I2 when the LocationSource
%   property is 'Input port'. LOCATION is an [x y] vector of coordinates.    
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   AlphaBlender methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create alpha blending object with same property values
%   isLocked - Locked status (logical)
%
%   AlphaBlender properties:
%
%   Operation      - Operation to perform
%   OpacitySource  - Source of opacity factor
%   Opacity        - Amount by which the object scales each pixel value
%                    before combining them
%   MaskSource     - Source of binary mask
%   Mask           - Which pixels are overwritten
%   LocationSource - Source of location of the upper-left corner of second
%                    input image
%   Location       - Location [x y] of upper-left corner of second
%                    input image relative to first input image
%
%   This System object supports fixed-point operations. For more
%   information, type vision.AlphaBlender.helpFixedPoint.
%
%   % EXAMPLE: Blend two images.
%      I1 = im2single(imread('blobs.png'));
%      I2 = im2single(imread('circles.png'));
%      halphablend = vision.AlphaBlender;
%      J = step(halphablend, I1, I2);
%      imshow(J)
%
%   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
%      vision.AlphaBlender.helpFixedPoint.

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=AlphaBlender
            %AlphaBlender Combine images, overlay images, or highlight selected pixels
            %   HALPHABLEND = vision.AlphaBlender returns an alpha blending System
            %   object, HALPHABLEND, that combines the pixel values of two images,
            %   overlays one image over another, or highlights selected pixels.
            %
            %   HALPHABLEND = vision.AlphaBlender('PropertyName', PropertyValue, ...)
            %   returns an alpha blending object, HALPHABLEND, with each specified
            %   property set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HALPHABLEND, I1, I2) blends images I1 and I2.
            %
            %   Y = step(HALPHABLEND, I1, I2, OPACITY) uses OPACITY input to combine
            %   pixel values of I1 and I2 when the Operation property is 'Blend' and
            %   the OpacitySource property is 'Input port'.
            %
            %   Y = step(HALPHABLEND, I1, I2, MASK) uses MASK input to overlay I2 over
            %   I1 when the Operation property is 'Binary mask' and the MaskSource
            %   property is 'Input port'.
            %
            %   Y = step(HALPHABLEND, I1, MASK) uses MASK input to determine which
            %   pixels in I1 are set to the maximum value supported by their data type
            %   when the Operation property is 'Highlight selected pixels' and the
            %   MaskSource property is 'Input port'.
            %
            %   Y = step(HALPHABLEND, I1, I2, ..., LOCATION) uses LOCATION input to
            %   specify the upper-left corner position of I2 when the LocationSource
            %   property is 'Input port'. LOCATION is an [x y] vector of coordinates.    
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   AlphaBlender methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create alpha blending object with same property values
            %   isLocked - Locked status (logical)
            %
            %   AlphaBlender properties:
            %
            %   Operation      - Operation to perform
            %   OpacitySource  - Source of opacity factor
            %   Opacity        - Amount by which the object scales each pixel value
            %                    before combining them
            %   MaskSource     - Source of binary mask
            %   Mask           - Which pixels are overwritten
            %   LocationSource - Source of location of the upper-left corner of second
            %                    input image
            %   Location       - Location [x y] of upper-left corner of second
            %                    input image relative to first input image
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.AlphaBlender.helpFixedPoint.
            %
            %   % EXAMPLE: Blend two images.
            %      I1 = im2single(imread('blobs.png'));
            %      I2 = im2single(imread('circles.png'));
            %      halphablend = vision.AlphaBlender;
            %      J = step(halphablend, I1, I2);
            %      imshow(J)
            %
            %   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
            %      vision.AlphaBlender.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.AlphaBlender System object fixed-point 
            %information
            %   vision.AlphaBlender.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.AlphaBlender
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
        %   Specify the accumulator fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOpacityDataType Opacity word and fraction lengths
        %   Specify the opacity factor fixed-point type as an auto-signed,
        %   unscaled numerictype object. This property is applicable when the
        %   OpacityDataType property is 'Custom'. The default value of this
        %   property is numerictype([],16).
        %
        %   See also numerictype.
        CustomOpacityDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,10).
        %
        %   See also numerictype.
        CustomProductDataType;

        %Location Location [x y] of upper-left corner of second input
        %image relative to first input image
        %   Specify the [x y]coordinates of upper-left corner of the
        %   second input image relative to upper-left corner of first input
        %   image as a two-element vector. This property is applicable when the
        %   LocationSource property is 'Property'. This property is tunable.
        %   The default value of this property is [1 1].
        Location;

        %LocationSource Source of location of the upper-left corner of second
        %input image
        %   Specify how to enter location of the upper-left corner of second
        %   input image as one of [{'Property'} | 'Input port'].
        LocationSource;

        %Mask Which pixels are overwritten
        %   Specify which pixels are overwritten as a binary scalar 0 or 1 used
        %   for all pixels, or a matrix of 0s and 1s that defines the factor
        %   for each pixel. This property is applicable when the MaskSource
        %   property is 'Property'. This property is tunable. The default value
        %   of this property is 1.
        Mask;

        %MaskSource Source of binary mask
        %   Specify how to determine the masking factor(s) as one of
        %   [{'Property'} | 'Input port']. This property is applicable when the
        %   Operation property is 'Binary mask'.
        MaskSource;

        %Opacity Amount by which the object scales each pixel value before
        %combining them
        %   Specify the amount by which the object scales each pixel value
        %   before combining them as a scalar value used for all pixels, or a
        %   matrix of values that defines the factor for each pixel. This
        %   property is applicable when the OpacitySource property is
        %   'Property'. This property is tunable. The default value of this
        %   property is 0.75.
        Opacity;

        %OpacityDataType Opacity word- and fraction-length designations
        %   Specify the opacity factor fixed-point data type as one of [{'Same
        %   word length as input'} | 'Custom'].
        OpacityDataType;

        %OpacitySource Source of opacity factor
        %   Specify how to determine the opacity factor(s) as one of
        %   [{'Property'} | 'Input port']. This property is applicable when the
        %   Operation property is 'Blend'.
        OpacitySource;

        %Operation Operation to perform
        %   Specify the operation that the object performs as one of [{'Blend'}
        %   | 'Binary mask' | 'Highlight selected pixels']. If this property is
        %   set to 'Blend', the object linearly combines the pixels of one
        %   image with another image. If this object is set to 'Binary mask',
        %   the object overwrites the pixel values of one image with the pixel
        %   values of another image. If this object is set to 'Highlight
        %   selected pixel', the object uses the binary image input, MASK, to
        %   determine which pixels are set to the maximum value supported by
        %   their data type.
        Operation;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as first
        %   input'} | 'Custom'].
        OutputDataType;

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
