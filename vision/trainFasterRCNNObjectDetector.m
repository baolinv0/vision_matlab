%trainFasterRCNNObjectDetector Train a Faster R-CNN deep learning object detector.
% Use of this function requires that you have the Neural Network Toolbox(TM).
% 
% This function supports training using a CUDA-capable NVIDIA(TM) GPU with
% compute capability 3.0 or higher. Use of a GPU is recommended and
% requires the Parallel Computing Toolbox(TM).
%
% detector = trainFasterRCNNObjectDetector(trainingData, network, options)
% trains a Faster R-CNN (Regions with CNN features) object detector using
% deep learning. A Faster R-CNN detector can be trained to detect multiple
% object classes.
% 
% Inputs
% ------
% trainingData - a table with 2 or more columns. The first column must
%                contain image file names. The images can be grayscale or
%                true color, and can be in any format supported by IMREAD.
%                The remaining columns must contain M-by-4 matrices of [x,
%                y, width, height] bounding boxes specifying object
%                locations within each image. Each column represents a
%                single object class, e.g. person, car, dog. The table
%                variable names define the object class names. You can use
%                the imageLabeler app to create this table.
%
% network      - a SeriesNetwork or an array of Layer objects defining the
%                network. The input network is used to create a Fast R-CNN
%                object detection network. The SeriesNetwork and Layer
%                object are available in the Neural Network Toolbox. See
%                <a href="matlab:doc SeriesNetwork">SeriesNetwork</a> and <a href="matlab:doc nnet.cnn.layer.Layer">nnet.cnn.layer.Layer</a> documentation for
%                more details.
%
% options      - training options returned by the trainingOptions function
%                from Neural Network Toolbox. The training options define
%                the training parameters of the neural network. See
%                <a href="matlab:doc trainingOptions">trainingOptions documentation</a> for more details. For
%                fine-tuning a pre-trained network for detection, it is
%                recommended to lower the initial learning rate to avoid
%                changing the model parameters too rapidly. For example,
%                use the following syntax to adjust the learning rate:
%
%                options = trainingOptions('sgdm', ...
%                           'InitialLearningRate', 1e-6, ...
%                           'CheckpointPath', tempdir);
%
%                detector = trainFasterRCNNObjectDetector(trainingData, network, options);
%
%                Setting a 'CheckpointPath' using the trainingOptions is
%                recommended because network training may take a few
%                hours.
% 
%                Specify a single set of training options or an array of 4
%                training options. When a single set of training options is
%                specified, the same set of options is used for all four
%                training stages. When an array of 4 options is specified,
%                each training stage uses its own set of options. 
%
% Resume Training
% ---------------
% When the 'CheckpointPath' is set using the trainingOptions function,
% detector checkpoints are periodically saved to a MAT-file at the location
% specified by 'CheckpointPath'. You may resume training from any one of
% these checkpoints by loading one of the MAT-files and passing the loaded
% detector checkpoint to the trainFasterRCNNObjectDetector function:
%
% [...] = trainFasterRCNNObjectDetector(trainingData, checkpoint, options, ...) 
% resumes training from a detector checkpoint. checkpoint must be a
% fasterRCNNObjectDetector object.
%
% Fine-tuning a detector
% ----------------------
% [...] = trainFastRCNNObjectDetector(trainingData, detector, options)
% continues training a Faster R-CNN object detector. Use this syntax to
% continue training a detector with additional training data or to perform
% more training iterations to improve detector accuracy. 
%
% % Additional input arguments
% ----------------------------
% [...] = trainFasterRCNNObjectDetector(..., Name, Value) specifies
% additional name-value pair arguments described below:
%
% 'PositiveOverlapRange' A two-element vector that specifies a range of
%                        bounding box overlap ratios between 0 and 1.
%                        Region proposals that overlap with ground truth
%                        bounding boxes within the specified range are used
%                        as positive training samples. Overlap ratio is
%                        computed using intersection-over-union between two
%                        bounding boxes.
%
%                        Default: [0.5 1]
%
% 'NegativeOverlapRange' A two-element vector that specifies a range of
%                        bounding box overlap ratios between 0 and 1.
%                        Region proposals that overlap with ground truth
%                        bounding boxes within the specified range are used
%                        as negative training samples. Overlap ratio is
%                        computed using intersection-over-union between two
%                        bounding boxes.
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
% 'SmallestImageDimension' The desired length, L, of the smallest image
%                          dimension in pixels. Training images are resized
%                          such that length of the shortest dimension
%                          (width or height) is equal to L. The aspect
%                          ratio of the image is preserved after resizing.
%                          By default, L is [], and training images are not
%                          resized. Resizing training images helps reduce
%                          computational costs and memory usage when
%                          training images are large. Typical values are
%                          between 400 - 600 pixels.
%
%                          Default: []
% 
% 'MinBoxSizes'         The minimum anchor box sizes. Valid values are
%                       'auto' or an M-by-2 matrix. If 'auto' is specified,
%                       the minimum box sizes are selected based on the
%                       aspect ratios and sizes of objects within the
%                       ground truth data. Otherwise, manually specify an
%                       M-by-2 matrix defining the minimum size of M anchor
%                       boxes. Each row defines the [height width] of an
%                       anchor box.
%
%                       Default: 'auto'
%
% 'BoxPyramidScale'     The scale factor used to successively upscale
%                       anchor box sizes. Recommended values are between 1
%                       and 2.
%                       
%                       Default: 2
%
% 'NumBoxPyramidLevels' The number of levels in an anchor box pyramid.
%                       Valid values are 'auto' or a numeric scalar. If
%                       'auto' is specified, the number of levels is
%                       selected based on the size of objects within the
%                       ground truth data. Otherwise, manually specify the
%                       number of levels as a scalar. Select a value that
%                       ensures the multi-scale anchor boxes are comparable
%                       in size to the size of objects in the ground truth
%                       data.
%
%                       Default: 'auto'
%
% Notes
% -----
% - The i-th anchor box pyramid contains anchor boxes with the following 
%   sizes:
%
%      MinBoxSizes(i,:) .* BoxPyramidScale .^ (0:NumBoxPyramidLevels-1)'
%
% - Faster R-CNN training is implemented using the 4-step alternating
%   training method described in 
%
%     Ren, Shaoqing, et al. "Faster R-CNN: Towards real-time object
%     detection with region proposal networks." Advances in neural
%     information processing systems. 2015.
%
% Example - Train a detector.
% ---------------------------
%
% % Load training data.
% data = load('fasterRCNNVehicleTrainingData.mat');
%
% % Use first few rows to reduce example training time. Training with all
% % the data can take a several minutes.
% trainingData = data.vehicleTrainingData(1:5,:);
%
% trainingData.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%     trainingData.imageFilename);
%
% % Setup network layers.
% layers = data.layers
%
% % Configure training options.
% %  * Lower the InitialLearningRate to reduce the rate at which network
% %    parameters are changed.
% %  * Set the CheckpointPath to save detector checkpoints to a temporary 
% %    directory. Change this to another location if required.
% %  * Set MaxEpochs to 1 to reduce example training time. Increase this
% %    to 10 for proper training.
% options = trainingOptions('sgdm', ...
%     'InitialLearnRate', 1e-6, ...
%     'MaxEpochs', 1, ...
%     'CheckpointPath', tempdir);
% 
% % Train detector.
% detector = trainFasterRCNNObjectDetector(trainingData, layers, options)
%
% % Test the Fast R-CNN detector on a test image.
% img = imread('highway.png');
% 
% % Run detector. 
% [bbox, score, label] = detect(detector, img);
% 
% % Display detection results.
% detectedImg = insertShape(img, 'Rectangle', bbox);
% figure
% imshow(detectedImg)
%
% % See <a href="matlab:helpview('vision','DeepLearningFasterRCNNObjectDetectionExample')">Object Detection using Faster R-CNN Deep Learning</a> for a detailed example.
%
% See also trainRCNNObjectDetector, trainFastRCNNObjectDetector,
%          trainACFObjectDetector, trainCascadeObjectDetector,
%          fasterRCNNObjectDetector, trainingOptions, SeriesNetwork, 
%          nnet.cnn.layer.Layer, imageLabeler.

%
% References:
% -----------
% [1] Girshick, Ross, et al. "Rich feature hierarchies for accurate object
%     detection and semantic segmentation." Proceedings of the IEEE
%     conference on computer vision and pattern recognition. 2014.
%
% [2] Girshick, Ross. "Fast r-cnn." Proceedings of the IEEE International
%     Conference on Computer Vision. 2015.
%
% [3] Zitnick, C. Lawrence, and Piotr Dollar. "Edge boxes: Locating object
%     proposals from edges." Computer Vision-ECCV 2014. Springer
%     International Publishing, 2014. 391-405.
%
% [4] Ren, Shaoqing, et al. "Faster R-CNN: Towards real-time object
%     detection with region proposal networks." Advances in neural
%     information processing systems. 2015.

% Copyright 2016 The MathWorks, Inc. 

function detector = trainFasterRCNNObjectDetector(trainingData, network, options, varargin)
 
vision.internal.requiresNeuralToolbox(mfilename);

[trainingData, fastRCNN, rpn, options, params] = ...
    vision.internal.cnn.parseInputsFasterRCNN(...
    trainingData, network, options, mfilename, varargin{:});

% Configure printer for verbose printing
printer = vision.internal.MessagePrinter.configure(options(1).Verbose);

% Configure detector checkpoint saver
checkpointSaver = vision.internal.cnn.DetectorCheckpointSaver( options(1).CheckpointPath );
checkpointSaver.DetectorFcn = @(net,dd)fasterRCNNObjectDetector.detectorCheckpoint(net, dd);

fasterRCNNObjectDetector.printHeader(printer, trainingData);

if any(params.TrainingStage == [1 2 3 4])
    printer.printMessage('vision:rcnn:resumeTrainingAtStage',find(params.DoTrainingStage,1,'first'));
    printer.linebreak;
end

if params.DoTrainingStage(1)
    
    printer.printMessage('vision:rcnn:fasterStep1');
    
    % Step 1: Train RPN network
    params.TrainingStage = 1;
    checkpointSaver.CheckpointPrefix = 'faster_rcnn_stage_1';
    checkpointSaver.CheckpointPath = options(1).CheckpointPath;
    checkpointSaver.Detector = iCheckPointDetector(fastRCNN, rpn, params);   
    
    [d, rpn] = fasterRCNNObjectDetector.trainRPN(trainingData, rpn, options(1), params, checkpointSaver);
    
    printer.linebreak;
else
    d = iCheckPointDetector(fastRCNN, rpn, params);
end

minBoxSize = params.ModelSize;
% MinObjectSize is used within Fast R-CNN trainer. Set it to the model size.
params.MinObjectSize = params.ModelSize;

miniBatchSize = options.MiniBatchSize;

if params.DoTrainingStage(2)
    
    % Step 2: Use RPN as region proposal function for training Fast
    % R-CNN. Use the same layers used to train RPN.
    printer.printMessage('vision:rcnn:fasterStep2');
    params.RegionProposalFcn = @(x)d.propose(x,minBoxSize,'MiniBatchSize',miniBatchSize);
    params.UsingDefaultRegionProposalFcn = false;
    
    % disable parallel b/c region proposals will use RPN on GPU.
    prev = params.UseParallel;
    params.UseParallel = false;
    
    % Update checkpoint for stage 2
    params.TrainingStage = 2;
    checkpointSaver.CheckpointPrefix = 'faster_rcnn_stage_2';
    checkpointSaver.CheckpointPath = options(2).CheckpointPath;
    checkpointSaver.Detector = iCheckPointDetector(fastRCNN, rpn, params);
        
    [~, fastRCNN] = fastRCNNObjectDetector.train(trainingData, fastRCNN, options(2), params, checkpointSaver);
    
    params.UseParallel = prev;
    
    printer.linebreak;
end

% Freeze conv layers for final training stages.
frozenConvLayers = iFreezeConvLayers(fastRCNN.Layers);

% Keep previous layers, so we can revert back to original settings. We will
% only revert the weight and bias learn rate factors.
prevConvLayers = fastRCNN.Layers;

if params.DoTrainingStage(3)
    % Step 3: Fine-tune RPN using frozen conv layers form Fast R-CNN.
    
    printer.printMessage('vision:rcnn:fasterStep3');
             
    rpnLayers = rpn.Layers;
    
    rpnLayers(1:params.LastConvLayerIdx) = frozenConvLayers(1:params.LastConvLayerIdx);
    
    rpn = vision.cnn.RegionProposalNetwork(rpnLayers, rpn.RegLayers, rpn.BranchLayerIdx);
    
    % Update checkpoint for stage 3
    params.TrainingStage = 3;
    checkpointSaver.CheckpointPrefix = 'faster_rcnn_stage_3';
    checkpointSaver.CheckpointPath = options(3).CheckpointPath;
    checkpointSaver.Detector = iCheckPointDetector(fastRCNN, rpn, params);    
    
    [d, rpn] = fasterRCNNObjectDetector.trainRPN(trainingData, rpn, options(3), params, checkpointSaver);
    
    printer.linebreak;
else
    d = iCheckPointDetector(fastRCNN, rpn, params);
end

if params.DoTrainingStage(4)
    % Step 4: Train Fast-RCNN using frozen layers of RPN
    printer.printMessage('vision:rcnn:fasterStep4');
    params.RegionProposalFcn = @(x)d.propose(x,minBoxSize,'MiniBatchSize',miniBatchSize);
    params.UsingDefaultRegionProposalFcn = false;
    
    % disable parallel b/c region proposals will use RPN on GPU.
    prev = params.UseParallel;
    params.UseParallel = false;
    
    % Freeze fastRCNN layers. These are the same as the RPN layers.
    fastRCNNLayers = fastRCNN.Layers;
    
    fastRCNNLayers(1:params.LastConvLayerIdx) = frozenConvLayers(1:params.LastConvLayerIdx);
    
    fastRCNN = vision.cnn.FastRCNN(fastRCNNLayers, fastRCNN.RegLayers, fastRCNN.BranchLayerIdx);
    
    % Update checkpoint for stage 4
    params.TrainingStage = 4;
    checkpointSaver.CheckpointPrefix = 'faster_rcnn_stage_4';
    checkpointSaver.CheckpointPath = options(4).CheckpointPath;
    checkpointSaver.Detector = iCheckPointDetector(fastRCNN, rpn, params);    
    
    % Fine-tune Fast R-CNN
    [~, frcnn] = fastRCNNObjectDetector.train(trainingData, fastRCNN, options(4), params, checkpointSaver);
    
    % Unfreeze weights back to their original settings.
    fastRCNNLayers = iUnfreezeConvLayers(frcnn.Layers, prevConvLayers);
    frcnn = vision.cnn.FastRCNN(fastRCNNLayers, frcnn.RegLayers, frcnn.BranchLayerIdx);
    
    params.UseParallel = prev;
    
    printer.linebreak;
end

printer.printMessage('vision:rcnn:fasterTrainingDone');
printer.linebreak;

% Mark training complete.
params.TrainingStage = 5;
detector = iCheckPointDetector(frcnn, rpn, params);

%--------------------------------------------------------------------------
function detector = iCheckPointDetector(frcnn, rpn, params)
detector = fasterRCNNObjectDetector.checkPointDetector(frcnn, rpn, params);

%--------------------------------------------------------------------------
function layers = iFreezeConvLayers(layers)
for i = 1:numel(layers)
    if isa(layers(i),'nnet.cnn.layer.Convolution2DLayer')
        layers(i).WeightLearnRateFactor = 0;
        layers(i).BiasLearnRateFactor = 0;
        layers(i).WeightL2Factor = 0;
        layers(i).BiasL2Factor = 0;
    end
end 

%--------------------------------------------------------------------------
function layers = iUnfreezeConvLayers(layers, prevLayers)
for i = 1:numel(layers)
    if isa(layers(i),'nnet.cnn.layer.Convolution2DLayer')
        layers(i).WeightLearnRateFactor = prevLayers(i).WeightLearnRateFactor;
        layers(i).BiasLearnRateFactor = prevLayers(i).BiasLearnRateFactor;
        layers(i).WeightL2Factor = prevLayers(i).WeightL2Factor;
        layers(i).BiasL2Factor = prevLayers(i).BiasL2Factor;
    end
end 
