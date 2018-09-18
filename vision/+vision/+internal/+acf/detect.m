function [bboxes, scores] = detect(P, detector, params, flag)
% Run aggregate channel features object detector on given image.

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

shrink        = params.Shrink;
pad           = params.ChannelPadding;
boundingBoxes = cell(P.NumScales,1);
modelDsPad    = params.ModelSizePadded;
modelDs       = params.ModelSize;

flagPresent = (nargin == 4);

% Apply sliding window classifiers
for i=1:P.NumScales
    if flagPresent
        bb = visionACFDetector(P.Channels{i}, detector, shrink, ...
                modelDsPad(1), ...
                modelDsPad(2), ...
                params.WindowStride, ...
                params.Threshold, ...
                flag{i});
    else
        bb = visionACFDetector(P.Channels{i}, detector, shrink, ...
                params.ModelSizePadded(1), ...
                params.ModelSizePadded(2), ...
                params.WindowStride, ...
                params.Threshold);
    end
    
    % Shift and scale the detections due to actual object size
    % (shift-= modelDsPad-modelDs)/2), channel padding (shift -= pad)
    % and scale difference (bb=(bb+shift)/P.scaleshw)   
    shift   = (modelDsPad - modelDs)/2 - pad;
    bb(:,1) = (bb(:,1) + shift(2))/P.ScaledImageSize(i,2);
    bb(:,2) = (bb(:,2) + shift(1))/P.ScaledImageSize(i,1);
    bb(:,3) = modelDs(2)/P.Scales(i);
    bb(:,4) = modelDs(1)/P.Scales(i);
    boundingBoxes{i,1} = bb;
end

boundingBoxes = cat(1,boundingBoxes{:});

if isempty(boundingBoxes)
    bboxes = zeros(0,4);
    scores = zeros(0,1);
else
    bboxes = boundingBoxes(:,1:4);
    scores = boundingBoxes(:,5);
end

