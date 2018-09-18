function [miniBatchData, miniBatchResponse, miniBatchLabels] = batchReadAndCropForBBoxRegression(...
    imds, trainingSamples, regionResizer, randomSelector, ...
    start, stop, miniBatchSize, numPosSamples)

networkImageSize = regionResizer.ImageSize;

% gather samples
numImages   = stop - start;
posSamples  = cell(numImages,1);
posResponse = cell(numImages,1);
posLabels   = cell(numImages,1);
k = 1;

for i = start:stop-1
        
    I = readimage(imds, i);
    
    I = localConvertImageToMatchNumberOfNetworkImageChannels(I, networkImageSize);
    
    posSamples{k} = regionResizer.cropAndResize(I, trainingSamples.Boxes{i});
                      
    % regression response
    posResponse{k} = trainingSamples.Targets{i}; 
    
    % labels
    posLabels{k} = trainingSamples.Labels{i};
    
    k = k + 1; 
end

posSamples  = cat(4, posSamples{:});
posResponse = vertcat(posResponse{:});
posLabels   = vertcat(posLabels{:});

% There may be more positive samples than we need, randomly
% sample enough to fill mini-batch.
pidx = randomSelector.randperm(numPosSamples, min(miniBatchSize, numPosSamples));

miniBatchData = cat(4,posSamples(:,:,:,pidx));

miniBatchResponse = posResponse(pidx,:);
miniBatchLabels   = posLabels(pidx);

%--------------------------------------------------------------------------
function I = localConvertImageToMatchNumberOfNetworkImageChannels(I, imageSize)

isNetImageRGB = numel(imageSize) == 3 && imageSize(end) == 3;
isImageRGB    = ~ismatrix(I);

if isImageRGB && ~isNetImageRGB
    I = rgb2gray(I);
    
elseif ~isImageRGB && isNetImageRGB
    I = repmat(I,1,1,3);
end

