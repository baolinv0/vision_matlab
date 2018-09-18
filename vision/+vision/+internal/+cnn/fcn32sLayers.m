%fcn32sLayers Create FCN 32s.

% Copyright 2017 The MathWorks, Inc.
function lgraph = fcn32sLayers(imageSize, numClasses)

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
% * Fix weight learning rate to zero.

upscore = transposedConv2dLayer(64, numClasses, ...
    'NumChannels', numClasses, 'Stride', 32, 'Name', 'upscore');
upscore.Weights = vision.internal.cnn.bilinearUpsamplingWeights([64 64], numClasses, numClasses);
upscore.Bias = zeros(1,1,numClasses);
upscore.BiasL2Factor = 0;
upscore.BiasLearnRateFactor = 0;
upscore.WeightLearnRateFactor = 0;
upscore.WeightL2Factor = 0;

%% add in layers
layers = [
    layers
    convolution2dLayer(1, numClasses, 'Name', 'score_fr');
    upscore  
    crop2dLayer('centercrop', 'Name', 'score')
    softmaxLayer('Name', 'softmax')
    pixelClassificationLayer('Name', 'pixelLabels')
    ];

lgraph = layerGraph(layers);

% connect image output to second input of crop ("score")
lgraph = connectLayers(lgraph, 'input', 'score/ref');
