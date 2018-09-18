%fasterRCNNObjectDetector Detect objects using Faster R-CNN deep learning detector.
%  fasterRCNNObjectDetector is returned by the trainFasterRCNNObjectDetector
%  function. It contains a Faster R-CNN (Regions with CNN features) object
%  detection network trained to detect objects. Use of
%  fasterRCNNObjectDetector requires Neural Network Toolbox.
%
%  A CUDA-capable NVIDIA(TM) GPU with compute capability 3.0 or higher is
%  highly recommended when using the detect method of
%  fasterRCNNObjectDetector. This will reduce computation time 
%  significantly. Usage of the GPU requires the Parallel Computing Toolbox.
%
%  fasterRCNNObjectDetector properties:
%     ModelName             - Name of the trained object detector.
%     Network               - Trained Fast R-CNN network.
%     RegionProposalNetwork - Trained Region proposal network (RPN).
%     MinBoxSizes           - Minimum anchor box sizes. 
%     BoxPyramidScale       - Anchor box pyramid scale.
%     NumBoxPyramidLevels   - Number of anchor box pyramid levels.
%     ClassNames            - A cell array of object class names.
%     MinObjectSize         - Minimum object size supported by the detection network.
%
%  fasterRCNNObjectDetector methods:
%     detect - Detect objects in an image.
%     
% See also trainFasterRCNNObjectDetector, trainFastRCNNObjectDetector, 
%          trainRCNNObjectDetector, fastRCNNObjectDetector,
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

classdef fasterRCNNObjectDetector < vision.internal.EnforceScalarHandle
    
    properties(GetAccess = public, SetAccess = public)
        % ModelName Name of the classification model. By default, the name
        %           is set by trainFasterRCNNObjectDetector. The name may
        %           be modified after training as desired.
        ModelName   char
    end        
       
    properties(GetAccess = public, SetAccess = protected)
        % Network An object representing the Fast R-CNN network used within
        %         the Faster R-CNN detector. This network classifies region
        %         proposals produced by the RegionProposalNetwork.
        Network 
        
        % RegionProposalNetwork An object representing the region proposal
        %                       network (RPN) used to within the Faster
        %                       R-CNN detector. The RPN network shares
        %                       weights with the Fast R-CNN Network stored
        %                       in the Network property.
        RegionProposalNetwork                  
        
        % MinBoxSizes The minimum anchor box sizes used to build the anchor
        % box pyramid used within the Region Proposal Network (RPN).
        MinBoxSizes
        
        % BoxPyramidScale The scale factor used to successively upscale
        % anchor box sizes.
        BoxPyramidScale
        
        % NumBoxPyramidLevels The number of levels in the anchor box
        % pyramid. 
        NumBoxPyramidLevels
    end
    
    properties(Dependent)
        % ClassNames A cell array of object class names. These are the
        %            object classes that the Faster R-CNN detector was
        %            trained to find.
        ClassNames   
    end
    
    properties(Dependent, Transient)
        % MinObjectSize Minimum object size supported by the Faster R-CNN
        %               network. The minimum size depends on the network
        %               architecture.
        MinObjectSize
    end
    
    properties(Hidden, Dependent)
        NumAnchors
    end
    
    properties (Hidden)       
        ModelSize                   
        LastSharedLayerIndex
        TrainingStage
    end
        
    properties(Hidden, Access = protected)        
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
    
    methods
        function v = get.NumAnchors(this)
            v = size(this.MinBoxSizes,1) * this.NumBoxPyramidLevels;
        end
        
        function sz = get.MinObjectSize(this)
            sz = this.ModelSize;
        end
    end
    
    
    methods(Static, Access = public, Hidden)
                                       
        %------------------------------------------------------------------
        function [detector, rpn] = trainRPN(groundTruth, layers, opts, params, checkpointSaver)                   
              
            % Use network training options to control verbosity.
            params.Verbose = opts.Verbose;         
            
            assert( isa(layers, 'vision.cnn.RegionProposalNetwork') );
                                    
            % input size used by dispatcher to determine num channels in
            % images. uses it to convert gray <-> rgb.
            inputSize = layers.Layers(1).InputSize;
           
            detector = fasterRCNNObjectDetector();
            detector.BoxPyramidScale = params.BoxPyramidScale;
            detector.NumBoxPyramidLevels = params.NumBoxPyramidLevels;
            detector.MinBoxSizes = params.MinBoxSizes;
            detector.ModelSize = params.ModelSize;     
            
            % Create the rpn training dispatcher                 
            params.Layers = layers.Layers;
            dispatcher = createRPNTrainingDispatcher(detector, groundTruth, opts, inputSize, params);          
                      
            rpn = vision.internal.cnn.trainNetwork(dispatcher, layers, opts, checkpointSaver);
                        
            detector.RegionProposalNetwork = rpn;
                        
        end               
        
        %------------------------------------------------------------------
        % Detector checkpoint function specialized for either RPN or Fast
        % R-CNN networks. This is required for use of alternating training
        % scheme.
        %------------------------------------------------------------------
        function detector = detectorCheckpoint(net, detector)   
            % store fast r-cnn checkpoint
            if isa(net, 'vision.cnn.RegionProposalNetwork')
                detector.RegionProposalNetwork = net;
            else
                detector.Network = net;                                    
            end
        end
        
        
        %------------------------------------------------------------------
        function checkpointSaver(rpn, detector)
            detector.RegionProposalNetwork = rpn;
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
         
    end
    
    %----------------------------------------------------------------------
    methods (Hidden)    
        
        function [bboxes, scores] = proposeImpl(this, I, fmap)
            
            % Unpack output from running the network.
            reg = fmap.Regression{1};
            fmap = fmap.Classification{1};                                  

            boxScales = cumprod([1 repelem(this.BoxPyramidScale, this.NumBoxPyramidLevels-1)]);
            
            % Generate anchor box sizes.
            aboxes = cell(1,size(this.MinBoxSizes,1));
            for i = 1:size(this.MinBoxSizes,1)
                % fliplr the box sizes so they are in [width height] format
                aboxes{i} = bsxfun(@times, fliplr(this.MinBoxSizes(i,:)), boxScales');
            end
            aboxes = vertcat(aboxes{:});
            
            % Predict which regions contain objects and non-objects. 
            [allScores, idx] = max(fmap,[],3);

            % Find just the regions that are objects.
            [y,xzk] = find(idx == 1);
            
            % Get the object region locations within the feature map. k is
            % the index to the anchor box.
            szidx = size(idx);
            [x,~,k] = ind2sub(szidx(2:end), xzk);
            
            % filter anchor boxes that are larger than the input image.
            imageSize = size(I);
            widthHeight = aboxes(k,:); 
            keepAnchors = all(widthHeight <= fliplr(imageSize(1:2)), 2);
            
            widthHeight = widthHeight(keepAnchors,:);
            
            y = y(keepAnchors);
            x = x(keepAnchors);
            k = k(keepAnchors);

            % Use the object region locations as the box centers in the
            % feature map space.
            froi = [x y repmat([1 1], numel(x),1)];
            
            % Scale boxes in feature map space to boxes in the image space.
            % min/max format [x1 y1 x2 y2]
            
            [sx, sy] = iComputeFeatureMapToImageScaleFactors(this, imageSize);
            scaledROI = vision.internal.cnn.scaleROI(froi, sx, sy);
             
            % Generate anchor boxes in the image space.
            boxCenters = scaledROI(:,1:2) + floor((scaledROI(:,3:4) - scaledROI(:,1:2))/2);
           
            halfWidth = floor( widthHeight/2 );
            
            bboxes = [boxCenters - halfWidth widthHeight];
            
            % Regression input is [M N 4*NumAnchors], where the 4
            % box coordinates are consequitive elements. Reshape data to
            % [M N 4 NumAnchors] so that we can gather the regression
            % values based on the max score indices.
            reg = reshape(reg, size(reg,1), size(reg,2), 4, []);
           
            % Generate the indices for accessing the regression data.
            r = repmat((1:4)', numel(y), 1); 
            yreg = repelem(y,4,1);
            xreg = repelem(x,4,1);
            kreg = repelem(k,4,1);
            
            indices = sub2ind(size(reg), yreg, xreg, r, kreg);
            
            reg1 = reg(indices);
               
            reg1 = reshape(reg1, 4, [])';
            
            b = applyRPNBoxRegression(bboxes, reg1);
            
            % Filter out boxes that are outside the image.
            x2 = b(:,1) + b(:,3) - 1;
            y2 = b(:,2) + b(:,4) - 1;
            
            outsideImage = (b(:,1) < 1) | (b(:,2) < 1) | (x2 > imageSize(2)) | (y2 > imageSize(1));
            
            b(outsideImage, :) = [];
            
            y = y(~outsideImage);
            x = x(~outsideImage);
            k = k(~outsideImage);
            
            scoreIndices = sub2ind(size(allScores), y, x, k);
            
            bboxes = b;
            scores = allScores(scoreIndices);
            
        end
        
        function [bboxes, scores] = propose(this, I, minBoxSize, varargin)
            
            params = fasterRCNNObjectDetector.parseProposeInputs(I, varargin{:});
                      
           
            numLayers = numel(this.RegionProposalNetwork.Layers);
            
            fmap = internalActivations(this.RegionProposalNetwork, I, numLayers, 1, ...
                'MiniBatchSize', params.MiniBatchSize, ...
                'ExecutionEnvironment', params.ExecutionEnvironment,...
                'OutputAs','channels');
            
            [bboxes, scores] = this.proposeImpl(I, fmap);
            
            % remove low scoring boxes
            lowScores = scores < params.MinScore;
            bboxes(lowScores,:) = [];
            scores(lowScores,:) = [];
                                           
            [bboxes, scores] = fastRCNNObjectDetector.filterSmallBBoxes(bboxes, scores, minBoxSize);
                        
            % The RatioType is set to 'Min'. This helps suppress
            % proposal results where large boxes surround smaller
            % boxes.
            [bboxes, scores] = selectStrongestBbox(bboxes, scores, ...
                'RatioType', 'Union', 'OverlapThreshold', 0.7);
            
        end
    end
    
    methods
        function [bboxes, scores, labels] = detect(this, I, varargin)
            % bboxes = detect(fasterRCNN, I) detects objects within the image I.
            % The location of objects within I are returned in bboxes, an
            % M-by-4 matrix defining M bounding boxes. Each row of bboxes
            % contains a four-element vector, [x, y, width, height]. This
            % vector specifies the upper-left corner and size of a bounding
            % box in pixels. fasterRCNN is a fasterRCNNObjectDetector object 
            % and I is a truecolor or grayscale image.
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
            % training using the trainFasterRCNNObjectDetector function.
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
            %  'MinSize'          Specify the size of the smallest
            %                     region containing an object, in pixels,
            %                     as a two-element vector, [height width].
            %                     When the minimum size is known, you can
            %                     reduce computation time by setting this
            %                     parameter to that value. By default,
            %                     'MinSize' is the smallest object that can
            %                     be detected by the trained network.            
            %              
            %                     Default: fasterRCNN.MinObjectSize
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
            % Faster R-CNN detector. Valid values for resource are:
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
            % % Load pre-trained vehicle detector.
            % data = load('fasterRCNNVehicleTrainingData.mat', 'detector');
            % detector = data.detector;
            %
            % % Read test image.
            % I = imread('highway.png');
            %
            % % Run detector.
            % [bboxes, scores, labels] = detect(detector, I)
            %
            % % Display results.
            % detectedImg = insertObjectAnnotation(I, 'Rectangle', bboxes, cellstr(labels));
            % figure
            % imshow(detectedImg)
            %
            % See also trainFasterRCNNObjectDetector.
            
            params = this.parseDetectInputs(I, varargin{:});
            
            roi    = params.ROI;
            useROI = params.UseROI;
            
            Iroi = vision.internal.detector.cropImageIfRequested(I, roi, useROI);
            
            % Convert image to uint8. Faster R-CNN training forces images to
            % be in range [0 255]. Converting to uint8 here to ensure data
            % range is similar during inference.
            Iroi = im2uint8(Iroi);
            
            imageSize = size(Iroi);
            
            % Convert image from RGB <-> grayscale as required by network.
            Iroi = fastRCNNObjectDetector.convertImageToMatchNumberOfNetworkImageChannels(...
                Iroi, this.Network.InputSize);
            
            % run activations up to last shared conv layer
            convmap = internalActivations(this.Network, Iroi, [], ...
                this.LastSharedLayerIndex, 1, ...               
                'ExecutionEnvironment', params.ExecutionEnvironment,...
                'OutputAs','channels'); 
                        
            % run proposal network and get proposals
            fmap = internalActivations(this.RegionProposalNetwork, convmap, ...
                numelLayers(this.RegionProposalNetwork), this.LastSharedLayerIndex + 1, ...                
                'ExecutionEnvironment', params.ExecutionEnvironment,...
                'OutputAs','channels');                                
                                              
            [bboxes, scores] = this.proposeImpl(Iroi, fmap);   
            
            [bboxes, scores] = this.filterBBoxes(bboxes, scores, params.MinSize, params.MaxSize);                        
                      
            [bboxes, scores] = fastRCNNObjectDetector.selectStrongestRegions(bboxes, scores, params.NumStrongestRegions);
            
            % Remove overlapping proposals.
            bboxes = selectStrongestBbox(bboxes, scores, ...
                'RatioType', 'Union', 'OverlapThreshold', 0.7);
                                
            if isempty(bboxes)
                
                scores = zeros(0,1,'single');
                labels = categorical(cell(0,1),this.ClassNames);
                
            else
                featureMapSize = size(convmap);
                
                % Scale boxes for ROI Pooling layer
                scaledBBoxes = this.Network.scaleBoxes(bboxes, imageSize);
                
                % scale is [sx sy]
                this.Network.setScale( fliplr( featureMapSize(1:2) ./ imageSize(1:2)) );
                
                % run detection network after last conv layer till end.
                fmap = internalActivations(this.Network, convmap, scaledBBoxes, ...
                    numelLayers(this.Network), this.LastSharedLayerIndex + 1, ...
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
                bboxes = vision.internal.detector.clipBBox(bboxes, imageSize);
                   
                [bboxes, scores] = fastRCNNObjectDetector.removeNegativeBoxes(bboxes, scores);
                               
                if params.SelectStrongest
                    % The RatioType is set to 'Min'. This helps suppress
                    % detection results where large boxes surround smaller
                    % boxes.
                    [bboxes, scores, index] = selectStrongestBbox(bboxes, scores, ...
                        'RatioType', 'Min', 'OverlapThreshold', 0.5);
                    
                    labels = labels(index,:);
                end
                
                bboxes(:,1:2) = vision.internal.detector.addOffsetForROI(bboxes(:,1:2), roi, useROI);
            end
        end               
    end
    
    methods
        
        %------------------------------------------------------------------
        function this = fasterRCNNObjectDetector(varargin)
            if nargin == 0
                this.BackgroundLabel = 'Background';  
                this.TrainingStage = 0; % untrained
            elseif nargin == 1
                
                clsname = 'fasterRCNNObjectDetector';
                
                validateattributes(varargin{1},{clsname}, ...
                    {'scalar'}, mfilename);
                
                if isequal(class(varargin{1}), clsname)
                    this = setPropertiesOnLoad(this, saveobj(varargin{1}));
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = set.Network(this, network)
            if ~isempty(network)                            
                
                validateattributes(network, ...
                    {'vision.cnn.RegionProposalNetwork',...
                    'vision.cnn.FastRCNN',...
                    'SeriesNetwork'},{'scalar'});
                
                cls = 'nnet.cnn.layer.ImageInputLayer';
                if isempty(network.Layers)|| ~isa(network.Layers(1), cls)
                    error(message('vision:rcnn:firstLayerNotImageInputLayer'));
                end
                
                cls = 'nnet.cnn.layer.ClassificationOutputLayer';
                if isempty(network.Layers)|| ~isa(network.Layers(end), cls)
                    error(message('vision:rcnn:lastLayerNotClassificationLayer'));
                end                                
                                
            end
            
            this.Network = network;
        end
        
        %------------------------------------------------------------------
        function cls = get.ClassNames(this)
            if ~isempty(this.Network)
                cls = this.Network.ClassNames;
            else
                cls = {};
            end
        end
    end
    
    methods (Access = protected)
        function dispatcher = createRPNTrainingDispatcher(~, groundTruth, opts, imageSize, params)
            
            params.miniBatchSize   = opts.MiniBatchSize;
            params.endOfEpoch      = 'discardLast';
            params.precision       = nnet.internal.cnn.util.Precision('single');
            params.resizer         = [];
            params.RandomSelector  = vision.internal.rcnn.RandomSelector();
            params.BackgroundLabel = 'Background';                       
            params.ImageSize       = imageSize;
                        
            dispatcher = vision.internal.cnn.rpn.RPNTrainingRegionDispatcher(...
                groundTruth, params);
            
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
        
        function [bboxes, scores] = filterBBoxes(~, bboxes, scores, minSize, maxSize)
                          
            [bboxes, scores] = fastRCNNObjectDetector.filterSmallBBoxes(bboxes, scores, minSize);
            
            [bboxes, scores] = fastRCNNObjectDetector.filterLargeBBoxes(bboxes, scores, maxSize);
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
            
            networkInputSize = this.Network.InputSize;
            if any(sz(1:2) < networkInputSize(1:2))
                error(message('vision:rcnn:imageSmallerThanNetwork',mat2str(networkInputSize(1:2))));
            end
                        
            useROI = ~ismember('roi', p.UsingDefaults);
            
            if useROI
                vision.internal.detector.checkROI(userInput.roi, size(I));
            end
            
            vision.internal.inputValidation.validateLogical(...
                userInput.SelectStrongest, 'SelectStrongest');
            
            wasMinSizeSpecified = ~ismember('MinSize', p.UsingDefaults);
            wasMaxSizeSpecified = ~ismember('MaxSize', p.UsingDefaults);
                       
            if wasMinSizeSpecified
                vision.internal.detector.ValidationUtils.checkMinSize(userInput.MinSize, this.ModelSize, mfilename);
            else
                % set min size to model training size if not user specified.
                userInput.MinSize = this.ModelSize;
            end

            if wasMaxSizeSpecified
                vision.internal.detector.ValidationUtils.checkMaxSize(userInput.MaxSize, this.ModelSize, mfilename);
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
                        this.ModelSize, ...
                        'vision:ObjectDetector:ROILessThanMinSize', ...
                        'vision:ObjectDetector:ROILessThanModelSize');
                end
            else        
                vision.internal.detector.ValidationUtils.checkImageSizes(sz(1:2), userInput, wasMinSizeSpecified, ...
                    this.ModelSize , ...
                    'vision:ObjectDetector:ImageLessThanMinSize', ...
                    'vision:ObjectDetector:ImageLessThanModelSize');
            end
                                   
            % TODO make these shared - also used in fastRCNN just make this
            % public static
            fasterRCNNObjectDetector.checkStrongestRegions(userInput.NumStrongestRegions);
            
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
            s.Network               = saveobj(this.Network);                   
            s.BackgroundLabel       = this.BackgroundLabel;
            s.RegionProposalNetwork = saveobj(this.RegionProposalNetwork);
            s.BoxPyramidScale       = this.BoxPyramidScale;
            s.NumBoxPyramidLevels   = this.NumBoxPyramidLevels;
            s.MinBoxSizes           = this.MinBoxSizes;
            s.ModelSize             = this.ModelSize;
            s.LastSharedLayerIndex  = this.LastSharedLayerIndex;            
            s.TrainingStage         = this.TrainingStage;
            s.ModelName             = this.ModelName;
            s.Version               = 1.5;
        end
        
        %------------------------------------------------------------------
        function this = setPropertiesOnLoad(this, s)
            try
               vision.internal.requiresNeuralToolbox(mfilename);
                
                s = iLoadPreviousVersion(s);
                                
                this.BackgroundLabel   = s.BackgroundLabel;
                if ~isempty(s.Network)
                    % partial training - this is empty until object is fully
                    % trained. this is required to handle parallel training.
                    this.Network = vision.cnn.FastRCNN.loadobj(s.Network);
                end
                this.RegionProposalNetwork = vision.cnn.RegionProposalNetwork.loadobj(s.RegionProposalNetwork);
                this.BoxPyramidScale       = s.BoxPyramidScale;
                this.NumBoxPyramidLevels   = s.NumBoxPyramidLevels;
                this.MinBoxSizes           = s.MinBoxSizes;
                this.ModelSize             = s.ModelSize;
                this.LastSharedLayerIndex  = s.LastSharedLayerIndex;
                this.TrainingStage         = s.TrainingStage;
                this.ModelName             = s.ModelName;
            catch ME
                rethrow(ME)
            end
        end
        
    end
    
    methods(Static, Hidden)
        function this = loadobj(s)
           this = fasterRCNNObjectDetector();
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
        
        function detector = checkPointDetector(frcnn, rpn, params)
            
            detector = fasterRCNNObjectDetector();
            
            if ~isempty(frcnn)
                detector.RegionProposalNetwork = rpn;
            end
            
            if ~isempty(frcnn)
                detector.Network = frcnn;
            end
            
            detector.LastSharedLayerIndex = params.LastConvLayerIdx;
            detector.BoxPyramidScale      = params.BoxPyramidScale;
            detector.MinBoxSizes          = params.MinBoxSizes;
            detector.NumBoxPyramidLevels  = params.NumBoxPyramidLevels;
            detector.ModelSize            = params.ModelSize;
            detector.TrainingStage        = params.TrainingStage;
            detector.ModelName            = params.ModelName;
        end
    end
    
    %----------------------------------------------------------------------
    methods(Hidden, Static, Access = public)              
        
        function params = parseProposeInputs(I, varargin)
            
            p = inputParser;
            p.addOptional('roi', zeros(0,4));
            p.addParameter('NumStrongestRegions', 2000);            
            p.addParameter('MiniBatchSize', 128);
            p.addParameter('MinScore', 0.5);
            p.addParameter('ExecutionEnvironment', 'auto');
            parse(p, varargin{:});
            
            userInput = p.Results;
            
            % grayscale or RGB images allowed
            vision.internal.inputValidation.validateImage(I, 'I');
            
            useROI = ~ismember('roi', p.UsingDefaults);
            
            if useROI
                userInput.roi = vision.internal.detector.checkROI(userInput.roi, size(I));
            end                      
            
            fasterRCNNObjectDetector.checkStrongestRegions(userInput.NumStrongestRegions);
            vision.internal.cnn.validation.checkMiniBatchSize(userInput.MiniBatchSize, mfilename);
            
            exeenv = vision.internal.cnn.validation.checkExecutionEnvironment(...
                userInput.ExecutionEnvironment, mfilename);
                       
            params.NumStrongestRegions  = double(userInput.NumStrongestRegions);            
            params.MiniBatchSize        = double(userInput.MiniBatchSize);
            params.MinScore             = double(userInput.MinScore);
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
            printer.print('*************************************************************************\n');
            printer.printMessage('vision:rcnn:fasterTrainingBanner');
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
            printer.print('*************************************************************************\n');
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

%--------------------------------------------------------------------------
function bboxes = applyRPNBoxRegression(P, reg)
% input reg targets for RPN is [size(P,1) 4].
bboxes = fastRCNNObjectDetector.applyReg(P, reg);
end

%--------------------------------------------------------------------------
function s = iLoadPreviousVersion(s)
if ~isfield(s,'Version') || s.Version == 1.0
    % version 1.0 has BoxAspectRatios, BoxPyramidScales, 
    
    % MinBoxSizes
    n = numel(s.BoxAspectRatios);
    w = zeros(n,1);
    h = zeros(n,1);
    
    iw = s.BoxAspectRatios < 1; % W < H
    ih = s.BoxAspectRatios >=1; % H < W
    
    w(iw) = s.MinBoxSize(1);
    h(ih) = s.MinBoxSize(2);
    
    h(iw) = w(iw) ./ s.BoxAspectRatios(iw);
    w(ih) = h(ih) .* s.BoxAspectRatios(ih);
    
    s.MinBoxSizes = [h w];
    
    % BoxPyramidScale
    scales = sort(s.BoxScales);
    scale = median( scales(2:end) ./ scales(1:end-1) );
    s.BoxPyramidScale = scale;
    
    % NumBoxPyramidLevels
    s.NumBoxPyramidLevels = numel(s.BoxScales);
    
    % ModelSize
    s.ModelSize = s.MinBoxSize;
    
    s.ModelName = '';
    
    s.Version = 1.5;
end

if s.Version <= 1.5
    % Fix-up min model size for models saved in previous versions.
    if isfield(s,'Network')
        modelSize = fastRCNNObjectDetector.determineMinBoxSize(s.Network);
        
        s.ModelSize = modelSize;
        
        % MinBoxSizes must be >= ModelSize
        s.MinBoxSizes = max(s.MinBoxSizes, s.ModelSize);
    end
end

end

%--------------------------------------------------------------------------
function [sx, sy] = iComputeFeatureMapToImageScaleFactors(detector, imageSize)
if isempty(detector.CachedFeatureMapSize) ...
    || ~isequal(detector.CachedImageSize(1:2),imageSize(1:2))
    detector.CachedImageSize      = imageSize;
    detector.CachedFeatureMapSize = computeFeatureMapSize(detector.RegionProposalNetwork, imageSize);
end

scaleFactor = detector.CachedImageSize(1:2)./detector.CachedFeatureMapSize(1:2);

sx = scaleFactor(2);
sy = scaleFactor(1);
end
