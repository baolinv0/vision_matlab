function [ luv ] = rgb2luv(I, mexApply)
% RGB to LUV converter. Input image I must be RGB single type (between [0,1])
% Applies Dollar's normalization [1]. 
%
% If so, the LUV channels are normalized to fall in ~[0,1]. Without
% normalization the ranges are L ~ [0,100], u ~ [-88,182], and v ~
% [-134,105] (and typically u,v ~ [-100,100]). The applied transformation
% is L = L/270, u = (u + 88)/270, and v = (v + 134)/270. This results in
% ranges L ~ [0,.37], u ~ [0,1], and v ~ [0,.89]. Perceptual uniformity is
% maintained since divisor is constant (normalizing each color channel
% independently would break uniformity).
%
% To undo the normalization on an LUV image J use:
%   J = J * 270; J(:,:,2) = J(:,:,2)-88; J(:,:,3) = J(:,:,3) - 134;
%
% RGB to XYZ is approximated.
% XYZ to LUV is of type Observer = 2, Illuminant= D65 if hash table (yTable) 
% isn't used. yTable is a global variable and must be precomputed.
%
% INPUT
%   I       - [m n 3] RGB input single image

% OUTPUT 
%   luv     - [m n 3] LUV image  
%
% REFERENCES
% [1] P. Dollar, Z. Tu, P. Perona and S. Belongie
%  "Integral Channel Features", BMVC 2009.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

persistent yTable;
if isempty(yTable)
   yTable = initHashTable;
end

% Check input
if (nargin < 1 || isempty(I) || size(I,3) ~= 3)
    luv = zeros(0,0,3);
    return; 
end

if ~mexApply
    
    % RGB to XYZ
    X = I(:,:,1) * 0.430574 + I(:,:,2) * 0.341550 + I(:,:,3) * 0.178325;
    Y = I(:,:,1) * 0.222015 + I(:,:,2) * 0.706655 + I(:,:,3) * 0.071330;
    Z = I(:,:,1) * 0.020183 + I(:,:,2) * 0.129553 + I(:,:,3) * 0.939180;
    
    C = 1./( X + ( 15 * Y ) + ( 3 * Z ) + single(1e-6));
    
    vU = ( 4 * X ) .* C;
    vV = ( 9 * Y ) .* C;
    
    % Hash Table approximations to avoid cube root computation
    cieL = yTable(int32(Y*1024 + 0.5));
    
    % % Comment above statement and uncomment below two statements for exact
    % % xyz to luv computation. Yields better accuracy but is slightly slower.
    % Y(Y > 0.008856) = (Y(Y > 0.008856)) .^ (1/3);
    % Y(Y <= 0.008856) = ( 7.787 *  Y(Y <= 0.008856) ) + ( 16 / 116 );
    
    rU = single(0.197833);
    rV = single(0.468331);
    
    cieU = 13 * cieL .* ( vU - rU );
    cieV = 13 * cieL .* ( vV - rV );
    
    c = 1/270;
    cieU = cieU + 88.*c;
    cieV = cieV + 134.*c;
    luv = cat(3,cieL,cieU,cieV);
else
    luv = visionACFRgb2luv(I,yTable);
end


%--------------------------------------------------------------------------
function yTable = initHashTable()

yTable = zeros(1,1064,'single');
y0 = single((6.0/29)*(6.0/29)*(6.0/29));
a =  single((29.0/3)*(29.0/3)*(29.0/3));
maxi = single(1.0/270); 
for i = 0:1024
    y = single(i/1024.0);
    if y > y0
        l = 116 * y^(1/3) - 16;
    else
        l =  y * a;
    end
    yTable(i+1) = l*maxi;
end

for i = 1025:1063
    yTable(i+1) = yTable(i);
end