function outputImage = interp2d(inputImage,X,Y,method,fillValues)
% FOR INTERNAL USE ONLY -- This function is intentionally
% undocumented and is intended for use only within other toolbox
% classes and functions. Its behavior may change, or the feature
% itself may be removed in a future release.
%
% Vq = INTERP2D(V,XINTRINSIC,YINTRINSIC,METHOD,FILLVAL) computes 2-D
% interpolation on the input grid V at locations in the intrinsic
% coordinate system XINTRINSIC, YINTRINSIC. The value of the output grid
% Vq(I,J) is determined by performing 2-D interpolation at locations
% specified by the corresponding grid locations in XINTRINSIC(I,J),
% YINTRINSIC(I,J). XINTRINSIC and YINTRINSIC are plaid matrices of the
% form constructed by MESHGRID. When V has more than two dimensions, the
% output Vq is determined by interpolating V a slice at a time beginning at
% the 3rd dimension.
%
% See also INTERP2, MAKERESAMPLER, MESHGRID

% Copyright 2012-2014 The MathWorks, Inc.

% Algorithm Notes
%
% This function is intentionally very similar to the MATLAB INTERP2
% function. The differences between INTERP2 and images.internal.interp2d
% are:
%
% 1) Edge behavior. This function uses the 'fill' pad method described in
% the help for makeresampler. When the interpolation kernel partially
% extends beyond the grid, the output value is determined by blending fill
% values and input grid values.
%
% 2) Plane at a time behavior. When the input grid has more than 2 
% dimensions, this function treats the input grid as a stack of 2-D interpolation
% problems beginning at the 3rd dimension.
%
% 3) Degenerate 2-D grid behavior. Unlike interp2, this function handles
% input grids that are 1-by-N or N-by-1.
    
% IPP requires that X,Y,and fillVal are of same type. We enforce this for
% both codepaths for consistency of results.

switch class(inputImage)
    case 'double'
        X = double(X);
        Y = double(Y);
        fillValues = double(fillValues);
    case 'single'
        X = single(X);
        Y = single(Y);
        fillValues = single(fillValues);
    case 'uint8'
        X = single(X);
        Y = single(Y);
        fillValues = uint8(fillValues);
    otherwise
        assert('Unexpected inputImage datatype.');
end

if (~ismatrix(inputImage) && isscalar(fillValues))
    % If we are doing plane at at time behavior, make sure fillValues
    % always propogates through code as a matrix of size determine by
    % dimensions 3:end of inputImage.
    sizeInputImage = size(inputImage);
    if (ndims(inputImage)==3)
        % This must be handled as a special case because repmat(X,N)
        % replicates a scalar X as a NxN matrix. We want a Nx1 vector.
        sizeVec = [sizeInputImage(3) 1];
    else
        sizeVec = sizeInputImage(3:end);
    end
    fillValues = repmat(fillValues,sizeVec);
end

if ippl
    %inputImage = padImage(inputImage, fillValues);
        
    % We have to account for 1 vs. 0 difference in intrinsic
    % coordinate system between remapmex and MATLAB
    
    if isreal(inputImage)    
        outputImage = images.internal.remapmex(inputImage,X,Y,method,fillValues);
    else
        outputImage = complex(images.internal.remapmex(real(inputImage),X,Y,method,real(fillValues)),...
                              images.internal.remapmex(imag(inputImage),X,Y,method,imag(fillValues)));
    end                
else
    
    inputClass = class(inputImage);
    
    % Required since we allow uint8 inputs to interp2d and interp2 in
    % MATLAB does not support integer datatype inputs.
    if ~isfloat(inputImage)
        inputImage = single(inputImage);
        fillValues = cast(fillValues, 'like', inputImage);
    end
    
    % Preallocate outputImage so that we can call interp2 a plane at a time if
    % the number of dimensions in the input image is greater than 2.
    if ~ismatrix(inputImage)
        [~,~,P] = size(inputImage);
        sizeInputVec = size(inputImage);
        outputImage = zeros([size(X) sizeInputVec(3:end)],'like',inputImage);
    else
        P = 1;
        outputImage = zeros(size(X),'like',inputImage);
    end
    
    %inputImage = padImage(inputImage, fillValues);
    
    for plane = 1:P
        outputImage(:,:,plane) = interp2(inputImage(:,:,plane),X,Y,method,fillValues(plane));
    end
    
    outputImage = cast(outputImage,inputClass);

end
