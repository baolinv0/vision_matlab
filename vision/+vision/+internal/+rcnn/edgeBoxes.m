function [bboxes, scores] = edgeBoxes(I, alpha, beta, minScore)
% Generates region proposals using a variant of the Edge Boxes algorithm.

% References:
% -----------
% Zitnick, C. Lawrence, and Piotr Dollar. "Edge boxes: Locating object
% proposals from edges." Computer Vision-ECCV 2014. Springer International
% Publishing, 2014. 391-405.

% Convert image to uint8. The minScore depends on the range of the gradient
% values. R-CNN usage defaults minScore to 0.1, which works well for uint8.
% This can be modified in the future to handle other datatypes.

I = im2uint8(I);

[gmag, bw] = vision.internal.rcnn.edgeMap(I);

cc = bwconncomp(bw,8);

% Remove small edge groups.
minEdgeGroup = floor(sqrt(1000));
count = cellfun(@numel,cc.PixelIdxList);
remove = count < minEdgeGroup;
cc.PixelIdxList(remove) = [];
cc.NumObjects = numel(cc.PixelIdxList);
L = labelmatrix(cc);

% Update gmag after removing small ones
gmag(L==0) = 0;

% Use an integral image to speed-up box scoring.
intM = integralImage(gmag);

[bboxes, scores] = visionEdgeBoxes(cc, L, gmag, intM, alpha, beta, minScore);

[bboxes, scores] = selectStrongestBbox(bboxes, scores,'OverlapThreshold',beta);

