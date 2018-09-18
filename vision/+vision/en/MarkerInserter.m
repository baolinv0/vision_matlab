classdef MarkerInserter< matlab.system.SFunSystem
%MarkerInserter Draw image markers
%   The vision.MarkerInserter System object (TM) will be removed in a
%   future release. Use the insertMarker function instead.
%
%   The MarkerInserter object can draw markers, such as circles, x-marks,
%   plus signs, stars or rectangles in a 2-D grayscale or truecolor RGB
%   image. The output image can then be displayed or saved to a file.
%
%   markerInserter = vision.MarkerInserter returns a System object,
%   markerInserter. Invoking this object's step method, described below,
%   draws a Circle in an image. The location of where the Circle is
%   drawn, its size, and other characteristics are determined by the
%   properties described below. To draw other marker types you can change
%   the Shape property of the object.
%
%   markerInserter = vision.MarkerInserter(...,'Name', 'Value') configures
%   the shape inserter properties, specified as one or more name-value pair
%   arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   J = step(markerInserter, I, PTS) draws a marker specified by Shape 
%   property on input image I and returns the result in image J. PTS is 
%   an M-by-2 matrix where each row specifies [x y] location of the
%   marker's center.
%
%   J = step(markerInserter, I, PTS, ROI) draws a marker only inside an
%   area defined by an ROI, when the ROIInputPort property is true. The ROI
%   defines a rectangular area as [x y width height], where [x y] is the
%   upper-left corner of the region.
%
%   J = step(markerInserter, I, PTS, ..., CLR) uses the border or fill
%   color CLR to draw the border or fill the specified marker, when the
%   BorderColorSource property or the FillColorSource property is 'Input
%   port'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   MarkerInserter methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create marker inserter object with same property values
%   isLocked - Locked status (logical)
%
%   MarkerInserter properties:
%
%   Shape             - Marker to draw
%   Size              - Size of marker
%   Fill              - Enables filling marker
%   BorderColorSource - Source of border color
%   BorderColor       - Border color of marker
%   CustomBorderColor - Intensity or color value for marker's border
%   FillColorSource   - Source of fill color
%   FillColor         - Fill color of marker
%   CustomFillColor   - Intensity or color value for marker's interior
%   Opacity           - Opacity of shading inside marker
%   ROIInputPort      - Enables defining a region of interest for drawing
%                       a marker
%   Antialiasing      - Enables performing smoothing algorithm on marker
%
%   This System object supports fixed-point operations. For more
%   information, type vision.MarkerInserter.helpFixedPoint.
%
%   EXAMPLE 1: Draw white plus signs in a grayscale image
%   -----------------------------------------------------
%   markerInserter = vision.MarkerInserter('Shape','Plus',...
%           'BorderColor', 'white');
%   I = imread('cameraman.tif');
%   Pts = int32([10 10; 20 20; 30 30]);
%   J = step(markerInserter, I, Pts);
%   imshow(J);
%
%   EXAMPLE 2: Draw red circles in a grayscale image
%   ------------------------------------------------
%   red = uint8([255 0 0]);  % [R G B]; class of red must match class of I
%   markerInserter = vision.MarkerInserter('Shape','Circle',...
%      'BorderColor', 'Custom', 'CustomBorderColor', red);
%   I = imread('cameraman.tif');
%   RGB = repmat(I,[1 1 3]); % convert the image to RGB
%   Pts = int32([60 60; 80 80; 100 100]);
%   J = step(markerInserter, RGB, Pts);
%   imshow(J);
%
%   EXAMPLE 3: Draw blue X-marks in a color image
%   ---------------------------------------------
%   markerInserter = vision.MarkerInserter('Shape','X-mark',...
%      'BorderColor', 'Custom', 'CustomBorderColor', uint8([0 0 255]));
%   RGB = imread('autumn.tif');
%   Pts = int32([20 20; 40 40; 60 60]);
%   J = step(markerInserter, RGB, Pts);
%   imshow(J);
%
%   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
%      vision.MarkerInserter.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=MarkerInserter
            %MarkerInserter Draw image markers
            %   The vision.MarkerInserter System object (TM) will be removed in a
            %   future release. Use the insertMarker function instead.
            %
            %   The MarkerInserter object can draw markers, such as circles, x-marks,
            %   plus signs, stars or rectangles in a 2-D grayscale or truecolor RGB
            %   image. The output image can then be displayed or saved to a file.
            %
            %   markerInserter = vision.MarkerInserter returns a System object,
            %   markerInserter. Invoking this object's step method, described below,
            %   draws a Circle in an image. The location of where the Circle is
            %   drawn, its size, and other characteristics are determined by the
            %   properties described below. To draw other marker types you can change
            %   the Shape property of the object.
            %
            %   markerInserter = vision.MarkerInserter(...,'Name', 'Value') configures
            %   the shape inserter properties, specified as one or more name-value pair
            %   arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   J = step(markerInserter, I, PTS) draws a marker specified by Shape 
            %   property on input image I and returns the result in image J. PTS is 
            %   an M-by-2 matrix where each row specifies [x y] location of the
            %   marker's center.
            %
            %   J = step(markerInserter, I, PTS, ROI) draws a marker only inside an
            %   area defined by an ROI, when the ROIInputPort property is true. The ROI
            %   defines a rectangular area as [x y width height], where [x y] is the
            %   upper-left corner of the region.
            %
            %   J = step(markerInserter, I, PTS, ..., CLR) uses the border or fill
            %   color CLR to draw the border or fill the specified marker, when the
            %   BorderColorSource property or the FillColorSource property is 'Input
            %   port'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   MarkerInserter methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create marker inserter object with same property values
            %   isLocked - Locked status (logical)
            %
            %   MarkerInserter properties:
            %
            %   Shape             - Marker to draw
            %   Size              - Size of marker
            %   Fill              - Enables filling marker
            %   BorderColorSource - Source of border color
            %   BorderColor       - Border color of marker
            %   CustomBorderColor - Intensity or color value for marker's border
            %   FillColorSource   - Source of fill color
            %   FillColor         - Fill color of marker
            %   CustomFillColor   - Intensity or color value for marker's interior
            %   Opacity           - Opacity of shading inside marker
            %   ROIInputPort      - Enables defining a region of interest for drawing
            %                       a marker
            %   Antialiasing      - Enables performing smoothing algorithm on marker
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.MarkerInserter.helpFixedPoint.
            %
            %   EXAMPLE 1: Draw white plus signs in a grayscale image
            %   -----------------------------------------------------
            %   markerInserter = vision.MarkerInserter('Shape','Plus',...
            %           'BorderColor', 'white');
            %   I = imread('cameraman.tif');
            %   Pts = int32([10 10; 20 20; 30 30]);
            %   J = step(markerInserter, I, Pts);
            %   imshow(J);
            %
            %   EXAMPLE 2: Draw red circles in a grayscale image
            %   ------------------------------------------------
            %   red = uint8([255 0 0]);  % [R G B]; class of red must match class of I
            %   markerInserter = vision.MarkerInserter('Shape','Circle',...
            %      'BorderColor', 'Custom', 'CustomBorderColor', red);
            %   I = imread('cameraman.tif');
            %   RGB = repmat(I,[1 1 3]); % convert the image to RGB
            %   Pts = int32([60 60; 80 80; 100 100]);
            %   J = step(markerInserter, RGB, Pts);
            %   imshow(J);
            %
            %   EXAMPLE 3: Draw blue X-marks in a color image
            %   ---------------------------------------------
            %   markerInserter = vision.MarkerInserter('Shape','X-mark',...
            %      'BorderColor', 'Custom', 'CustomBorderColor', uint8([0 0 255]));
            %   RGB = imread('autumn.tif');
            %   Pts = int32([20 20; 40 40; 60 60]);
            %   J = step(markerInserter, RGB, Pts);
            %   imshow(J);
            %
            %   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
            %      vision.MarkerInserter.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.MarkerInserter System object 
            %               fixed-point information
            %   vision.MarkerInserter.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.MarkerInserter
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
        %   product'} | 'Same as first input' | 'Custom']. This property is
        %   applicable when the Fill property is true and/or the Antialiasing
        %   property is true.
        AccumulatorDataType;

        %Antialiasing Enables performing smoothing algorithm on marker
        %   Set this property to true to perform a smoothing algorithm on the
        %   marker. This property is applicable when the Shape property is not
        %   'Square' or 'Plus'. The default value of this property is false.
        Antialiasing;

        %BorderColor Border color of marker
        %   Specify the border color of the marker as one of [{'Black'} |
        %   'White' | 'Custom']. If this property is set to 'Custom', the
        %   CustomBorderColor property is used to specify the value. This
        %   property is applicable when the BorderColorSource property is
        %   enabled and set to 'Property'.
        BorderColor;

        %BorderColorSource Source of border color
        %   Specify how the marker's border color is provided as one of ['Input
        %   port' | {'Property'}]. This property is applicable either when the
        %   Shape property is 'X-mark', 'Plus', or 'Star', or when the Shape
        %   property is 'Circle' or 'Square', and the Fill property is false.
        %   When BorderColorSource is set to 'Input port', a border color
        %   vector must be provided as an input to the System object's step
        %   method.
        BorderColorSource;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the Fill
        %   property is true and/or the Antialiasing property is true, and the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,14);
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomBorderColor Intensity or color value for marker's border
        %   Specify an intensity or color value for the marker's border. If the
        %   input is an intensity image, this property can be set to a scalar
        %   intensity value for one marker or R-element vector where R is the
        %   number of markers. If the input is a color image, this property can
        %   be set to a P-element vector where P is the number of color planes
        %   or an R-by-P matrix where R is the number of markers and P is the
        %   number of color planes. This property is applicable when the
        %   BorderColor property is 'Custom'. The default value of this property
        %   is [200 120 50].
        CustomBorderColor;

        %CustomFillColor Intensity or color value for marker's interior
        %   Specify an intensity or color value to fill the marker. If the
        %   input is an intensity image, this property can be set to a scalar
        %   intensity value for one marker or R-element vector where R is the
        %   number of markers. If the input is a color image, this property can
        %   be set to a P-element vector where P is the number of color planes
        %   or an R-by-P matrix where R is the number of markers and P is the
        %   number of color planes. This property is applicable when the
        %   FillColor property is 'Custom'. The default value of this property
        %   is [200 120 50].
        CustomFillColor;

        %CustomOpacityDataType Opacity word length
        %   Specify the opacity fixed-point type as an auto-signed, unscaled
        %   numerictype object. This property is applicable when the Fill
        %   property is true and the OpacityDataType property is 'Custom'. The
        %   default value of this property is numerictype([],16);
        %
        %   See also numerictype.
        CustomOpacityDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the Fill
        %   property is true and/or the Antialiasing property is true, and the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,14);
        %
        %   See also numerictype.
        CustomProductDataType;

        %Fill Enables filling marker
        %   Set this property to true to fill the marker with an intensity
        %   value or a color. This property is applicable when the Shape
        %   property is 'Circle' or 'Square'. The default value of this
        %   property is false.
        Fill;

        %FillColor Fill color of marker
        %   Specify the color to fill the marker as one of [{'Black'} | 'White'
        %   | 'Custom' |]. If this property is set to 'Custom', the
        %   CustomFillColor property is used to specify the value. This
        %   property is applicable when the FillColorSource property is enabled
        %   and set to 'Property'.
        FillColor;

        %FillColorSource Source of fill color
        %   Specify how the marker's fill color is provided as one of ['Input
        %   port' | {'Property'}]. This property is applicable when the Shape
        %   property is 'Circle' or 'Square', and the Fill property is true.
        %   When this property is set to 'Input port', a fill color vector must
        %   be provided as an input to the System object's step method.
        FillColorSource;

        %Opacity Opacity of shading inside marker
        %   Specify the opacity of the shading inside the marker by a scalar
        %   value between 0 and 1, where 0 is transparent and 1 is opaque. The
        %   default value of this property is 0.6. This property is tunable. 
        Opacity;

        %OpacityDataType Opacity word-length designations
        %   Specify the opacity fixed-point data type as one of ['Same word
        %   length as input' | {'Custom'}]. This property is applicable when
        %   the Fill property is true.
        OpacityDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate']. This
        %   property is applicable when the Fill property is true and/or the
        %   Antialiasing property is true.
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as first
        %   input' | {'Custom'}]. This property is applicable when the Fill
        %   property is true and/or the Antialiasing property is true.
        ProductDataType;

        %ROIInputPort Enables defining a region of interest for drawing a marker
        %   Set this property to true to specify a region of interest (ROI) on
        %   the input image through an input to the step method. If the
        %   property is set to false, the object uses the entire image. The
        %   default value of this property is false.
        ROIInputPort;

        %RoundingMethod  Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest'| 'Round' | 'Simplest' | 'Zero']. This
        %   property is applicable when the Fill property is true and/or the
        %   Antialiasing property is true.
        RoundingMethod;

        %Shape Shape of marker(s) to draw
        %   Specify the type of marker(s) to draw as one of [{'Circle'} |
        %   'X-mark' | 'Plus' | 'Star' | 'Square'].
        Shape;

        %Size Size of marker
        %   Specify the size of the marker, in pixels, as a scalar value
        %   greater than or equal to 1. The default value of this property is
        %   3. This property is tunable. 
        Size;

    end
end
