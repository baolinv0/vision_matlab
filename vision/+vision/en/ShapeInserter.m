classdef ShapeInserter< matlab.system.SFunSystem
%ShapeInserter Draw rectangles, lines, polygons, or circles on images
%   The vision.ShapeInserter System object (TM) will be removed in a
%   future release. Use the insertShape function instead.
%
%   The ShapeInserter object can draw multiple rectangles, lines, polygons,
%   or circles in a 2-D grayscale or truecolor RGB image. The output image
%   can then be displayed or saved to a file.
%
%   shapeInserter = vision.ShapeInserter returns a System object,
%   shapeInserter. Invoking this object's step method, described below,
%   draws rectangles in an image. The location of where the rectangle is
%   drawn, its size and other characteristics are determined by the
%   properties described below. To draw other shapes you can change the
%   Shape property of the object.
%
%   shapeInserter = vision.ShapeInserter(...,'Name', 'Value') configures
%   the shape inserter properties, specified as one or more name-value pair
%   arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   J = step(shapeInserter, I, PTS) draws the shape specified in Shape
%   property on image I and returns the result in image J. The shape is
%   drawn at location PTS described below:
%
%    Shape property                       PTS
%    --------------  -----------------------------------------------------
%     'Rectangles'   M-by-4 matrix where each row specifies a rectangle as
%                    [x y width height]. [x y] determine the upper-left
%                    corner of the rectangle.
%
%     'Lines'        M-by-2L matrix where each row specifies a polyline
%                    as a series of consecutive point locations, 
%                    [x1,y1,x2,y2...xL,yL].
%
%     'Polygons'     M-by-2L matrix where each row specifies a polygon as
%                    an array of consecutive points, [x1,y1,x2,y2...xL,yL],
%                    defining polygon vertices.
%
%                    
%     'Circles'      M-by-3 matrix where each row specifies a circle as
%                    [x y radius], where [x y] are the coordinates of the
%                    center .
%
%   J = step(shapeInserter, I, PTS, ROI) draws a shape only inside an area
%   defined by an ROI, when the ROIInputPort property is true. The ROI 
%   defines a rectangular area as [x y width height], where [x y] is the 
%   upper-left corner of the region.
%
%   J = step(shapeInserter, I, PTS, ..., CLR) uses the border or fill color
%   CLR to draw the border or to fill the specified shape, when the
%   BorderColorSource property or the FillColorSource property is 'Input
%   port'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   ShapeInserter methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create shape inserter object with same property values
%   isLocked - Locked status (logical)
%
%   ShapeInserter properties:
%
%   Shape             - Shape to draw
%   Fill              - Enables filling of the shape
%   LineWidth         - Line width of shape
%   BorderColorSource - Source of border color
%   BorderColor       - Border color of shape
%   CustomBorderColor - Intensity or color value for shape's border
%   FillColorSource   - Source of fill color
%   FillColor         - Fill color of shape
%   CustomFillColor   - Intensity or color value for shape's interior
%   Opacity           - Opacity of the shading inside shape
%   ROIInputPort      - Enables region of interest for drawing shapes via input
%   Antialiasing      - Smooth shape edges
%
%   This System object supports fixed-point operations. For more
%   information, type vision.ShapeInserter.helpFixedPoint.
%
%   EXAMPLE 1: Draw black rectangle in grayscale image
%   --------------------------------------------------
%   shapeInserter = vision.ShapeInserter;
%   I = imread('cameraman.tif');
%   rectangle = int32([10 10 30 30]); % [x y width height]
%   J = step(shapeInserter, I, rectangle);
%   imshow(J);
%
%   EXAMPLE 2: Draw two yellow circles in grayscale image
%   -----------------------------------------------------
%   yellow = uint8([255 255 0]); % [R G B]; class of yellow must match class of I
%   shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor',...
%                    'Custom', 'CustomBorderColor', yellow);
%   I = imread('cameraman.tif');
%   circles = int32([30 30 20; ...  % [x1 y1 radius1]
%                    80 80 25]);    % [x2 y2 radius2]
%   RGB = repmat(I,[1,1,3]); % convert I to an RGB image
%   J = step(shapeInserter, RGB, circles);
%   imshow(J);
%
%   EXAMPLE 3: Draw a red triangle in a color image
%   -----------------------------------------------
%   shapeInserter = vision.ShapeInserter('Shape','Polygons','BorderColor',...
%                   'Custom', 'CustomBorderColor', uint8([255 0 0]));
%   I = imread('autumn.tif');
%   % Define vertices which will form a triangle: [x1 y1 x2 y2 x3 y3]
%   polygon = int32([50 60 100 60 75 30]); 
%   J = step(shapeInserter, I, polygon);
%   imshow(J);
%
%   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
%      vision.ShapeInserter.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=ShapeInserter
            %ShapeInserter Draw rectangles, lines, polygons, or circles on images
            %   The vision.ShapeInserter System object (TM) will be removed in a
            %   future release. Use the insertShape function instead.
            %
            %   The ShapeInserter object can draw multiple rectangles, lines, polygons,
            %   or circles in a 2-D grayscale or truecolor RGB image. The output image
            %   can then be displayed or saved to a file.
            %
            %   shapeInserter = vision.ShapeInserter returns a System object,
            %   shapeInserter. Invoking this object's step method, described below,
            %   draws rectangles in an image. The location of where the rectangle is
            %   drawn, its size and other characteristics are determined by the
            %   properties described below. To draw other shapes you can change the
            %   Shape property of the object.
            %
            %   shapeInserter = vision.ShapeInserter(...,'Name', 'Value') configures
            %   the shape inserter properties, specified as one or more name-value pair
            %   arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   J = step(shapeInserter, I, PTS) draws the shape specified in Shape
            %   property on image I and returns the result in image J. The shape is
            %   drawn at location PTS described below:
            %
            %    Shape property                       PTS
            %    --------------  -----------------------------------------------------
            %     'Rectangles'   M-by-4 matrix where each row specifies a rectangle as
            %                    [x y width height]. [x y] determine the upper-left
            %                    corner of the rectangle.
            %
            %     'Lines'        M-by-2L matrix where each row specifies a polyline
            %                    as a series of consecutive point locations, 
            %                    [x1,y1,x2,y2...xL,yL].
            %
            %     'Polygons'     M-by-2L matrix where each row specifies a polygon as
            %                    an array of consecutive points, [x1,y1,x2,y2...xL,yL],
            %                    defining polygon vertices.
            %
            %                    
            %     'Circles'      M-by-3 matrix where each row specifies a circle as
            %                    [x y radius], where [x y] are the coordinates of the
            %                    center .
            %
            %   J = step(shapeInserter, I, PTS, ROI) draws a shape only inside an area
            %   defined by an ROI, when the ROIInputPort property is true. The ROI 
            %   defines a rectangular area as [x y width height], where [x y] is the 
            %   upper-left corner of the region.
            %
            %   J = step(shapeInserter, I, PTS, ..., CLR) uses the border or fill color
            %   CLR to draw the border or to fill the specified shape, when the
            %   BorderColorSource property or the FillColorSource property is 'Input
            %   port'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   ShapeInserter methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create shape inserter object with same property values
            %   isLocked - Locked status (logical)
            %
            %   ShapeInserter properties:
            %
            %   Shape             - Shape to draw
            %   Fill              - Enables filling of the shape
            %   LineWidth         - Line width of shape
            %   BorderColorSource - Source of border color
            %   BorderColor       - Border color of shape
            %   CustomBorderColor - Intensity or color value for shape's border
            %   FillColorSource   - Source of fill color
            %   FillColor         - Fill color of shape
            %   CustomFillColor   - Intensity or color value for shape's interior
            %   Opacity           - Opacity of the shading inside shape
            %   ROIInputPort      - Enables region of interest for drawing shapes via input
            %   Antialiasing      - Smooth shape edges
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.ShapeInserter.helpFixedPoint.
            %
            %   EXAMPLE 1: Draw black rectangle in grayscale image
            %   --------------------------------------------------
            %   shapeInserter = vision.ShapeInserter;
            %   I = imread('cameraman.tif');
            %   rectangle = int32([10 10 30 30]); % [x y width height]
            %   J = step(shapeInserter, I, rectangle);
            %   imshow(J);
            %
            %   EXAMPLE 2: Draw two yellow circles in grayscale image
            %   -----------------------------------------------------
            %   yellow = uint8([255 255 0]); % [R G B]; class of yellow must match class of I
            %   shapeInserter = vision.ShapeInserter('Shape','Circles','BorderColor',...
            %                    'Custom', 'CustomBorderColor', yellow);
            %   I = imread('cameraman.tif');
            %   circles = int32([30 30 20; ...  % [x1 y1 radius1]
            %                    80 80 25]);    % [x2 y2 radius2]
            %   RGB = repmat(I,[1,1,3]); % convert I to an RGB image
            %   J = step(shapeInserter, RGB, circles);
            %   imshow(J);
            %
            %   EXAMPLE 3: Draw a red triangle in a color image
            %   -----------------------------------------------
            %   shapeInserter = vision.ShapeInserter('Shape','Polygons','BorderColor',...
            %                   'Custom', 'CustomBorderColor', uint8([255 0 0]));
            %   I = imread('autumn.tif');
            %   % Define vertices which will form a triangle: [x1 y1 x2 y2 x3 y3]
            %   polygon = int32([50 60 100 60 75 30]); 
            %   J = step(shapeInserter, I, polygon);
            %   imshow(J);
            %
            %   See also insertText, insertShape, insertMarker, insertObjectAnnotation,
            %      vision.ShapeInserter.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.ShapeInserter System object fixed-point
            %               information
            %   vision.ShapeInserter.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.ShapeInserter
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

        %Antialiasing Smooth shape edges
        %   Set this property to true to perform a smoothing algorithm on the
        %   line, polygon, or circle. This property is applicable when the
        %   Shape property is 'Lines', 'Polygons', or 'Circles'. The default
        %   value of this property is false.
        Antialiasing;

        %BorderColor Border color of shape
        %   Specify the appearance of the shape's border as one of [{'Black'} |
        %   'White' | 'Custom']. If this property is set to 'Custom', the
        %   CustomBorderColor property is used to specify the value. This
        %   property is applicable when BorderColorSource is enabled and set to
        %   'Property' .
        BorderColor;

        %BorderColorSource Source of border color
        %   Specify how the shape's border color is provided as one of ['Input
        %   port' | {'Property'}]. This property is applicable when Shape is
        %   'Lines' or when Shape is not 'Lines' and Fill is false. When
        %   BorderColorSource is set to 'Input port', a border color vector
        %   must be provided as an input to the System object's step method.
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

        %CustomBorderColor Intensity or color value for shape's border
        %   Specify an intensity or color value for the shape's border. If the
        %   input is an intensity image, this property can be set to a scalar
        %   intensity value for one shape or R-element vector where R is the
        %   number of shapes. If the input is a color image, this property can
        %   be set to a P-element vector where P is the number of color planes
        %   or an R-by-P matrix where R is the number of shapes and P is the
        %   number of color planes. This property is applicable when the
        %   BorderColor property is 'Custom'. The default value of this property
        %   is [200 255 100].
        CustomBorderColor;

        %CustomFillColor Intensity or color value for shape's interior
        %   Specify an intensity or color value for the shape's interior. If
        %   the input is an intensity image, this property can be set to a
        %   scalar intensity value for one shape or an R-element vector where R
        %   is the number of shapes. If the input is a color image, this
        %   property can be set to a P-element vector where P is the number of
        %   color planes or an R-by-P matrix where R is the number of shapes
        %   and P is the number of color planes. This property is applicable
        %   when the FillColor property is 'Custom'. The default value of this
        %   property is [200 255 100].
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

        %Fill Enables filling of the shape
        %   Set this property to true to fill the shape with an intensity value
        %   or a color. This property is applicable when the Shape property is
        %   not 'Lines'. The default value of this property is false.
        Fill;

        %FillColor Fill color of shape
        %   Specify the intensity of the shading inside the shape as one of
        %   [{'Black'} | 'White' | 'Custom']. If this property is set to
        %   'Custom', the CustomFillColor property is used to specify the
        %   value. This property is applicable when FillColorSource is enabled
        %   and set to 'Property'.
        FillColor;

        %FillColorSource Source of fill color
        %   Specify how the shape's fill color is provided as one of ['Input
        %   port' | {'Property'}]. This property is applicable when Shape is
        %   not 'Lines' and Fill is true. When FillColorSource is set to 'Input
        %   port', a fill color vector must be provided as an input to the
        %   System object's step method.
        FillColorSource;

        %LineWidth Line width of shapes
        LineWidth;

        %Opacity Opacity of the shading inside shapes
        %   Specify the opacity of the shading inside the shape by a scalar
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

        %ROIInputPort Enables defining area for drawing shapes via input
        %   Set this property to true to define the area in which to draw the
        %   shapes via an input to the step method. The input is a four-element
        %   vector, [r c height width], where r and c are the row and column
        %   coordinates of the upper-left corner of the area, and height and
        %   width represent the height (in rows) and width (in columns) of the
        %   area. If the property is false then the entire image will be used
        %   as the area in which to draw. The default value of this property is
        %   false.
        ROIInputPort;

        %RoundingMethod  Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest'| 'Round' | 'Simplest' | 'Zero']. This
        %   property is applicable when the Fill property is true and/or the
        %   Antialiasing property is true.
        RoundingMethod;

        %Shape Shape to draw
        %   Specify the type of shape(s) to draw as one of [{'Rectangles'} |
        %   'Lines' | 'Polygons' | 'Circles'].
        Shape;

    end
end
