function data = computeChannels( I, params )
% Compute channel features at a single scale given an input image.
%
% Compute the channel features as described in [1].
%
% Currently, three channel types are available by default
%  (1) color channels (computed using rgbConvert.m)
%  (2) gradient magnitude (computed using gradient.m)
%  (3) quantized gradient channels (computed using gradientHist.m)
%
% References
% ----------
% [1] P. Dollar, Z. Tu, P. Perona and S. Belongie
%  "Integral Channel Features", BMVC 2009.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

% Crop I so divisible by shrink and get target dimensions
shrink = params.Shrink;

[h,w,~] = size(I);
cr = mod([h w],shrink);
if(any(cr))
    h = h - cr(1);
    w = w - cr(2);
    I = I(1:h,1:w,:);
end
h = h / shrink;
w = w / shrink;

I = vision.internal.acf.convTri(I, params.PreSmoothColor);

% Compute gradient channel
[M, O] = vision.internal.acf.gradient(I, params.gradient);

% resize I and gradient magnitude at same time for efficiency.
data = visionACFResize(cat(3, I, M), h, w, 1);

% Compute HOG channels
H = vision.internal.acf.gradientHist( M, O, params.hog);

% Shrink data
[h1,w1,~] = size(H);

if(h1 ~= h || w1 ~= w)
    H = visionACFResize(H, h, w, 1);
end

data = cat(3, data, H);