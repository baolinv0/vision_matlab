%==========================================================================
% Clip the bounding box when it is positioned outside the image. This can
% happen when detections occur near the image boundaries. 
%==========================================================================
function clippedBBox = clipBBox(bbox, imgSize)

%#codegen

% bounding boxes are returned as doubles
clippedBBox  = double(bbox);

% The original bounding boxes all overlap the image. Therefore, a check to
% remove non-overlapping boxes is not required.

% Get coordinates of upper-left (x1,y1) and bottom-right (x2,y2) corners. 
x1 = clippedBBox(:,1);
y1 = clippedBBox(:,2);

x2 = clippedBBox(:,1) + clippedBBox(:,3) - 1;
y2 = clippedBBox(:,2) + clippedBBox(:,4) - 1;

% Clip boxes so that they are within the upper-left corner of the image
xIndex = x1 < 1;
yIndex = y1 < 1;

clippedBBox(xIndex, 1) = 1;
clippedBBox(yIndex, 2) = 1;

% Update the width and height after clipping
clippedBBox(xIndex, 3) = x2(xIndex);
clippedBBox(yIndex, 4) = y2(yIndex);

% Clip boxes so that they are within the lower-right corner of the image.
clippedBBox(:,3) = min(imgSize(2), x2) - clippedBBox(:,1) + 1;
clippedBBox(:,4) = min(imgSize(1), y2) - clippedBBox(:,2) + 1;
