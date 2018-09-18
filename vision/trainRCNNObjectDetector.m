function detector = trainRCNNObjectDetector(trainingData, network, options, varargin)
%trainRCNNObjectDetector Train an R-CNN deep learning object detector
% Use of this function requires that you have the Neural Network
% Toolbox(TM) and the Statistics and Machine Learning Toolbox(TM).
%
% This function supports training using a CUDA-capable NVIDIA(TM) GPU with
% compute capability 3.0 or higher. Use of a GPU is recommended and
% requires the Parallel Computing Toolbox(TM).
%
% detector = trainRCNNObjectDetector(trainingData, network, options) trains
% an R-CNN (Regions with CNN features) based object detector using deep
% learning. An R-CNN detector can be trained to detect multiple object
% classes.
%
% Inputs:
% -------
% trainingData  - a table with 2 or more columns. The first column must
%                 contain image file names. The images can be grayscale or
%                 true color, and can be in any format supported by IMREAD.
%                 The remaining columns must contain M-by-4 matrices of [x,
%                 y, width, height] bounding boxes specifying object
%                 locations within each image. Each column represents a
%                 single object class, e.g. person, car, dog. The table
%                 variable names define the object class names. You can use
%                 the imageLabeler app to create this table. 
%
% network       - a SeriesNetwork or an array of Layer objects defining the
%                 pre-trained network. The network is trained to classify
%                 object classes defined in the input trainingData. The
%                 SeriesNetwork and Layer object are available in the
%                 Neural Network Toolbox. See help for SeriesNetwork and
%                 nnet.cnn.layer for more details.
%
% options       - training options returned by the trainingOptions function
%                 from Neural Network Toolbox. The training options define
%                 the training parameters of the neural network. See help
%                 for trainingOptions for more details. For fine-tuning a
%                 pre-trained network for detection, it is recommended to
%                 lower the initial learning rate to avoid changing the
%                 model parameters too rapidly. For example, use the
%                 following syntax to adjust the learning rate: 
%
%                 options = trainingOptions('sgdm', 'InitialLearningRate', 1e-6);
%
%                 rcnn = trainRCNNObjectDetector(trainingData, network, options);
%
%                 Setting a 'CheckpointPath' using the trainingOptions is
%                 also recommended because network training may take a few
%                 hours.
%
% [...] = trainRCNNObjectDetector(..., Name, Value) specifies additional
% name-value pair arguments described below:
%
% 'PositiveOverlapRange' A two-element vector that specifies a range of
%                        bounding box overlap ratios between 0 and 1.
%                        Region proposals that overlap with ground truth
%                        bounding boxes within the specified range are used
%                        as positive training samples.
%
%                        Default: [0.5 1]
%
% 'NegativeOverlapRange' A two-element vector that specifies a range of
%                        bounding box overlap ratios between 0 and 1.
%                        Region proposals that overlap with ground truth
%                        bounding boxes within the specified range are used
%                        as negative training samples.
%
%                        Default: [0.1 0.5]
%
% 'NumStrongestRegions'  The maximum number of strongest region proposals
%                        to use for generating training samples. Reduce
%                        this value to speed-up processing time at the cost
%                        of training accuracy. Set this to inf to use all
%                        region proposals.
%
%                        Default: 2000
%
% [...] = trainRCNNObjectDetector(..., 'RegionProposalFcn', proposalFcn)
% optionally train an R-CNN detector using a custom region proposal
% function, proposalFcn.  If a custom region proposal function is not
% specified, a variant of the EdgeBoxes algorithm is automatically used. A
% custom proposalFcn must have the following functional form:
%
%    [bboxes, scores] = proposalFcn(I)
%
% where the input I is an image defined in the trainingData table. The
% function must return rectangular bounding boxes in an M-by-4 array. Each
% row of bboxes contains a four-element vector, [x, y, width, height]. This
% vector specifies the upper-left corner and size of a bounding box in
% pixels. The function must also return a score for each bounding box in an
% M-by-1 vector. Higher score values indicate that the bounding box is more
% likely to contain an object. The scores are used to select the strongest
% N regions, where N is defined by the value of 'NumStrongestRegions'.
%
% Notes:
% ------
% - trainRCNNObjectDetector supports parallel computing using
%   multiple MATLAB workers. Enable parallel computing using the 
%   <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>. 
%
% - This implementation of R-CNN does not train an SVM classifier for each
%   object class. 
%
% - The overlap ratio used in 'PositiveOverlapRange' and
%  'NegativeOverlapRange' is defined as area(A intersect B) / area(A union B),
%   where A and B are bounding boxes.
% 
% - Use the trainingOptions function to enable or disable verbose printing.
%
% - When the network is a SeriesNetwork, the network layers are
%   automatically adjusted to support the number of object classes defined
%   within the trainingData plus an extra "Background" class.
% 
% - When the network is an array of Layer objects, the network must have a
%   classification layer that supports the number of object classes plus a
%   background class. Use this input type when you want to customize the
%   learning rates of each layer. You may also use this type of input to
%   resume training from a previous training session. This can be useful if
%   the network requires additional rounds of fine-tuning or if you wish to
%   train with additional training data.
% 
% Example - Train a stop sign detector
% ------------------------------------
% load('rcnnStopSigns.mat', 'stopSigns', 'layers')
%
% % Add fullpath to image files
% stopSigns.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%     stopSigns.imageFilename);
%
% % Set network training options to use mini-batch size of 32 to reduce GPU
% % memory usage. Lower the InitialLearningRate to reduce the rate at which
% % network parameters are changed. This is beneficial when fine-tuning a
% % pre-trained network and prevents the network from changing too rapidly.
% % Set network training options. 
% %  * Lower the InitialLearningRate to reduce the rate at which network
% %    parameters are changed.
% %  * Set the CheckpointPath to save detector checkpoints to a temporary 
% %    directory. 
% options = trainingOptions('sgdm', ...
%     'MiniBatchSize', 32, ...
%     'InitialLearnRate', 1e-6, ...
%     'MaxEpochs', 10);
%
% % Train the R-CNN detector. Training can take a few minutes to complete.
% rcnn = trainRCNNObjectDetector(stopSigns, layers, options, 'NegativeOverlapRange', [0 0.3]);
%
% % Test the R-CNN detector on a test image.
% img = imread('stopSignTest.jpg');
%
% [bbox, score, label] = detect(rcnn, img, 'MiniBatchSize', 32);
%
% % Display strongest detection result
% [score, idx] = max(score);
%
% bbox = bbox(idx, :);
% annotation = sprintf('%s: (Confidence = %f)', label(idx), score);
%
% detectedImg = insertObjectAnnotation(img, 'rectangle', bbox, annotation);
%
% figure
% imshow(detectedImg)
%
% % <a href="matlab:showdemo('DeepLearningRCNNObjectDetectionExample')">Learn more about training an R-CNN Object Detector.</a> 
%
% See also rcnnObjectDetector, SeriesNetwork, trainingOptions, trainNetwork,
%          imageLabeler, trainCascadeObjectDetector,
%          nnet.cnn.layer.Layer.

% References:
% -----------
% Girshick, Ross, et al. "Rich feature hierarchies for accurate object
% detection and semantic segmentation." Proceedings of the IEEE conference
% on computer vision and pattern recognition. 2014.
%
% Girshick, Ross. "Fast r-cnn." Proceedings of the IEEE International
% Conference on Computer Vision. 2015.
%
% Zitnick, C. Lawrence, and Piotr Dollar. "Edge boxes: Locating object
% proposals from edges." Computer Vision-ECCV 2014. Springer International
% Publishing, 2014. 391-405.

vision.internal.requiresStatisticsToolbox(mfilename);
vision.internal.requiresNeuralToolbox(mfilename);

params = vision.internal.rcnn.parseInputs(trainingData, network, options, mfilename, varargin{:});

if params.IsNetwork
    % auto trim network for detection task
    layers = rcnnObjectDetector.initializeRCNNLayers(...
        network, params.NumClasses);
else
    layers = network;
end

layers = vision.internal.rcnn.removeAugmentationIfNeeded(layers,'randcrop');

detector = rcnnObjectDetector.train(trainingData, layers, options, params);

