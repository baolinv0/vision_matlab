classdef TemplateMatcher< matlab.system.SFunSystem
%TemplateMatcher Locate template in image
%   HTM = vision.TemplateMatcher returns a template matcher System object,
%   HTM, that finds the best match of a template within an input image.
%
%   HTM = vision.TemplateMatcher('PropertyName', PropertyValue, ...)
%   returns a template matcher object, HTM, with each specified property
%   set to the specified value.
%
%   Step method syntax:
%
%   LOC = step(HTM, I, T) computes the [x y] location coordinates, LOC,
%   of the best template match relative to the top left corner of the image
%   between the image matrix, I, and the template matrix, T. The object
%   computes the location by shifting the template in single-pixel
%   increments throughout the interior of the image.
%
%   METRIC = step(HTM, I, T) computes the match metric values for image, I,
%   with T as the template, when the OutputValue property is 'Metric
%   matrix'.
%
%   LOC = step(HTM, I, T, ROI) computes the location of the best
%   template match, LOC, in the specified region of interest, ROI, when the
%   OutputValue property is 'Best match location' and the ROIInputPort
%   property is true. ROI must be a four element vector, [x y width height],
%   where the first two elements represent the [x y] coordinates of 
%   the upper-left corner of the rectangular ROI.
%
%   [LOC, ROIVALID] = step(HTM, I, T, ROI) computes the location
%   of the best template match, LOC, in the specified region of interest,
%   ROI, and also returns a logical flag in ROIVALID indicating if the
%   specified ROI is outside the bounds of the input image I. This option
%   is applicable when the OutputValue property is 'Best match location',
%   and ROIInputPort and ROIValidityOutputPort properties are true.
%
%   [LOC, NVALS, NVALID] = step(HTM, I, T) returns the best template match,
%   LOC, the metric values around the best match, NVALS, and a logical flag,
%   NVALID. NVALID indicates, when false, that the neighborhood around the
%   best match extended outside the borders of the metric value matrix when
%   constructing NVALS. This syntax is possible when the OutputValue
%   property is 'Best match location' and the
%   BestMatchNeighborhoodOutputPort property is true.
%
%   [LOC, NVALS, NVALID, ROIVALID] = step(HTM, I, T, ROI) returns the best
%   template match, LOC, the metric values around the best match, NVALS, and
%   two logical flags, NVALID and ROIVALID. NVALID indicates, when false,
%   that the neighborhood around the best match extended outside the borders
%   of the metric value matrix when constructing NVALS. ROIVALID indicates,
%   when false, that the specified ROI is outside the bounds of the input
%   image I. This syntax is possible when the OutputValue property is 'Best
%   match location', the BestMatchNeighborhoodOutputPort property is true,
%   the ROIInputPort property is true, and the ROIValidityOutputPort
%   property is true.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   TemplateMatcher methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create template matcher object with same property values
%   isLocked - Locked status (logical)
%
%   TemplateMatcher properties:
%
%   Metric                          - Metric used for template matching
%   OutputValue                     - Type of output
%   SearchMethod                    - How to search for minimum difference
%                                     between two inputs
%   BestMatchNeighborhoodOutputPort - Enables metric values output
%   NeighborhoodSize                - Size of the metric values
%   ROIInputPort                    - Enables ROI specification via input
%   ROIValidityOutputPort           - Enables output of flag indicating if
%                                     any part of ROI is outside input
%                                     image
%
%   This System object supports fixed-point operations. For more
%   information, type vision.TemplateMatcher.helpFixedPoint.
%
%   % EXAMPLE: Find the location of a particular chip on an electronic board.
%       htm = vision.TemplateMatcher;
%       I = imread('board.tif');
%       I = I(1:200,1:200,:);    % input image
%       Igray = rgb2gray(I);     % use grayscale data for the search
%       T = Igray(20:75,90:135); % use a second similar chip as template
%
%       % find the [x y] coordinates of the chip's center
%       Loc = step(htm, Igray, T);   
%       % mark the location on the image using a red star
%       J = insertMarker(I, Loc, '*', 'Size', 15, 'Color', 'red');
%       imshow(T); title('Template');
%       figure; imshow(J); title('Marked target');
%
%   See also opticalFlowHS, opticalFlowLK, opticalFlowLKDoG, 
%            opticalFlowFarneback, insertMarker, 
%            vision.TemplateMatcher.helpFixedPoint. 

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=TemplateMatcher
            %TemplateMatcher Locate template in image
            %   HTM = vision.TemplateMatcher returns a template matcher System object,
            %   HTM, that finds the best match of a template within an input image.
            %
            %   HTM = vision.TemplateMatcher('PropertyName', PropertyValue, ...)
            %   returns a template matcher object, HTM, with each specified property
            %   set to the specified value.
            %
            %   Step method syntax:
            %
            %   LOC = step(HTM, I, T) computes the [x y] location coordinates, LOC,
            %   of the best template match relative to the top left corner of the image
            %   between the image matrix, I, and the template matrix, T. The object
            %   computes the location by shifting the template in single-pixel
            %   increments throughout the interior of the image.
            %
            %   METRIC = step(HTM, I, T) computes the match metric values for image, I,
            %   with T as the template, when the OutputValue property is 'Metric
            %   matrix'.
            %
            %   LOC = step(HTM, I, T, ROI) computes the location of the best
            %   template match, LOC, in the specified region of interest, ROI, when the
            %   OutputValue property is 'Best match location' and the ROIInputPort
            %   property is true. ROI must be a four element vector, [x y width height],
            %   where the first two elements represent the [x y] coordinates of 
            %   the upper-left corner of the rectangular ROI.
            %
            %   [LOC, ROIVALID] = step(HTM, I, T, ROI) computes the location
            %   of the best template match, LOC, in the specified region of interest,
            %   ROI, and also returns a logical flag in ROIVALID indicating if the
            %   specified ROI is outside the bounds of the input image I. This option
            %   is applicable when the OutputValue property is 'Best match location',
            %   and ROIInputPort and ROIValidityOutputPort properties are true.
            %
            %   [LOC, NVALS, NVALID] = step(HTM, I, T) returns the best template match,
            %   LOC, the metric values around the best match, NVALS, and a logical flag,
            %   NVALID. NVALID indicates, when false, that the neighborhood around the
            %   best match extended outside the borders of the metric value matrix when
            %   constructing NVALS. This syntax is possible when the OutputValue
            %   property is 'Best match location' and the
            %   BestMatchNeighborhoodOutputPort property is true.
            %
            %   [LOC, NVALS, NVALID, ROIVALID] = step(HTM, I, T, ROI) returns the best
            %   template match, LOC, the metric values around the best match, NVALS, and
            %   two logical flags, NVALID and ROIVALID. NVALID indicates, when false,
            %   that the neighborhood around the best match extended outside the borders
            %   of the metric value matrix when constructing NVALS. ROIVALID indicates,
            %   when false, that the specified ROI is outside the bounds of the input
            %   image I. This syntax is possible when the OutputValue property is 'Best
            %   match location', the BestMatchNeighborhoodOutputPort property is true,
            %   the ROIInputPort property is true, and the ROIValidityOutputPort
            %   property is true.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   TemplateMatcher methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create template matcher object with same property values
            %   isLocked - Locked status (logical)
            %
            %   TemplateMatcher properties:
            %
            %   Metric                          - Metric used for template matching
            %   OutputValue                     - Type of output
            %   SearchMethod                    - How to search for minimum difference
            %                                     between two inputs
            %   BestMatchNeighborhoodOutputPort - Enables metric values output
            %   NeighborhoodSize                - Size of the metric values
            %   ROIInputPort                    - Enables ROI specification via input
            %   ROIValidityOutputPort           - Enables output of flag indicating if
            %                                     any part of ROI is outside input
            %                                     image
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.TemplateMatcher.helpFixedPoint.
            %
            %   % EXAMPLE: Find the location of a particular chip on an electronic board.
            %       htm = vision.TemplateMatcher;
            %       I = imread('board.tif');
            %       I = I(1:200,1:200,:);    % input image
            %       Igray = rgb2gray(I);     % use grayscale data for the search
            %       T = Igray(20:75,90:135); % use a second similar chip as template
            %
            %       % find the [x y] coordinates of the chip's center
            %       Loc = step(htm, Igray, T);   
            %       % mark the location on the image using a red star
            %       J = insertMarker(I, Loc, '*', 'Size', 15, 'Color', 'red');
            %       imshow(T); title('Template');
            %       figure; imshow(J); title('Marked target');
            %
            %   See also opticalFlowHS, opticalFlowLK, opticalFlowLKDoG, 
            %            opticalFlowFarneback, insertMarker, 
            %            vision.TemplateMatcher.helpFixedPoint. 
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.TemplateMatcher System object 
            %               fixed-point information
            %   vision.TemplateMatcher.helpFixedPoint displays information about
            %   fixed-point properties and operations of the
            %   vision.TemplateMatcher System object.
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
        %   first input' | {'Custom'}].
        AccumulatorDataType;

        %BestMatchNeighborhoodOutputPort Enables metric values output
        %   Set this property to true to return two outputs, NMETRIC and NVALID.
        %   The output NMETRIC denotes an N-by-N matrix of metric values around
        %   the best match, where N is the value of the NeighborhoodSize
        %   property. The output NVALID is a logical indicating whether the
        %   object went beyond the metric matrix to construct output NMETRIC.
        %   This property is applicable when the OutputValue property is 'Best
        %   match location'. The default value of this property is false.
        BestMatchNeighborhoodOutputPort;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,0).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is applicable and is set to 'Custom'. The
        %   default value of this property is numerictype([],32,0).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed, scaled
        %   numerictype object. This property is applicable when the Metric
        %   property is 'Sum of squared differences', and the ProductDataType
        %   property is 'Custom'. The default value of this property is
        %   numerictype([],32,0).
        %
        %   See also numerictype.
        CustomProductDataType;

        %Metric Metric used for template matching
        %   Specify the metric to use for template matching as one of [{'Sum of
        %   absolute differences'} | 'Sum of squared differences' | 'Maximum
        %   absolute difference'].
        Metric;

        %NeighborhoodSize Size of the metric values
        %   Specify the size, N, of the N-by-N matrix of metric values as an odd
        %   number. For example, if the matrix size is 3-by-3 set this property
        %   to 3. This property is applicable when the OutputValue is 'Best match
        %   location' and the BestMatchNeighborhoodOutputPort property is true.
        %   The default value of this property is 3.
        NeighborhoodSize;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as one of [{'Same as first
        %   input'} | 'Custom']. This property is applicable when the OutputValue
        %   property is 'Metric matrix'. This property is also applicable when
        %   the OutputValue property is 'Best match location', and the
        %   BestMatchNeighborhoodOutputPort property is true.
        OutputDataType;

        %OutputValue Type of output
        %   Specify the output that the object should return as one of
        %   ['Metric matrix' | {'Best match location'}].
        OutputValue;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate'].
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as first
        %   input' | {'Custom'}]. This property is applicable when the Metric
        %   property is 'Sum of squared differences'.
        ProductDataType;

        %ROIInputPort Enables ROI specification via input
        %   Set this property to true to define the Region of Interest (ROI) over
        %   which to perform the template matching. If this property is set to
        %   true, the ROI is specified using an input to the step method.
        %   Otherwise the entire input image is used. The default value of this
        %   property is false.
        ROIInputPort;

        %ROIValidityOutputPort Enables output of a flag indicating if any part
        %                      of ROI is outside input image
        %   When this logical property is set to true, the object will return an ROI
        %   flag indicating, when false, that a part of the ROI is outside the
        %   input image. This property is applicable when the ROIInputPort
        %   property is true. The default value is false.
        ROIValidityOutputPort;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %SearchMethod How to search for minimum difference between two inputs
        %   Specify how the object searches for the minimum difference between
        %   the two input matrices as one of [{'Exhaustive'} | 'Three-step']. If
        %   this property is set to 'Exhaustive', the object searches for the
        %   minimum difference pixel-by-pixel. If this property is set to
        %   'Three-step', the object searches for the minimum difference using
        %   a steadily decreasing step size. The 'Three-step' method is
        %   computationally less expensive than the 'Exhaustive' method, though
        %   it might not find the optimal solution. This property is applicable
        %   when the OutputValue property is 'Best match location'.
        SearchMethod;

    end
end
