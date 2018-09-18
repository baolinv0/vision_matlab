classdef Mean< dsp.private.MeanBase
%Mean Mean value
%   HMEAN = vision.Mean returns a System object, HMEAN, that computes the
%   mean of an input or a sequence of inputs.
%
%   HMEAN = vision.Mean('PropertyName', PropertyValue, ...) returns a mean
%   System object, HMEAN, with each specified property set to the specified
%   value.
%
%   Step method syntax:
%
%   Y = step(HMEAN, X) computes mean of X. When the RunningMean property is
%   true, Y corresponds to the mean of the input elements over successive
%   calls to the step method.
%
%   Y = step(HMEAN, X, R) computes the mean value, Y, of the input elements
%   over successive calls to the step method. The object optionally resets
%   its state based on the value of reset input signal, R, and the
%   ResetCondition property. This option is available when you set both the
%   RunningMean and the ResetInputPort properties to true.
%
%   Y = step(HMEAN, X, ROI) computes the mean of input image X within the
%   given region of interest ROI when the ROIProcessing property is true
%   and the ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
%
%   Y = step(HMEAN, X, LABEL, LABELNUMBERS) computes the mean of input
%   image, X, for region whose labels are specified in vector LABELNUMBERS.
%   The regions are defined and labeled in matrix LABEL. This option is
%   available when the ROIProcessing property is true and the ROIForm
%   property is 'Label matrix'.
%
%   % [Y, FLAG] = step(HMEAN, X, ROI) also returns FLAG which indicates
%   whether the given ROI is within the image bounds when both the
%   ROIProcessing and ValidityOutputPort properties are true and the
%   ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
%
%   [Y, FLAG] = step(HMEAN, X, LABEL, LABELNUMBERS) also returns FLAG which
%   indicates whether the input label numbers are valid when both the
%   ROIProcessing and ValidityOutputPort properties are true and the
%   ROIForm property is 'Label matrix'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Mean methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create mean object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset the states of running mean
%
%   Mean properties:
%
%   RunningMean        - Calculation over successive calls to step method
%   ResetInputPort     - Enables resetting in running mean mode
%   ResetCondition     - Reset condition for running mean mode
%   Dimension          - Dimension to operate along
%   CustomDimension    - Numerical dimension to operate along
%   ROIProcessing      - Enables region of interest processing
%   ROIForm            - Type of region of interest
%   ROIPortion         - Calculate over entire ROI or just perimeter
%   ROIStatistics      - Statistics for each ROI, or one for all ROIs
%   ValidityOutputPort - Return validity check of ROI or label numbers
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Mean.helpFixedPoint.
%
%   % EXAMPLE : Determine the mean in a grayscale image.
%       img = im2single(rgb2gray(imread('peppers.png')));
%       hmean = vision.Mean;
%       m = step(hmean, img);
%
%   See also vision.Mean.helpFixedPoint.

 
%   Copyright 2007-2016 The MathWorks, Inc.

    methods
        function out=Mean
            %Mean Mean value
            %   HMEAN = vision.Mean returns a System object, HMEAN, that computes the
            %   mean of an input or a sequence of inputs.
            %
            %   HMEAN = vision.Mean('PropertyName', PropertyValue, ...) returns a mean
            %   System object, HMEAN, with each specified property set to the specified
            %   value.
            %
            %   Step method syntax:
            %
            %   Y = step(HMEAN, X) computes mean of X. When the RunningMean property is
            %   true, Y corresponds to the mean of the input elements over successive
            %   calls to the step method.
            %
            %   Y = step(HMEAN, X, R) computes the mean value, Y, of the input elements
            %   over successive calls to the step method. The object optionally resets
            %   its state based on the value of reset input signal, R, and the
            %   ResetCondition property. This option is available when you set both the
            %   RunningMean and the ResetInputPort properties to true.
            %
            %   Y = step(HMEAN, X, ROI) computes the mean of input image X within the
            %   given region of interest ROI when the ROIProcessing property is true
            %   and the ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
            %
            %   Y = step(HMEAN, X, LABEL, LABELNUMBERS) computes the mean of input
            %   image, X, for region whose labels are specified in vector LABELNUMBERS.
            %   The regions are defined and labeled in matrix LABEL. This option is
            %   available when the ROIProcessing property is true and the ROIForm
            %   property is 'Label matrix'.
            %
            %   % [Y, FLAG] = step(HMEAN, X, ROI) also returns FLAG which indicates
            %   whether the given ROI is within the image bounds when both the
            %   ROIProcessing and ValidityOutputPort properties are true and the
            %   ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
            %
            %   [Y, FLAG] = step(HMEAN, X, LABEL, LABELNUMBERS) also returns FLAG which
            %   indicates whether the input label numbers are valid when both the
            %   ROIProcessing and ValidityOutputPort properties are true and the
            %   ROIForm property is 'Label matrix'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Mean methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create mean object with same property values
            %   isLocked - Locked status (logical)
            %   reset    - Reset the states of running mean
            %
            %   Mean properties:
            %
            %   RunningMean        - Calculation over successive calls to step method
            %   ResetInputPort     - Enables resetting in running mean mode
            %   ResetCondition     - Reset condition for running mean mode
            %   Dimension          - Dimension to operate along
            %   CustomDimension    - Numerical dimension to operate along
            %   ROIProcessing      - Enables region of interest processing
            %   ROIForm            - Type of region of interest
            %   ROIPortion         - Calculate over entire ROI or just perimeter
            %   ROIStatistics      - Statistics for each ROI, or one for all ROIs
            %   ValidityOutputPort - Return validity check of ROI or label numbers
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Mean.helpFixedPoint.
            %
            %   % EXAMPLE : Determine the mean in a grayscale image.
            %       img = im2single(rgb2gray(imread('peppers.png')));
            %       hmean = vision.Mean;
            %       m = step(hmean, img);
            %
            %   See also vision.Mean.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Mean System object fixed-point 
            %               information
            %   vision.Mean.helpFixedPoint displays information about fixed-point
            %   properties and operations of the vision.Mean System object.
        end

    end
    methods (Abstract)
    end
    properties
        %Dimension Numerical dimension to operate along
        %   Specify how the mean calculation is performed over the data as one
        %   of [{'All'} | 'Row' | 'Column' | 'Custom']. This property is
        %   applicable when the RunningMean property is false.
        Dimension;

    end
end
