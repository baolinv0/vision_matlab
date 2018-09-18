function patches = cropBboxes(I, bboxes, padEl, dims)
% Crop image regions from I encompassed by bboxes.
%
% If bboxes contains all integer entries cropping is straightforward. If
% entries are not integers, x=round(x+.499) is used, eg 1.2 actually goes
% to 2 (since it is closer to 1.5 then .5), and likewise for y.
%
%  I        - image from which to crop patches
%  bboxes   - Nx4 bounding boxes that indicate regions to crop
%  padEl    - string to indicate padding style
%  dims     - if specified, resize each cropped patch to [w h]
%
%  patches  - N cells of cropped image regions
%  bbs      - actual integer-valued bbs used to crop
%
% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

h = size(I, 1); 
w = size(I, 2);

% crop each patch in turn
n = size(bboxes, 1); 
patches = cell(1, n);

for i = 1 : n
    bb = bboxes(i, :);
    % crop single patch (use arrayCrop only if necessary)        
    lcsS = round(bb([2 1]) + 0.5 - 0.001); 
    lcsE = lcsS + round(bb([4 3])) - 1;
    if (any(lcsS < 1) || lcsE(1) > h || lcsE(2) > w)        
        pt = max(0, 1-lcsS(1)); 
        pb = max(0, lcsE(1)-h);
        pl = max(0, 1-lcsS(2)); 
        pr = max(0, lcsE(2)-w);
        lcsS1 = max(1, lcsS); 
        lcsE1 = min(lcsE, [h w]);
        patch = I(lcsS1(1):lcsE1(1), lcsS1(2):lcsE1(2), :);
        patch = padarray(patch, [pt pl], padEl, 'pre');
        patch = padarray(patch, [pb pr], padEl, 'post');
    else          
        patch = I(lcsS(1):lcsE(1), lcsS(2):lcsE(2), :);        
    end

    if ~isempty(dims)
      patch = visionACFResize(patch, dims(2), dims(1), 1); 
    end
    
    patches{i} = patch;
end
