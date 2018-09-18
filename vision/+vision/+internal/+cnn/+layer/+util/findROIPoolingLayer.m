function idx = findROIPoolingLayer(internalLayers)
% Returns index to ROI Average or ROI Max pooling layer. 

% Can use one isa check because average pooling inherits from max pooling.
idx = find(...
    cellfun( @(x)isa(x,'vision.internal.cnn.layer.ROIMaxPooling2DLayer'), ...
    internalLayers), 1, 'last');

end
