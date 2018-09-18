function [miniBatchData, miniBatchResponse] = batchReadAndCropParallel(...
    constDS, constTable, constTrainingSamples, constRegionResizer, constRandomSelector, ...
    start, stop, numPos, numPosSamples, currentMiniBatchSize)

% Access constant values on workers
constDS = constDS.Value;
constTable = constTable.Value;
constTrainingSamples = constTrainingSamples.Value;
constRegionResizer = constRegionResizer.Value;
constRandomSelector = constRandomSelector.Value;

[miniBatchData, miniBatchResponse] = vision.internal.rcnn.batchReadAndCrop(...
    constDS, constTable, constTrainingSamples, constRegionResizer, constRandomSelector, ...
    start, stop, numPos, numPosSamples, currentMiniBatchSize);