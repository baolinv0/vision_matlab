%trainFastRCNNObjectDetector Train a Fast R-CNN deep learning object detector.
% Use of this function requires that you have the Neural Network Toolbox(TM).
% 
% This function supports training using a CUDA-capable NVIDIA(TM) GPU with
% compute capability 3.0 or higher. Use of a GPU is recommended and
% requires the Parallel Computing Toolbox(TM).
%
% detector = trainFastRCNNObjectDetector(trainingData, network, options)
% trains a Fast R-CNN (Regions with CNN features) object detector using
% deep learning. A Fast R-CNN detector can be trained to detect multiple
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
%                detector = trainFastRCNNObjectDetector(trainingData, network, options);
%
%                Setting a 'CheckpointPath' using the trainingOptions is
%                recommended because network training may take a few
%                hours.
%
% Resume Training
% ---------------
% When the 'CheckpointPath' is set using the trainingOptions function,
% detector checkpoints are periodically saved to a MAT-file at the location
% specified by 'CheckpointPath'. You may resume training from any one of
% these checkpoints by loading one of the MAT-files and passing the loaded
% detector checkpoint to the trainFastRCNNObjectDetector function:
%
% [...] = trainFastRCNNObjectDetector(trainingData, checkpoint, options, ...) 
% resumes training from a detector checkpoint. checkpoint must be a
% fastRCNNObjectDetector object.
%
% Fine-tuning a detector
% ----------------------
% [...] = trainFastRCNNObjectDetector(trainingData, detector, options)
% continues training a Faster R-CNN object detector. Use this syntax to
% continue training a detector with additional training data or to perform
% more training iterations to improve detector accuracy. 
% 
% Custom region proposal function
% -------------------------------
% [...] = trainFastRCNNObjectDetector(..., 'RegionProposalFcn', proposalFcn)
% optionally train a Fast R-CNN detector using a custom region proposal
% function, proposalFcn. If a custom region proposal function is not
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
% Additional input arguments
% --------------------------
% [...] = trainFastRCNNObjectDetector(..., Name, Value) specifies
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
% Example - Train a stop sign detector
% ------------------------------------
% % Load training data.
% data = load('rcnnStopSigns.mat', 'stopSigns', 'fastRCNNLayers');
% stopSigns = data.stopSigns;
% fastRCNNLayers = data.fastRCNNLayers;
% 
% % Add fullpath to image files
% stopSigns.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%     stopSigns.imageFilename);
% 
% % Set network training options. 
% %  * Lower the InitialLearningRate to reduce the rate at which network
% %    parameters are changed.
% %  * Set the CheckpointPath to save detector checkpoints to a temporary 
% %    directory. Change this to another location if required.
% options = trainingOptions('sgdm', ...
%     'InitialLearnRate', 1e-6, ...
%     'MaxEpochs', 5, ...
%     'CheckpointPath', tempdir);
% 
% % Train the Fast R-CNN detector. Training can take a few minutes to complete.
% frcnn = trainFastRCNNObjectDetector(stopSigns, fastRCNNLayers , options, ...
%     'NegativeOverlapRange', [0 0.1], ...
%     'PositiveOverlapRange', [0.7 1], ...
%     'SmallestImageDimension', 600);
% 
% % Test the Fast R-CNN detector on a test image.
% img = imread('stopSignTest.jpg');
% 
% [bbox, score, label] = detect(frcnn, img);
% 
% % Display detection results
% detectedImg = insertShape(img, 'Rectangle', bbox);
% figure
% imshow(detectedImg)
%
% See also trainRCNNObjectDetector, trainFasterRCNNObjectDetector,
%          trainACFObjectDetector, trainCascadeObjectDetector,
%          fastRCNNObjectDetector, trainingOptions, SeriesNetwork,
%          nnet.cnn.layer.Layer, imageLabeler.

% Copyright 2016 The MathWorks, Inc. 

function detector = trainFastRCNNObjectDetector(trainingData, network, options, varargin)
 
vision.internal.requiresNeuralToolbox(mfilename);

[trainingData, layers, params] = vision.internal.cnn.parseInputsFastRCNN(...
    trainingData, network, options, mfilename, varargin{:});

checkpointSaver = iConfigureCheckpointSaver(options);

detector = fastRCNNObjectDetector.train(trainingData, layers, options, params, checkpointSaver);
detector.ModelName = params.ModelName;

%--------------------------------------------------------------------------
function checkpointSaver = iConfigureCheckpointSaver(options)
checkpointSaver = vision.internal.cnn.DetectorCheckpointSaver( options.CheckpointPath );
checkpointSaver.CheckpointPrefix = 'fast_rcnn';
checkpointSaver.DetectorFcn = @(x,y)fastRCNNObjectDetector.detectorCheckpoint(x,y);
checkpointSaver.Detector = fastRCNNObjectDetector();

