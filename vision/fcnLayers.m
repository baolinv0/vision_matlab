%fcnLayers Create Fully Convolutional Network (FCN) for semantic segmentation.
%
%   FCN is a convolutional neural network for semantic image segmentation.
%   It uses a pixelClassificationLayer to predict the categorical label for
%   every pixel in an input image.
%
%   Use fcnLayers to create the network architecture for FCN 32s, FCN 16s
%   or FCN 8s. These networks must be trained using trainNetwork from
%   Neural Network Toolbox before they can be used for semantic
%   segmentation.
%
%   lgraph = fcnLayers(imageSize, numClasses) returns a fully convolutional
%   network (FCN) for semantic segmentation. The network is pre-initialized
%   using layers and weights from VGG-16 and is configured as FCN 8s.
%   imageSize is the network image input size and specifies the [height
%   width] of input image. FCN only supports RGB images. numClasses is a
%   scalar that specifies the number of classes the network should be
%   configured to classify. The output lgraph is a LayerGraph object
%   representing the FCN network architecture.
%
%   lgraph = fcnLayers(..., Name, Value ) specifies additional name-value
%   pair arguments described below:
%
%   'Type'  The type of FCN to create specified as one of the 
%           following: '32s', '16s', or '8s'.
%
%           * FCN 32s upsamples the output of the final feature map by a
%             factor of 32. This provides coarse segmentation result with a
%             lower the computational cost.
%
%           * FCN 16s upsamples the final feature map by 16 after fusing
%             the feature map from the fourth pooling layer. This
%             additional information from earlier layers provides
%             medium-grain segmentation at the cost of additional
%             computation.
%
%           * FCN 8s upsamples the final feature map by 8 after fusing
%             feature maps from the 3rd and 4th max pooling layers. This
%             additional information from earlier layers provides
%             finer-grain segmentation at the cost of additional
%             computation.
%     
%           Default: '8s'
%
% Notes
% -----
% - All transposed convolution layer are initialized using bilinear
%   interpolation weights. The learning rate for all weights is fixed to 
%   zero.
% - All transposed convolution layer bias terms are fixed to zero.
% - The minimum image size is [224 224] because FCN is based on VGG-16.
%
% Example 1 - Create FCN 8s.
% ---------------------------
% imageSize = [480 640];
% numClasses = 5;
% lgraph = fcnLayers(imageSize, numClasses)
%
% % Display network.
% figure
% plot(lgraph)
%
% Example 2 - Create FCN 16s.
% ---------------------------
% imageSize = [480 640];
% numClasses = 5;
% lgraph = fcnLayers(imageSize, numClasses, 'Type', '16s')
%
% % Display network.
% figure
% plot(lgraph)
%
% See also segnetLayers, vgg16, vgg19, pixelClassificationLayer, LayerGraph, 
%          trainNetwork, DAGNetwork, semanticseg, pixelLabelImageSource.

% References 
% ----------
% Long, Jonathan, Evan Shelhamer, and Trevor Darrell. "Fully convolutional
% networks for semantic segmentation." Proceedings of the IEEE Conference
% on Computer Vision and Pattern Recognition. 2015.

% Copyright 2017 The MathWorks, Inc.

function lgraph = fcnLayers(imageSize, numClasses, varargin)

vision.internal.requiresNeuralToolbox(mfilename);

iCheckIfVGG16AddOnIsAvailable()

narginchk(2,inf);

type = parseInputs(imageSize, numClasses, varargin{:});

switch type
    case '32s'        
        lgraph = vision.internal.cnn.fcn32sLayers(imageSize, numClasses);
    case '16s'
        lgraph = vision.internal.cnn.fcn16sLayers(imageSize, numClasses);
    case '8s'
        lgraph = vision.internal.cnn.fcn8sLayers(imageSize, numClasses);        
end

%--------------------------------------------------------------------------
function type = parseInputs(imageSize, numClasses, varargin)

p = inputParser();
p.addParameter('Type', '8s');

p.parse(varargin{:});

% imageSize
validateattributes(imageSize, {'numeric'}, ...
    {'numel', 2, 'real', 'positive', 'finite', 'nonsparse', 'integer', '>=', 224}, ...
    mfilename, 'imageSize');

% numClasses
validateattributes(numClasses, {'numeric'}, ...
    {'scalar', 'real', 'positive', 'finite', 'nonsparse', 'integer', '>' 1}, ...
    mfilename, 'numClasses');

% type
type = validatestring(p.Results.Type, {'32s', '16s', '8s'}, mfilename, 'type');

%--------------------------------------------------------------------------
function iCheckIfVGG16AddOnIsAvailable()
breadcrumbFile = 'nnet.internal.cnn.supportpackages.IsVGG16Installed';
fullpath = which(breadcrumbFile);

if isempty(fullpath)
    name = 'Neural Network Toolbox Model for VGG-16 Network';
    error(message('vision:semanticseg:missingVGGAddon',name));
end

