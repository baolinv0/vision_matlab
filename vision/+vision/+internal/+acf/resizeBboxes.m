function bboxes = resizeBboxes(bboxes, hr, wr)
% Resize the bboxes (without moving their centers).
%
%  bboxes - n-by-4 original bboxes
%  hr     - ratio by which to multiply height
%  wr     - ratio by which to multiply width
%
% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]
if ~isempty(bboxes)
    if hr ~= 0
        d = (hr - 1) * bboxes(:, 4); 
        bboxes(:, 2) = bboxes(:, 2) - d / 2; 
        bboxes(:, 4) = bboxes(:, 4) + d; 
    end

    if wr ~= 0
        d = (wr - 1) * bboxes(:, 3); 
        bboxes(:, 1) = bboxes(:, 1) - d / 2; 
        bboxes(:, 3) = bboxes(:, 3) + d; 
    end
end