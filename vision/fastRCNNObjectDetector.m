%fastRCNNObjectDetector Detect objects using Fast R-CNN deep learning detector.
%  fastRCNNObjectDetector is returned by the trainFastRCNNObjectDetector
%  function. It contains a Fast R-CNN (Regions with CNN features) object
%  detection network trained to detect objects. Use of
%  fastRCNNObjectDetector requires Neural Network Toolbox.
%
%  A CUDA-capable NVIDIA(TM) GPU with compute capability 3.0 or higher is
%  highly recommended when using the detect method of
%  fastRCNNObjectDetector. This will reduce computation time 
%  significantly. Usage of the GPU requires the Parallel Computing Toolbox.
%
%  fastRCNNObjectDetector properties:
%     ModelName         - Name of the trained object detector.
%     Network           - Trained Fast R-CNN object detection network.
%     RegionProposalFcn - A function handle to the region proposal method.
%     ClassNames        - A cell array of object class names.
%     MinObjectSize     - Minimum object size supported by the detection network.
%
%  fastRCNNObjectDetector methods:
%     detect          - Detect objects in an image.
%     classifyRegions - Classify regions of interest within an image.
%     
% See also trainFastRCNNObjectDetector, trainFasterRCNNObjectDetector, 
%          trainRCNNObjectDetector, fasterRCNNObjectDetector,
%          rcnnObjectDetector.

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
%
% Ren, Shaoqing, et al. "Faster R-CNN: Towards real-time object detection
% with region proposal networks." Advances in neural information processing
% systems. 2015.

% Copyright 2016-2017 The MathWorks, Inc. 

classdef fastRCNNObjectDetector < vision.internal.EnforceScalarHandle
        
    properties(GetAccess = public, SetAccess = public)
        % ModelName Name of the classification model. By default, the name
        %           is set by trainFastRCNNObjectDetector. The name may
        %           be modified after training as desired.
        ModelName char
    end
    
    properties(GetAccess = public, SetAccess = protected)
        % Network An object representing the Fast R-CNN network used within
        %         the Faster R-CNN detector.
        Network        
    end
    
    properties(Access = public)
        % RegionProposalFcn A function handle to the region proposal
        %                   method.
        RegionProposalFcn
    end
    
    properties(Dependent)
        % ClassNames A cell array of object class names. These are the
        %            object classes that the R-CNN detector was trained to
        %            find.
        ClassNames           
    end      
    
    properties (GetAccess = public, SetAccess = protected) 
        % MinObjectSize Minimum object size supported by the Fast R-CNN
        %               network. The minimum size depends on the network
        %               architecture.
        MinObjectSize        
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
    
    properties(Hidden, Access = protected, Transient)
        % CachedImageSize Cached image size used to avoid recomputing
        %                 parameters during detection. 
        CachedImageSize
        % CachedFeatureMapSize Cached feature map size used to avoid
        %                      recomputing parameters during detection.
        CachedFeatureMapSize
    end
    
    methods(Static, Access = public, Hidden)
        
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
        function O = scaleImage(filename, imageLength)            
            I = imread(filename);                          
            
            % scale the smallest side to value specified
            sz = size(I);
            [~, smallestSide] = min(sz(1:2));
            scale = imageLength / sz(smallestSide);
            
            O = imresize(I, scale);            
        end               
        
        %------------------------------------------------------------------
        function [detector, network, regionProposals] = train(groundTruth, layers, opts, params, checkpointSaver)
            
            detector = fastRCNNObjectDetector();
            
            detector.RegionProposalFcn = params.RegionProposalFcn;
            detector.UsingDefaultRegionProposalFcn = params.UsingDefaultRegionProposalFcn;
            detector.BackgroundLabel = params.BackgroundLabel;
            
            % Use network training options to control verbosity.
            params.Verbose = opts.Verbose;
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            fastRCNNObjectDetector.printHeader(printer, groundTruth);
            
            assert( isa(layers, 'vision.cnn.FastRCNN') );
                        
            inputSize  = layers.Layers(1).InputSize;                                        
                        
            % Setup region proposal function. For parallel processing using
            % multiple MATLAB workers, copy the function handle before
            % assigning passing it to the extraction routine. This prevents
            % the fastRCNNObjectDetector object from being copied to all the
            % workers.
            if detector.UsingDefaultRegionProposalFcn
                fcn = @(x,~)fastRCNNObjectDetector.proposeRegions(x);
            else
                fcnCopy = detector.RegionProposalFcn;
                fcn = @(x,filename)fastRCNNObjectDetector.invokeRegionProposalFcn(fcnCopy, x, filename);
            end
            
            
            if params.ScaleImage
                imds = imageDatastore(groundTruth{:,1}, 'ReadFcn', @(x)fastRCNNObjectDetector.scaleImage(x, params.ImageScale));
            else
                imds = imageDatastore(groundTruth{:,1});
            end
            
            regionProposals = fastRCNNObjectDetector.extractRegionProposals(fcn, imds, params);
            
            
            % create dispatcher -
            %  dispatcher needs to scale roi depending on input image size for this it uses the network layers.            
            dispatcher = createTrainingDispatcher(...
                detector, groundTruth, regionProposals, ...
                opts, inputSize, params, layers);                        
            
            % train network
            network = vision.internal.cnn.trainNetwork(dispatcher, layers, opts, checkpointSaver);
                                    
            detector.MinObjectSize = params.MinObjectSize;
            detector.Network = network;                                   
            
        end                       
               
        %------------------------------------------------------------------
        % Returns region proposals. Proposals are sorted by score. Only
        % strongest N are kept. The ordering of Files and output region
        % proposals must match.
        %------------------------------------------------------------------
        function tbl = extractRegionProposals(fcn, imds, params)
            
            numfiles = numel(imds.Files);
            
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            printer.printMessageNoReturn('vision:rcnn:fastRegionProposalBegin', numfiles);
            
            minBoxSize = params.MinObjectSize;
            
            if params.UseParallel
                parfor i = 1:numfiles
                    I = readimage(imds, i);
                    
                    [bboxes, scores] = fcn(I, imds.Files{i}); %#ok<PFBNS>
                    
                    [bboxes, scores] = fastRCNNObjectDetector.filterSmallBBoxes(bboxes, scores, minBoxSize);
                    
                    bboxes = fastRCNNObjectDetector.selectStrongestRegions(bboxes, scores, params.NumStrongestRegions); %#ok<PFBNS>
                    
                    s(i).RegionProposalBoxes = bboxes;
                end
            else
                
                s(numfiles) = struct('RegionProposalBoxes',[]);
                for i = 1:numfiles
                    I = readimage(imds, i);
                    
                    [bboxes, scores] = fcn(I, imds.Files{i});
                    
                    [bboxes, scores] = fastRCNNObjectDetector.filterSmallBBoxes(bboxes, scores, minBoxSize);
                    
                    bboxes = fastRCNNObjectDetector.selectStrongestRegions(bboxes, scores, params.NumStrongestRegions);
                    
                    s(i).RegionProposalBoxes = bboxes;
                end
            end
            
            tbl = struct2table(s, 'AsArray', true);
            printer.printMessage('vision:rcnn:fastRegionProposalEnd');
            printer.linebreak;
        end
        
        function [bboxes, scores] = filterSmallBBoxes(bboxes, scores, minSize)            
            tooSmall = any((bboxes(:,[4 3]) < minSize), 2);            
            
            % regression may transform boxes so that they are smaller than
            % minSize.
            bboxes(tooSmall,:) = []; 
            scores(tooSmall,:) = [];
        end
        
        function [bboxes, scores] = filterLargeBBoxes(bboxes, scores, maxSize)            
            tooBig = any((bboxes(:,[4 3]) > maxSize), 2);            

            bboxes(tooBig,:) = []; 
            scores(tooBig,:) = [];
        end
        
        %------------------------------------------------------------------
        function [bboxes, scores] = invokeRegionProposalFcn(fcn, I, filename)
            
            % Call the custom function. Catch errors and issue as warning.
            % This is only used during training. For detect and
            % classifyRegions, the proposal function is called directly and
            % allowed to error.
            try
                [bboxes, scores] = fcn(I);
                
                fastRCNNObjectDetector.checkRegionProposalOutputs(bboxes, scores);
                
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
                [~, idx] = sort(scores, 'descend');
                topN = min(N, numel(scores));
                idx = idx(1:topN);
                bboxes = bboxes(idx,:);
                scores = scores(idx,:);
            end
        end
        
        %------------------------------------------------------------------
        % Detector checkpoint function. Assign network checkpoint to
        % detector.
        function detector = detectorCheckpoint(net, detector)
            detector.Network = net;
        end
    end
    
    %----------------------------------------------------------------------
    methods
        function [bboxes, scores, labels] = detect(this, I, varargin)
            % bboxes = detect(fastRCNN, I) detects objects within the image I.
            % The location of objects within I are returned in bboxes, an
            % M-by-4 matrix defining M bounding boxes. Each row of bboxes
            % contains a four-element vector, [x, y, width, height]. This
            % vector specifies the upper-left corner and size of a bounding
            % box in pixels. fastRCNN is a fastRCNNObjectDetector and I is
            % a truecolor or grayscale image.
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
            %                     suppression. Set this to false to if you
            %                     want to perform a custom selection
            %                     operation. When set to false, all the
            %                     detected bounding boxes are returned.
            %
            %                     Default: true           
            %
            %  'MinSize'          Specify the size of the smallest
            %                     region containing an object, in pixels,
            %                     as a two-element vector, [height width].
            %                     When the minimum size is known, you can
            %                     reduce computation time by setting this
            %                     parameter to that value. By default,
            %                     'MinSize' is the smallest object that can
            %                     be detected by the trained network.            
            %              
            %                     Default: fastRCNN.MinObjectSize            
            %
            %  'MaxSize'          Specify the size of the biggest region
            %                     containing an object, in pixels, as a
            %                     two-element vector, [height width]. When
            %                     the maximum object size is known, you can
            %                     reduce computation time by setting this
            %                     parameter to that value. Otherwise, the
            %                     maximum size is determined based on the
            %                     width and height of I.
            %
            %                     Default: size(I)                     
            %
            % [...] = detect(..., 'ExecutionEnvironment', resource)
            % determines what hardware resources will be used to run the
            % Fast R-CNN detector. Valid values for resource are:
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
            % Example
            % -------
            % % Load pre-trained detector.
            % data = load('rcnnStopSigns.mat', 'fastRCNN');
            % fastRCNN = data.fastRCNN;
            % 
            % % Read test image.
            % I = imread('stopSignTest.jpg');
            %
            % % Run detector
            % [bboxes, scores, labels] = detect(fastRCNN, I);
            %
            % % Show results.
            % detectedImg = insertShape(I, 'Rectangle', bboxes);
            % figure
            % imshow(detectedImg)
            %
            % See also trainFastRCNNObjectDetector,
            %          fastRCNNObjectDetector/classifyRegions.
            
            params = this.parseDetectInputs(I, varargin{:});
            
            roi    = params.ROI;
            useROI = params.UseROI;
            
            % Crop image, if needed.
            Iroi = vision.internal.detector.cropImageIfRequested(I, roi, useROI);
            
            % Convert image to uint8. Fast R-CNN training forces images to
            % be in range [0 255]. Converting to uint8 here to ensure data
            % range is similar during inference.
            Iroi = im2uint8(Iroi);
            
            imageSize = size(Iroi);
            
            % Convert image from RGB <-> grayscale as required by network.
            Iroi = fastRCNNObjectDetector.convertImageToMatchNumberOfNetworkImageChannels(...
                Iroi, this.Network.Layers(1).InputSize);
            
            % Run region proposal function.
            [bboxes, boxScores] = this.RegionProposalFcn(Iroi);
            
            fastRCNNObjectDetector.checkRegionProposalOutputs(bboxes, boxScores);
            
            [bboxes, boxScores] = this.filterBBoxes(bboxes, boxScores, params.MinSize, params.MaxSize);           
            
            % Keep the top-N strongest object proposals.
            bboxes = fastRCNNObjectDetector.selectStrongestRegions(bboxes, boxScores, params.NumStrongestRegions);
                                  
            if isempty(bboxes)
                
                scores = zeros(0,1,'single');
                labels = categorical(cell(0,1),this.ClassNames);
                
            else
                
                [sx, sy] = iComputeImageToFeatureMapScaleFactors(this, imageSize);
                
                scaledBBoxes = vision.internal.cnn.scaleROI(bboxes, sx, sy);
                
                fmap = internalActivations(this.Network, Iroi, scaledBBoxes, numel(this.Network.Layers), 1, ...
                    'ExecutionEnvironment', params.ExecutionEnvironment,...
                    'OutputAs','channels');
                
                % Unpack output
                reg = fmap.Regression;
                fmap = fmap.Classification;
                
                allScores = squeeze(fmap)';
                classNames = categorical(this.ClassNames, this.ClassNames);
                labels = nnet.internal.cnn.util.undummify( allScores, classNames );
                
                scores = getScoreAssociatedWithLabel(this, labels, allScores);
                
                % remove background class
                remove = labels == this.BackgroundLabel;
                bboxes(remove, :) = [];
                scores(remove, :) = [];
                labels(remove, :) = [];
                reg(:,:,:,remove) = [];
                
                % remove background category from categorical.
                labels = removecats(labels, this.BackgroundLabel);
                
                bboxes = fastRCNNObjectDetector.applyBoxRegression(bboxes, reg, labels, params.MinSize, params.MaxSize);
                
                % Clip bboxes to image. This can happen after regression
                % operation.
                bboxes = vision.internal.detector.clipBBox(bboxes, imageSize(1:2));                
                                    
                [bboxes, scores] = fastRCNNObjectDetector.removeNegativeBoxes(bboxes, scores);
                   
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
            
        end
              
        %------------------------------------------------------------------
        function [labels, scores, allScores] = classifyRegions(this, I, roi, varargin)
            % [labels, scores] = classifyRegions(fastRCNN, I, rois) classifies
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
            % [...] = classifyRegions(..., 'ExecutionEnvironment',
            % resource) determines what hardware resources will be used to
            % run Fast R-CNN detector. Valid values for resource
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
            % Example - Classify multiple image regions
            % -----------------------------------------
            % % Load a pre-trained detector
            % data = load('rcnnStopSigns.mat', 'fastRCNN');
            % fastRCNN = data.fastRCNN;
            %
            % % Read test image
            % img = imread('stopSignTest.jpg');
            %
            % % Specify multiple regions to classify within test image.
            % rois = [416   143    33    27
            %     347   168    36    54];
            %
            % % Classify regions
            % [labels, scores] = classifyRegions(fastRCNN, img, rois);
            %
            % detectedImg = insertObjectAnnotation(img, 'rectangle', rois, cellstr(labels));
            %
            % figure
            % imshow(detectedImg)
            %
            % See also fastRCNNObjectDetector/detect, trainFastRCNNObjectDetector.
            
            [roi, params] = fastRCNNObjectDetector.parseClassifyInputs(I, roi, varargin{:});
            
            % Convert image to uint8. Fast R-CNN training forces images to
            % be in range [0 255]. Converting to uint8 here to ensure data
            % range is similar during inference.        
            I = im2uint8(I);
                 
            % Scale bboxes to feature map space              
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(this.Network.Layers);
            idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
            [sx, sy] = vision.internal.cnn.roiScaleFactor(internalLayers(1:idx-1), size(I));
            
            scaledBBoxes = vision.internal.cnn.scaleROI(single(roi), sx, sy);
                     
            fmap = internalActivations(this.Network, I, scaledBBoxes, numel(this.Network.Layers), 1, ...               
                'ExecutionEnvironment', params.ExecutionEnvironment,...
                'OutputAs','channels');
                      
            fmap = fmap.Classification;
                        
            allScores = squeeze(fmap)';
            classNames = categorical(this.ClassNames, this.ClassNames); 
            labels = nnet.internal.cnn.util.undummify( allScores, classNames );
            
            scores = getScoreAssociatedWithLabel(this, labels, allScores);                       
            
        end
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = fastRCNNObjectDetector(varargin)
            if nargin == 0
                
                this.UsingDefaultRegionProposalFcn = false;
                this.BackgroundLabel = 'Background';
                
            elseif nargin == 1
                clsname = 'fastRCNNObjectDetector';
                
                validateattributes(varargin{1},...
                    {clsname}, ...
                    {'nonempty','scalar'}, mfilename);
                
                if isequal(clsname, class(varargin{1}))
                    this = setPropertiesOnLoad(this, saveobj(varargin{1}));
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = set.Network(this, network)
            
            validateattributes(network,{'vision.cnn.FastRCNN'},{'scalar'});
            
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
            fastRCNNObjectDetector.checkRegionProposalFcn(fcn);
            this.RegionProposalFcn = fcn;
        end
        
        %------------------------------------------------------------------
        function cls = get.ClassNames(this)
            cls = this.Network.Layers(end).ClassNames;
        end
    end
    
    methods (Access = protected)        
        
        function dispatcher = createTrainingDispatcher(this, groundTruth, regionProposals, opts, imageSize, params, network)
            
            params.miniBatchSize   = opts.MiniBatchSize;
            params.endOfEpoch      = 'discardLast';
            params.precision       = nnet.internal.cnn.util.Precision('single');            
            params.RandomSelector  = vision.internal.rcnn.RandomSelector();
            params.BackgroundLabel = this.BackgroundLabel;
            params.ImageSize       = imageSize;
            
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(network.Layers);
            idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
            
            params.LayersUpToROIPooling = internalLayers(1:idx-1);
                        
            dispatcher = vision.internal.cnn.fastrcnn.TrainingRegionDispatcher(...
                groundTruth, regionProposals, params);
            
        end
        
        function dispatcher = configureRegionDispatcher(~, I, bboxes, miniBatchSize, imageSize)
            endOfEpoch    = 'truncateLast';
            precision     = nnet.internal.cnn.util.Precision('single');
            regionResizer = fastRCNNObjectDetector.createRegionResizer(imageSize);
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
        
        %------------------------------------------------------------------
        function [bboxes, scores] = filterBBoxes(~, bboxes, scores, minSize, maxSize)
            
            [bboxes, scores] = fastRCNNObjectDetector.filterSmallBBoxes(bboxes, scores, minSize);
            
            [bboxes, scores] = fastRCNNObjectDetector.filterLargeBBoxes(bboxes, scores, maxSize);
        end
        
        %------------------------------------------------------------------
        function this = setPropertiesOnLoad(this, s)
            try
                vision.internal.requiresNeuralToolbox(mfilename);                                
                
                this.BackgroundLabel   = s.BackgroundLabel;
                
                if ~isempty(s.Network)
                    this.Network = vision.cnn.FastRCNN.loadobj(s.Network);
                end
                
                if ~isempty(s.RegionProposalFcn)
                    this.RegionProposalFcn = s.RegionProposalFcn;
                end
                
                this.UsingDefaultRegionProposalFcn = s.UsingDefaultRegionProposalFcn;
                this.MinObjectSize = s.MinObjectSize;
                this.ModelName  = s.ModelName;
                
            catch ME
                rethrow(ME);
            end
        end
        
        %------------------------------------------------------------------
        function params = parseDetectInputs(this, I, varargin)
            % image should be bigger network image input layer. This
            % ensures the feature map sizes are large enough to perform RPN
            % processing and ROI Pooling.
            sz = size(I);
            
            p = inputParser;
            p.addOptional('roi', zeros(0,4));
            p.addParameter('NumStrongestRegions', 2000);
            p.addParameter('SelectStrongest', true);         
            p.addParameter('MinSize', []);
            p.addParameter('MaxSize', sz(1:2));
            p.addParameter('ExecutionEnvironment', 'auto');
            parse(p, varargin{:});
            
            userInput = p.Results;
            
            % grayscale or RGB images allowed
            vision.internal.inputValidation.validateImage(I, 'I');
                       
            networkInputSize = this.Network.Layers(1).InputSize;
            if any(sz(1:2) < networkInputSize(1:2))
                error(message('vision:rcnn:imageSmallerThanNetwork',mat2str(networkInputSize(1:2))));
            end
            
            useROI = ~ismember('roi', p.UsingDefaults);
            
            if useROI
                vision.internal.detector.checkROI(userInput.roi, size(I));
            end
            
            vision.internal.inputValidation.validateLogical(...
                userInput.SelectStrongest, 'SelectStrongest');
            
            fastRCNNObjectDetector.checkStrongestRegions(userInput.NumStrongestRegions);
                        
            wasMinSizeSpecified = ~ismember('MinSize', p.UsingDefaults);
            wasMaxSizeSpecified = ~ismember('MaxSize', p.UsingDefaults);
                       
            if wasMinSizeSpecified
                vision.internal.detector.ValidationUtils.checkMinSize(userInput.MinSize, this.MinObjectSize, mfilename);
            else
                % set min size to model training size if not user specified.
                userInput.MinSize = this.MinObjectSize;
            end

            if wasMaxSizeSpecified
                vision.internal.detector.ValidationUtils.checkMaxSize(userInput.MaxSize, this.MinObjectSize, mfilename);
                % note: default max size set above in inputParser to size(I)
            end

            if wasMaxSizeSpecified && wasMinSizeSpecified
                % cross validate min and max size    
                coder.internal.errorIf(any(userInput.MinSize >= userInput.MaxSize) , ...
                    'vision:ObjectDetector:minSizeGTMaxSize');
            end
            
            if useROI              
                if ~isempty(userInput.roi)
                    sz = userInput.roi([4 3]);
                    vision.internal.detector.ValidationUtils.checkImageSizes(sz(1:2), userInput, wasMinSizeSpecified, ...
                        this.MinObjectSize, ...
                        'vision:ObjectDetector:ROILessThanMinSize', ...
                        'vision:ObjectDetector:ROILessThanModelSize');
                end
            else        
                vision.internal.detector.ValidationUtils.checkImageSizes(sz(1:2), userInput, wasMinSizeSpecified, ...
                    this.MinObjectSize , ...
                    'vision:ObjectDetector:ImageLessThanMinSize', ...
                    'vision:ObjectDetector:ImageLessThanModelSize');
            end                       
            exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
                userInput.ExecutionEnvironment, mfilename);
            
            params.ROI                  = double(userInput.roi);
            params.UseROI               = useROI;
            params.NumStrongestRegions  = double(userInput.NumStrongestRegions);
            params.SelectStrongest      = logical(userInput.SelectStrongest);   
            params.MinSize              = double(userInput.MinSize);
            params.MaxSize              = double(userInput.MaxSize);
            params.ExecutionEnvironment = exeenv;
        end
        
    end
    
    %======================================================================
    % Save/Load
    %======================================================================
    methods(Hidden)
        function s = saveobj(this)
            s.Network             = saveobj(this.Network);
            s.RegionProposalFcn   = this.RegionProposalFcn;
            s.UsingDefaultRegionProposalFcn = this.UsingDefaultRegionProposalFcn;                      
            s.BackgroundLabel     = this.BackgroundLabel;
            s.MinObjectSize       = this.MinObjectSize;
            s.ModelName           = this.ModelName;
            s.Version             = 1.0;
        end
    end
    
    methods(Static, Hidden)
        function this = loadobj(s)
            this = fastRCNNObjectDetector();
            this = setPropertiesOnLoad(this, s);            
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
        
        %------------------------------------------------------------------
        function sz = determineMinBoxSize(frcnn)
            % MinBox size is a function of the network architecture and the roi pooling
            % layer's grid size.
            
            internalLayers = nnet.cnn.layer.Layer.getInternalLayers(frcnn.Layers);
            
            idx = vision.internal.cnn.layer.util.findROIPoolingLayer(internalLayers);
            
            % figure out min box size that network can handle. get the
            % feature map size that will be input to the ROI pooling layer.
            featureMapSize = iOutputSize(internalLayers, idx-1);
            
            scaleFactor = internalLayers{1}.InputSize(1:2)./featureMapSize(1:2);
            sz = ceil( scaleFactor .* internalLayers{idx}.GridSize );
        end
        
        %------------------------------------------------------------------
        function I = convertImageToMatchNumberOfNetworkImageChannels(I, imageSize)
            
            isNetImageRGB = numel(imageSize) == 3 && imageSize(end) == 3;
            isImageRGB    = ~ismatrix(I);
            
            if isImageRGB && ~isNetImageRGB
                I = rgb2gray(I);
                
            elseif ~isImageRGB && isNetImageRGB
                I = repmat(I,1,1,3);
            end
        end
        
        %------------------------------------------------------------------
        function bboxes = applyReg(P,reg, minSize, maxSize)
            x = reg(:,1);
            y = reg(:,2);
            w = reg(:,3);
            h = reg(:,4);
            
            % center of proposals
            px = P(:,1) + floor(P(:,3)/2);
            py = P(:,2) + floor(P(:,4)/2);
            
            % compute regression value of ground truth box
            gx = P(:,3).*x + px; % center position
            gy = P(:,4).*y + py;
            
            gw = P(:,3) .* exp(w);
            gh = P(:,4) .* exp(h);
            
            if nargin > 2
                % regression can push boxes outside user defined range. clip the boxes
                % to the min/max range. This is only done after the initial min/max size
                % filtering.
                gw = min(gw, maxSize(2));
                gh = min(gh, maxSize(1));
                
                % expand to min size
                gw = max(gw, minSize(2));
                gh = max(gh, minSize(1));
            end
            
            % convert to [x y w h] format
            bboxes = [ gx - floor(gw/2) gy - floor(gh/2) gw gh];
            
            bboxes = double(round(bboxes));
            
        end
        
        %------------------------------------------------------------------
        function bboxes = applyBoxRegression(P, reg, labels, minSize, maxSize)
            
            % reg is 4D array [1 1 numClasses*4 numObs]. reshape to
            % 4-by-numClasses-by-numObs
            numObservations = size(reg,4);
            reg = reshape(reg, 4, numel(categories(labels)), numObservations);
            
            idx = int32(labels);
            v = zeros(numObservations, 4, 'like', reg);
            for i = 1:numObservations
                v(i,:) = reg(:, idx(i), i)';
            end
            
            bboxes = fastRCNNObjectDetector.applyReg(P, v, minSize, maxSize);
              
        end
        
        function  [bboxes, scores] = removeNegativeBoxes(bboxes, scores)
            % remove any boxes that have regressed width/height less than
            % a pixel.
            remove = bboxes(:,3) < 1 | bboxes(:,4) < 1;
            bboxes(remove, :) = [];
            scores(remove,:)  = [];
                      
        end
        
    end
    
    %----------------------------------------------------------------------
    methods(Hidden, Static, Access = private)
        function [roi, params] = parseClassifyInputs(I, roi, varargin)
            p = inputParser;            
            p.addParameter('ExecutionEnvironment', 'auto');
            parse(p, varargin{:});
            
            userInput = p.Results;
            
            % grayscale or RGB images allowed
            vision.internal.inputValidation.validateImage(I, 'I');
            
            roi = fastRCNNObjectDetector.checkROIs(roi, size(I));                      
            
            exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
                userInput.ExecutionEnvironment, mfilename);
                      
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
            printer.printMessage('vision:rcnn:fastTrainingHeader');
            printer.linebreak;
            
            classNames = groundTruth.Properties.VariableNames(2:end);
            
            for i = 1:numel(classNames)
                printer.print('* %s\n', classNames{i});
            end
            
            printer.linebreak;
            
        end
        
        %------------------------------------------------------------------
        function printFooter(printer)
            printer.printMessage('vision:rcnn:fastTrainingFooter');
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
            fastRCNNObjectDetector.updateMessage(printer, prevMessage(1:end-1), nextMessage);
        end
        
    end
end

function sz = iOutputSize(internalLayers, layerID)
% Return the size of a layers output.
sz = internalLayers{1}.InputSize;
for i = 2:layerID
    sz = internalLayers{i}.forwardPropagateSize(sz);
end
end

%--------------------------------------------------------------------------

function [sx, sy] = iComputeImageToFeatureMapScaleFactors(detector, imageSize)
% Scale bboxes to feature map space

if isempty(detector.CachedFeatureMapSize) ...
    || ~isequal(detector.CachedImageSize(1:2),imageSize(1:2))
    detector.CachedImageSize      = imageSize;
    detector.CachedFeatureMapSize = computeFeatureMapSize(detector.Network, imageSize);
end

scaleFactor = detector.CachedFeatureMapSize(1:2) ./ detector.CachedImageSize(1:2);

sx = scaleFactor(2);
sy = scaleFactor(1);

end

