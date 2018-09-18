%pixelClassificationLayer Pixel classification layer for semantic segmentation.
%
%   layer = pixelClassificationLayer() creates a pixel classification
%   output layer for semantic image segmentation networks. The layer
%   outputs the categorical label for each image pixel processed by a
%   convolutional neural network (CNN).
%
%   layer = pixelClassificationLayer('Name', Value) specifies additional
%   name-value pair arguments described below:
% 
%      'ClassNames'    Specify class names as string vector, cell array
%                      of character vectors, or 'auto'. When 'auto' is
%                      specified, the class names are automatically set
%                      during training. 
%  
%                      Default: 'auto'
%
%      'ClassWeights   Specify a weight for each class as a vector W.
%                      The weight W(k) corresponds to k-th class name in
%                      ClassNames. Use class weighting to balance classes
%                      when there are underrepresented classes in the
%                      training data.
%
%                      ClassNames must also be specified when ClassWeights
%                      is specified.
% 
%                      Default: 'none'
%
%      'Name'          A name for the layer. The default is ''.
%
% Notes
% -----
% - The layer automatically ignores undefined pixel labels during training.
%
% Example 1
% ---------
%     Use a pixelClassificationLayer to create a semantic segmentation
%     network. A pixelClassificationLayer predicts the categorical label
%     of every pixel in an input image.
%
%     layers = [
%         imageInputLayer([32 32 3])
%         convolution2dLayer(3, 16, 'Stride', 2, 'Padding', 1)
%         reluLayer()
%         transposedConv2dLayer(3, 1, 'Stride', 2, 'Cropping', 1)
%         pixelClassificationLayer()
%     ]
% 
% Example 2 
% ---------
%     Balance classes using inverse class frequency weighting when some
%     classes are underrepresented in the training data. First, count class
%     frequencies over the training data using pixelLabelImageSource.
%     Then, set the 'ClassWeights' in pixelClassificationLayer to the
%     computed inverse class frequencies.
%
%     % Location of image and pixel label data
%     dataDir = fullfile(toolboxdir('vision'), 'visiondata');
%     imDir = fullfile(dataDir, 'building');
%     pxDir = fullfile(dataDir, 'buildingPixelLabels');
%     
%     % Create datasource using ground truth and pixel labeled images.
%     imds = imageDatastore(imDir);
%     classNames = ["sky" "grass" "building" "sidewalk"];
%     pixelLabelID = [1 2 3 4];
%     pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);     
%     src = pixelLabelImageSource(imds, pxds);
%     
%     % Tabulate class distribution in dataset.
%     tbl = countEachLabel(src)
%
%     % Calculate inverse frequency class weights.
%     totalNumberOfPixels = sum(tbl.PixelCount);
%     frequency = tbl.PixelCount / totalNumberOfPixels;
%     inverseFrequency = 1./frequency
%  
%     % Set 'ClassWeights' to the inverse class frequencies.
%     layer = pixelClassificationLayer(...
%         'ClassNames', tbl.Name, 'ClassWeights', inverseFrequency)
%
% See also semanticseg, pixelLabelImageSource, pixelLabelDatastore,
%          pixelLabelImageSource/countEachLabel, trainNetwork, 
%          nnet.cnn.layer.PixelClassificationLayer.

% Copyright 2017 Mathworks, Inc.

function layer = pixelClassificationLayer(varargin)

vision.internal.requiresNeuralToolbox(mfilename);

% Parse the input arguments
args = nnet.cnn.layer.PixelClassificationLayer.parseInputs(varargin{:});

% Create an internal representation of a cross entropy layer
internalLayer = nnet.internal.cnn.layer.SpatialCrossEntropy( ...
    args.Name, ...
    args.ClassNames,...
    args.ClassWeights, ...
    []);

% Pass the internal layer to a function to construct
layer = nnet.cnn.layer.PixelClassificationLayer(internalLayer);

end
