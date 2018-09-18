%fcn16sLayers Create FCN 16s.

% Copyright 2017 The MathWorks, Inc.

function lgraph = fcn16sLayers(imageSize, numClasses)

%% Load VGG-16 Network
net = vgg16();

layers = net.Layers;

layers(1) = imageInputLayer([imageSize 3], 'Name', layers(1).Name,...
    'DataAugmentation', layers(1).DataAugmentation, ...
    'Normalization', layers(1).Normalization);

%% Replace Fully Connected Layers with Convolution 2D Layers

% fc6 is layers 33
idx = 33;
weights = layers(idx).Weights';
weights = reshape(weights, 7, 7, 512, 4096);
bias = reshape(layers(idx).Bias, 1, 1, []);

layers(idx) = convolution2dLayer(7, 4096, 'NumChannels', 512, 'Name', 'fc6');
layers(idx).Weights = weights;
layers(idx).Bias = bias;

% fc7 is layers 33
idx = 36;
weights = layers(idx).Weights';
weights = reshape(weights, 1, 1, 4096, 4096);
bias = reshape(layers(idx).Bias, 1, 1, []);

layers(idx) = convolution2dLayer(1, 4096, 'NumChannels', 4096, 'Name', 'fc7');
layers(idx).Weights = weights;
layers(idx).Bias = bias;

%% Add padding to first conv layer
% Follow approach used in FCN and add [100 100] padding.
conv1 = layers(2);
conv1New = convolution2dLayer(conv1.FilterSize, conv1.NumFilters, ...
    'Stride', conv1.Stride, ...
    'Padding', [100 100], ...
    'NumChannels', conv1.NumChannels, ...
    'WeightLearnRateFactor', conv1.WeightLearnRateFactor, ...
    'WeightL2Factor', conv1.WeightL2Factor, ...
    'BiasLearnRateFactor', conv1.BiasLearnRateFactor, ...
    'BiasL2Factor', conv1.BiasL2Factor, ...
    'Name', conv1.Name);

layers(2) = conv1New;

%% Remove Image Classification Layers
layers(end-2:end) = [];

%% Create transposed convolution layer (a.k.a. deconv layers)
% * Initialize weights using bilinear interpolation coefficients.
% * Disable bias term.
% * Fix weights learning rate to zero.

upscore2 = transposedConv2dLayer(4, numClasses, ...
    'NumChannels', numClasses, 'Stride', 2, 'Name', 'upscore2');
upscore2.Weights = vision.internal.cnn.bilinearUpsamplingWeights([4 4], numClasses, numClasses);
upscore2.Bias = zeros(1,1,numClasses);
upscore2.BiasL2Factor = 0;
upscore2.BiasLearnRateFactor = 0;
upscore2.WeightLearnRateFactor = 0;
upscore2.WeightL2Factor = 0;


upscore16 = transposedConv2dLayer(32, numClasses, ...
    'NumChannels', numClasses, 'Stride', 16, 'Name', 'upscore16') ;
upscore16.Weights = vision.internal.cnn.bilinearUpsamplingWeights([32 32], numClasses, numClasses);
upscore16.Bias = zeros(1,1,numClasses);
upscore16.BiasL2Factor = 0;
upscore16.BiasLearnRateFactor = 0;
upscore16.WeightLearnRateFactor = 0;
upscore16.WeightL2Factor = 0;

%% add in layers
layers = [
    layers
    convolution2dLayer(1, numClasses, 'Name', 'score_fr');
    upscore2
    additionLayer(2, 'Name', 'fuse') 
    upscore16
    crop2dLayer('centercrop', 'Name', 'score')
    softmaxLayer('Name', 'softmax')
    pixelClassificationLayer('Name', 'pixelLabels')
    ];

lgraph = layerGraph(layers);

%% Create layerGraph


%% Add Pixel Classification Layers

skipLayerBranch = [
    
    convolution2dLayer(1, numClasses, 'Name', 'score_pool4')
    crop2dLayer('centercrop', 'Name', 'score_pool4c')    
    
    ];

%% Create layerGraph
lgraph = lgraph.addLayers(skipLayerBranch);

%% Connect Skip Layer Branch

% connect pool4 to score_pool4
lgraph = connectLayers(lgraph, 'pool4', 'score_pool4');

% connect upscore2 to second input of score_pool4c
lgraph = connectLayers(lgraph, 'upscore2', 'score_pool4c/ref');

% connect score_pool4c to second input of fuse_pool4
lgraph = connectLayers(lgraph, 'score_pool4c', 'fuse/in2');

% connect input to second input of score
lgraph = connectLayers(lgraph, 'input', 'score/ref');
