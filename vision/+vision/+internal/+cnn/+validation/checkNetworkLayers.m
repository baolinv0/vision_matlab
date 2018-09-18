function checkNetworkLayers(layers)

% First layer must have an image input layer
if ~(numel(layers) >= 1 && isa(layers(1), 'nnet.cnn.layer.ImageInputLayer'))
    error(message('vision:rcnn:firstLayerNotImageInputLayer'));
end

% Last two layers must be softmax followed by a classification layer
if ~(numel(layers) >= 3 && ...
        isa(layers(end), 'nnet.cnn.layer.ClassificationOutputLayer') && ...
        isa(layers(end-1), 'nnet.cnn.layer.SoftmaxLayer'))
    
    error(message('vision:rcnn:lastLayerNotClassificationLayer'));
end