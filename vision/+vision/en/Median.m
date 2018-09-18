classdef Median< dsp.private.MedianBase
%Median Median values
%   HMDN = vision.Median returns a System object, HMDN, that computes the
%   median of the input or a sequence of inputs.
%
%   HMDN = vision.Median('PropertyName',PropertyValue, ...) returns a
%   median System object, HMDN, with each specified property set to the
%   specified value.
%
%   Step method syntax:
%
%   Y = step(HMDN, X) computes median of input X.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   Median methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create median object with same property values
%   isLocked - Locked status (logical)
%
%   Median properties:
%
%   SortMethod      - Sort method
%   Dimension       - Dimension to operate along
%   CustomDimension - Numerical dimension to operate along
%
%   This System object supports fixed-point operations. For more
%   information, type vision.Median.helpFixedPoint.
%
%   % EXAMPLE: Determine the median in a grayscale image.
%      img = im2single(rgb2gray(imread('peppers.png')));
%      hmdn = vision.Median;
%      med = step(hmdn, img);
%
%   See also vision.Median.helpFixedPoint.

 
%   Copyright 2007-2016 The MathWorks, Inc.

    methods
        function out=Median
            %Median Median values
            %   HMDN = vision.Median returns a System object, HMDN, that computes the
            %   median of the input or a sequence of inputs.
            %
            %   HMDN = vision.Median('PropertyName',PropertyValue, ...) returns a
            %   median System object, HMDN, with each specified property set to the
            %   specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HMDN, X) computes median of input X.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   Median methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create median object with same property values
            %   isLocked - Locked status (logical)
            %
            %   Median properties:
            %
            %   SortMethod      - Sort method
            %   Dimension       - Dimension to operate along
            %   CustomDimension - Numerical dimension to operate along
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.Median.helpFixedPoint.
            %
            %   % EXAMPLE: Determine the median in a grayscale image.
            %      img = im2single(rgb2gray(imread('peppers.png')));
            %      hmdn = vision.Median;
            %      med = step(hmdn, img);
            %
            %   See also vision.Median.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.Median System object fixed-point
            %               information
            %   vision.Median.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.Median
            %   System object.
        end

    end
    methods (Abstract)
    end
    properties
        %Dimension Dimension to operate along
        %   Specify how the calculation is performed over the data as one of
        %   [{'All'} | 'Row' | 'Column' | 'Custom'].
        Dimension;

    end
end
