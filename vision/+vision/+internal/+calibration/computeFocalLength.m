% computeFocalLength compute focal length given a set of homography
% measurements, a fixed principal point and zero skew.

% Copyright 2016 MathWorks, Inc.
function [fx, fy] = computeFocalLength(homographies, cx, cy)

numImages = size(homographies, 3);
Ap = zeros(2*numImages, 2);
bp = zeros(2*numImages, 1);

% Each homography measurement gives two equations:
% [ h11*h21       h12*h22    ][1/fx^2]   [ -h13 h23   ]
%                                      = 
% [ h11^2-h21^2   h12^2-h22^2][1/fy^2]   [ h23^2-h13^2]
%
% where homography matrix is modified to remove the principal point offset
for i = 1 : numImages
    H = homographies(:, :, i);
    H(1, :) = H(1, :) - cx * H(3, :);
    H(2, :) = H(2, :) - cy * H(3, :);
    
    h = [0, 0, 0];
    v = [0, 0, 0];
    d1 = [0, 0, 0];
    d2 = [0, 0, 0];
    n = [0, 0, 0, 0];
    for j = 1:3
        t0 = H(j,1);
        t1 = H(j,2);
        h(j) = t0; 
        v(j) = t1;
        d1(j) = (t0 + t1) * 0.5;
        d2(j) = (t0 - t1) * 0.5;
        n(1) = n(1) + t0 * t0; 
        n(2) = n(2) + t1 * t1;
        n(3) = n(3) + d1(j) * d1(j); 
        n(4) = n(4) + d2(j) * d2(j); 
    end

    n = 1 ./ sqrt(n);
    h = h * n(1);
    v = v * n(2);
    d1 = d1 * n(3);
    d2 = d2 * n(4);
    
    Ap(2 * i - 1, 1) = h(1) * v(1); 
    Ap(2 * i - 1, 2) = h(2) * v(2); 
    Ap(2 * i, 1) = d1(1) * d2(1); 
    Ap(2 * i, 2) = d1(2) * d2(2); 
    bp(2 * i - 1) = -h(3) * v(3); 
    bp(2 * i) = -d1(3) * d2(3); 
end

f = Ap \ bp;
fx = sqrt(abs(1/f(1)));
fy = sqrt(abs(1/f(2)));