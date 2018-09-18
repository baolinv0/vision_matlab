function [ J ] = convTri( I, r, s )
% Convolves an image by a 2D triangle filter (the 1D triangle filter f is
% [1:r r+1 r:-1:1]/(r+1)^2, the 2D version is simply conv2(f,f')).
%
% INPUTS
%  I      - [m n k] input k channel single image
%  r      - [3] integer filter radius (or any value between 0 and 1)
%  s      - [1] integer downsampling amount after convolving
%
% OUTPUTS
%  J      - [m x n x k] smoothed image

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

% Check inputs
if (nargin < 2 || isempty(r))
    r = 3;
end
if (nargin < 3 || isempty(s))
    s=1; 
end
if (isempty(I) || (r == 0 && s == 1))
    J = I; 
    return; 
end
m = min(size(I,1), size(I,2)); 
if ( m < 4 || 2 * r + 1 >= m )
    if (r <= 1)
        p = 12/r/(r+2)-2; 
        f = [1 p 1]/(2+p); 
        r = 1;
    else
        f = [1:r r+1 r:-1:1]/(r+1)^2; 
    end
    
    J = padarray(I, [r r], 'symmetric', 'both');
    J = convn(convn(J, f, 'valid'), f', 'valid');
    if (s > 1)
        t = floor(s/2)+1; 
        J = J(t:s:end-s+t, t:s:end-s+t, :); 
    end
else
    % Apply convolution
    J = visionACFConvTri(I, r, s);
end

