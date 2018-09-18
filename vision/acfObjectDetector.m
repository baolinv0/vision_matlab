%acfObjectDetector Detect objects using ACF features
%   acfObjectDetector is returned by the trainACFObjectDetector function.
%   It contains a classifier trained to recognize rigid objects.
% 
%   acfObjectDetector properties:
%      ModelName          - Name of the classification model.
%      ObjectTrainingSize - The size of the model in the form of [height, width]. (read only)
%      NumWeakLearners    - Number of weak learners used in the detector. (read only)
%
%   acfObjectDetector methods:
%      detect             - Detect objects in an image.
%
%  Example - Train a stop sign detector
%  ------------------------------------
%  % Load training data
%  load('stopSignsAndCars.mat')
%
%  % Select the ground truth for stop signs
%  stopSigns = stopSignsAndCars(:, 1:2);
%
%  % Add fullpath to image files
%  stopSigns.imageFilename = fullfile(toolboxdir('vision'),'visiondata', ...
%      stopSigns.imageFilename);
%
%  % Train the ACF detector. 
%  acfDetector = trainACFObjectDetector(stopSigns,'NegativeSamplesFactor',2,'Verbose',false);
%
%  % Test the ACF detector on a test image.
%  img = imread('stopSignTest.jpg');
%
%  [bboxes, scores] = detect(acfDetector, img);
%
%  % Display the detection result
%  for i = 1:length(scores)
%      annotation = sprintf('Confidence = %.1f', scores(i));
%      img = insertObjectAnnotation(img, 'rectangle', bboxes(i,:), annotation);
%  end
%
%  figure
%  imshow(img)
%
% See also trainACFObjectDetector, imageLabeler, 
%          rcnnObjectDetector, vision.CascadeObjectDetector.

% Copyright 2016 The MathWorks, Inc.
%
% References
% ----------
%   Dollar, Piotr, et al. "Fast feature pyramids for object detection."
%   Pattern Analysis and Machine Intelligence, IEEE Transactions on 36.8
%   (2014): 1532-1545.

classdef acfObjectDetector < vision.internal.EnforceScalarHandle
    
    properties(Access = public)
        % ModelName Name of the classification model. By default, it is set to the
        % heading string of the second column of the ground truth table in
        % trainACFObjectDetection function.
        ModelName
    end
    
    properties(SetAccess = private, Dependent)
        % ObjectTrainingSize The size of the model in the form of [height, width].
        ObjectTrainingSize 
        % NumWeakLearners Number of weak learners used in the detector.
        NumWeakLearners
    end
        
    properties(Access = protected)
        % A structure of adaboost classifier
        Classifier
        % A structure of feature pyramid parameters
        TrainingOptions
    end

    %======================================================================
    methods
        function [bboxes, scores] = detect(this, I, varargin)
        %  bboxes = detect(detector, I) detects objects within the image
        %  I. The locations of objects within I are returned in bboxes, an
        %  M-by-4 matrix defining M bounding boxes. Each row of bboxes
        %  contains a four-element vector, [x, y, width, height]. This
        %  vector specifies the upper-left corner and size of a bounding
        %  box in pixels. detector is an acfObjectDetector and I is a
        %  truecolor or grayscale image.
        %
        %  [..., scores] = detect(...) optionally returns the detection
        %  scores for each bounding box. Larger score values indicate
        %  higher confidence in the detection.
        %
        %  [...] = detect(..., roi) optionally detects objects within the
        %  rectangular search region specified by roi. roi must be a
        %  4-element vector, [x, y, width, height], that defines a
        %  rectangular region of interest fully contained in I.
        %
        %  [...] = detect(..., Name, Value) specifies additional name-value
        %  pairs described below.
        %
        %  'NumScaleLevels'  Number of scale levels per octave, where each
        %                    octave is a power of 2 downscaling of the
        %                    image. Increase this number to detect object
        %                    at finer scale increments. Recommended values
        %                    are between 4 and 10.
        % 
        %                    Default: 8
        %
        %  'WindowStride'    Specify the window stride for sliding-window
        %                    object detection. The same stride is used in
        %                    both the x and y directions.
        %
        %                    Default: 4
        %
        %  'SelectStrongest' A logical scalar. Set this to true to
        %                    eliminate overlapping bounding boxes based on
        %                    their scores. This process is often referred
        %                    to as non-maximum suppression. Set this to
        %                    false if you want to perform a custom
        %                    selection operation. When set to false all the
        %                    detected bounding boxes are returned.
        % 
        %                    Default: true
        %
        %  'MinSize'         Specify the size of the smallest region
        %                    containing an object, in pixels, as a
        %                    two-element vector, [height width]. When the
        %                    minimum size is known, you can reduce
        %                    computation time by setting this parameter to
        %                    that value. By default, 'MinSize' is the
        %                    smallest object that can be detected by the
        %                    trained classification model.
        %                         
        %                    Default: detector.ObjectTrainingSize
        %
        %  'MaxSize'         Specify the size of the biggest region
        %                    containing an object, in pixels, as a
        %                    two-element vector, [height width]. When the
        %                    maximum object size is known, you can reduce
        %                    computation time by setting this parameter to
        %                    that value. Otherwise, the maximum size is
        %                    determined based on the width and height of I.
        %
        %                    Default: size(I)
        %
        %  'Threshold'       The threshold value to control the
        %                    classification accuracy and speed of
        %                    individual image sub-regions as object or
        %                    non-object during multi-scale object
        %                    detection. Increase this threshold to speed up
        %                    the performance at the risk of potentially
        %                    missing true detections. Typical values range
        %                    from -1 to 1.
        %
        %                    Default: -1
        %
        % Notes:
        % -----
        % - When 'SelectStrongest' is true the selectStrongestBbox
        %   function is used to eliminate overlapping boxes. The 
        %   function is called with the following values:
        %
        %      selectStrongestBbox(bbox, scores, 'RatioType', 'Min', ...
        %                                        'OverlapThreshold', 0.65);
        %
        % See also selectStrongestBbox, trainACFObjectDetector.
            
            params = acfObjectDetector.parseDetectInputs(I, ...
                this.TrainingOptions.ModelSize, varargin{:});

            Iroi = vision.internal.detector.cropImageIfRequested(I, ...
                params.ROI, params.UseROI);

            this.TrainingOptions.Threshold       = params.Threshold;
            this.TrainingOptions.MinSize         = params.MinSize;
            this.TrainingOptions.MaxSize         = params.MaxSize;
            this.TrainingOptions.WindowStride    = params.WindowStride;
            this.TrainingOptions.NumScaleLevels  = params.NumScaleLevels;

            % Compute scale-space pyramid of channels
            P = vision.internal.acf.computePyramid(Iroi, this.TrainingOptions);

            % Apply the detector on feature pyramid
            [bboxes, scores] = vision.internal.acf.detect(P, ...
                this.Classifier, this.TrainingOptions);

            bboxes = round(bboxes);

            % Channels are padded during detection. This may lead to negative box
            % positions. Clip boxes to ensure they are within image boundary.
            bboxes = vision.internal.detector.clipBBox(bboxes, size(Iroi));

            if params.SelectStrongest    
                [bboxes, scores] = selectStrongestBbox(bboxes, scores, ...
                    'RatioType', 'Min', 'OverlapThreshold', 0.65);
            end
            
            bboxes(:,1:2) = vision.internal.detector.addOffsetForROI(...
                bboxes(:,1:2), params.ROI, params.UseROI);
        end
    end
    
    %======================================================================
    % Constructor
    %======================================================================
    methods (Hidden)
        function this = acfObjectDetector(classifier, params)
            this.checkClassifierInput(classifier);
            this.checkParametersInput(params);
            
            this.ModelName = params.ModelName;
            this.Classifier = classifier;
            this.TrainingOptions = params;
        end
    end
    
    %======================================================================
    % Get/Set Properties
    %======================================================================
    methods
        function sz = get.ObjectTrainingSize(this)
            sz = this.TrainingOptions.ModelSize;
        end  
        
        function num = get.NumWeakLearners(this)
            num = size(this.Classifier.child, 2);
        end
        
        function set.ModelName(this, value) 
            if isa(value, 'string')
                validateattributes(value,{'string'}, {'nonempty','scalar'});
            else
                validateattributes(value,{'char'}, {'nonempty'});
            end
            this.ModelName = value;
        end
    end
    
    methods(Hidden)
        function cls = getClassifier(this)
            cls = this.Classifier;
        end  
        
        function params = getTrainingOptions(this)
            params = this.TrainingOptions;
        end        
    end
    
    %======================================================================
    % Save/Load
    %======================================================================
    methods(Hidden)
        function s = saveobj(this)
            s.ModelName       = this.ModelName;
            s.Classifier      = this.Classifier;
            s.TrainingOptions = this.TrainingOptions;
            s.Version         = 1.0;
        end
    end
    
    methods(Static, Hidden)
        function this = loadobj(s)
            this = acfObjectDetector(s.Classifier, s.TrainingOptions);
            % By default, the model name is set by the training function.
            % The users may change it to their preferred name.
            this.ModelName = s.ModelName;
        end
    end
    
    %======================================================================
    % Parameter validation routines.
    %======================================================================
    methods(Static, Hidden, Access = protected)
        function params = parseDetectInputs(I, modelSize, varargin)
            
            p = inputParser;
            [M, N, ~] = size(I);
            p.addOptional('ROI', zeros(0,4));
            p.addParameter('Threshold', -1, ...
                @(x)validateattributes(x,{'numeric'},...
                    {'nonempty','nonsparse','scalar','real','finite'}, ...
                    mfilename, 'Threshold'));
            p.addParameter('WindowStride', 4, ...
                @(x)validateattributes(x,{'numeric'},...
                    {'nonempty','nonsparse','real','positive','scalar','integer'},...
                    mfilename, 'WindowStride'));
            p.addParameter('NumScaleLevels', 8, ...
                @(x)validateattributes(x,{'numeric'},...
                    {'nonempty','nonsparse','scalar','real','integer','positive'},...
                    mfilename,'NumScaleLevels'));
            p.addParameter('MinSize', modelSize);
            p.addParameter('MaxSize', [M N]);
            p.addParameter('SelectStrongest', true, ...
                @(x)vision.internal.inputValidation.validateLogical(x,'SelectStrongest'));

            p.parse(varargin{:});
            userInput = p.Results;

            wasMinSizeSpecified = ~ismember('MinSize', p.UsingDefaults);
            wasMaxSizeSpecified = ~ismember('MaxSize', p.UsingDefaults);

            % validate user input
            acfObjectDetector.checkImage(I);

            if wasMinSizeSpecified
                vision.internal.detector.ValidationUtils.checkMinSize(userInput.MinSize, modelSize, mfilename);
            else
                % set min size to model training size if not user specified.
                userInput.MinSize = modelSize;
            end

            if wasMaxSizeSpecified
                vision.internal.detector.ValidationUtils.checkMaxSize(userInput.MaxSize, modelSize, mfilename);
                % note: default max size set above in inputParser to size(I)
            end

            if wasMaxSizeSpecified && wasMinSizeSpecified
                % cross validate min and max size    
                coder.internal.errorIf(any(userInput.MinSize >= userInput.MaxSize) , ...
                    'vision:ObjectDetector:minSizeGTMaxSize');
            end

            useROI = ~ismember('ROI', p.UsingDefaults);

            if useROI
                vision.internal.detector.checkROI(userInput.ROI, size(I));          
                if ~isempty(userInput.ROI)
                    sz = userInput.ROI([4 3]);
                    vision.internal.detector.ValidationUtils.checkImageSizes(sz, userInput, wasMinSizeSpecified, ...
                        modelSize, ...
                        'vision:ObjectDetector:ROILessThanMinSize', ...
                        'vision:ObjectDetector:ROILessThanModelSize');
                end
            else        
                vision.internal.detector.ValidationUtils.checkImageSizes([M N], userInput, wasMinSizeSpecified, ...
                    modelSize, ...
                    'vision:ObjectDetector:ImageLessThanMinSize', ...
                    'vision:ObjectDetector:ImageLessThanModelSize');
            end

            % set user input to expected type
            params.ROI              = double(userInput.ROI);
            params.UseROI           = useROI;
            params.Threshold        = double(userInput.Threshold);
            params.MinSize          = double(userInput.MinSize);
            params.MaxSize          = double(userInput.MaxSize);
            params.SelectStrongest  = logical(userInput.SelectStrongest);
            params.WindowStride     = double(userInput.WindowStride);
            params.NumScaleLevels   = double(userInput.NumScaleLevels);
        end

        function checkImage(I)
            if ismatrix(I)
                vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');
            else
                vision.internal.inputValidation.validateImage(I, 'I', 'rgb');
            end
        end
        
        %------------------------------------------------------------------
        % Issue warning if sz < min size or sz < model size.
        %------------------------------------------------------------------
        function checkImageSizes(sz, userInput, wasMinSizeSpecified, modelSize, minSizeID, modelID)
            if wasMinSizeSpecified
                if any(sz < userInput.MinSize)
                    warning(message(minSizeID, ...
                        acfObjectDetector.printSizeVector(sz),...
                        acfObjectDetector.printSizeVector(userInput.MinSize)));
                end
            else
                if any(sz < modelSize)
                    warning(message(modelID, ...
                        acfObjectDetector.printSizeVector(sz),...
                        acfObjectDetector.printSizeVector(modelSize)));
                end
            end
        end

        %------------------------------------------------------------------
        function vstr = printSizeVector(v)
            vstr = sprintf('[%d %d]',v(1),v(2));
        end

        %------------------------------------------------------------------
        function checkMinSize(minSize, modelSize)

            acfObjectDetector.checkSize(minSize, 'MinSize');

            % validate that MinSize is greater than or equal to the minimum
            % object size used to train the classification model
            coder.internal.errorIf(any(minSize < modelSize) , ...
                'vision:ObjectDetector:minSizeLTTrainingSize', ...
                modelSize(1),modelSize(2));
        end
        
        %------------------------------------------------------------------
        function checkMaxSize(maxSize, modelSize)

            acfObjectDetector.checkSize(maxSize, 'MaxSize');

            % validate the MaxSize is greater than the model size when
            % MinSize is not specified
            coder.internal.errorIf(any(modelSize >= maxSize) , ...
                'vision:ObjectDetector:modelMinSizeGTMaxSize', ...
                modelSize(1),modelSize(2));
        end

        %------------------------------------------------------------------
        function checkSize(sz, name)
            validateattributes(sz,{'numeric'},...
                {'nonempty','nonsparse','real','finite','integer','positive','size',[1,2]},...
                mfilename,name);
        end

        %------------------------------------------------------------------
        function checkClassifierInput(classifier)
            ispresent = isfield(classifier, {'fids', 'thrs', 'child', 'hs', ...
                'weights', 'depth', 'treeDepth'});
            if any(~ispresent)
                error(message('vision:acfObjectDetector:InvalidClassifier'));
            end
            
            validateattributes(classifier.fids, {'uint32'}, ...
                {'2d', 'real', 'nonsparse'}, mfilename);
            
            sz = size(classifier.fids);
            
            validateattributes(classifier.thrs, {'single'}, ...
                {'2d', 'real', 'nonsparse', 'size', sz}, mfilename);
            
            validateattributes(classifier.child, {'uint32'}, ...
                {'2d', 'real', 'nonsparse', 'size', sz}, mfilename);
            
            validateattributes(classifier.hs, {'single'}, ...
                {'2d', 'real', 'nonsparse', 'size', sz}, mfilename);
            
            validateattributes(classifier.weights, {'single'}, ...
                {'2d', 'real', 'nonsparse', 'size', sz}, mfilename);

            validateattributes(classifier.depth, {'uint32'}, ...
                {'2d', 'real', 'nonsparse', 'size', sz}, mfilename);

        end
        %------------------------------------------------------------------
        function checkParametersInput(params)
            ispresent = isfield(params, {'ModelName', 'ModelSize', 'ModelSizePadded', ...
                'ChannelPadding', 'NumApprox', 'Shrink', ...
                'SmoothChannels', 'PreSmoothColor', ...
                'NumUpscaledOctaves', 'gradient', 'hog', 'Lambdas', ...
                'NumStages', 'NegativeSamplesFactor', 'MaxWeakLearners'});
            if any(~ispresent)
                error(message('vision:acfObjectDetector:InvalidParameter'));
            end
        end
    end
end


