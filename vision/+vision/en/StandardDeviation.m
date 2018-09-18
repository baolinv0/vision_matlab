classdef StandardDeviation< dsp.private.StandardDeviationBase
%StandardDeviation Standard deviation
%   HSTD = vision.StandardDeviation returns a System object, HSTD, that
%   computes the standard deviation of an input or a sequence of inputs.
%
%   HSTD = vision.StandardDeviation('PropertyName', PropertyValue, ...)
%   returns a standard deviation System object, HSTD, with each specified
%   property set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HSTD, X) computes the standard deviation of input X. It
%   computes the standard deviation, Y, of the input elements over
%   successive calls to the step method when the RunningStandardDeviation
%   property is true.
%
%   Y = step(HSTD, X, R) computes the standard deviation, Y, of the input
%   elements over successive calls to the step method. The object
%   optionally resets its state based on the value of reset input signal,
%   R, and the ResetCondition property. This option is available when you
%   set both the RunningStandardDeviation and the ResetInputPort properties
%   to true.
%
%   Y = step(HSTD, X, ROI) uses additional input ROI as the region of
%   interest when the ROIProcessing property is set to true and the ROIForm
%   property is 'Lines', 'Rectangles' or 'Binary mask'.
%
%   Y = step(HSTD, X, LABEL, LABELNUMBERS) computes the standard deviation
%   of input image X for region labels contained in vector LABELNUMBERS,
%   with matrix LABEL marking pixels of different regions. This option is
%   available when the ROIProcessing property is set to true and the
%   ROIForm property is set to 'Label matrix'.
%
%   [Y, FLAG] = step(HSTD, X, ROI) also returns FLAG which indicates
%   whether the given region of interest is within the image bounds when
%   the ValidityOutputPort property is true.
%
%   [Y, FLAG] = step(HSTD, X, LABEL, LABELNUMBERS) also returns FLAG which
%   indicates whether the input label numbers are valid when the
%   ValidityOutputPort property is true.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   StandardDeviation methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create standard deviation object with same property values
%   isLocked - Locked status (logical)
%   reset    - Resets the running standard deviation state.
%
%   StandardDeviation properties:
%
%   RunningStandardDeviation - Calculation over successive calls to step
%                              method
%   ResetInputPort           - Enables resetting in running standard
%                              deviation mode
%   ResetCondition           - Reset condition for running standard
%                              deviation mode
%   Dimension                - Dimension to operate along
%   CustomDimension          - Numerical dimension to operate along
%   ROIProcessing            - Enables region-of-interest processing
%   ROIForm                  - Type of region of interest
%   ROIPortion               - Calculate over entire ROI or just perimeter
%   ROIStatistics            - Statistics for each ROI, or one for all ROIs
%   ValidityOutputPort       - Enabled output of validity check of ROI or
%                              label numbers
%
%   % EXAMPLE: Determine the standard deviation in a grayscale image.
%      img = im2single(rgb2gray(imread('peppers.png')));
%      hstd2d = vision.StandardDeviation;
%      std = step(hstd2d,img);
%
%   See also vision.Variance.

 
%   Copyright 2007-2016 The MathWorks, Inc.

    methods
        function out=StandardDeviation
            %StandardDeviation Standard deviation
            %   HSTD = vision.StandardDeviation returns a System object, HSTD, that
            %   computes the standard deviation of an input or a sequence of inputs.
            %
            %   HSTD = vision.StandardDeviation('PropertyName', PropertyValue, ...)
            %   returns a standard deviation System object, HSTD, with each specified
            %   property set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HSTD, X) computes the standard deviation of input X. It
            %   computes the standard deviation, Y, of the input elements over
            %   successive calls to the step method when the RunningStandardDeviation
            %   property is true.
            %
            %   Y = step(HSTD, X, R) computes the standard deviation, Y, of the input
            %   elements over successive calls to the step method. The object
            %   optionally resets its state based on the value of reset input signal,
            %   R, and the ResetCondition property. This option is available when you
            %   set both the RunningStandardDeviation and the ResetInputPort properties
            %   to true.
            %
            %   Y = step(HSTD, X, ROI) uses additional input ROI as the region of
            %   interest when the ROIProcessing property is set to true and the ROIForm
            %   property is 'Lines', 'Rectangles' or 'Binary mask'.
            %
            %   Y = step(HSTD, X, LABEL, LABELNUMBERS) computes the standard deviation
            %   of input image X for region labels contained in vector LABELNUMBERS,
            %   with matrix LABEL marking pixels of different regions. This option is
            %   available when the ROIProcessing property is set to true and the
            %   ROIForm property is set to 'Label matrix'.
            %
            %   [Y, FLAG] = step(HSTD, X, ROI) also returns FLAG which indicates
            %   whether the given region of interest is within the image bounds when
            %   the ValidityOutputPort property is true.
            %
            %   [Y, FLAG] = step(HSTD, X, LABEL, LABELNUMBERS) also returns FLAG which
            %   indicates whether the input label numbers are valid when the
            %   ValidityOutputPort property is true.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   StandardDeviation methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create standard deviation object with same property values
            %   isLocked - Locked status (logical)
            %   reset    - Resets the running standard deviation state.
            %
            %   StandardDeviation properties:
            %
            %   RunningStandardDeviation - Calculation over successive calls to step
            %                              method
            %   ResetInputPort           - Enables resetting in running standard
            %                              deviation mode
            %   ResetCondition           - Reset condition for running standard
            %                              deviation mode
            %   Dimension                - Dimension to operate along
            %   CustomDimension          - Numerical dimension to operate along
            %   ROIProcessing            - Enables region-of-interest processing
            %   ROIForm                  - Type of region of interest
            %   ROIPortion               - Calculate over entire ROI or just perimeter
            %   ROIStatistics            - Statistics for each ROI, or one for all ROIs
            %   ValidityOutputPort       - Enabled output of validity check of ROI or
            %                              label numbers
            %
            %   % EXAMPLE: Determine the standard deviation in a grayscale image.
            %      img = im2single(rgb2gray(imread('peppers.png')));
            %      hstd2d = vision.StandardDeviation;
            %      std = step(hstd2d,img);
            %
            %   See also vision.Variance.
        end

    end
    methods (Abstract)
    end
    properties
        %Dimension How calculation is performed over the data
        %   Specify how the standard deviation calculation is performed over
        %   the data as one of [{'All'} | 'Row' | 'Column' | 'Custom']. This
        %   property is applicable when the RunningStandardDeviation property
        %   is false.
        Dimension;

    end
end
