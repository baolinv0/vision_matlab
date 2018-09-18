classdef BlockMatcher< matlab.System
%BlockMatcher Estimate motion between images or video frames
%   HBM = vision.BlockMatcher returns a System object, HBM, that estimates
%   motion between two images or two video frames using a block matching
%   method by moving a block of pixels over a search region.
%
%   HBM = vision.BlockMatcher('PropertyName', PropertyValue, ...) returns a
%   block matcher System object, HBM, with each specified property set to
%   the specified value.
%
%   Step method syntax:
%
%   VSQ = step(HBM, I) computes the motion of input image I from one video
%   frame to another, and returns VSQ as a matrix of velocity magnitudes.
%
%   V = step(HBM, I) computes the motion of input image I from one video
%   frame to another, and returns V as a complex matrix of horizontal and
%   vertical components, when the OutputValue property is 'Horizontal and
%   vertical components in complex form'.
%
%   Y = step(HBM, I, IREF) computes the motion between input image I and
%   reference image IREF when the ReferenceFrameSource property is 'Input
%   port'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   BlockMatcher methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create block matcher object with same property values
%   isLocked - Locked status (logical)
%
%   BlockMatcher properties:
%
%   ReferenceFrameSource - Source of reference frame
%   ReferenceFrameDelay  - Number of frames between reference and current
%                          frame
%   SearchMethod         - Search method for best match
%   BlockSize            - Size of block in pixels
%   Overlap              - Overlap of two subdivisions of input image in
%                          pixels
%   MaximumDisplacement  - Maximum displacement to search in pixels
%   MatchCriteria        - Match criteria between blocks
%   OutputValue          - Desired form of motion output
%
%   This System object supports fixed-point operations. For more
%   information, type vision.BlockMatcher.helpFixedPoint.
%
%   % EXAMPLE: Estimate motion using BlockMatcher
%       img1 = im2double(rgb2gray(imread('onion.png')));
%       hbm = vision.BlockMatcher( ...
%           'ReferenceFrameSource', 'Input port', 'BlockSize', [35 35]);
%       hbm.OutputValue = ...
%           'Horizontal and vertical components in complex form';
%       halphablend = vision.AlphaBlender;
%       % Offset the first image by [5 5] pixels to create second image
%       img2 = imtranslate(img1, [5 5]);
%       % Compute motion for the two images
%       motion = step(hbm, img1, img2);  
%       % Blend two images
%       img12 = step(halphablend, img2, img1);
%       % Use quiver plot to show the direction of motion on the images   
%       [X, Y] = meshgrid(1:35:size(img1, 2), 1:35:size(img1, 1));         
%       imshow(img12); hold on;
%       quiver(X(:), Y(:), real(motion(:)), imag(motion(:)), 0); hold off;
%
%   See also opticalFlowHS, opticalFlowLK, opticalFlowLKDoG, 
%            opticalFlowFarneback, vision.BlockMatcher.helpFixedPoint.

 
%   Copyright 2007-2016 The MathWorks, Inc.

    methods
        function out=BlockMatcher
            %BlockMatcher Estimate motion between images or video frames
            %   HBM = vision.BlockMatcher returns a System object, HBM, that estimates
            %   motion between two images or two video frames using a block matching
            %   method by moving a block of pixels over a search region.
            %
            %   HBM = vision.BlockMatcher('PropertyName', PropertyValue, ...) returns a
            %   block matcher System object, HBM, with each specified property set to
            %   the specified value.
            %
            %   Step method syntax:
            %
            %   VSQ = step(HBM, I) computes the motion of input image I from one video
            %   frame to another, and returns VSQ as a matrix of velocity magnitudes.
            %
            %   V = step(HBM, I) computes the motion of input image I from one video
            %   frame to another, and returns V as a complex matrix of horizontal and
            %   vertical components, when the OutputValue property is 'Horizontal and
            %   vertical components in complex form'.
            %
            %   Y = step(HBM, I, IREF) computes the motion between input image I and
            %   reference image IREF when the ReferenceFrameSource property is 'Input
            %   port'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   BlockMatcher methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create block matcher object with same property values
            %   isLocked - Locked status (logical)
            %
            %   BlockMatcher properties:
            %
            %   ReferenceFrameSource - Source of reference frame
            %   ReferenceFrameDelay  - Number of frames between reference and current
            %                          frame
            %   SearchMethod         - Search method for best match
            %   BlockSize            - Size of block in pixels
            %   Overlap              - Overlap of two subdivisions of input image in
            %                          pixels
            %   MaximumDisplacement  - Maximum displacement to search in pixels
            %   MatchCriteria        - Match criteria between blocks
            %   OutputValue          - Desired form of motion output
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.BlockMatcher.helpFixedPoint.
            %
            %   % EXAMPLE: Estimate motion using BlockMatcher
            %       img1 = im2double(rgb2gray(imread('onion.png')));
            %       hbm = vision.BlockMatcher( ...
            %           'ReferenceFrameSource', 'Input port', 'BlockSize', [35 35]);
            %       hbm.OutputValue = ...
            %           'Horizontal and vertical components in complex form';
            %       halphablend = vision.AlphaBlender;
            %       % Offset the first image by [5 5] pixels to create second image
            %       img2 = imtranslate(img1, [5 5]);
            %       % Compute motion for the two images
            %       motion = step(hbm, img1, img2);  
            %       % Blend two images
            %       img12 = step(halphablend, img2, img1);
            %       % Use quiver plot to show the direction of motion on the images   
            %       [X, Y] = meshgrid(1:35:size(img1, 2), 1:35:size(img1, 1));         
            %       imshow(img12); hold on;
            %       quiver(X(:), Y(:), real(motion(:)), imag(motion(:)), 0); hold off;
            %
            %   See also opticalFlowHS, opticalFlowLK, opticalFlowLKDoG, 
            %            opticalFlowFarneback, vision.BlockMatcher.helpFixedPoint.
        end

        function getNumInputsImpl(in) %#ok<MANU>
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.BlockMatcher System object fixed-point information
            %   vision.BlockMatcher.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.BlockMatcher
            %   System object.
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function isInputComplexityLockedImpl(in) %#ok<MANU>
        end

        function isInputSizeLockedImpl(in) %#ok<MANU>
        end

        function isOutputComplexityLockedImpl(in) %#ok<MANU>
        end

        function loadObjectImpl(in) %#ok<MANU>
        end

        function resetImpl(in) %#ok<MANU>
            % reset subobjects
        end

        function saveObjectImpl(in) %#ok<MANU>
        end

        function setupImpl(in) %#ok<MANU>
            % get properties and set them
        end

        function stepImpl(in) %#ok<MANU>
        end

        function validateInputsImpl(in) %#ok<MANU>
            % Input validation
        end

    end
    methods (Abstract)
    end
    properties
        %AccumulatorDataType Accumulator word- and fraction-length designations
        %   Specify the accumulator fixed-point data type as 'Custom'.
        AccumulatorDataType;

        %BlockSize Size of block in pixels
        %   Specify the size of the block in pixels. The default value of this
        %   property is [17 17].
        BlockSize;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. The default value of this property is
        %   numerictype([],32,0).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed, unscaled
        %   numerictype object. The default value of this property is
        %   numerictype([],8).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   MatchCriteria property is 'Mean square error (MSE)' and the
        %   ProductDataType property is 'Custom'. The default value of this
        %   property is numerictype([],32,0).
        %
        %   See also numerictype.
        CustomProductDataType;

        %MatchCriteria Match criteria between blocks 
        %   Specify how the System object measures the similarity of the block
        %   of pixels between two frames or images as one of [{'Mean square
        %   error (MSE)'} | 'Mean absolute difference (MAD)'].
        MatchCriteria;

        %MaximumDisplacement Maximum displacement to search in pixels
        %   Specify the maximum number of pixels that any center pixel in a
        %   block of pixels might move, from image to image or from frame to
        %   frame. The System object uses this property to determine the size
        %   of the search region. The default value of this property is [7 7].
        MaximumDisplacement;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output fixed-point data type as 'Custom'.
        OutputDataType;

        %OutputValue Desired form of motion output
        %   Specify the desired form of motion output as one of
        %   [{'Magnitude-squared'} | 'Horizontal and vertical components in
        %   complex form'].
        OutputValue;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of ['Wrap' | {'Saturate'}].
        OverflowAction;

        %Overlap Overlap of two subdivisions of input image in pixels
        %   Specify the overlap (in pixels) of two subdivisions of the input
        %   image. The default value of this property is [0 0].
        Overlap;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product fixed-point data type as one of ['Same as
        %   input' | {'Custom'}]. This property is applicable when the
        %   MatchCriteria property is 'Mean square error (MSE)'.
        ProductDataType;

        %ReferenceFrameDelay Number of frames between reference and current 
        %                    frames
        %   Specify the number of frames between the reference frame and the
        %   current frame as a scalar integer value greater than or equal to
        %   zero. This property is applicable when the ReferenceFrameSource
        %   is 'Property'. The default value of this property is 1.
        ReferenceFrameDelay;

        %ReferenceFrameSource Source of reference frame
        %   Specify the source of the reference frame as one of ['Input port |
        %   {'Property'}]. When ReferenceFrameSource is 'Input port' a
        %   reference frame input must be specified to the step method of the
        %   System object
        ReferenceFrameSource;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero'].
        RoundingMethod;

        %SearchMethod Search method for best match
        %   Specify how to locate the block of pixels in frame k+1 that best
        %   matches the block of pixels in frame k as one of [{'Exhaustive'} |
        %   'Three-step']. 
        %   If this property is set to 'Exhaustive', the System object selects
        %   the location of the block of pixels in frame k+1 by moving the
        %   block over the search region one pixel at a time. This process is
        %   computationally expensive. 
        %   If this property is set to 'Three-step', the System object searches
        %   for the block of pixels in frame k+1 that best matches the block of
        %   pixels in frame k using a steadily decreasing step size. The System
        %   object begins with a step size approximately equal to half the
        %   maximum search range. In each step, the object compares the central
        %   point of the search region to eight search points located on the
        %   boundaries of the region and moves the central point to the search
        %   point whose values is the closest to that of the central point. The
        %   object then reduces the step size by half, and begins the process
        %   again. This option is less computationally expensive, though it
        %   might not find the optimal solution.
        SearchMethod;

    end
end
