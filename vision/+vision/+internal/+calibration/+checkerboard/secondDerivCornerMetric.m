function [cxy, c45, Ix, Iy, Ixy, I_45_45] = secondDerivCornerMetric(I, sigma)
%#codegen

% Low-pass filter the image
G = fspecial('gaussian', coder.const(round(sigma * 7)+1), sigma);
Ig = imfilter(I, G, 'conv');

derivFilter = [-1 0 1];

% first derivatives
Iy = imfilter(Ig, derivFilter', 'conv');
Ix = imfilter(Ig, derivFilter, 'conv');
    
% define steerable filter constants
cosPi4 = coder.const(cast(cos(pi/4), 'like', I));
cosNegPi4 = coder.const(cast(cos(-pi/4), 'like', I));
sinPi4 = coder.const(cast(sin(pi/4), 'like', I));
sinNegPi4 = coder.const(cast(sin(-pi/4), 'like', I));

% first derivative at 45 degrees
I_45 = Ix * cosPi4 + Iy * sinPi4;
I_n45 = Ix * cosNegPi4 + Iy * sinNegPi4;

% second derivative
Ixy = imfilter(Ix, derivFilter', 'conv');

I_45_x = imfilter(I_45, derivFilter, 'conv');
I_45_y = imfilter(I_45, derivFilter', 'conv');    

I_45_45 = I_45_x * cosNegPi4 + I_45_y * sinNegPi4;

% suppress the outer corners
cxy = sigma^2 * abs(Ixy) - 1.5 * sigma * (abs(I_45) + abs(I_n45));
cxy(cxy < 0) = 0;
c45 = sigma^2 * abs(I_45_45) - 1.5 * sigma * (abs(Ix) + abs(Iy));
c45(c45 < 0) = 0;


