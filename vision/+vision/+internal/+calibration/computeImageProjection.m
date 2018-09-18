% computeImageProjection compute image projections for fisheye camera
% model. The method is described in Scaramuzza's Taylor model.
%
% Input: 
%       points  - N-by-3 matrix specifying the points in camera's coordinate
%                system.
%       coeffs  - polynomial coefficients in Scaramuzza's camera model
%       stretch - 2-by-2 alignment matrix
%       center  - 2-element vector for distortion center
% Output:
%       distortedPoints  - N-by-2 image points
%
% Let p = (x, y, z) and q = (u, v), p and q are related by the equation:
%     p = lambda * [u, v, f(u,v)], where lambda is an unknown scalar, and
%                                  f is a polynomial function of rho =
%                                  sqrt(u^2+v^2)
%
% The sensor to image alignment is described as follows:
%     p_image = stretch * p_sensor + center
%

% Copyright 2017 MathWorks, Inc.

% References:
%
% Scaramuzza, D., Martinelli, A. and Siegwart, R., "A Toolbox for Easy
% Calibrating Omnidirectional Cameras", Proceedings to IEEE International
% Conference on Intelligent Robots and Systems (IROS 2006), Beijing China,
% October 7-15, 2006.

function distortedPoints = computeImageProjection(points, coeffs, ...
                                                  stretch, center)

lambdaRho = sqrt(points(:, 1).^2 + points(:, 2).^2);
lambdaRho(lambdaRho == 0) = eps;
mm = points(:, 3) ./ lambdaRho;

% Potentially reduce the computation by skipping same or symmetric points
[m, ~, IC] = unique(mm);  % mm = m(IC) 

rho = nan(length(m), 1);
coeffs = coeffs(end:-1:1);
tmp = coeffs;
for j = 1:length(m)
    tmp(end-1) = coeffs(end-1) - m(j);
    rhoTmp = roots(tmp);
    res = rhoTmp(imag(rhoTmp)==0 & rhoTmp>0);
    if ~isempty(res) 
        if length(res) > 1 
            rho(j) = min(res);
        else
            rho(j) = res;
        end
    end
end

rho = rho(IC);

u = points(:, 1) ./ lambdaRho .* rho ;
v = points(:, 2) ./ lambdaRho .* rho ;

uprime = u * stretch(1, 1) + v * stretch(1, 2) + center(1);
vprime = u * stretch(2, 1) + v + center(2);

distortedPoints = [uprime, vprime];
