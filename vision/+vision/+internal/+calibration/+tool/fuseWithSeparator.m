% fuseWithSeparator Join two images side by side separated by a white line

% Copyright 2012-2013 The MathWorks, Inc.

function [I, offset] = fuseWithSeparator(I1, I2)

% if one of the images is RGB and the other is grayscale,
% convert the grayscale to a 3-channel.
if size(I1, 3) ~= size(I2, 3)
    if ismatrix(I1)
        I1 = repmat(I1, [1, 1, 3]);
    else
        I2 = repmat(I2, [1,1,3]);
    end
end

if isfloat(I1)
    fillValue = cast(1, 'like', I1);
else
    fillValue = intmax(class(I1));
end

dividerWidth = max(ceil(0.003 * size(I1, 2)), 2);
divider = ones([size(I1, 1), dividerWidth, size(I1, 3)], 'like', I1) * fillValue;
I = cat(2, I1, divider, I2);

offset = size(I1, 2) + size(divider, 2);