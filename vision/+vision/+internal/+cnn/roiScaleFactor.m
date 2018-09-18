function [sx, sy] = roiScaleFactor(internalLayers, inputSize)
% returns the scale factors, sx and sy, for scaling ROI from the image
% space to the feature map space.
%
% internalLayers contain all layers up to, but not including, the ROI
% pooling layer.

featureMapSize = inputSize;
for i = 2:numel(internalLayers) % start from 2 to exclude image layer
    featureMapSize = internalLayers{i}.forwardPropagateSize(featureMapSize);
end

scaleFactor = featureMapSize(1:2) ./ inputSize(1:2);

sx = scaleFactor(2);
sy = scaleFactor(1);


end