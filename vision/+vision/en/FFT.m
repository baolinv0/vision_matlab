classdef FFT< matlab.system.SFunSystem
%FFT 2-D fast Fourier transform
%   fftObj = vision.FFT returns a System object, fftObj, that calculates
%   the fast Fourier transform of a two-dimensional input matrix.
%
%   fftObj = vision.FFT('PropertyName', PropertyValue, ...) configures the
%   System object properties,  specified as one or more name-value pair
%   arguments. Unspecified properties have default values.
%
%   Step method syntax:
%
%   J = step(fftObj, I) computes the 2-D FFT, J, of an M-by-N input matrix I.
%   M and N must be positive integer powers of two if any of the following
%   are true:
%      - the input is a fixed-point data type;
%      - the 'BitReversedOutput' property is true; or
%      - the 'FFTImplementation' property is 'Radix-2'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   FFT methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D fast Fourier transform object with same property
%              values
%   isLocked - Locked status (logical)
%
%   FFT properties:
%
%   FFTImplementation - FFT implementation choice
%   BitReversedOutput - Enables output in bit-reversed order
%   Normalize         - Whether to divide butterfly outputs by two
%
%   This System object supports fixed-point operations when the
%   'FFTImplementation' property is set to 'Auto' or 'Radix-2'. For more
%   information, type vision.FFT.helpFixedPoint.
%
%   Example: Use 2-D FFT to view the frequency components of an image.
%   ------------------------------------------------------------------
%   fftObj = vision.FFT;               % create the object
%
%   I = im2single(imread('pout.tif')); % read in an image
%   J = step(fftObj, I);               % compute the FFT
%   J_shifted = fftshift(J);           % shift zero-frequency components to
%                                      % the center of spectrum
%   % Display original image and visualize its FFT magnitude response
%   figure; imshow(I); title('Input image, I'); 
%   figure; imshow(log(max(abs(J_shifted), 1e-6)),[]), colormap(jet(64));
%   title('Magnitude of the FFT of I');
%
%   See also vision.IFFT, vision.DCT, vision.IDCT, fft2,
%            vision.FFT.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=FFT
            %FFT 2-D fast Fourier transform
            %   fftObj = vision.FFT returns a System object, fftObj, that calculates
            %   the fast Fourier transform of a two-dimensional input matrix.
            %
            %   fftObj = vision.FFT('PropertyName', PropertyValue, ...) configures the
            %   System object properties,  specified as one or more name-value pair
            %   arguments. Unspecified properties have default values.
            %
            %   Step method syntax:
            %
            %   J = step(fftObj, I) computes the 2-D FFT, J, of an M-by-N input matrix I.
            %   M and N must be positive integer powers of two if any of the following
            %   are true:
            %      - the input is a fixed-point data type;
            %      - the 'BitReversedOutput' property is true; or
            %      - the 'FFTImplementation' property is 'Radix-2'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   FFT methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D fast Fourier transform object with same property
            %              values
            %   isLocked - Locked status (logical)
            %
            %   FFT properties:
            %
            %   FFTImplementation - FFT implementation choice
            %   BitReversedOutput - Enables output in bit-reversed order
            %   Normalize         - Whether to divide butterfly outputs by two
            %
            %   This System object supports fixed-point operations when the
            %   'FFTImplementation' property is set to 'Auto' or 'Radix-2'. For more
            %   information, type vision.FFT.helpFixedPoint.
            %
            %   Example: Use 2-D FFT to view the frequency components of an image.
            %   ------------------------------------------------------------------
            %   fftObj = vision.FFT;               % create the object
            %
            %   I = im2single(imread('pout.tif')); % read in an image
            %   J = step(fftObj, I);               % compute the FFT
            %   J_shifted = fftshift(J);           % shift zero-frequency components to
            %                                      % the center of spectrum
            %   % Display original image and visualize its FFT magnitude response
            %   figure; imshow(I); title('Input image, I'); 
            %   figure; imshow(log(max(abs(J_shifted), 1e-6)),[]), colormap(jet(64));
            %   title('Magnitude of the FFT of I');
            %
            %   See also vision.IFFT, vision.DCT, vision.IDCT, fft2,
            %            vision.FFT.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.FFT System object fixed-point 
            %               information
            %   vision.FFT.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.FFT
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
        %   Specify the accumulator data type as one of [{'Full precision'} |
        %   'Same as input' | 'Same as product' | 'Custom']. This property is
        %   applicable when the 'FFTImplementation' property is 'Auto' or
        %   'Radix-2'.
        AccumulatorDataType;

        %BitReversedOutput Enables output in bit-reversed order relative to input
        %   Designate order of output channel elements relative to order of input
        %   elements. Set this property to true to output the frequency indices
        %   in bit-reversed order. The default value of this property is false,
        %   which denotes linear ordering of frequency indices. This property is
        %   applicable when the FFTImplementation property is set to 'Auto' or
        %   'Radix-2'. When this property is true, the length of each dimension
        %   of the input must be a power of two.
        BitReversedOutput;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   AccumulatorDataType property is 'Custom' and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'. The default value of this property
        %   is numerictype([],32,30).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   OutputDataType property is 'Custom' and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'. The default value of this property
        %   is numerictype([],16,15).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ProductDataType property is 'Custom' and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'. The default value of this property
        %   is numerictype([],32,30).
        %
        %   See also numerictype.
        CustomProductDataType;

        %CustomSineTableDataType Sine table word and fraction lengths
        %   Specify the sine table fixed-point type as an auto-signed unscaled
        %   numerictype object. This property is applicable when the
        %   SineTableDataType property is 'Custom' and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'. The default value of this property
        %   is numerictype([],16).
        %
        %   See also numerictype.
        CustomSineTableDataType;

        %FFTImplementation FFT implementation choice
        %   Specify the implementation used for the FFT as one of [{'Auto'} | 
        %   'Radix-2' | 'FFTW']. When this property is set to 'Radix-2', the
        %   length of each dimension of the input must be a power of two.
        FFTImplementation;

        %Normalize Whether to divide butterfly outputs by two
        %   Set this property to true if the output of each butterfly of the FFT
        %   should be divided by two. The default value of this property is false
        %   and no scaling occurs.
        Normalize;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output data type as one of [{'Full precision'} | 'Same as
        %   input' | 'Custom']. This property is applicable when the
        %   'FFTImplementation' property is 'Auto' or 'Radix-2'.
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate']. This
        %   property is applicable when the 'FFTImplementation' property is
        %   'Auto' or 'Radix-2'.
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product data type as one of [{'Full precision'} | 'Same
        %   as input' | 'Custom']. This property is applicable when the
        %   'FFTImplementation' property is 'Auto' or 'Radix-2'.
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero']. This property
        %   is applicable when the 'FFTImplementation' property is 'Auto' or
        %   'Radix-2'.
        RoundingMethod;

        %SineTableDataType Sine table word- and fraction-length designations
        %   Specify the sine table data type as one of [ {'Same word length as
        %   input'} | 'Custom' ]. This property is applicable when the
        %   'FFTImplementation' property is 'Auto' or 'Radix-2'.
        SineTableDataType;

    end
end
