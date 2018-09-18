function [miniBatchData, miniBatchResponse] = batchReadAndCrop(...
    imds, tbl, trainingSamples, regionResizer, randomSelector, ...
    start, stop, numPos, numPosSamples, currentMiniBatchSize)

networkImageSize = regionResizer.ImageSize;

% mini-batch size smaller than 4 will have no positive samples!
assert(currentMiniBatchSize >= 4);

numNeg = currentMiniBatchSize - numPos;

% gather samples
numImages = stop - start;
posSamples = cell(numImages,1);
negSamples = cell(numImages,1);
posResponse = cell(numImages,1);
negResponse = cell(numImages,1);
k = 1;

negSamplesPerImage = round(numNeg/numImages);

for i = start:stop-1
    samples = tbl.RegionProposalBoxes{i};
    
    I = readimage(imds, i);
    
    I = localConvertImageToMatchNumberOfNetworkImageChannels(I, networkImageSize);
    
    posSamples{k} = regionResizer.cropAndResize(I, ...
        samples(trainingSamples.Positive{i},:));
    
    % only crop out enough samples to fill current mini-batch.
    bb = samples(trainingSamples.Negative{i},:);
    labels = trainingSamples.Labels{i};
    N = size(bb,1);
    
    id = randomSelector.randperm(N, min(N, negSamplesPerImage));
    negSamples{k} = regionResizer.cropAndResize(I, bb(id,:));
    
    % response
    posResponse{k} = labels(trainingSamples.Positive{i});
    negResponse{k} = labels(trainingSamples.Negative{i});
    k = k + 1; 
end

posSamples = cat(4, posSamples{:});
negSamples = cat(4, negSamples{:});
numNegSamples = size(negSamples,4);

posResponse = vertcat(posResponse{:});
negResponse = vertcat(negResponse{:});

% There may be more positive samples than we need, randomly
% sample enough to fill mini-batch.
pidx = randomSelector.randperm(numPosSamples, min(numPos, numPosSamples));
nidx = randomSelector.randperm(numNegSamples, min(numNeg, numNegSamples));

miniBatchData = cat(4,posSamples(:,:,:,pidx), negSamples(:,:,:,nidx));

% data in mini-batch need not be shuffled. training responses
% are averaged over all mini-batch samples so order does not
% matter.
miniBatchResponse = nnet.internal.cnn.util.dummify(...
    [posResponse(pidx); negResponse(nidx)]);

%--------------------------------------------------------------------------
function I = localConvertImageToMatchNumberOfNetworkImageChannels(I, imageSize)

isNetImageRGB = numel(imageSize) == 3 && imageSize(end) == 3;
isImageRGB    = ~ismatrix(I);

if isImageRGB && ~isNetImageRGB
    I = rgb2gray(I);
    
elseif ~isImageRGB && isNetImageRGB
    I = repmat(I,1,1,3);
end

