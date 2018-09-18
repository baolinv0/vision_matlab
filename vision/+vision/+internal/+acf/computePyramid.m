function pyramid = computePyramid(I, params)
% Compute channel feature pyramid given an input image.
%
% computePyramid repeatedly calls computeChannels on different scale
% images to create a scale-space pyramid of channel features
%
% References
% ----------
% [1] P. Dollar, R. Appel, S. Belongie and P. Perona
%   "Fast Feature Pyramids for Object Detection", PAMI 2014.
% [2] P. Dollar, Z. Tu, P. Perona and S. Belongie
%  "Integral Channel Features", BMVC 2009.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

nPerOct = params.NumScaleLevels;
nApprox = params.NumApprox;
pad     = params.ChannelPadding;
minDs   = params.ModelSize;
smooth  = params.SmoothChannels;
shrink  = params.Shrink;
nOctUp  = params.NumUpscaledOctaves;
lambdas = params.Lambdas;

imageSize = [size(I,1) size(I,2)];

if isfloat(I)       
    I = single(mat2gray(I)); % scales floating point values between [0 1].       
else
    I = im2single(I);
end

if ismatrix(I)
    I = cat(3, I, I, I);
end

% Generate the LUV color channels at the original scale and sample it
% during pyramid construction, faster than generating the color channels at
% each scale separately. Output is single.
I = vision.internal.acf.rgb2luv(I,true);

% Get scales at which to compute features and list of real/approx scales
[imageScales,scaledImageSize] = getScales(nPerOct, nOctUp, minDs, shrink, imageSize);

% Apply min/max object size constraints
if (~isempty(imageScales) && all(isfield(params, {'MaxSize','MinSize'})))
    
    detectionSize = floor(bsxfun(@times, 1./imageScales, round(minDs)'));
    detectionSize(:,1) = round(minDs); % should be value of round(minDs);
    
    % Find the range of scales between min and max size
    lessThanOrEqToMaxSize    = all(bsxfun(@le, detectionSize, params.MaxSize'));
    greaterThanOrEqToMinSize = all(bsxfun(@ge, detectionSize, params.MinSize'));
    
    minmaxRange = lessThanOrEqToMaxSize & greaterThanOrEqToMinSize;  % check if empty!
    
    if ~any(minmaxRange)
        % min max range falls in between two scales. In this edge case, select
        % the upper and lower scale for processing.
        idx = [find(lessThanOrEqToMaxSize, 1, 'last') ...
            find(greaterThanOrEqToMinSize, 1)];
        if numel(idx) > 1
            minmaxRange(idx) = true;
        end
    end
    
    % Only keep the scales between min and max size
    imageScales   = imageScales(minmaxRange);
    scaledImageSize = scaledImageSize(minmaxRange, :);
end

nScales = length(imageScales);

% The scales which channels are computed exactly
realScaleInd = 1;
realScaleInd = realScaleInd:nApprox + 1:nScales;

% The scales which channels are approximated
approxScaleInd = 1:nScales;
approxScaleInd(realScaleInd) = [];

% Index denoting which scales are used to approximate
j = [0 floor((realScaleInd(1:end-1) + realScaleInd(2:end)) / 2) nScales];
referenceScales = 1:nScales;
for i = 1:length(realScaleInd)
    referenceScales(j(i) + 1:j(i + 1)) = realScaleInd(i);
end

data = cell(nScales,1);

persistent inputImageSize;
persistent realScaleRemap;
if (~isequal(inputImageSize, size(I)))
    inputImageSize = size(I);
    realScaleRemap = {};
end
if (size(realScaleRemap, 1) ~= length(imageScales))
    realScaleRemap = cell(length(imageScales), 2);
end

% Compute image pyramid [real scales]
for i = realScaleInd
    s = imageScales(i);
    imageScaledSize = round(imageSize * s / shrink) * shrink;
    
    if (all(imageSize == imageScaledSize))
        Is = I;
    else
        if (~isequal(size(realScaleRemap{i, 1}), single(imageScaledSize)))
            [X, Y] = generateRemapXY(I, imageScaledSize(2), imageScaledSize(1));
            realScaleRemap{i, 1} = X;
            realScaleRemap{i, 2} = Y;
        end
        Is = images.internal.remapmex(I, realScaleRemap{i, 1}, realScaleRemap{i, 2}, 'bilinear', zeros(1, size(I, 3)));
    end

    % Generate channels for scaled image Is
    data{i} = vision.internal.acf.computeChannels(Is, params);
end

% Compute image pyramid [approximated scales]
for i = approxScaleInd
    iR = referenceScales(i);
    imageScaledSize=round(imageSize*imageScales(i)/shrink);
    data{i} = visionACFResize(data{iR}, imageScaledSize(1), imageScaledSize(2), 1);
        
    ratio = (imageScales(i)/imageScales(iR)).^-lambdas;
    data{i} = bsxfun(@times, data{i}, reshape(repelem(ratio, ...
        [3 1 params.hog.NumBins]), 1, 1, []));
end

% Smooth channels and add padding for detections near border.
for i=1:nScales
    data{i} = vision.internal.acf.convTri(data{i},smooth);
    data{i} = ConstantPadBothWithZero(data{i}, [pad/shrink,0]);
end

pyramid.NumScales = nScales;
pyramid.Channels = data;
pyramid.Scales = imageScales;
pyramid.ScaledImageSize = scaledImageSize;

%--------------------------------------------------------------------------
function [scales,scaleshw] = getScales(nPerOct,nOctUp,minDs,shrink,sz)
% set each scale s such that max(abs(round(sz*s/shrink)*shrink-sz*s)) is
% minimized without changing the smaller dim of sz (tricky algebra)
if(any(sz == 0))
    scales = [];
    scaleshw = [];
    return;
end
nScales = floor(nPerOct * (nOctUp + log2(min(sz ./ minDs))) + 1);
scales = 2.^(-(0:nScales - 1) / nPerOct + nOctUp);
if(sz(1) < sz(2))
    d0 = sz(1);
    d1 = sz(2);
else
    d0 = sz(2);
    d1 = sz(1);
end
for i = 1:nScales
    s = scales(i);
    s0 = (round(d0 * s / shrink) * shrink - .25 * shrink) ./ d0;
    s1 = (round(d0 * s / shrink) * shrink + .25 * shrink) ./ d0;
    ss = (0:.01:1 - eps) * (s1 - s0) + s0;
    es0 = d0 * ss;
    es0 = abs(es0 - round(es0 / shrink) * shrink);
    es1 = d1 * ss;
    es1 = abs(es1 - round(es1 / shrink) * shrink);
    [~, x] = min(max(es0,es1));
    scales(i) = ss(x);
end
kp = [scales(1:end-1) ~= scales(2:end) true];

if isempty(scales)
    scaleshw = zeros(2,0);
else
    scales = scales(kp);
    scaleshw = [round(sz(1) * scales / shrink) * shrink / sz(1);
        round(sz(2) * scales / shrink) * shrink / sz(2)]';
end

%--------------------------------------------------------------------------
function b = ConstantPadBothWithZero(a, padSize)

numDims = numel(padSize);

% Form index vectors to subsasgn input array into output array.
% Also compute the size of the output array.
idx   = cell(1,numDims);
sizeB = zeros(1,numDims);
for k = 1:numDims
    M = size(a,k);
    idx{k}   = (1:M) + padSize(k);
    sizeB(k) = M + 2*padSize(k);
end

% Initialize output array with the padding value.  Make sure the
% output array is the same type as the input.
b = zeros(sizeB, class(a));
b(idx{:}) = a;

%--------------------------------------------------------------------------
function [X, Y] = generateRemapXY(data, w, h)
[X, Y] = meshgrid(0:single(w-1), 0:single(h-1));
X = X * size(data, 2) / w;
Y = Y * size(data, 1) / h;
