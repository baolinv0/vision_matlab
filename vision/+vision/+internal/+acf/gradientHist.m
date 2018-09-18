function [ grHist ] = gradientHist( gMag, gDir, params)
% For each binSize x binSize region in an image I, computes a histogram of
% gradients, with each gradient quantized by its angle and weighed by its
% magnitude. If I has dimensions [m n], the size of the computed feature
% vector H is (m/cellSize n/cellSize numBins]). [m n] must be divisible to
% cellSize in which cellSize must be an even number.
%
% The input to the function are the gradient magnitude gMag and orientation
% gDir at each image location.
%
% References
% ----------
% P. Dollar, R. Appel, S. Belongie and P. Perona
% "Fast Feature Pyramids for Object Detection", PAMI 2014.

cellSize    = params.CellSize;
numBins     = params.NumBins;
interpolate = params.Interpolation;
full        = params.FullOrientation;

% Check inputs
if (nargin < 2 || isempty(gMag))
    grHist = gMag;
    return;
end

[m, n] = size(gMag);
m = single(m);
n = single(n);

% Shape input to desired size: m and n must be divisible to CellSize
cr = single(mod([m n],cellSize));
if(any(cr))
    m   = m - cr(1);
    n   = n - cr(2);
    gMag = gMag(1:m,1:n,:);
    gDir = gDir(1:m,1:n,:);
end

grHist = visionACFGradHist( gMag, gDir, cellSize, ...
    numBins, interpolate, full);

