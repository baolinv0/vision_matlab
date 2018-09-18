classdef Maximum< dsp.private.MaximumBase
%Maximum Maximum values
%   HMAX = vision.Maximum returns a System object, HMAX, that computes the
%   value and/or index of the maximum elements in an input or a sequence of
%   inputs.
%
%   HMAX = vision.Maximum('PropertyName', PropertyValue, ...) returns a
%   maximum System object, HMAX, with each specified property set to the
%   specified value.
%
%   Step method syntax:
%
%   [VAL, IND] = step(HMAX, X) computes maximum value, VAL, and the index or
%   position of the maximum value, IND, in each row or column of input X,
%   along vectors of a specified dimension of X, or of the entire input X,
%   depending on the value of the Dimension property.
%
%   VAL = step(HMAX, X) returns the maximum value, VAL, of the input X.
%   When the RunningMaximum property is true, VAL corresponds to the
%   maximum of the input elements over successive calls to the step method.
%
%   IND = step(HMAX, X) returns the one-based index IND of the maximum
%   value when the IndexOutputPort property is true and the ValueOutputPort
%   property is false. The RunningMaximum property must be false.
%
%   VAL = step(HMAX, X, R) computes the maximum value, VAL, of the input
%   elements over successive calls to the step method. The object
%   optionally resets its state based on the value of reset input signal,
%   R, and the ResetCondition property. This option is available when you
%   set both the RunningMaximum and the ResetInputPort properties to true.
%
%   [...] = step(HMAX, I, ROI) computes the maximum of input image, I,
%   within the given region of interest, ROI, when the ROIProcessing
%   property is true and the ROIForm property is 'Lines', 'Rectangles' or
%   'Binary mask'.
%
%   [...] = step(HMAX, I, LABEL, LABELNUMBERS) computes the maximum of
%   input image, I, for region whose labels are specified in vector
%   LABELNUMBERS. The regions are defined and labeled in matrix LABEL. This
%   option is available when the ROIProcessing property is true and the
%   ROIForm property is 'Label matrix'.
%
%   [..., FLAG] = step(HMAX, I, ROI) also returns FLAG which indicates
%   whether the given ROI is within the image bounds when both the
%   ROIProcessing and ValidityOutputPort properties are true and the
%   ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
%
%   [..., FLAG] = step(HMAX, I, LABEL, LABELNUMBERS) also returns FLAG
%   which indicates whether the input label numbers are valid when both the
%   ROIProcessing and ValidityOutputPort properties are true and the
%   ROIForm property is 'Label matrix'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Maximum methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create maximum object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset states of running maximum
%
%   Maximum properties:
%
%   ValueOutputPort    - Enables output of the maximum value
%   RunningMaximum     - Calculation over successive calls to step method
%   IndexOutputPort    - Enables output of the index of the maximum
%   ResetInputPort     - Enables resetting in running maximum mode
%   ResetCondition     - Reset condition for running maximum mode
%   Dimension          - Dimension to operate along
%   CustomDimension    - Numerical dimension to operate along
%   ROIProcessing      - Enables region of interest processing
%   ROIForm            - Type of region of interest
%   ROIPortion         - Calculate over entire ROI or just perimeter
%   ROIStatistics      - Statistics for each ROI, or one for all ROIs
%   ValidityOutputPort - Return validity check of ROI or label numbers
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Maximum.helpFixedPoint.
%
%   % EXAMPLE : Determine the maximum and its index in a grayscale image.
%       img = im2single(rgb2gray(imread('peppers.png')));
%       hmax = vision.Maximum;
%       [m, ind] = step(hmax, img);
%
%   See also vision.Maximum.helpFixedPoint.

 
%   Copyright 2004-2016 The MathWorks, Inc.

    methods
        function out=Maximum
            %Maximum Maximum values
            %   HMAX = vision.Maximum returns a System object, HMAX, that computes the
            %   value and/or index of the maximum elements in an input or a sequence of
            %   inputs.
            %
            %   HMAX = vision.Maximum('PropertyName', PropertyValue, ...) returns a
            %   maximum System object, HMAX, with each specified property set to the
            %   specified value.
            %
            %   Step method syntax:
            %
            %   [VAL, IND] = step(HMAX, X) computes maximum value, VAL, and the index or
            %   position of the maximum value, IND, in each row or column of input X,
            %   along vectors of a specified dimension of X, or of the entire input X,
            %   depending on the value of the Dimension property.
            %
            %   VAL = step(HMAX, X) returns the maximum value, VAL, of the input X.
            %   When the RunningMaximum property is true, VAL corresponds to the
            %   maximum of the input elements over successive calls to the step method.
            %
            %   IND = step(HMAX, X) returns the one-based index IND of the maximum
            %   value when the IndexOutputPort property is true and the ValueOutputPort
            %   property is false. The RunningMaximum property must be false.
            %
            %   VAL = step(HMAX, X, R) computes the maximum value, VAL, of the input
            %   elements over successive calls to the step method. The object
            %   optionally resets its state based on the value of reset input signal,
            %   R, and the ResetCondition property. This option is available when you
            %   set both the RunningMaximum and the ResetInputPort properties to true.
            %
            %   [...] = step(HMAX, I, ROI) computes the maximum of input image, I,
            %   within the given region of interest, ROI, when the ROIProcessing
            %   property is true and the ROIForm property is 'Lines', 'Rectangles' or
            %   'Binary mask'.
            %
            %   [...] = step(HMAX, I, LABEL, LABELNUMBERS) computes the maximum of
            %   input image, I, for region whose labels are specified in vector
            %   LABELNUMBERS. The regions are defined and labeled in matrix LABEL. This
            %   option is available when the ROIProcessing property is true and the
            %   ROIForm property is 'Label matrix'.
            %
            %   [..., FLAG] = step(HMAX, I, ROI) also returns FLAG which indicates
            %   whether the given ROI is within the image bounds when both the
            %   ROIProcessing and ValidityOutputPort properties are true and the
            %   ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
            %
            %   [..., FLAG] = step(HMAX, I, LABEL, LABELNUMBERS) also returns FLAG
            %   which indicates whether the input label numbers are valid when both the
            %   ROIProcessing and ValidityOutputPort properties are true and the
            %   ROIForm property is 'Label matrix'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Maximum methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create maximum object with same property values
            %   isLocked - Locked status (logical)
            %   reset    - Reset states of running maximum
            %
            %   Maximum properties:
            %
            %   ValueOutputPort    - Enables output of the maximum value
            %   RunningMaximum     - Calculation over successive calls to step method
            %   IndexOutputPort    - Enables output of the index of the maximum
            %   ResetInputPort     - Enables resetting in running maximum mode
            %   ResetCondition     - Reset condition for running maximum mode
            %   Dimension          - Dimension to operate along
            %   CustomDimension    - Numerical dimension to operate along
            %   ROIProcessing      - Enables region of interest processing
            %   ROIForm            - Type of region of interest
            %   ROIPortion         - Calculate over entire ROI or just perimeter
            %   ROIStatistics      - Statistics for each ROI, or one for all ROIs
            %   ValidityOutputPort - Return validity check of ROI or label numbers
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Maximum.helpFixedPoint.
            %
            %   % EXAMPLE : Determine the maximum and its index in a grayscale image.
            %       img = im2single(rgb2gray(imread('peppers.png')));
            %       hmax = vision.Maximum;
            %       [m, ind] = step(hmax, img);
            %
            %   See also vision.Maximum.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Maximum System object fixed-point
            %               information
            %   vision.Maximum.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Maximum
            %   System object.
        end

    end
    methods (Abstract)
    end
    properties
        %Dimension Dimension to operate along
        %   Specify how the maximum calculation is performed over the data as
        %   one of [{'All'} | 'Row' | 'Column' | 'Custom']. This property is
        %   applicable when the RunningMaximum property is false.
        Dimension;

    end
end
