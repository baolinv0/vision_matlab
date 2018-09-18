classdef LocalMaximaFinder< matlab.system.SFunSystem
%LocalMaximaFinder Local maxima
%   HFINDMAX = vision.LocalMaximaFinder returns a local maxima finder
%   System object, HFINDMAX, that finds local maxima in input matrices.
%
%   HFINDMAX = vision.LocalMaximaFinder('PropertyName', PropertyValue, ...)
%   returns a local maxima finder object, HFINDMAX, with each specified
%   property set to the specified value.
%
%   HFINDMAX = vision.LocalMaximaFinder(MAXNUM, NEIGHBORSIZE,
%   'PropertyName', PropertyValue, ...) returns a local maxima finder
%   object, HFINDMAX, with the MaximumNumLocalMaxima property set to
%   MAXNUM, NeighborhoodSize property set to NEIGHBORSIZE, and other
%   specified properties set to the specified values.
%
%   Step method syntax:
%
%   IDX = step(HFINDMAX, I) returns [x y] coordinates of the local maxima
%   in an M-by-2 matrix, IDX, where M is the number of local maxima found.
%   Note that the maximum value of M is bound by the MaximumNumLocalMaxima
%   property.    
%
%   [...] = step(HFINDMAX, I, THRESH) finds the local maxima in input image
%   I, using threshold value THRESH, when the ThresholdSource property is
%   'Input port'.
%
%   When the HoughMatrixInput property is true, the System object assumes
%   that the input matrix is a Hough matrix. Additional processing,
%   specific to Hough transform, is applied on right and left boundaries of
%   the input matrix.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   LocalMaximaFinder methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create local maxima finder object with same property values
%   isLocked - Locked status (logical)
%
%   LocalMaximaFinder properties:
%
%   MaximumNumLocalMaxima - Maximum number of maxima to find
%   NeighborhoodSize      - Neighborhood size for zero-ing out values
%   ThresholdSource       - Source of threshold
%   Threshold             - Value that all maxima should match or exceed
%   HoughMatrixInput      - Set to true if input is a Hough Transform matrix
%   IndexDataType         - Data type of index values
%
%   % EXAMPLE: Find a local maxima in an input.
%   %---------    
%      I = [0 0 0 0 0 0 0 0 0 0 0 0; ...
%           0 0 0 1 1 2 3 2 1 1 0 0; ...
%           0 0 0 1 2 3 4 3 2 1 0 0; ...
%           0 0 0 1 3 5 7 5 3 1 0 0; ... % local max at x=7, y=4
%           0 0 0 1 2 3 4 3 2 1 0 0; ...
%           0 0 0 1 1 2 3 2 1 1 0 0; ...
%           0 0 0 0 0 0 0 0 0 0 0 0];    
%
%      hLocalMax = vision.LocalMaximaFinder;
%      hLocalMax.MaximumNumLocalMaxima = 1;
%      hLocalMax.NeighborhoodSize = [3 3];
%      hLocalMax.Threshold = 1;
%
%      location = step(hLocalMax, I)
%
%   See also hough, houghlines, vision.Maximum.

 
%   Copyright 2009-2016 The MathWorks, Inc.

    methods
        function out=LocalMaximaFinder
            %LocalMaximaFinder Local maxima
            %   HFINDMAX = vision.LocalMaximaFinder returns a local maxima finder
            %   System object, HFINDMAX, that finds local maxima in input matrices.
            %
            %   HFINDMAX = vision.LocalMaximaFinder('PropertyName', PropertyValue, ...)
            %   returns a local maxima finder object, HFINDMAX, with each specified
            %   property set to the specified value.
            %
            %   HFINDMAX = vision.LocalMaximaFinder(MAXNUM, NEIGHBORSIZE,
            %   'PropertyName', PropertyValue, ...) returns a local maxima finder
            %   object, HFINDMAX, with the MaximumNumLocalMaxima property set to
            %   MAXNUM, NeighborhoodSize property set to NEIGHBORSIZE, and other
            %   specified properties set to the specified values.
            %
            %   Step method syntax:
            %
            %   IDX = step(HFINDMAX, I) returns [x y] coordinates of the local maxima
            %   in an M-by-2 matrix, IDX, where M is the number of local maxima found.
            %   Note that the maximum value of M is bound by the MaximumNumLocalMaxima
            %   property.    
            %
            %   [...] = step(HFINDMAX, I, THRESH) finds the local maxima in input image
            %   I, using threshold value THRESH, when the ThresholdSource property is
            %   'Input port'.
            %
            %   When the HoughMatrixInput property is true, the System object assumes
            %   that the input matrix is a Hough matrix. Additional processing,
            %   specific to Hough transform, is applied on right and left boundaries of
            %   the input matrix.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   LocalMaximaFinder methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create local maxima finder object with same property values
            %   isLocked - Locked status (logical)
            %
            %   LocalMaximaFinder properties:
            %
            %   MaximumNumLocalMaxima - Maximum number of maxima to find
            %   NeighborhoodSize      - Neighborhood size for zero-ing out values
            %   ThresholdSource       - Source of threshold
            %   Threshold             - Value that all maxima should match or exceed
            %   HoughMatrixInput      - Set to true if input is a Hough Transform matrix
            %   IndexDataType         - Data type of index values
            %
            %   % EXAMPLE: Find a local maxima in an input.
            %   %---------    
            %      I = [0 0 0 0 0 0 0 0 0 0 0 0; ...
            %           0 0 0 1 1 2 3 2 1 1 0 0; ...
            %           0 0 0 1 2 3 4 3 2 1 0 0; ...
            %           0 0 0 1 3 5 7 5 3 1 0 0; ... % local max at x=7, y=4
            %           0 0 0 1 2 3 4 3 2 1 0 0; ...
            %           0 0 0 1 1 2 3 2 1 1 0 0; ...
            %           0 0 0 0 0 0 0 0 0 0 0 0];    
            %
            %      hLocalMax = vision.LocalMaximaFinder;
            %      hLocalMax.MaximumNumLocalMaxima = 1;
            %      hLocalMax.NeighborhoodSize = [3 3];
            %      hLocalMax.Threshold = 1;
            %
            %      location = step(hLocalMax, I)
            %
            %   See also hough, houghlines, vision.Maximum.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function setPortDataTypeConnections(in) %#ok<MANU>
            % only want the connection for floating-point
        end

    end
    methods (Abstract)
    end
    properties
        %HoughMatrixInput Indicator of Hough Transform matrix input
        %   Set this property to true if the input is antisymmetric about the rho
        %   axis and the theta value ranges from -pi/2 to pi/2 radians, which
        %   correspond to a Hough matrix. The default value of this property is
        %   false.
        HoughMatrixInput;

        %IndexDataType Data type of index values
        %   Specify the data type of index values as one of ['double' | 'single'
        %   | 'uint8' | 'uint16' | {'uint32'}].
        IndexDataType;

        %MaximumNumLocalMaxima Maximum number of maxima to find
        %   Specify the maximum number of maxima to find as a positive scalar
        %   integer value. The default value of this property is 2.
        MaximumNumLocalMaxima;

        %NeighborhoodSize Neighborhood size for zero-ing out values
        %   Specify the size of the neighborhood around the maxima, over which
        %   the System object zeros out values, as a 2-element vector of positive
        %   odd integers. The default value of this property is [5 7].
        NeighborhoodSize;

        %Threshold Value that all maxima should match or exceed
        %   Specify the threshold value as a scalar of MATLAB built-in numeric
        %   data type. The default value of this property is 10. This property is
        %   applicable when ThresholdSource property is set to 'Property'. This
        %   property is tunable.
        Threshold;

        %ThresholdSource Source of threshold
        %   Specify how to enter the threshold value as one of [{'Property'} |
        %   'Input port'].
        ThresholdSource;

    end
end
