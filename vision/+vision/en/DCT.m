classdef DCT< dsp.DCT
%DCT 2-D discrete cosine transform
%   HDCT = vision.DCT returns a discrete cosine transform System object,
%   HDCT, used to compute the two-dimensional discrete cosine transform
%   (2-D DCT) of a real input signal. The number of rows and columns of the
%   input matrix must be a power of 2.
%
%   HDCT = vision.DCT('PropertyName', PropertyValue, ...) returns a
%   discrete cosine transform System object, HDCT, with each specified
%   property set to the specified value.
%
%   Step method syntax:
%
%   Y = step(HDCT, X) computes the 2-D DCT Y of input X.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   DCT methods:
%
%   step     - See above description for use of this method
%   release  - Allow property value and input characteristics changes
%   clone    - Create 2-D discrete cosine transform object with same
%              property values
%   isLocked - Locked status (logical)
%
%   DCT properties:
%
%   SineComputation - Method to compute sines and cosines
%
%   This System object supports fixed-point operations. For more
%   information, type vision.DCT.helpFixedPoint.
%
%   % EXAMPLE: Use 2-D DCT to analyze the energy content in an image. Set
%   % the DCT coefficients lower than a threshold to 0 and reconstruct the
%   % image using 2-D IDCT.
%       hdct = vision.DCT;
%       I = double(imread('cameraman.tif'));
%       J = step(hdct, I);
%       imshow(log(abs(J)),[]), colormap(jet(64)), colorbar
%
%       hidct = vision.IDCT;
%       J(abs(J) < 10) = 0;
%       It = step(hidct, J);
%       figure, imshow(I, [0 255]), title('Original image')
%       figure, imshow(It,[0 255]), title('Reconstructed image')
%
%   See also vision.IDCT.

 
%   Copyright 1995-2016 The MathWorks, Inc.

    methods
        function out=DCT
            %DCT 2-D discrete cosine transform
            %   HDCT = vision.DCT returns a discrete cosine transform System object,
            %   HDCT, used to compute the two-dimensional discrete cosine transform
            %   (2-D DCT) of a real input signal. The number of rows and columns of the
            %   input matrix must be a power of 2.
            %
            %   HDCT = vision.DCT('PropertyName', PropertyValue, ...) returns a
            %   discrete cosine transform System object, HDCT, with each specified
            %   property set to the specified value.
            %
            %   Step method syntax:
            %
            %   Y = step(HDCT, X) computes the 2-D DCT Y of input X.
            %
            %   System objects may be called directly like a function instead of using
            %   the step method. For example, y = step(obj, x) and y = obj(x) are
            %   equivalent.
            %
            %   DCT methods:
            %
            %   step     - See above description for use of this method
            %   release  - Allow property value and input characteristics changes
            %   clone    - Create 2-D discrete cosine transform object with same
            %              property values
            %   isLocked - Locked status (logical)
            %
            %   DCT properties:
            %
            %   SineComputation - Method to compute sines and cosines
            %
            %   This System object supports fixed-point operations. For more
            %   information, type vision.DCT.helpFixedPoint.
            %
            %   % EXAMPLE: Use 2-D DCT to analyze the energy content in an image. Set
            %   % the DCT coefficients lower than a threshold to 0 and reconstruct the
            %   % image using 2-D IDCT.
            %       hdct = vision.DCT;
            %       I = double(imread('cameraman.tif'));
            %       J = step(hdct, I);
            %       imshow(log(abs(J)),[]), colormap(jet(64)), colorbar
            %
            %       hidct = vision.IDCT;
            %       J(abs(J) < 10) = 0;
            %       It = step(hidct, J);
            %       figure, imshow(I, [0 255]), title('Original image')
            %       figure, imshow(It,[0 255]), title('Reconstructed image')
            %
            %   See also vision.IDCT.
        end

    end
    methods (Abstract)
    end
end
