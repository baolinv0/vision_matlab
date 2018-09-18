%computeApproxImageProjection compute approximate image projections for
% fisheye camera model. The method is described in Scaramuzza's Taylor
% model. Unlike computeImageProjection function, this approximation avoid
% solving polynomial equations.
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
% Note, this function should only be called if the input has large number
% of points. Otherwise, you can call computeImageProjection directly, which
% returns exact solutions.

% Copyright 2017 MathWorks, Inc.

% References:
%
% Scaramuzza, D., Martinelli, A. and Siegwart, R., "A Toolbox for Easy
% Calibrating Omnidirectional Cameras", Proceedings to IEEE International
% Conference on Intelligent Robots and Systems (IROS 2006), Beijing China,
% October 7-15, 2006.
function [distortedPoints, maxError] = computeApproxImageProjection(...
                                points, coeffs, stretch, center)
                            
    lambdaRho = sqrt(points(:, 1).^2 + points(:, 2).^2);
    lambdaRho(lambdaRho == 0) = eps;
    mm = points(:, 3) ./ lambdaRho;
    
    m = atan(mm);
    warningState = warning('off','MATLAB:polyfit:RepeatedPointsOrRescale');
    % Fit a new polynomial to the roots of the original polynomial model
    [newCoeffs, maxError] = findInversePolyCoefficients(coeffs, [min(m), max(m)]);
    
    warning(warningState);
    
    rho = polyval(newCoeffs, m);

    u = points(:, 1) ./ lambdaRho .* rho ;
    v = points(:, 2) ./ lambdaRho .* rho ;

    uprime = u * stretch(1, 1) + v * stretch(1, 2) + center(1);
    vprime = u * stretch(2, 1) + v + center(2);

    distortedPoints = [uprime, vprime];
end
        
function [newCoeffs, maxError] = findInversePolyCoefficients(coeffs, range)
    maxError = inf;
    N = 1;
    while (maxError > 0.1 && N <= 20)
        %Repeat until the reprojection error is smaller than 0.1 pixels
        N = N + 1;
        [newCoeffs, error] = findinvpoly(coeffs, range, N);
        maxError = max(error);  
    end
end

function [p, error] = findinvpoly(coeffs, range, N)
    theta = (range(1):0.01:range(2))';
    numTheta = numel(theta);
    if numTheta < 150 && numTheta > 10
        step = (range(2) - range(1)) / 150;
        theta = (range(1):step:range(2))';
    elseif numTheta <= 10
        theta = [-pi/2:0.01:pi/2, pi/2]';
    end
    m = tan(theta);
    
    r = findRho(coeffs, m);
    ind = ~isnan(r);
    theta = theta(ind);
    r = r(ind);
    if numel(r) > N
        p = polyfit(theta, r, N);
        
        % Compute approximation error in pixels
        error = abs(r - polyval(p, theta)); 
    else
        p = [];
        error = inf;
    end
end

function rho = findRho(coeffs, m)
    
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
end
