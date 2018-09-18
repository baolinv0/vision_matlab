function [anchorBoxes, anchorID] = generateAnchorBoxesInImage(...
    imageSize, featureMapSize, boxSizes, boxPyramidScale, numLevels)
% Returns anchorBoxes in a cell array. Each cell element contains a set of
% boxes generated at 1 scale and aspect ratio. 
%
% Each box is centered within the receptive field. 
%
% anchorID is a cell array. it is the index into the feature map where each
% anchor box maps. Two anchor boxes can map to the same feature map
% location. The ID helps prevent using the same feature for both positive
% and negative samples. 

scaleFactor = imageSize(1:2)./featureMapSize(1:2);

sx = scaleFactor(2);
sy = scaleFactor(1);

stepX = floor(sx);
stepY = floor(sy);

offset = locateBaseOffset(sx, sy);

base_offsetx = offset(1);
base_offsety = offset(2);

width = imageSize(2);
height = imageSize(1);

anchorBoxes = {};
anchorID = {};


boxScales = cumprod([1 repelem(boxPyramidScale, numLevels-1)]);

for j = 1:size(boxSizes,1)
    
    boxSize = boxSizes(j,:);
    
    for i = 1:numel(boxScales)
                      
        sz = boxSize .* boxScales(i);               
        
        halfWidth = floor(sz ./ 2);
        
        nx = ceil(halfWidth(2) / base_offsetx);
        ny = ceil(halfWidth(1) / base_offsety);
        
        offsetx = nx*base_offsetx;
        offsety = ny*base_offsety;
        
        gridX = offsetx:stepX:(width-halfWidth(2));
        gridY = offsety:stepY:(height-halfWidth(1));
        
        % box center
        [xCenter, yCenter] = meshgrid(gridX, gridY);
        
        xCenter = reshape(xCenter,[],1);
        yCenter = reshape(yCenter,[],1);
        
        dim = repelem(fliplr(sz), size(xCenter,1), 1);
        
        boxes = [ (xCenter - halfWidth(2) + 1) (yCenter - halfWidth(1) + 1) dim];
        
        anchorBoxes{i + (j-1)*numel(boxScales)} = boxes;
        
        
        ax = ceil(gridX/sx);
        ay = ceil(gridY/sy);
        
        [ax,ay] = meshgrid(ax,ay);
        
        
        ids = [ax(:) ay(:)];
        anchorID{i + (j-1)*numel(boxScales)} = ids;
        
        assert( all(ax(:) >= 1) )
        
        assert( all(ay(:) >= 1) )
        
        assert( all(ax(:) <= featureMapSize(2)) )
        
        assert( all(ay(:) <= featureMapSize(1)) )
        
        assert( size(anchorBoxes{i + (j-1)*numel(boxScales)},1) == size(anchorID{i + (j-1)*numel(boxScales)},1) );
    end
    
    
end
           
function boxCenters = locateBaseOffset(sx, sy)
x = 1:1;
y = 1:1;
[x,y] = meshgrid(x,y);
froi = [x(:), y(:), ones(numel(x(:)),2)];

% min/max format output
scaledROI = vision.internal.cnn.scaleROI(froi, sx, sy);

boxCenters = scaledROI(:,[1 2]) + floor((scaledROI(:,[3 4]) - scaledROI(:,[1 2]))/2);