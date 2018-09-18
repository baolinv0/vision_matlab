function checkNetworkClassificationLayer(layers, groundTruth)

% Get the internal layers
internalLayers = nnet.internal.cnn.layer.util.ExternalInternalConverter.getInternalLayers(layers);

% The classification layer must support N classes plus a background class
processedLayers = nnet.internal.cnn.layer.util.inferParameters(internalLayers);
if processedLayers{end}.NumClasses ~= width(groundTruth)
    error(message('vision:rcnn:notEnoughObjectClasses'));
end