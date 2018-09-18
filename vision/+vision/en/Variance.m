classdef Variance< dsp.private.VarianceBase
%Variance Variance
%   HVAR = vision.Variance returns a System object, HVAR, that computes the
%   variance of an input or a sequence of inputs.
%
%   HVAR = vision.Variance('PropertyName', PropertyValue, ...) returns a
%   variance System object, HVAR, with each specified property set to the
%   specified value.
%
%   Step method syntax:
%
%   Y = step(HVAR, X) computes the variance of input X. When you set the
%   RunningVariance property to true, the object computes the variance of
%   the input elements over successive calls to the step method.
%
%   Y = step(HVAR, X, R) computes the variance, Y, of the input elements
%   over successive calls to the step method. The object optionally resets
%   its state based on the value of reset input signal, R, and the
%   ResetCondition property. This option is available when you set both the
%   RunningVariance and the ResetInputPort properties to true.
%
%   VAR2D = step(HVAR, X, ROI) computes the variance of input image X
%   within the given region of interest ROI when the ROIProcessing property
%   is true and the ROIForm property is 'Lines', 'Rectangles' or 'Binary
%   mask'.
%
%   VAR2D = step(HVAR, X, LABEL, LABELNUMBERS) computes the variance of
%   input image X for region labels contained in vector LABELNUMBERS, with
%   matrix LABEL marking pixels of different regions. This option is
%   available when the ROIProcessing property is true and the ROIForm
%   property is 'Label matrix'.
%
%   [VAR2D, FLAG] = step(HVAR, X, ROI) also returns FLAG which indicates
%   whether the given region of interest is within the image bounds when
%   both the ROIProcessing and ValidityOutputPort properties are true and
%   the ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
%
%   [VAR2D, FLAG] = step(HVAR, X, LABEL, LABELNUMBERS) also returns FLAG
%   which indicates whether the input label numbers are valid when both the
%   ROIProcessing and ValidityOutputPort properties are true and the
%   ROIForm property is 'Label matrix'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Variance methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create variance object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset the states of running variance
%
%   Variance properties:
%
%   RunningVariance    - Calculation over successive calls to step method
%   ResetInputPort     - Enables resetting in running variance mode
%   ResetCondition     - Reset condition for running variance mode
%   Dimension          - Dimension to operate along
%   CustomDimension    - Numerical dimension to operate along
%   ROIProcessing      - Enables region-of-interest processing
%   ROIForm            - Type of region of interest
%   ROIPortion         - Calculate over entire ROI or just perimeter
%   ROIStatistics      - Statistics for each ROI, or one for all ROIs
%   ValidityOutputPort - Enabled output of validity check of ROI or label
%                        numbers
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Variance.helpFixedPoint.
%
%   % EXAMPLE: Determine the variance in a grayscale image.
%      img = im2single(rgb2gray(imread('peppers.png')));
%      hvar2d = vision.Variance;
%      var2d = step(hvar2d, img);
%
%   See also vision.Variance.helpFixedPoint.

 
%   Copyright 2007-2016 The MathWorks, Inc.

    methods
        function out=Variance
            %Variance Variance
            %   HVAR = vision.Variance returns a System object, HVAR, that computes the
            %   variance of an input or a sequence of inputs.
            %
            %   HVAR = vision.Variance('PropertyName', PropertyValue, ...) returns a
            %   variance System object, HVAR, with each specified property set to the
            %   specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HVAR, X) computes the variance of input X. When you set the
            %   RunningVariance property to true, the object computes the variance of
            %   the input elements over successive calls to the step method.
            %
            %   Y = step(HVAR, X, R) computes the variance, Y, of the input elements
            %   over successive calls to the step method. The object optionally resets
            %   its state based on the value of reset input signal, R, and the
            %   ResetCondition property. This option is available when you set both the
            %   RunningVariance and the ResetInputPort properties to true.
            %
            %   VAR2D = step(HVAR, X, ROI) computes the variance of input image X
            %   within the given region of interest ROI when the ROIProcessing property
            %   is true and the ROIForm property is 'Lines', 'Rectangles' or 'Binary
            %   mask'.
            %
            %   VAR2D = step(HVAR, X, LABEL, LABELNUMBERS) computes the variance of
            %   input image X for region labels contained in vector LABELNUMBERS, with
            %   matrix LABEL marking pixels of different regions. This option is
            %   available when the ROIProcessing property is true and the ROIForm
            %   property is 'Label matrix'.
            %
            %   [VAR2D, FLAG] = step(HVAR, X, ROI) also returns FLAG which indicates
            %   whether the given region of interest is within the image bounds when
            %   both the ROIProcessing and ValidityOutputPort properties are true and
            %   the ROIForm property is 'Lines', 'Rectangles' or 'Binary mask'.
            %
            %   [VAR2D, FLAG] = step(HVAR, X, LABEL, LABELNUMBERS) also returns FLAG
            %   which indicates whether the input label numbers are valid when both the
            %   ROIProcessing and ValidityOutputPort properties are true and the
            %   ROIForm property is 'Label matrix'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Variance methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create variance object with same property values
            %   isLocked - Locked status (logical)
            %   reset    - Reset the states of running variance
            %
            %   Variance properties:
            %
            %   RunningVariance    - Calculation over successive calls to step method
            %   ResetInputPort     - Enables resetting in running variance mode
            %   ResetCondition     - Reset condition for running variance mode
            %   Dimension          - Dimension to operate along
            %   CustomDimension    - Numerical dimension to operate along
            %   ROIProcessing      - Enables region-of-interest processing
            %   ROIForm            - Type of region of interest
            %   ROIPortion         - Calculate over entire ROI or just perimeter
            %   ROIStatistics      - Statistics for each ROI, or one for all ROIs
            %   ValidityOutputPort - Enabled output of validity check of ROI or label
            %                        numbers
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Variance.helpFixedPoint.
            %
            %   % EXAMPLE: Determine the variance in a grayscale image.
            %      img = im2single(rgb2gray(imread('peppers.png')));
            %      hvar2d = vision.Variance;
            %      var2d = step(hvar2d, img);
            %
            %   See also vision.Variance.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Variance System object fixed-point
            %               information
            %   vision.Variance.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Variance
            %   System object.
        end

    end
    methods (Abstract)
    end
    properties
        %Dimension Dimension to operate along
        %   Specify how the variance calculation is performed over the data as
        %   one of [{'All'} | 'Row' | 'Column' | 'Custom']. This property is
        %   applicable when the RunningVariance property is false.
        Dimension;

    end
end
