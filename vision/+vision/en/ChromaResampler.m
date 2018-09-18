classdef ChromaResampler< matlab.system.SFunSystem
%ChromaResampler Downsample or upsample chrominance components of images
%   HCHRESAMP = vision.ChromaResampler returns a chroma resampling System
%   object, HCHRESAMP, that down/up samples chroma components of a YCbCr
%   signal to reduce the bandwidth and/or storage requirements.
%
%   HCHRESAMP = vision.ChromaResampler('PropertyName', PropertyValue, ...)
%   returns a chroma resampling System object, HCHRESAMP, with each
%   specified property set to the specified value.
%
%   Step method syntax:
%
%   [Cb1, Cr1] = step(HCHRESAMP, Cb, Cr) resamples the input chrominance
%   components Cb and Cr and returns Cb1 and Cr1, as the resampled outputs.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   ChromaResampler methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create chroma resampling object with same property values
%   isLocked - Locked status (logical)
%
%   ChromaResampler properties:
%
%   Resampling                   - Resampling format
%   InterpolationFilter          - Interpolation method used to approximate
%                                  missing chrominance values
%   AntialiasingFilterSource     - Lowpass filter used to prevent aliasing
%   HorizontalFilterCoefficients - Horizontal filter coefficients
%   VerticalFilterCoefficients   - Vertical filter coefficients
%   TransposedInput              - Indicate if input data is in row-major
%                                  format
%
%   Example: Resample the chrominance components of an image.  
%   ----------------------------------------------------------
%       resampler = vision.ChromaResampler;
%       imageRGB = imread('peppers.png');
%       imageYCbCr = rgb2ycbcr(imageRGB);
%       [Cb, Cr] = step(resampler, imageYCbCr(:,:,2), imageYCbCr(:,:,3));
%
%   See also rgb2ycbcr

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=ChromaResampler
            %ChromaResampler Downsample or upsample chrominance components of images
            %   HCHRESAMP = vision.ChromaResampler returns a chroma resampling System
            %   object, HCHRESAMP, that down/up samples chroma components of a YCbCr
            %   signal to reduce the bandwidth and/or storage requirements.
            %
            %   HCHRESAMP = vision.ChromaResampler('PropertyName', PropertyValue, ...)
            %   returns a chroma resampling System object, HCHRESAMP, with each
            %   specified property set to the specified value.
            %
            %   Step method syntax:
            %
            %   [Cb1, Cr1] = step(HCHRESAMP, Cb, Cr) resamples the input chrominance
            %   components Cb and Cr and returns Cb1 and Cr1, as the resampled outputs.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   ChromaResampler methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create chroma resampling object with same property values
            %   isLocked - Locked status (logical)
            %
            %   ChromaResampler properties:
            %
            %   Resampling                   - Resampling format
            %   InterpolationFilter          - Interpolation method used to approximate
            %                                  missing chrominance values
            %   AntialiasingFilterSource     - Lowpass filter used to prevent aliasing
            %   HorizontalFilterCoefficients - Horizontal filter coefficients
            %   VerticalFilterCoefficients   - Vertical filter coefficients
            %   TransposedInput              - Indicate if input data is in row-major
            %                                  format
            %
            %   Example: Resample the chrominance components of an image.  
            %   ----------------------------------------------------------
            %       resampler = vision.ChromaResampler;
            %       imageRGB = imread('peppers.png');
            %       imageYCbCr = rgb2ycbcr(imageRGB);
            %       [Cb, Cr] = step(resampler, imageYCbCr(:,:,2), imageYCbCr(:,:,3));
            %
            %   See also rgb2ycbcr
        end

        function isInactivePropertyImpl(in) %#ok<MANU>
        end

        function setPortDataTypeConnections(in) %#ok<MANU>
        end

    end
    methods (Abstract)
    end
    properties
        %AntialiasingFilterSource Lowpass filter used to prevent aliasing
        %   Specify the lowpass filter used to prevent aliasing as one of
        %   [{'Auto'} | 'Property' | 'None']. If this property is set to
        %   'Auto', the System object uses a built-in lowpass filter. If this
        %   property is set to 'Property', the coefficients of the filters are
        %   specified by the properties HorizontalFilterCoefficients and/or
        %   VerticalFilterCoefficients. If this property is set to 'None', the
        %   System object does not filter the input signal. This property is
        %   applicable when it downsamples the chrominance values.
        AntialiasingFilterSource;

        %HorizontalFilterCoefficients Horizontal filter coefficients
        %   Specify the filter coefficients to apply to the input signal. This
        %   property is applicable when the Resampling property is one of
        %   ['4:4:4 to 4:2:2' | '4:4:4 to 4:2:0 (MPEG1)' | '4:4:4 to 4:2:0
        %   (MPEG2)' | '4:4:4 to 4:1:1'] and the AntialiasingFilterSource
        %   property is 'Property'. The default value of this
        %   property is [0.2 0.6 0.2].
        HorizontalFilterCoefficients;

        %InterpolationFilter Interpolation method used to approximate missing
        %                    chrominance values
        %   Specify the interpolation method used to approximate the missing
        %   chrominance values as one of ['Pixel replication' | {'Linear'}]. If
        %   this property is set to 'Linear', the System object uses linear
        %   interpolation to calculate the missing values. If this property is
        %   set to 'Pixel replication', the System object replicates the
        %   chrominance values of the neighboring pixels to create the
        %   upsampled image. This property is applicable when it upsamples the
        %   chrominance values.
        InterpolationFilter;

        %Resampling Resampling format
        %   Specify the resampling format as one of 
        %   [{'4:4:4 to 4:2:2'} |
        %     '4:4:4 to 4:2:0 (MPEG1)' | 
        %     '4:4:4 to 4:2:0 (MPEG2)' | 
        %     '4:4:4 to 4:1:1' | 
        %     '4:2:2 to 4:2:0 (MPEG1)' | 
        %     '4:2:2 to 4:2:0 (MPEG2)' | 
        %     '4:2:2 to 4:4:4' |
        %     '4:2:0 (MPEG1) to 4:4:4' | 
        %     '4:2:0 (MPEG2) to 4:4:4' |
        %     '4:1:1 to 4:4:4' | 
        %     '4:2:0 (MPEG1) to 4:2:2' | 
        %     '4:2:0 (MPEG2) to 4:2:2'].
        %   If this property is set to the first six formats listed above, it
        %   downsamples the chrominance components of images. Otherwise, it
        %   upsamples the chrominance values.
        Resampling;

        %TransposedInput Indicate if input data is in row-major format 
        %   Set this property to true when the input buffer contains data
        %   elements from the first row first, then data elements from the
        %   second row second, and so on through the last row. Otherwise, the
        %   System object assumes that the input data is stored in column-major
        %   format. The default value of this property is false.
        TransposedInput;

        %VerticalFilterCoefficients Vertical filter coefficients
        %   Specify the filter coefficients to apply to the input signal. This
        %   property is applicable when the Resampling property is one of
        %   ['4:4:4 to 4:2:0 (MPEG1)' | '4:4:4 to 4:2:0 (MPEG2)' | '4:2:2 to
        %   4:2:0 (MPEG1)' | '4:2:2 to 4:2:0 (MPEG2)'] and the
        %   AntialiasingFilterSource property is 'Property'. The default value
        %   of this property is [0.5 0.5].
        VerticalFilterCoefficients;

    end
end
