function out = integralFilter(intImage, kernel)
%integralFilter Filter using integral image.
%   J = integralFilter(intI, H) filters an image, given its integral image,
%   intI, and a filter H, an object of class integralKernel. 
%   integralFilter returns only the parts of correlation that are computed 
%   without padding. This results in size(J) = size(intI) - size(H)
%   for an upright filter, and size(J) = size(intI) - size(H) - [0 1] for a
%   rotated filter. This function uses correlation for filtering.
%   
%   Class Support
%   -------------
%   intI must be single or double. H must be of class integralKernel.
%
%   Example 1
%   ---------
%   % Compute vertical and horizontal edge responses of the image
%   I = imread('pout.tif');
%   intImage = integralImage(I);
%
%   % Construct Haar-like wavelet filters
%   horiH = integralKernel([1 1 4 3; 1 4 4 3], [-1, 1]); % horizontal filter
%   vertH = horiH.'; % vertical filter; note use of the dot before '
%   % visualize the horizontal filter
%   imtool(horiH.Coefficients, 'InitialMagnification','fit');
%
%   % Compute filter responses
%   horiResponse = integralFilter(intImage, horiH);
%   vertResponse = integralFilter(intImage, vertH);
%
%   figure;
%   imshow(horiResponse, []); 
%   title('Horizontal edge responses');
%   figure; 
%   imshow(vertResponse, []);
%   title('Vertical edge responses');
%
%   Example 2
%   ---------
%   % Compute 45 degree edge responses of the image 
%   I = imread('pout.tif');
%   intImage = integralImage(I,'rotated');
%   figure;
%   imshow(I);
%   title('Original Image');
%
%   % Construct 45 degree rotated Haar-like wavelet filters
%   rotH = integralKernel([2 1 2 2;4 3 2 2], [1 -1], 'rotated');
%   rotHTrans = rotH.';
%   % visualize the filter rotH
%   figure;
%   imshow(rotH.Coefficients, [], 'InitialMagnification', 'fit');    
%
%   % Compute filter responses
%   rotHResponse = integralFilter(intImage, rotH);
%   rotHTransResponse = integralFilter(intImage, rotHTrans);
%
%   figure;
%   imshow(rotHResponse, []);
%   title('Response for SouthWest-NorthEast edges');
%   figure;
%   imshow(rotHTransResponse, []);
%   title('Response for NorthWest-SouthEast edges');
%
%   See also integralImage, integralKernel

%   Copyright 2010 The MathWorks, Inc.

%   References:
%      P.A. Viola and M.J. Jones. Rapid object detection using boosted
%      cascade of simple features. 
%      In Conference on Computer Vision and Pattern Recognition,
%      pages 511-518, 2001.
%
%      Rainer Lienhart and Jochen Maydt. An Extended Set of Haar-like
%      Features for Rapid Object Detection.
%      In International Conference on Image Processing
%      pages I-900-I-913, 2002

h = parseInputs(intImage, kernel);

% if integral image is empty, return empty output
if(isempty(intImage))
    out = [];
    return;
end

% if empty filter, return zeros, the same size as the image
if(isempty(h.bbox))
    if(strcmp(h.Orientation, 'upright'))
        out = zeros(size(intImage) - 1);
        return;
    else
        out = zeros(size(intImage) - [1 2]);
        return;
    end
end

% determine if any code needs to be generated. 
isCodegen = ~isempty(coder.target);
% isCodegen = true;
% call different functions based on whether codegen is on or off
% the isCodegen flag is currently set to false because codegen is not
% supported currently for class objects. 
% This restriction may be removed in the future. 
if(isCodegen)
    out = codegenIntegralFilter(intImage, h);
else % run the built-in
    localBBox = double(kernel.BoundingBoxes);
    localWeights = double(kernel.Weights);
    localKernel = integralKernel(localBBox, localWeights, h.Orientation);
    out = visionIntegralFilter(intImage, localKernel);
end

end

% Function which performs filtering, when codegen is enabled
function out = codegenIntegralFilter(intImage, h)

if(strcmp(h.Orientation, 'upright'))       %for upright kernels
    if all(h.size) % properly handle empty kernel
        outSize = size(intImage) - h.size; % recall that intImage is padded
    else
        outSize = size(intImage) - 1; % remove padding
    end

    out = zeros(outSize, 'like', intImage);

    for n = 1:outSize(2)
        for m = 1:outSize(1)
            for k = 1:size(h.bbox,1)
                sR = m  + h.bbox(k,2) - 1;
                sC = n  + h.bbox(k,1) - 1;
                eR = sR + h.bbox(k,4);
                eC = sC + h.bbox(k,3); 
                
                bboxSum = intImage(eR,eC) - intImage(eR,sC) - ...
                    intImage(sR,eC) + intImage(sR,sC);

                out(m,n) = out(m,n) + h.weights(k) * bboxSum;
            end
        end
    end
else            %filter using the RSAT
    %you cannot specify an empty rotated kernel
    outSize = size(intImage) - h.size - [0 1];
    
    %predefine output array to be the same data type as the integral image
    out = zeros(outSize, 'like', intImage);
    
    for n = 1:outSize(2)
        for m = 1:outSize(1)
            for k = 1:size(h.bbox,1)
                x = n + h.bbox(k,1) - 1;
                y = m + h.bbox(k,2) - 1;
                width = h.bbox(k,3);
                height = h.bbox(k,4);
                
                bboxSum = intImage(y+width+height,x+width-height+1) ...
                            + intImage(y,x+1) ...
                            - intImage(y+height,x-height+1) ...
                            - intImage(y+width,x+width+1);
                
                out(m,n) = out(m,n) + h.weights(k)*bboxSum;
            end
        end
    end
    
end

end

%==========================================================================
% Parse and check inputs
%==========================================================================
function h = parseInputs(intImage, kernel)

validateattributes(intImage, {'double','single'}, ...
                      {'2d', 'nonsparse', 'real'},...
                       mfilename, 'integral image');

validateattributes(kernel, {'integralKernel'}, {'scalar'},...
    mfilename, 'kernel');

%intImage can be single or double
classToUse = class(intImage);

% pre-process the kernel by eliminating any entries with zero value weight
h.bbox    = cast(kernel.BoundingBoxes(kernel.Weights~=0, :), classToUse);
h.weights = cast(kernel.Weights(kernel.Weights~=0), classToUse);
h.size           = kernel.Size;
h.center         = kernel.Center;
h.Orientation    = kernel.Orientation;

end