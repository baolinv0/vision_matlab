function [ grM, grO ] = gradient(I, params)
% Computes gradients and orientation of input image I.  If norm_rad > 0
% then normalization is applied.

normRad   = params.NormalizationRadius;
normConst = params.NormalizationConstant;

% Check inputs
if(nargin < 1 || isempty(I))
    grM = single([]);
    grO = grM;
    return;
end

if max(max(I)) > 1
    I = im2single(I);
end

[grM,grO] = visionACFGradient(I, 1, params.FullOrientation);

% Convolve with triangle filter
if normRad > 0
    S = vision.internal.acf.convTri( grM, normRad, 1 );
    grM = grM ./ (S + normConst);
end
