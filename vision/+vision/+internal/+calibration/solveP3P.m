% solveP3P World camera pose from three 2D-3D correspondences
%  [Rs, Ts] = solveP3P(imagePoints, worldPoints, K) returns up to four 
%  solutions to the perspective-3-point problem. imagePoints is an M-by-2
%  array containing [x,y] image point coordinates. worldPoints is an M-by-3
%  array containing the corresponding [x,y,z] world coordinates. K is the
%  3-by-3 intrinsics matrix. The function assumes no lens distortion.
%
%  Rs is a 3-by-3-by-P array containing the rotation matrices, and Ts is a
%  P-by-3 matrix containing the translation vectors, where 1 <= P <= 4.
%
%  Note: if the 4th degree polynomial has no real solution, Rs and Ts will
%  be empty.

% Refrences:
% X.-Sh. Gao, X.-R. Hou, J. Tang, H.-F. Cheng. Complete Solution 
% Classification for the Perspective-Three-Point Problem. IEEE PAMI, 
% v. 25(8), 2003. pp. 930-943.
%
% The P3P (Perspective-Three-Point) Principle 
% http://iplimage.com/blog/p3p-perspective-point-overview/

% Copyright 2016 MathWorks, Inc.

%#codegen

function [Rs, Ts] = solveP3P(imagePointsIn, worldPointsIn, K)

% The computation is done in double precision internally
imagePoints = double(imagePointsIn);
worldPoints = double(worldPointsIn);

% Convert image points to normalized image coordinates
numPoints = size(imagePoints, 1);
U = [imagePoints, ones(numPoints, 1)] / K;

% Normalize to unit vectors
uNorm = sqrt(sum(U.^2, 2));
U = bsxfun(@rdivide, U, uNorm);

% u, v, and w are unit vectors, which point to the world points from the
% camera center.
u = U(1, :);
v = U(2, :);
w = U(3, :);

% Angles between the unit vectors
cosUV = u * v';
cosUW = u * w';
cosVW = v * w';

% World points
A = worldPoints(1, :);
B = worldPoints(2, :);
C = worldPoints(3, :);

% Squared distances between the world points
AB2 = sum((A - B).^2);
BC2 = sum((B - C).^2);
AC2 = sum((A - C).^2);

a = BC2 / AB2;
b = AC2 / AB2;

p = 2 * cosVW;
q = 2 * cosUW;
r = 2 * cosUV;

% Check that we do not have a "degenerate" case
c = whichComponent(a, b, p, q, r);
if c ~= 1
    % Output poses
    Rs = zeros(3, 3, 0, 'like', imagePointsIn);
    Ts = zeros(0, 3, 'like', imagePointsIn);    
    return;
end

% Coefficients of the 4th degree polynomial equation
pbr = p*b*r;
a4 = -2*b + b^2 + a^2 + 1 - b*r^2*a + 2*b*a - 2*a;
a3 = -2*b*q*a - 2*a^2*q + b*r^2*q*a - 2*q + 2*b*q + 4*a*q + pbr + pbr*a - b^2*r*p;
a2 = q^2 + b^2*r^2 - b*p^2 - q*pbr + b^2*p^2 - b*r^2*a + 2 - 2*b^2 - a*pbr*q + 2*a^2 - 4*a - 2*q^2*a + q^2*a^2;
a1 = -b^2*r*p + pbr*a - 2*a^2*q + q*p^2*b + 2*b*q*a + 4*a*q + pbr - 2*b*q - 2*q;
a0 = 1 - 2*a + 2*b + b^2 - b*p^2 + a^2 - 2*b*a;

% Solve the 4th degree polynomial equation
coeffs = [a4, a3, a2, a1, a0];
if ~all(isfinite(coeffs))
    Rs = zeros(3, 3, 0, 'like', imagePointsIn);
    Ts = zeros(0, 3, 'like', imagePointsIn);
    return;
end

X = roots(coeffs);

% Only keep the real roots
X = real(X(abs(imag(X)) < 1e-8));

numSolutions = numel(X);

% Output poses
Rs = zeros([3, 3, numSolutions], 'like', imagePointsIn);
Ts = zeros([numSolutions, 3], 'like', imagePointsIn);

% Coefficients of the second equation
b1 = b*((p^2 - p*q*r + r^2)*a + (p^2 - r^2)*b - p^2 + p*q*r - r^2)^2;

% Compute output poses
for i = 1:numSolutions
    x = X(i);
    b0 = ((1 - a - b)*x^2 + (a - 1)*q*x - a + b + 1) * ...
        ((r^3 * (a^2 + b^2 - 2*a - 2*b + (2 - r^2)*a*b + 1))*x^3 + ...
        r^2*(p+p*a^2 - 2*r*q*a*b + 2*r*q*b - 2*r*q - 2*p*a - 2*p*b + p*r^2*b + 4*r*q*a + q*r^3*a*b - 2*r*q*a^2 + 2*p*a*b + p*b^2 - r^2*p*b^2)*x^2 + ...
        (r^5*(b^2 - a*b) - r^4*p*q*b + r^3*(q^2 - 4*a - 2*q^2*a + q^2*a^2 + 2*a^2 - 2*b^2 + 2) + r^2*(4*p*q*a - 2*p*q*a*b + 2*p*q*b - 2*p*q - 2*p*q*a^2) + ...
        r*(p^2*b^2 - 2*p^2*b + 2*p^2*a*b - 2*p^2*a + p^2 + p^2*a^2))*x + ...
        (2*p*r^2 - 2*r^3*q + p^3 - 2*p^2*q*r + p*q^2*r^2)*a^2 + (p^3 - 2*p*r^2)*b^2 + (4*q*r^3 - 4*p*r^2 - 2*p^3 + 4*p^2*q*r - 2*p*q^2*r^2)*a + ...
        (-2*q*r^3 + p*r^4 + 2*p^2*q*r - 2*p^3)*b + (2*p^3 + 2*q*r^3 - 2*p^2*q*r)*a*b + ...
        p*q^2*r^2 - 2*p^2*q*r + 2*p*r^2 + p^3 - 2*r^3*q);
    y = b0 / b1;

    cv = x^2 + y^2 - 2*x*y*cosUV;
    
    % Distances from the camera center to the world points
    PC = sqrt(AB2 / cv);
    PB = y * PC;
    PA = x * PC;
    
    % The distances must be positive
    if PC > 0 && PB > 0 && PA > 0
        
        % Find coordinates of the world points in the camera's coordinate
        % system
        Ac = u * PA;
        Bc = v * PB;
        Cc = w * PC;        
        
        % Compute the rigid transformation from world into camera
        % coordinate system
        [R, t] = vision.internal.calibration.rigidTransform3D(...
            worldPoints(1:3, :), [Ac; Bc; Cc;]);
        Rs(:,:,i) = cast(R', 'like', imagePointsIn);
        Ts(i, :) =  cast(t', 'like', imagePointsIn); 
    end
end

function c = whichComponent(a, b, p, q, r)

if isTS2(a, b, r)
    c = 2;
elseif isTS3(a, b, p, q, r)
    c = 3;
elseif isTS4(a, b, r)
    c = 4;
elseif isTS5(a, b, p, q, r)
    c = 5;
elseif isTS6(a, b, p, q, r)
    c = 6;
elseif isTS7(b, p, q, r)
    c = 7;
elseif isTS8()
    c = 8;    
elseif isTS9(p, r)
    c = 9;
% elseif isTS10(a, b, p, q, r)
%     c = 10;
% elseif isTS11(a, b, p, q, r)
%     c = 11;    
else 
    c = 1;
end

%--------------------------------------------------------------------------
function tf = isTS2(a, b, r)
tf = a^2 + (-2 + 2*b - b*r^2)*a - 2*b + b^2 + 1 == 0;

%--------------------------------------------------------------------------
function tf = isTS3(a, b, p, q, r)
pqr = p * q * r;
F = (-4*p^2 + 4*pqr + r^2*p^2 + r^2*q^2 - r^3*p*q - 4*q^2);
tf =  (F*a + r^2*p^2 - 4*pqr + 4*q^2 == 0) && ...
      (F*b + r^2*q^2 + 4*p^2 - 4*pqr == 0);
  
%--------------------------------------------------------------------------
function tf = isTS4(a, b, r)
tf = (a + b - 1 == 0) && (r == 0);

%--------------------------------------------------------------------------
function tf = isTS5(a, b, p, r, q)
q2 = q^2;
p2 = p^2;
F = (p2 + q2);
tf = (F*a - q2 == 0) && (F*b - p2 == 0) && (r == 0);

%--------------------------------------------------------------------------
function tf = isTS6(a, b, p, r, q)
q2 = q^2;
p2 = p^2;
F = (p2^2 - 2*p2*q2 + q2^2);
tf = (F*a - p2*q2 - q2^2 == 0) && (F*b - p2*q2 - p2^2 == 0) && ...
    ((p2 + q2)*r - 4*p*q == 0);

%--------------------------------------------------------------------------
function tf = isTS7(b, p, r, q)
tf = (4*r^2 + p^2*q^2 + p^4 - r^4 - p^3*q*r + p*r^3*q - 4*q*p*r)*b + ...
    2*p*r^3 - 2*p^2*r^2 + 2*p^3*q*r - p^2*q^2*r^2 - p^4 - r^4 == 0;

%--------------------------------------------------------------------------
function tf = isTS8()
% No way to tell
tf = false;

%--------------------------------------------------------------------------
function tf = isTS9(p, r)
tf = (p == 0) && (r == 0);
