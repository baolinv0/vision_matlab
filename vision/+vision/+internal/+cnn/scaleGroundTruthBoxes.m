function [groundTruth, scales, boxesRemoved] = scaleGroundTruthBoxes(groundTruth, imageSizes, imageLength, useParallel)
% Returns scaled groundTruth, scales used, and logical vector of
% groundTruth images where a box was removed because of scaling.


numImages = size(imageSizes,1);
scales = zeros(numImages,1);

if useParallel 
    
    parfor i = 1:numImages
       
        sz = imageSizes(i,:);
        
        [~, smallestSide] = min(sz(1:2));
        
        % scale the smallest side to value specified
        scales(i) = imageLength / sz(smallestSide);               
    end
    
    
    s = table2struct(groundTruth(:,2:end));
    
    boxesRemoved = false(1,height(groundTruth));
    
    % scale boxes in ground truth table
    fields = fieldnames(s);
    parfor i = 1:numel(s)
        
        a = s(i);
        bool = boxesRemoved(i);
        for j = 1:numel(fields)
            b = a.(fields{j});
           
            [bboxes, removed] = scaleBoxes(b, scales(i,:));            
            a.(fields{j}) = bboxes;
            
            % keep track if any boxes in i_th image were removed.
            bool = bool | removed;
            
        end  
        boxesRemoved(i) = bool;
        
        s(i) = a;
    end
    groundTruth = [groundTruth(:,1) struct2table(s, 'AsArray', true)];
  
else        

    for i = 1:numImages
        
        sz = imageSizes(i,:);
        
        [~, smallestSide] = min(sz(1:2));
        
        % scale the smallest side to value specified
        scales(i) = imageLength / sz(smallestSide);
    end
       
    % scale boxes in ground truth table
    boxesRemoved = false(1,height(groundTruth));
    for i = 1:height(groundTruth)
        
        for j = 2:width(groundTruth)
            
            [bboxes, removed] = scaleBoxes(groundTruth{i,j}{1}, scales(i,:));
            groundTruth{i,j} = {bboxes};
            
            boxesRemoved(i) = boxesRemoved(i) | removed;            
            
        end
        
    end
  
end

function [scaledBoxes, boxesRemoved] = scaleBoxes(boxes, scale)
% scale is [sy sx]
if isempty(boxes)
    scaledBoxes = zeros(0,4);
    boxesRemoved = false;
else
    
    % returned boxes are in [x1 y1 x2 y2] format
    scaledBoxes = vision.internal.cnn.scaleROI(boxes, scale, scale);
    
    % convert to [x y w h]
    scaledBoxes(:, 3) =  scaledBoxes(:, 3) - scaledBoxes(:, 1) + 1;
    scaledBoxes(:, 4) =  scaledBoxes(:, 4) - scaledBoxes(:, 2) + 1;

    % remove boxes that have been scaled to 0 width height.
    zeroWidthHeight = any(scaledBoxes(:, 3:4) < 1, 2);
    scaledBoxes(zeroWidthHeight,:) = [];    
    
    boxesRemoved = any(zeroWidthHeight);
end