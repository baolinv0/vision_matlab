%rcnnObjectDetector Detect objects using R-CNN deep learning detector
%   rcnnObjectDetector is returned by the trainRCNNObjectDetector function.
%   It contains a Convolutional Neural Network (CNN) classifier trained to
%   recognize objects. Use of the rcnnObjectDetector requires Neural
%   Network Toolbox and Statistics and Machine Learning Toolbox.
%
%   A CUDA-capable NVIDIA(TM) GPU with compute capability 3.0 or higher is
%   highly recommended when using the detect or classifyRegions methods of
%   rcnnObjectDetector. This will reduce computation time significantly.
%   Usage of the GPU requires the Parallel Computing Toolbox.
%
%   rcnnObjectDetector methods:
%      detect          - Detect objects in an image.
%      classifyRegions - Classify regions of interest within an image.
%
%   rcnnObjectDetector properties:
%      Network           - A SeriesNetwork object representing the CNN.
%      RegionProposalFcn - A function handle to the region proposal method.
%      ClassNames        - A cell array of object class names.
%
% Example 1 - Train a stop sign detector
% --------------------------------------
% % Load training data and network layers.
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
% See also trainRCNNObjectDetector, SeriesNetwork, trainNetwork,
%          imageLabeler, vision.CascadeObjectDetector.

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

classdef rcnnObjectDetector < vision.internal.EnforceScalarValue
    
    properties(Access = public)
        % Network A SeriesNetwork object representing the convolutional
        %         neural network used within the R-CNN detector. See help
        %         for SeriesNetwork for more details.
        Network
    end
    
    properties(Dependent)
        % ClassNames A cell array of object class names. These are the
        %            object classes that the R-CNN detector was trained to
        %            find.
        ClassNames
    end
    
    properties(Access = public)
        % RegionProposalFcn A function handle to the region proposal
        %                   method.
        RegionProposalFcn
    end
    
    properties(Hidden, Access = protected)
        % UsingDefaultRegionProposalFcn A logical flag to determine whether
        % or not the user has trained the detector with a custom region
        % proposal function.
        UsingDefaultRegionProposalFcn
        
        % BackgroundLabel Label to use for background class. Default is
        % 'Background'.
        BackgroundLabel
    end
    
    properties(Hidden)
        UseBBoxRegression
        BBoxRegressionModel
        BBoxFeatureLayer
    end
    
    methods(Static, Access = public, Hidden)
        function layers = initializeRCNNLayers(network, numClasses)
            % modify network layers by changing last layers to num objects
            % in ground truth + background, and increasing learning rates
            % of new layers.
            
            lastFCLayerIndex = find( ...
                arrayfun(@(x)isa(x,'nnet.cnn.layer.FullyConnectedLayer'), network.Layers), ...
                1, 'last');
            
            % define new FC layer for number of classes in ground truth
            % plus 1 for background.
            newFCLayer = fullyConnectedLayer(numClasses + 1,'Name','fc_rcnn');
            
            % boost learning rate of the new FC layer
            newFCLayer.WeightLearnRateFactor = 20;
            newFCLayer.WeightL2Factor = 1;
            newFCLayer.BiasLearnRateFactor = 10;
            newFCLayer.BiasL2Factor = 1;
            
            if isempty(lastFCLayerIndex)
                % Attach an FC layer
                layers = network.Layers(1:end-2);
                layers(end+1) = newFCLayer;
                layers(end+1) = softmaxLayer();
                layers(end+1) = classificationLayer();
            else
                % Replace last FC layer
                layers = network.Layers;
                
                layers(lastFCLayerIndex) = newFCLayer;
                
                % replace softmax and classification layers
                layers(end-1) = softmaxLayer();
                layers(end)   = classificationLayer();
            end
        end
        
        %------------------------------------------------------------------
        % Returns bounding boxes in an M-by-4 array. Each bounding box is a
        % row vector containing [x y width height]. The scores is an M-by-1
        % vector. Higher score values indicate the bounding box is more
        % likely to contain an object.
        %------------------------------------------------------------------
        function [bboxes, scores] = proposeRegions(I)
            alpha = 0.65;
            beta  = 0.75;
            minScore = 0.1;
            
            [bboxes, scores] = vision.internal.rcnn.edgeBoxes(I, alpha, beta, minScore);
            
        end
        
        %------------------------------------------------------------------
        % Returns a utility object to crop and resize training samples.
        %------------------------------------------------------------------
        function resizer = createRegionResizer(networkInputSize)
            resizer = vision.internal.rcnn.RegionCropAndResizer();
            % Expands region proposals by 8 pixels in every direction to
            % capture more background pixels.
            resizer.ExpansionAmount = 8;
            
            % Resize region proposals to size of network input. Do not
            % preserve aspect ratio. Set this to true to preserve the
            % aspect ratio.
            resizer.PreserveAspectRatio = false;
            
            resizer.ImageSize = networkInputSize;
            
            % approximate average image using half value of uint8 range.
            resizer.PadValue = 128;
        end
        
        %------------------------------------------------------------------
        function [detector, regionProposals] = train(groundTruth, layers, opts, params)
            
            detector = rcnnObjectDetector();
            
            detector.RegionProposalFcn = params.RegionProposalFcn;
            detector.UsingDefaultRegionProposalFcn = params.UsingDefaultRegionProposalFcn;
            detector.BackgroundLabel = params.BackgroundLabel;
            
            imds = imageDatastore(groundTruth{:,1});
            
            % Use network training options to control verbosity.
            params.Verbose = opts.Verbose;
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            rcnnObjectDetector.printHeader(printer, groundTruth);
            
            % Setup region proposal function. For parallel processing using
            % multiple MATLAB workers, copy the function handle before
            % assigning passing it to the extraction routine. This prevents
            % the rcnnObjectDetector object from being copied to all the
            % workers.
            if detector.UsingDefaultRegionProposalFcn
                fcn = @(x,~)rcnnObjectDetector.proposeRegions(x);
            else
                fcnCopy = detector.RegionProposalFcn;
                fcn = @(x,filename)rcnnObjectDetector.invokeRegionProposalFcn(fcnCopy, x, filename);
            end
            
            regionProposals = rcnnObjectDetector.extractRegionProposals(fcn, imds, params);
            
            dispatcher = createTrainingDispatcher(detector, groundTruth, regionProposals, opts, layers(1).InputSize, params);
            
            printer.printMessage('vision:rcnn:trainNetworkBegin');
            printer.linebreak;
            
            detector.Network = trainNetwork(dispatcher, layers, opts);
            
            printer.linebreak;
            printer.printMessage('vision:rcnn:trainNetworkEnd');
            printer.linebreak;
            
            lastConvolutionalLayer = find( ...
                arrayfun(@(x)isa(x,'nnet.cnn.layer.Convolution2DLayer'), detector.Network.Layers), ...
                1, 'last');
            
            if isempty(lastConvolutionalLayer)
                warning(message('vision:rcnn:noConvLayerSkipBoxReg'));
                detector.UseBBoxRegression = false;
                
            else
                bboxopts.FeatureLayer    = lastConvolutionalLayer;
                bboxopts.MaxEpochs       = 1;
                bboxopts.Lambda          = 1000;
                
                params.miniBatchSize  = opts.MiniBatchSize;
                params.endOfEpoch     = 'truncateLast';
                params.precision      = nnet.internal.cnn.util.Precision('single');
                params.resizer        = rcnnObjectDetector.createRegionResizer( detector.Network.Layers(1).InputSize );
                params.RandomSelector = vision.internal.rcnn.RandomSelector();
                params.PositiveOverlapRange = [0.7 1];
                
                detector.BBoxRegressionModel = rcnnObjectDetector.trainBBoxRegressor(...
                    groundTruth, detector.Network, params, bboxopts);
                
                detector.UseBBoxRegression = true;
                detector.BBoxFeatureLayer = bboxopts.FeatureLayer;
            end
            
            rcnnObjectDetector.printFooter(printer);
        end
        
        %------------------------------------------------------------------
        function models = trainBBoxRegressor(groundTruth, ...
                network, params, bboxopts)
            
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            printer.printMessageNoReturn('vision:rcnn:bboxRegressionBegin');
            
            dispatcher = vision.internal.rcnn.BBoxTrainingDataDispatcher(...
                groundTruth, params);
            
            classNames = groundTruth.Properties.VariableNames(2:end);
            
            maxEpochs = bboxopts.MaxEpochs;
            
            sdata = cell(1, numel(classNames) * 2);
            sdata(1:2:end) = classNames;
            allFeatures = struct(sdata{:});
            allTargets  = struct(sdata{:});
            
            regressionParams.Lambda = bboxopts.Lambda;
            sdata(2:2:end) = {vision.internal.rcnn.BoundingBoxRegressionModel(regressionParams)};
            
            models = struct(sdata{:});
            
            % For printing training progression.
            numIterations = ceil(dispatcher.NumObservations / dispatcher.MiniBatchSize) * maxEpochs;
            currentIteration = 1;
            msg = '';
            
            for i = 1:maxEpochs
                dispatcher.start();
                while ~dispatcher.IsDone
                    
                    msg = rcnnObjectDetector.printProgress(...
                        printer, msg, currentIteration, numIterations);
                    
                    [batch, targets, labels] = dispatcher.next();
                    
                    features = activations(network, batch, bboxopts.FeatureLayer, ...
                        'OutputAs', 'columns', ...
                        'MiniBatchSize', params.miniBatchSize);
                    
                    % group features by category label.
                    for j = 1:numel(labels)
                        
                        label = labels{j};
                        allFeatures.(label) = ...
                            [allFeatures.(label) features(:, j)];
                        
                        allTargets.(label)  = ...
                            [allTargets.(label); targets(j,:)];
                    end
                    
                    for k = 1:numel(classNames)
                        
                        name = classNames{k};
                        
                        if ~isempty(allFeatures.(name))
                            
                            % update class specific models
                            update(models.(name), allFeatures.(name), allTargets.(name));
                            
                            % clear features
                            allFeatures.(name) = [];
                            allTargets.(name)  = [];
                        end
                        
                    end
                    
                    currentIteration = currentIteration + 1;
                end
                
            end
            
            if numIterations > 0
                % print last iteration
                rcnnObjectDetector.printProgress(...
                    printer, msg, numIterations, numIterations);
                
                printer.print('...');
                printer.printMessage('vision:rcnn:bboxRegressionEnd');
                printer.linebreak;
            end
        end
        
        %------------------------------------------------------------------
        % Returns region proposals. Proposals are sorted by score. Only
        % strongest N are kept. The ordering of Files and output region
        % proposals must match.
        %------------------------------------------------------------------
        function tbl = extractRegionProposals(fcn, imds, params)
            
            numfiles = numel(imds.Files);
            
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            printer.printMessageNoReturn('vision:rcnn:regionProposalBegin', numfiles);
            
            if params.UseParallel
                parfor i = 1:numfiles
                    I = readimage(imds, i);
                    
                    [bboxes, scores] = fcn(I, imds.Files{i}); %#ok<PFBNS>
                    bboxes = rcnnObjectDetector.selectStrongestRegions(bboxes, scores, params.NumStrongestRegions); %#ok<PFBNS>
                    
                    s(i).RegionProposalBoxes = bboxes;
                end
            else
                
                s(numfiles) = struct('RegionProposalBoxes',[]);
                for i = 1:numfiles
                    I = readimage(imds, i);
                    
                    [bboxes, scores] = fcn(I, imds.Files{i});
                    bboxes = rcnnObjectDetector.selectStrongestRegions(bboxes, scores, params.NumStrongestRegions);
                    
                    s(i).RegionProposalBoxes = bboxes;
                end
            end
            
            tbl = struct2table(s, 'AsArray', true);
            printer.printMessage('vision:rcnn:regionProposalEnd');
            printer.linebreak;
        end
        
        %------------------------------------------------------------------
        function [bboxes, scores] = invokeRegionProposalFcn(fcn, I, filename)
            
            % Call the custom function. Catch errors and issue as warning.
            % This is only used during training. For detect and
            % classifyRegions, the proposal function is called directly and
            % allowed to error.
            try
                [bboxes, scores] = fcn(I);
                
                rcnnObjectDetector.checkRegionProposalOutputs(bboxes, scores);
                
                % cast output to required type
                bboxes = double(bboxes);
                scores = single(scores);
                
            catch exception
                str = func2str(fcn);
                
                warning(...
                    message('vision:rcnn:proposalFcnErrorOccurred', ...
                    str, filename, exception.message));
                
                bboxes = zeros(0, 4);
                scores = zeros(0, 1, 'single');
            end
            
        end
        
        %------------------------------------------------------------------
        % Returns the strongest N bboxes based on the scores.
        %------------------------------------------------------------------
        function [bboxes, scores] = selectStrongestRegions(bboxes, scores, N)
            if ~isinf(N)
                [scores, idx] = sort(scores, 'descend');
                topN = min(N, numel(scores));
                idx = idx(1:topN);
                bboxes = bboxes(idx,:);
            end
        end
    end
    
    %----------------------------------------------------------------------
    methods
        function [bboxes, scores, labels] = detect(this, I, varargin)
            % bboxes = detect(rcnn, I) detects objects within the image I.
            % The location of objects within I are returned in bboxes, an
            % M-by-4 matrix defining M bounding boxes. Each row of bboxes
            % contains a four-element vector, [x, y, width, height]. This
            % vector specifies the upper-left corner and size of a bounding
            % box in pixels. rcnn is a rcnnObjectDetector and I is a
            % truecolor or grayscale image.
            %
            % [..., scores] = detect(...) optionally return the detection
            % scores for each bounding box. The score for each detection is
            % the output of the softmax classifier used in the
            % rcnn.Network. The range of the score is [0 1]. Larger score
            % values indicate higher confidence in the detection.
            %
            % [..., labels] = detect(...) optionally return the labels
            % assigned to the bounding boxes in an M-by-1 categorical
            % array. The labels used for object classes is defined during
            % training using the trainRCNNObjectDetector function.
            %
            % [...] = detect(..., roi) optionally detects objects within
            % the rectangular search region specified by roi. roi must be a
            % 4-element vector, [x, y, width, height], that defines a
            % rectangular region of interest fully contained in I.
            %
            % [...] = detect(..., Name, Value) specifies additional
            % name-value pairs described below:
            %
            %  'NumStrongestRegions' Specify the maximum number of
            %                        strongest region proposals to process.
            %                        Reduce this value to speed-up
            %                        processing time at the cost of
            %                        detection accuracy. Set this to inf to
            %                        use all region proposals.
            %
            %                        Default: 2000
            %
            %  'SelectStrongest'  A logical scalar. Set this to true to
            %                     eliminate overlapping bounding boxes
            %                     based on their scores. This process is
            %                     often referred to as non-maximum
            %                     suppression. Set this to false if you
            %                     want to perform a custom selection
            %                     operation. When set to false, all the
            %                     detected bounding boxes are returned.
            %
            %                     Default: true
            %
            %  'MiniBatchSize'    The size of the mini-batches for
            %                     R-CNN data processing. Larger mini-batch
            %                     sizes lead to faster processing, at the
            %                     cost of more memory.
            %
            %                     Default: 128
            %
            % [...] = detect(..., 'ExecutionEnvironment', resource)
            % determines what hardware resources will be used to run the
            % CNN used within the R-CNN detector. Valid values for resource
            % are:
            %
            %  'auto' - Use a GPU if it is available, otherwise use the CPU.
            %
            %  'gpu'  - Use the GPU. To use a GPU, you must have Parallel
            %           Computing Toolbox(TM), and a CUDA-enabled NVIDIA
            %           GPU with compute capability 3.0 or higher. If a
            %           suitable GPU is not available, an error message is
            %           issued.
            %
            %  'cpu'  - Use the CPU.
            %
            % The default is 'auto'.
            %
            % Notes:
            % -----
            % - When 'SelectStrongest' is true the selectStrongestBbox
            %   function is used to eliminate overlapping boxes. By
            %   default, the function is called as follows:
            %
            %      selectStrongestBbox(bbox, scores, ...
            %                            'RatioType', 'Min', ...
            %                            'OverlapThreshold', 0.5);
            %
            % Class Support
            % -------------
            % The input image I can be uint8, uint16, int16, double,
            % single, or logical, and it must be real and non-sparse.
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
            % See also rcnnObjectDetector/classifyRegions,
            %          selectStrongestBbox, trainRCNNObjectDetector.
            
            params = rcnnObjectDetector.parseDetectInputs(I, varargin{:});
            
            roi    = params.ROI;
            useROI = params.UseROI;
            
            Iroi = vision.internal.detector.cropImageIfRequested(I, roi, useROI);
            
            [bboxes, boxScores] = this.RegionProposalFcn(Iroi);
            
            rcnnObjectDetector.checkRegionProposalOutputs(bboxes, boxScores);
            
            bboxes = rcnnObjectDetector.selectStrongestRegions(bboxes, boxScores, params.NumStrongestRegions);
                                   
            imageSize = this.Network.Layers(1).InputSize;
            
            dispatcher = configureRegionDispatcher(this, Iroi, bboxes, params.MiniBatchSize, imageSize);
            
            [labels, allScores] = classify(this.Network, dispatcher, ...
                'MiniBatchSize', params.MiniBatchSize, ...
                'ExecutionEnvironment', params.ExecutionEnvironment);
            
            scores = getScoreAssociatedWithLabel(this, labels, allScores);
            
            % remove background class
            remove = labels == this.BackgroundLabel;
            bboxes(remove, :) = [];
            scores(remove, :) = [];
            labels(remove, :) = [];
            
            % Apply class specific regression models
            if this.UseBBoxRegression
                dispatcher = configureRegionDispatcher(this, Iroi, bboxes, params.MiniBatchSize, imageSize);
                               
                features   = activations(this.Network, dispatcher, this.BBoxFeatureLayer,'OutputAs', 'columns');
                
                classNames = this.ClassNames;
                classNames(strcmp(this.BackgroundLabel, classNames)) = [];
                
                for j = 1:numel(classNames)
                    
                    name = classNames{j};
                    
                    if this.BBoxRegressionModel.(name).IsTrained
                        
                        idx = labels == name;
                        
                        bboxes(idx,:) = this.BBoxRegressionModel.(name).apply(features(:, idx), bboxes(idx,:));
                    end
                end
            end
            
            if params.SelectStrongest
                % The RatioType is set to 'Min'. This helps suppress
                % detection results where large boxes surround smaller
                % boxes.
                [bboxes, scores, index] = selectStrongestBbox(bboxes, scores, ...
                    'RatioType', 'Min', 'OverlapThreshold', 0.5);
                
                labels = labels(index,:);
            end
            
            % return bboxes in original image space.
            bboxes(:,1:2) = vision.internal.detector.addOffsetForROI(bboxes(:,1:2), roi, useROI);
             
        end
        
        %------------------------------------------------------------------
        function [labels, scores, allScores] = classifyRegions(this, I, roi, varargin)
            % [labels, scores] = classifyRegions(rcnn, I, rois) classifies
            % objects within regions specified in rois, an M-by-4 array
            % defining M rectangular regions. Each row of rois contains a
            % four-element vector [x, y, width, height]. This vector
            % specifies the upper-left corner and size of a region in
            % pixels.
            %
            % The output labels is an M-by-1 categorical array of class
            % names assigned to each region in rois. scores is an M-by-1
            % vector of classification scores. The range of the score is [0
            % 1]. Larger score values indicate higher confidence in the
            % classification.
            %
            % [..., allScores] = classifyRegions(...) optionally return all
            % the classification scores in an M-by-N matrix for M regions.
            % N is the number of classes.
            %
            % [...] = classifyRegions(..., Name, Value) specifies
            % additional name-value pairs described below:
            %
            %  'MiniBatchSize'    The size of the mini-batches for
            %                     R-CNN data processing. Larger mini-batch
            %                     sizes lead to faster processing, at the
            %                     cost of more memory.
            %
            %                     Default: 128
            %
            % [...] = classifyRegions(..., 'ExecutionEnvironment', resource)
            % determines what hardware resources will be used to run the
            % CNN used within the R-CNN detector. Valid values for resource
            % are:
            %
            %  'auto' - Use a GPU if it is available, otherwise use the CPU.
            %
            %  'gpu'  - Use the GPU. To use a GPU, you must have Parallel
            %           Computing Toolbox(TM), and a CUDA-enabled NVIDIA
            %           GPU with compute capability 3.0 or higher. If a
            %           suitable GPU is not available, an error message is
            %           issued.
            %
            %  'cpu'  - Use the CPU.
            %
            % The default is 'auto'.
            %
            %
            % Example - Classify multiple image regions
            % -----------------------------------------
            % % Load a pre-trained detector
            % load('rcnnStopSigns.mat', 'rcnn')
            %
            % % Read test image
            % img = imread('stopSignTest.jpg');
            %
            % % Specify multiple regions to classify within test image.
            % rois = [416   143    33    27
            %         347   168    36    54];
            %
            % % Classify regions
            % [labels, scores] = classifyRegions(rcnn, img, rois);
            %
            % detectedImg = insertObjectAnnotation(img, 'rectangle', rois, cellstr(labels));
            %
            % figure
            % imshow(detectedImg)
            %
            % % <a href="matlab:showdemo('DeepLearningRCNNObjectDetectionExample')">Learn more about training an R-CNN Object Detector.</a>
            %
            % See also rcnnObjectDetector/detect, trainRCNNObjectDetector.
            
            [roi, params] = rcnnObjectDetector.parseClassifyInputs(I, roi, varargin{:});
            
            imageSize = this.Network.Layers(1).InputSize;
            
            dispatcher = configureRegionDispatcher(this, I, roi, params.MiniBatchSize, imageSize);
            
            [labels, allScores] = classify(this.Network, dispatcher, ...
                'MiniBatchSize', params.MiniBatchSize, ...
                'ExecutionEnvironment', params.ExecutionEnvironment);
            
            scores = getScoreAssociatedWithLabel(this, labels, allScores);
            
        end
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = rcnnObjectDetector()
            this.UsingDefaultRegionProposalFcn = false;
            this.UseBBoxRegression = false;
            this.BackgroundLabel = 'Background';
        end
        
        %------------------------------------------------------------------
        function this = set.Network(this, network)
            
            validateattributes(network,{'SeriesNetwork'},{'scalar'});
            
            cls = 'nnet.cnn.layer.ImageInputLayer';
            if isempty(network.Layers)|| ~isa(network.Layers(1), cls)
                error(message('vision:rcnn:firstLayerNotImageInputLayer'));
            end
            
            cls = 'nnet.cnn.layer.ClassificationOutputLayer';
            if isempty(network.Layers)|| ~isa(network.Layers(end), cls)
                error(message('vision:rcnn:lastLayerNotClassificationLayer'));
            end
                        
            checkLayerForBackgroundLabel(this, network)         
            
            this.Network = network;
        end
        
        %------------------------------------------------------------------
        function this = set.RegionProposalFcn(this, fcn)
            rcnnObjectDetector.checkRegionProposalFcn(fcn);
            this.RegionProposalFcn = fcn;
        end
        
        %------------------------------------------------------------------
        function cls = get.ClassNames(this)
            cls = this.Network.Layers(end).ClassNames;
        end
    end
    
    methods (Access = protected)
        
        function dispatcher = createTrainingDispatcher(this, groundTruth, regionProposals, opts, imageSize, params)
            
            params.miniBatchSize   = opts.MiniBatchSize;
            params.endOfEpoch      = 'discardLast';
            params.precision       = nnet.internal.cnn.util.Precision('single');
            params.resizer         = rcnnObjectDetector.createRegionResizer(imageSize);
            params.RandomSelector  = vision.internal.rcnn.RandomSelector();
            params.BackgroundLabel = this.BackgroundLabel;
            
            dispatcher = vision.internal.rcnn.TrainingRegionDispatcher(...
                groundTruth, regionProposals, params);
            
        end
        
        function dispatcher = configureRegionDispatcher(~, I, bboxes, miniBatchSize, imageSize)
            endOfEpoch    = 'truncateLast';
            precision     = nnet.internal.cnn.util.Precision('single');
            regionResizer = rcnnObjectDetector.createRegionResizer(imageSize);
            dispatcher    = vision.internal.rcnn.ImageRegionDispatcher(...
                I, bboxes, miniBatchSize, endOfEpoch, precision, imageSize, regionResizer);
        end
        
        %------------------------------------------------------------------
        % Returns classification score associated with a label.
        %------------------------------------------------------------------
        function scores = getScoreAssociatedWithLabel(this, labels, allScores)
            N = numel(this.ClassNames);
            M = numel(labels);
            
            ind = sub2ind([M N], 1:M, double(labels)');
            
            scores = allScores(ind)';
        end
        
        %------------------------------------------------------------------
        function checkLayerForBackgroundLabel(this, network)
            % The classification layer must have a "Background" class to
            % support the detect method. Networks trained using
            % trainRCNNObjectDetector will have this type of network.
            if ~ismember(this.BackgroundLabel, network.Layers(end).ClassNames)
                error(message('vision:rcnn:missingBackgroundClass'));
            end
        end
    end
    
    %======================================================================
    % Save/Load
    %======================================================================
    methods(Hidden)
        function s = saveobj(this)
            s.Network           = this.Network;
            s.RegionProposalFcn = this.RegionProposalFcn;
            s.UsingDefaultRegionProposalFcn = this.UsingDefaultRegionProposalFcn;
            s.UseBBoxRegression   = this.UseBBoxRegression;
            s.BBoxRegressionModel = this.BBoxRegressionModel;
            s.BBoxFeatureLayer    = this.BBoxFeatureLayer;
            s.BackgroundLabel     = this.BackgroundLabel;
        end
    end
    
    methods(Static, Hidden)
        function this = loadobj(s)
            
            % Check if object can be loaded. Errors here will present
            % themselves as warnings during load.
            try
                vision.internal.requiresNeuralToolbox(mfilename);
                vision.internal.requiresStatisticsToolbox(mfilename);
            
                this = rcnnObjectDetector();
            
                this.BackgroundLabel   = s.BackgroundLabel;   
                
                if ~isempty(s.Network) 
                    this.Network = s.Network;
                end
                
                if ~isempty(s.RegionProposalFcn)
                    this.RegionProposalFcn = s.RegionProposalFcn;
                end
                
                this.UsingDefaultRegionProposalFcn = s.UsingDefaultRegionProposalFcn;
    
                this.UseBBoxRegression   = s.UseBBoxRegression;
                this.BBoxRegressionModel = s.BBoxRegressionModel;
                this.BBoxFeatureLayer    = s.BBoxFeatureLayer;
                
            catch ME      
                rethrow(ME)
            end
            
            
        end
    end
    
    %----------------------------------------------------------------------
    % Shared parameter validation routines.
    %----------------------------------------------------------------------
    methods(Hidden, Static)
        
        function checkRegionProposalFcn(func)
            
            validateattributes(func, {'function_handle'}, {'scalar'}, ...
                '', 'RegionProposalFcn');
            
            % get num args in/out. This errors out if func does not exist.
            numIn  = nargin(func);
            numOut = nargout(func);
            
            % functions may have varargin/out (i.e. anonymous functions)
            isVarargin  = (numIn  < 0);
            isVarargout = (numOut < 0);
            
            numIn  = abs(numIn);
            numOut = abs(numOut);
            
            % validate this API: [bboxes, scores] = func(I)
            if ~isVarargin && numIn ~= 1
                error(message('vision:rcnn:proposalFcnInvalidNargin'));
            end
            
            if ~isVarargout && numOut ~= 2
                error(message('vision:rcnn:proposalFcnInvalidNargout'));
            end
        end
    end
    
    %----------------------------------------------------------------------
    methods(Hidden, Static, Access = private)
        function [roi, params] = parseClassifyInputs(I, roi, varargin)
            p = inputParser;
            p.addParameter('MiniBatchSize', 128);
            p.addParameter('ExecutionEnvironment', 'auto');
            parse(p, varargin{:});
            
            userInput = p.Results;
            
            % grayscale or RGB images allowed
            vision.internal.inputValidation.validateImage(I, 'I');
            
            roi = rcnnObjectDetector.checkROIs(roi, size(I));
            
            vision.internal.cnn.validation.checkMiniBatchSize(...
                userInput.MiniBatchSize, mfilename);
            
            exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
                userInput.ExecutionEnvironment, mfilename);
            
            params.MiniBatchSize        = double(userInput.MiniBatchSize);
            params.ExecutionEnvironment = exeenv;
        end
        
        %------------------------------------------------------------------
        function params = parseDetectInputs(I, varargin)
            
            p = inputParser;
            p.addOptional('roi', zeros(0,4));
            p.addParameter('NumStrongestRegions', 2000);
            p.addParameter('SelectStrongest', true);
            p.addParameter('MiniBatchSize', 128);
            p.addParameter('ExecutionEnvironment', 'auto');
            parse(p, varargin{:});
            
            userInput = p.Results;
            
            % grayscale or RGB images allowed
            vision.internal.inputValidation.validateImage(I, 'I');
            
            useROI = ~ismember('roi', p.UsingDefaults);
            
            if useROI
                vision.internal.detector.checkROI(userInput.roi, size(I));
            end
            
            vision.internal.inputValidation.validateLogical(...
                userInput.SelectStrongest, 'SelectStrongest');
            
            rcnnObjectDetector.checkStrongestRegions(userInput.NumStrongestRegions);
            vision.internal.cnn.validation.checkMiniBatchSize(...
                userInput.MiniBatchSize, mfilename);
            
            exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
                userInput.ExecutionEnvironment, mfilename);
            
            params.ROI                  = double(userInput.roi);
            params.UseROI               = useROI;
            params.NumStrongestRegions  = double(userInput.NumStrongestRegions);
            params.SelectStrongest      = logical(userInput.SelectStrongest);
            params.MiniBatchSize        = double(userInput.MiniBatchSize);
            params.ExecutionEnvironment = exeenv;
        end
        
        %------------------------------------------------------------------
        function checkStrongestRegions(N)
            if isinf(N)
                % OK, use all regions.
            else
                validateattributes(N, ...
                    {'numeric'},...
                    {'scalar', 'real', 'positive', 'integer', 'nonempty', 'finite', 'nonsparse'}, ...
                    mfilename, 'NumStrongestRegions');
            end
        end
        
        %------------------------------------------------------------------
        function roi = checkROIs(roi, imageSize)
            validateattributes(roi, {'numeric'}, ...
                {'size', [NaN 4], 'real', 'nonsparse', 'finite', 'nonsparse'},...
                mfilename, 'roi');
            
            % rounds floats and casts to int32 to avoid saturation of smaller integer types.
            roi = vision.internal.detector.roundAndCastToInt32(roi);
            
            % width and height must be >= 0
            if any(roi(:,3) < 0) || any(roi(:,4) < 0)
                error(message('vision:validation:invalidROIWidthHeight'));
            end
            
            % roi must be fully contained within I
            if any(roi(:,1) < 1) || any(roi(:,2) < 1)...
                    || any(roi(:,1) + roi(:,3) > imageSize(2)+1) ...
                    || any(roi(:,2) + roi(:,4) > imageSize(1)+1)
                
                error(message('vision:validation:invalidROIValue'));
            end
            
        end
        
        %------------------------------------------------------------------
        function checkRegionProposalOutputs(bboxes, scores)
            if ~ismatrix(bboxes) || size(bboxes, 2) ~= 4
                error(message('vision:rcnn:invalidBBoxDim'));
            end
            
            if ~iscolumn(scores)
                error(message('vision:rcnn:invalidScoreDim'));
            end
            
            if ~isreal(bboxes) || issparse(bboxes) || ~all(isfinite(bboxes(:)))
                error(message('vision:rcnn:invalidBBox'));
            end
            
            if ~isreal(scores) || issparse(scores) || ~all(isfinite(scores))
                error(message('vision:rcnn:invalidScores'));
            end
            
            if size(bboxes, 1) ~= size(scores, 1)
                error(message('vision:rcnn:proposalInconsistentNumel'));
            end
            
            if any(bboxes(:,3) <= 0) || any(bboxes(:,4) <= 0)
                error(message('vision:rcnn:proposalInvalidWidthHeight'));
            end
            
        end               
        
        %------------------------------------------------------------------
        function printHeader(printer, groundTruth)
            printer.print('*******************************************************************\n');
            printer.printMessage('vision:rcnn:trainingHeader');
            printer.linebreak;
            
            classNames = groundTruth.Properties.VariableNames(2:end);
            
            for i = 1:numel(classNames)
                printer.print('* %s\n', classNames{i});
            end
            
            printer.linebreak;
            
        end
        
        %------------------------------------------------------------------
        function printFooter(printer)
            printer.printMessage('vision:rcnn:trainingFooter');
            printer.print('*******************************************************************\n');
            printer.linebreak;
        end
        
        %------------------------------------------------------------------
        function updateMessage(printer, prevMessage, nextMessage)
            backspace = sprintf(repmat('\b',1,numel(prevMessage))); % figure how much to delete
            printer.printDoNotEscapePercent([backspace nextMessage]);
        end
        
        %------------------------------------------------------------------
        function nextMessage = printProgress(printer, prevMessage, k, K)
            nextMessage = sprintf('%.2f%%%%',100*k/K);
            rcnnObjectDetector.updateMessage(printer, prevMessage(1:end-1), nextMessage);
        end
        
    end
end


