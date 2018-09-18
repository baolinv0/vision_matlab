function W = bilinearUpsamplingWeights(filterSize, numChannels, numFilters)
% Return 4D bilinear filter coefficients suitable for initializing
% transposed convolution layer.

% Copyright 2017 The MathWorks, Inc.

halfWidth = floor( (filterSize + 1) / 2 );

isodd = logical(rem(filterSize,2));

offset = [0.5 0.5];

offset(isodd) = 0;

center = halfWidth + offset;

CH = 1:filterSize(1);
CW = 1:filterSize(2);

WH = ones(1,filterSize(1)) - abs(CH - center(1))./halfWidth(1);
WW = ones(1,filterSize(2)) - abs(CW - center(2))./halfWidth(2); 

W = WH' * WW;

W = repelem(W, 1, 1, numChannels, numFilters);