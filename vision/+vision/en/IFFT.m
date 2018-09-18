classdef IFFT< matlab.system.SFunSystem
%IFFT 2-D inverse fast Fourier transform
%   HIFFT = vision.IFFT returns a System object, HIFFT, that calculates
%   the inverse fast Fourier transform of a two-dimensional input matrix.
%
%   HIFFT = vision.IFFT('PropertyName', PropertyValue, ...) returns a
%   two-dimensional inverse fast Fourier transform (2-D IFFT) System
%   object, HIFFT, with each specified property set to the specified
%   value.
%
%   Step method syntax:
%
%   Y = step(HIFFT, X) computes the 2-D IFFT, Y, of an M-by-N input matrix
%   X. M and N must be positive integer powers of two if any of the
%   following are true:
%   * the input is a fixed-point data type;
%   * the 'BitReversedInput' property is true; or
%   * the 'FFTImplementation' property is 'Radix-2'.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   IFFT methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D inverse fast Fourier transform object with same
%              property values
%   isLocked - Locked status (logical)
%
%   IFFT properties:
%
%   FFTImplementation       - FFT implementation choice
%   BitReversedInput        - Specifies bit-reversed order of input
%                             elements
%   ConjugateSymmetricInput - Specifies conjugate symmetric input
%   Normalize               - Divide output by FFT length
%
%   This System object supports fixed-point operations when the
%   ConjugateSymmetricInput property is false and the 'FFTImplementation'
%   property is set to 'Auto' or 'Radix-2'. For more information, type
%   vision.IFFT.helpFixedPoint.
%
%   % EXAMPLE: Use the 2-D IFFT System object to convert an intensity image 
%   %          from frequency to spatial domain.
%      % Create the System objects
%      hfft = vision.FFT;
%      hifft = vision.IFFT;
%      % Read in the image
%      xorig = single(imread('cameraman.tif'));
%      % Convert the image from the spatial to frequency domain and back
%      Y = step(hfft, xorig);
%      xtran = step(hifft, Y);
%      % Display the newly generated intensity image
%      imshow(abs(xtran), []);
%
%   See also vision.FFT, vision.DCT, vision.IDCT,
%            vision.IFFT.helpFixedPoint.

 
%   Copyright 2008-2016 The MathWorks, Inc.

    methods
        function out=IFFT
            %IFFT 2-D inverse fast Fourier transform
            %   HIFFT = vision.IFFT returns a System object, HIFFT, that calculates
            %   the inverse fast Fourier transform of a two-dimensional input matrix.
            %
            %   HIFFT = vision.IFFT('PropertyName', PropertyValue, ...) returns a
            %   two-dimensional inverse fast Fourier transform (2-D IFFT) System
            %   object, HIFFT, with each specified property set to the specified
            %   value.
            %
            %   Step method syntax:
            %
            %   Y = step(HIFFT, X) computes the 2-D IFFT, Y, of an M-by-N input matrix
            %   X. M and N must be positive integer powers of two if any of the
            %   following are true:
            %   * the input is a fixed-point data type;
            %   * the 'BitReversedInput' property is true; or
            %   * the 'FFTImplementation' property is 'Radix-2'.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   IFFT methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D inverse fast Fourier transform object with same
            %              property values
            %   isLocked - Locked status (logical)
            %
            %   IFFT properties:
            %
            %   FFTImplementation       - FFT implementation choice
            %   BitReversedInput        - Specifies bit-reversed order of input
            %                             elements
            %   ConjugateSymmetricInput - Specifies conjugate symmetric input
            %   Normalize               - Divide output by FFT length
            %
            %   This System object supports fixed-point operations when the
            %   ConjugateSymmetricInput property is false and the 'FFTImplementation'
            %   property is set to 'Auto' or 'Radix-2'. For more information, type
            %   vision.IFFT.helpFixedPoint.
            %
            %   % EXAMPLE: Use the 2-D IFFT System object to convert an intensity image 
            %   %          from frequency to spatial domain.
            %      % Create the System objects
            %      hfft = vision.FFT;
            %      hifft = vision.IFFT;
            %      % Read in the image
            %      xorig = single(imread('cameraman.tif'));
            %      % Convert the image from the spatial to frequency domain and back
            %      Y = step(hfft, xorig);
            %      xtran = step(hifft, Y);
            %      % Display the newly generated intensity image
            %      imshow(abs(xtran), []);
            %
            %   See also vision.FFT, vision.DCT, vision.IDCT,
            %            vision.IFFT.helpFixedPoint.
        end

        function helpFixedPoint(in) %#ok<MANU>
            %helpFixedPoint Display vision.IFFT System object fixed-point 
            %               information
            %   vision.IFFT.helpFixedPoint displays information about
            %   fixed-point properties and operations of the vision.IFFT
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
        %   applicable when the ConjugateSymmetricInput property is false and the
        %   'FFTImplementation' property is 'Auto' or 'Radix-2'.
        AccumulatorDataType;

        %BitReversedInput Indicates whether input is in bit-reversed order
        %   Set this property to true if the order of 2-D FFT transformed input
        %   elements to the 2-D IFFT System object are in bit-reversed order. The
        %   default value of this property is false, which denotes linear
        %   ordering. This property is applicable when the FFTImplementation
        %   property is set to 'Auto' or 'Radix-2'. When this property is true,
        %   the length of each dimension of the input must be a power of two.
        BitReversedInput;

        %ConjugateSymmetricInput Indicates whether input is conjugate symmetric
        %   Set this property to true if the input is conjugate symmetric to
        %   yield real-valued outputs. The 2-D FFT of a real valued signal is
        %   conjugate symmetric and setting this property to true optimizes the
        %   2-D IFFT computation method. Setting this property to false for
        %   conjugate symmetric inputs results in complex output values with
        %   small imaginary parts. Setting this property to true for non
        %   conjugate symmetric inputs results in invalid outputs. This property
        %   must be set to false for fixed-point inputs. The default value of
        %   this property is true.
        ConjugateSymmetricInput;

        %CustomAccumulatorDataType Accumulator word and fraction lengths
        %   Specify the accumulator fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ConjugateSymmetricInput property is false, the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2', and the AccumulatorDataType property
        %   is 'Custom'. The default value of this property is
        %   numerictype([],32,30).
        %
        %   See also numerictype.
        CustomAccumulatorDataType;

        %CustomOutputDataType Output word and fraction lengths
        %   Specify the output fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ConjugateSymmetricInput property is false, the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2', and the OutputDataType property is
        %   'Custom'. The default value of this property is
        %   numerictype([],16,15).
        %
        %   See also numerictype.
        CustomOutputDataType;

        %CustomProductDataType Product word and fraction lengths
        %   Specify the product fixed-point type as an auto-signed scaled
        %   numerictype object. This property is applicable when the
        %   ConjugateSymmetricInput property is false, the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2', and the ProductDataType property is
        %   'Custom'. The default value of this property is numerictype([],32,30)
        %
        %   See also numerictype.
        CustomProductDataType;

        %CustomSineTableDataType Sine table word and fraction lengths
        %   Specify the sine table fixed-point type as an auto-signed unscaled
        %   numerictype object. This property is applicable when the
        %   ConjugateSymmetricInput property is false, the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2', and the SineTableDataType property
        %   is 'Custom'. The default value of this property is
        %   numerictype([],16).
        %
        %   See also numerictype.
        CustomSineTableDataType;

        %FFTImplementation FFT implementation choice
        %   Specify the implementation used for the FFT as one of [{'Auto'} | 
        %   'Radix-2' | 'FFTW']. When this property is set to 'Radix-2', the
        %   length of each dimension of the input must be a power of two.
        FFTImplementation;

        %Normalize Divide output by FFT length
        %   Specify if the 2-D IFFT output should be divided by the FFT length.
        %   The default value of this property is true which denotes that the
        %   output is divided by the FFT length.
        Normalize;

        %OutputDataType Output word- and fraction-length designations
        %   Specify the output data type as one of [{'Full precision'} | 'Same as
        %   input' | 'Custom']. This property is applicable when the
        %   ConjugateSymmetricInput property is false and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'.
        OutputDataType;

        %OverflowAction Overflow action for fixed-point operations
        %   Specify the overflow action as one of [{'Wrap'} | 'Saturate']. This
        %   property is applicable when the ConjugateSymmetricInput property is
        %   false and the 'FFTImplementation' property is 'Auto' or 'Radix-2'.
        OverflowAction;

        %ProductDataType Product word- and fraction-length designations
        %   Specify the product data type as one of [{'Full precision'} | 'Same
        %   as input' | 'Custom']. This property is applicable when the
        %   ConjugateSymmetricInput property is false and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'.
        ProductDataType;

        %RoundingMethod Rounding method for fixed-point operations
        %   Specify the rounding method as one of ['Ceiling' | 'Convergent' |
        %   {'Floor'} | 'Nearest' | 'Round' | 'Simplest' | 'Zero']. This property
        %   is applicable when the ConjugateSymmetricInput property is false and
        %   the 'FFTImplementation' property is 'Auto' or 'Radix-2'.
        RoundingMethod;

        %SineTableDataType Sine table word- and fraction-length designations
        %   Specify the sine table data type as one of [{'Same word length as
        %   input'} | 'Custom']. This property is applicable when the
        %   ConjugateSymmetricInput property is false and the 'FFTImplementation'
        %   property is 'Auto' or 'Radix-2'.
        SineTableDataType;

    end
end
