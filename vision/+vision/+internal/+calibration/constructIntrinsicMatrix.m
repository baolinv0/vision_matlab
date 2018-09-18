function A = constructIntrinsicMatrix(fx, fy, cx, cy, skew)
% constructIntrinsicMatrix Assemble intrinsic camera parameters into intrinsic
% matrix.
%
% A = constructIntrinsicMatrix(fx, fy, cx, cy, skew) constructs projective 
% camera matrix A from the intrinsic parameters.
%
% [fx, fy] values measured in pixels, that are related to the focal length. 
% fx = F * sx, fy = F * sy, where F is the focal length in world units 
% (typically mm), and [sx, sy] are the number of pixels per world unit in 
% the x and y direction respectively.
%
% [cx, cy] are the coordinates of the optical center (the principal point)
% in pixels.
%
% skew is a parameter that is 0 if the x and y axes of the image plane are
% exactly perpendicular, and non-zero otherwise. This parameters is
% optional.  If it is omitted, the skew is assumed to be 0.

% References:
% [1] R. Hartley, A. Zisserman, "Multiple View Geometry in Computer
%     Vision," Cambridge University Press, 2003.

% Copyright 2012 MathWorks, Inc.

if nargin < 5
    skew = 0;
end

A = [fx, skew, cx; ...
     0, fy, cy; ...
     0, 0, 1];
