%bagOfFeatures Create bag of visual features.
%   bag = bagOfFeatures(imds) returns a bag of visual features. imds is
%   an ImageDatastore object. By default, SURF features are used to
%   generate the vocabulary features. Vocabulary is quantized using K-means
%   algorithm.
%
%   bag = bagOfFeatures(imds,'CustomExtractor',extractorFcn) returns a
%   bag of features that uses a custom feature extractor function to
%   generate the vocabulary features. extractorFcn is a function handle to
%   a custom feature extraction function.
%
%     <a href="matlab:helpview(fullfile(docroot,'toolbox','vision','vision.map'),'bagOfFeaturesCustomFeatures')">Learn more about writing a custom feature extractor.</a>
%
%     <a href="matlab:bagOfFeatures.createExtractorTemplate">Open a custom feature extractor template.</a>
%
%   bag = bagOfFeatures(...,Name,Value) specifies additional
%   name-value pair arguments described below:
%
%   'VocabularySize'    Integer scalar, VocabularySize >=2. Specifies 
%                       number of visual words to hold in the bag. It
%                       corresponds to K in K-means algorithm used to
%                       quantize the visual vocabulary.
%
%                       Default: 500
%
%   'StrongestFeatures' Fraction of strongest features to use from each 
%                       label contained in imds input.
%
%                       Default: 0.8
%
%   'Verbose'           Set true to display progress information.
%
%                       Default: true
%
%  The following name-value pairs apply only when 'CustomExtractor' is not
%  specified.
%
%   'PointSelection'    'Grid' or 'Detector'. When set to 'Detector',
%                       the feature points are picked using SURF feature
%                       detector. Otherwise, the points are picked on a
%                       regular grid with spacing defined by 'GridStep'.
%
%                       Default: 'Grid'
%
%   'GridStep'          Applies only when 'PointSelection' is 'Grid'.
%                       Specifies step in X and Y directions defining the
%                       locations where features are extracted.
%
%                       Default: [8 8]
%
%   'BlockWidth'        Applies only when 'PointSelection' is 'Grid'.
%                       Specify a vector of block widths. Each element of
%                       the vector corresponds to the size of a square
%                       block from which SURF descriptors are extracted.
%                       Use multiple square sizes to extract multi-scale
%                       features. The minimum BlockWidth is 32 pixels.
%
%                       Default: [32 64 96 128]
%
%   'Upright'           A logical scalar. When set to true, the orientation
%                       of the SURF feature vectors is not estimated. Set
%                       'Upright' to false when you need the image
%                       descriptors to capture rotation information.                     
%                
%                       Default: true
%
%   bagOfFeatures methods:
%      encode - Create a feature vector, a histogram of visual word occurrences
%
%   bagOfFeatures read-only properties:
%      CustomExtractor   - A function handle to a custom extraction function
%      VocabularySize    - Number of visual words held by the bag
%      StrongestFeatures - Fraction of strongest features to use from each label      
%      PointSelection    - Method used to define point locations for feature extraction
%      GridStep          - Step in X and Y directions defining the grid spacing
%      BlockWidth        - Patch sizes from which SURF descriptor is extracted
%      Upright           - Whether or not to use upright SURF descriptors
%
%   Notes:
%   ------
%   - If imds.Labels contains more than one unique label, an
%     equal number of strongest features is extracted for each unique
%     label. That number is min(number of features found in each
%     label)*strongestFraction, where strongestFraction is a value of the
%     'StrongestFeatures' property.
%   
%   - bagOfFeatures supports parallel computing using multiple MATLAB
%     workers. Enable parallel computing using the <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
%   Example 1
%   ---------
%   % Load a set of images
%   setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets');
%   imds = imageDatastore(setDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
%
%   trainingSet = splitEachLabel(imds, 2); % pick the first 2 images from each label
%   bag = bagOfFeatures(trainingSet); % bag creation can take a few minutes
%
%   % Compute histogram of visual word occurrences for one of the images
%   img = readimage(imds, 1);
%   featureVector = encode(bag, img);
%
%   Example 2 - Using custom features
%   ---------------------------------
%
%   % Load a set of images
%   setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets');
%   imds = imageDatastore(setDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
%
%   % Specify a custom feature extractor
%   extractor = @exampleBagOfFeaturesExtractor;
%   bag = bagOfFeatures(imds,'CustomExtractor',extractor) 
%
%   % <a href="matlab:edit('exampleBagOfFeaturesExtractor')">Open exampleBagOfFeaturesExtractor for more details.</a>
%
%   See also imageDatastore, trainImageCategoryClassifier, imageCategoryClassifier, 
%            retrieveImages, indexImages.

%   Copyright 2014 MathWorks, Inc.

%   References:
%      Gabriella Csurka, Christopher R. Dance, Lixin Fan, Jutta Willamowski,
%      Cedric Bray "Visual Categorization with Bag of Keypoints",
%      Workshop on Statistical Learning in Computer Vision, ECCV, 2004.

classdef bagOfFeatures < vision.internal.EnforceScalarHandle & matlab.mixin.CustomDisplay

    
    properties(GetAccess = public, SetAccess = private)
        
        % CustomExtractor - A function handle to a custom feature extraction function
        CustomExtractor;   
        % VocabularySize - Number of visual words held by the bag
        VocabularySize;
        % StrongestFeatures - Fraction of strongest features to use from each label.
        StrongestFeatures;
        % PointSelection - Method used to define point locations for feature extraction
        PointSelection;
        % GridStep - Step in X and Y directions defining the grid spacing
        GridStep;
        % BlockWidth - Patch sizes from which SURF descriptor is extracted
        BlockWidth;
        % Upright - Whether or not to extract upright SURF descriptors
        Upright;
    end
    
    properties(Hidden, Access = protected)
        Vocabulary; 
        UsingCustomExtractor;
        CustomFeatureLength;        
        ExtractorOutputsLocations;
        KDTreeIndexState;
    end
    
    properties(Hidden, Transient, Access = protected)        
        VocabularySearchTree;
        
        % Function handle to either default or custom extractor.
        Extractor; 
    end
    
    properties(Hidden, Constant, Access = protected)
        ValidPointSelectionOptions = {'Grid','Detector'};
    end      

    %----------------------------------------------------------------------
    methods (Access = public)
        
        %------------------------------------------------------------------
        % Constructor
        function this = bagOfFeatures(varargin)

            if nargin == 0
                
                % Just return empty object with all default configuration
                % settings.
                d = bagOfFeatures.getDefaultSettings;
                this = this.setParams(d);
                this.VocabularySize = 0; % this is actually an empty bag
                
            else            
                % parse the inputs
                [imgSets, params] = bagOfFeatures.parseInputs(varargin{:});

                this = this.setParams(params);                                
                
                printer = vision.internal.MessagePrinter.configure(params.Verbose);
                                           
                [descriptors, scores] = this.extractDescriptors(imgSets, params, printer);                                              
                
                % If needed, remove some of the descriptors
                descriptorSet = this.trimDescriptors(descriptors, scores, printer);                                                                
                
                printer.printMessage('vision:bagOfFeatures:vocabCreation', ...
                    this.VocabularySize);                
                
                this.Vocabulary = this.createVocabulary(descriptorSet, ...
                    'Verbose', params.Verbose, 'UseParallel', params.UseParallel);                                 
                
                this.initializeVocabularySearchTree();
                
                printer.printMessage('vision:bagOfFeatures:finishedBoF').linebreak;                
            end
          
        end % end of Constructor
         
        %------------------------------------------------------------------
        function out = isempty(this)

            out = (this.VocabularySize == 0);
        end
        
        %------------------------------------------------------------------
        function [featureVector, varargout] = encode(this, in, varargin)
            %encode Create a feature vector, a histogram of visual word occurrences
            %  featureVector = encode(bag, I) returns a feature vector, 
            %  that is a histogram of visual word occurrences in I.  I can
            %  be grayscale or truecolor. bag is the bagOfFeatures object.
            %  featureVector's length is bag.VocabularySize.
            %
            %  [..., words] = encode(bag, I) optionally returns the visual
            %  words as a visualWords object. A visualWords object stores
            %  the visual words that occur in I and the locations of those
            %  words.
            %
            %  featureVector = encode(bag, imds) returns a feature vector,
            %  that is a histogram of visual word occurrences in imds.
            %  imds is an ImageDatastore object. featureVector is
            %  M-by-bag.VocabularySize, where M is the total number of
            %  images in imds, numel(imds.Files).
            %
            %  [..., words] = encode(bag, imds) optionally returns an
            %  array of visualWords objects for each image in imds, an
            %  ImageDatastore object. A visualWords object stores the
            %  visual words and the locations of those words within an
            %  image.
            %
            %  [...] = encode(..., Name, Value) specifies additional
            %  name-value pairs described below:
            %
            %  'Normalization' Specify the type of normalization applied
            %                  to the feature vector. Set to either 'L2' or
            %                  'none'.
            %
            %                  Default: 'L2'    
            %
            %  'SparseOutput'  True or false. Set to true to return visual
            %                  word histograms as sparse matrices. This
            %                  reduces memory consumption for large visual
            %                  vocabularies where the visual word
            %                  histograms contain many zero elements.
            %
            %                  Default: false
            %
            %  'Verbose'       Set true to display progress information.
            %                  
            %                  Default: true
            %  Example
            %  -------
            %  % Load a set of images
            %  setDir  = fullfile(toolboxdir('vision'),'visiondata','imageSets');
            %  imds = imageDatastore(setDir, 'IncludeSubfolders',true, 'LabelSource', 'foldernames');
            %
            %  trainingSet = splitEachLabel(imds, 2); % pick first 2 images from each label
            %  bag = bagOfFeatures(trainingSet);
            % 
            %  % encode one of the images into a feature vector
            %  img = readimage(trainingSet, 1);
            %  featureVector = encode(bag, img);
                       
            nargoutchk(0,2);
              
            % Check if extractor supports visual word output
            if nargout == 2 && ~this.ExtractorOutputsLocations
                error(message('vision:bagOfFeatures:customNoLocations',...
                    func2str(this.CustomExtractor)));                
            end
                                    
            params = bagOfFeatures.parseEncodeInputs(in, varargin{:});
            
            numVarargout = nargout-1;
            
            if ~isnumeric(in)        
                
                printer = vision.internal.MessagePrinter.configure(params.Verbose);
                                        
                printer.linebreak;
                printer.printMessage('vision:bagOfFeatures:encodeTitle');     
                printer.print('--------------------------------------\n');
                
                bagOfFeatures.printImageSetDescription(printer, in);

                if bagOfFeatures.isImageSet(in)
                    numImages = sum([in.Count]);
                    
                    featureVector = bagOfFeatures.allocateFeatureVector(numImages, this.VocabularySize, params.SparseOutput);
                    tmp = cell(1,numVarargout);
                    outIdx = 1;
                    
                    if numVarargout == 1
                        for i = 1:numel(in)
                            count = in(i).Count;
                            
                            printer.printMessageNoReturn('vision:bagOfFeatures:encodeStart', count, i);
                            
                            [featureVector(outIdx:outIdx+count-1,:), ...
                                varargout{1:numVarargout}] = this.encodeScalarImageSet(in(i), params);
                            
                            tmp{1:numVarargout}(outIdx:outIdx+count-1,1) = varargout{1:numVarargout};
                            
                            outIdx = outIdx+count;
                            
                            printer.printMessage('vision:bagOfFeatures:encodeDone');
                        end
                        varargout{1:numVarargout} = tmp{1:numVarargout};
                    else
                        for i = 1:numel(in)
                            count = in(i).Count;
                            
                            printer.printMessageNoReturn('vision:bagOfFeatures:encodeStart', count, i);
                            
                            featureVector(outIdx:outIdx+count-1,:) = this.encodeScalarImageSet(in(i), params);
                            
                            outIdx = outIdx+count;
                            
                            printer.printMessage('vision:bagOfFeatures:encodeDone');
                        end
                    end
                    printer.linebreak;
                    printer.printMessage('vision:bagOfFeatures:encodeFinished').linebreak;
                    
                else
                    % input is a imageDatastore
                    printer.printMessageNoReturn('vision:bagOfFeatures:encodeStartDS', numel(in.Files));     
                    
                    [featureVector, varargout{1:numVarargout}] = ...
                        this.encodeScalarImageSet(in, params);
                    
                    printer.printMessage('vision:bagOfFeatures:encodeDone');                                                    
                end
                    
            else                
                [featureVector, varargout{1:numVarargout}] = this.encodeSingleImage(in, params);
            end          
            
        end        
        
        %------------------------------------------------------------------
        function s = saveobj(this)
            % save properties into struct
            s.VocabularySize            = this.VocabularySize;
            s.StrongestFeatures         = this.StrongestFeatures;
            s.GridStep                  = this.GridStep;
            s.BlockWidth                = this.BlockWidth;
            s.PointSelection            = this.PointSelection;
            s.Vocabulary                = this.Vocabulary; 
            s.CustomExtractor           = this.CustomExtractor;
            s.UsingCustomExtractor      = this.UsingCustomExtractor;
            s.CustomFeatureLength       = this.CustomFeatureLength;
            s.Upright                   = this.Upright;              
            s.ExtractorOutputsLocations = this.ExtractorOutputsLocations;
            s.KDTreeIndexState          = this.KDTreeIndexState;
        end       
    end % end public methods
            
    %======================================================================
    methods (Hidden, Access = protected)
        
        %------------------------------------------------------------------
        % This method may trim the number of descriptors depending on the
        % circumstances. Here are the conditions:
        % * when imgSet set is a scalar, i.e. it contains one set of images,
        %   the number of features is reduced to (num all
        %   features)*strongestFeaturesFraction
        % * when imgSet is an array, the number of features is reduced to 
        %   min(num features per set)*strongestFeaturesFraction in order to
        %   balance relative "strength" of each set
        %------------------------------------------------------------------
        function trimmedDescriptors = trimDescriptors(this, ...
                descriptorCell, scores, printer)
            
            numFeatures = cellfun(@length,scores);
            
            % Determine smallest number of features in any of the sets.
            % That will determine the maximum number of features to use
            % while forming the vocabulary            
            [maxNumFeatures, setIdx] = min(numFeatures);
            
            % Based on percentage, figure out how many features to keep
            numToKeep = round(maxNumFeatures*this.StrongestFeatures);                        
            
            printer.printMessage('vision:bagOfFeatures:trimDescriptors', ...
                100 * this.StrongestFeatures).linebreak;                               
            
            this.printFeatureBalancingMessage(printer, ...
                numFeatures, setIdx, numToKeep);
            
            numSets = length(descriptorCell);
            trimmedDescriptors = zeros(numSets*numToKeep, ...
                size(descriptorCell{1}, 2), 'single');
            
            insertIdx = 1:numToKeep;
            for i=1:numSets
                setScores      = scores{i};
                setDescriptors = descriptorCell{i};
                
                % limit the features to only the strong ones
                [~, sortIdx] = sort(setScores ,'descend');
                
                topScoresIdx = sortIdx(1:numToKeep,:);
                
                setDescriptors = setDescriptors(topScoresIdx,:);
                trimmedDescriptors(insertIdx,:) = setDescriptors;
                insertIdx = insertIdx+numToKeep;
            end
            
        end
        
        %------------------------------------------------------------------   
        function [descriptors, scores] = extractDescriptorsFromImageSet(this, imgSets, params)
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            numSets = numel(imgSets);
            
            % Extract descriptors that will be used to create visual vocabulary
            descriptors = cell(1, numSets);
            scores      = cell(1, numSets);                       
            
            for categoryIndex=1:numSets
                
                printer.printMessageNoReturn('vision:bagOfFeatures:extractingFeatures',imgSets(categoryIndex).Count, categoryIndex);
                
                [descriptors{categoryIndex}, ...
                    scores{categoryIndex}] = this.extractDescriptorsFromSet(imgSets(categoryIndex), params);
                
                printer.printMessage('vision:bagOfFeatures:extractingFeaturesDone',...
                    size(descriptors{categoryIndex},1));
            end
            printer.linebreak;
        end
        
        %------------------------------------------------------------------
        function [groupedDescriptors, groupedScores] = extractDescriptorsFromImageDS(this, imds, params)
           
            printer = vision.internal.MessagePrinter.configure(params.Verbose);                                   
            
            numImages = numel(imds.Files);
            
            descriptors = cell(numImages,1);
            scores = cell(numImages,1); 
            
            if isempty(imds.Labels)        
                categoryIndices = repelem(1,numImages);
            else
                
                % Use categorical to get category indices for grouping
                % descriptors and scores.
                c = categorical(imds.Labels);                               
                
                % check if any of the labels were left undefined, which can
                % happen if files are added incrementally to the image
                % datastore.
                undefined = isundefined(c);
                if all(undefined)
                    % manually set category index 
                    categoryIndices = repelem(1,numImages);
                    
                elseif any(undefined)
                    % Disallow partially undefined labels
                    error(message('vision:bagOfFeatures:labelsUndefined'))
                    
                else                    
                    categoryIndices = double(c);
                end
            
            end
            
            printer.printMessageNoReturn('vision:bagOfFeatures:extractingFeaturesDS', numImages);
            
            if params.UseParallel  
                parfor i = 1:numImages
                    img = imds.readimage(i); %#ok<PFBNS>     
                    
                    [descriptors{i}, scores{i}] = ...
                        this.Extractor(img); %#ok<PFBNS>
                end                
            else
                for i = 1:numImages
                    img = imds.readimage(i); % read in an image from the set
                    
                    [descriptors{i}, scores{i}] = ...
                        this.Extractor(img);                    
                end
            end
            
            numFeatures = sum(cellfun(@(x)size(x,1),descriptors));
            
            printer.printMessage(...
                'vision:bagOfFeatures:extractingFeaturesDone', numFeatures);
            printer.linebreak;
            
            numCategories      = bagOfFeatures.getNumCategories(imds);
            groupedDescriptors = cell(numCategories,1);
            groupedScores      = cell(numCategories,1);                                               
            
            % group descriptors by labels
            for i = 1:numImages
                groupedDescriptors{categoryIndices(i)} = [groupedDescriptors{categoryIndices(i)}; descriptors{i}];
                groupedScores{categoryIndices(i)} = [groupedScores{categoryIndices(i)}; scores{i}];
                
                % clear memory to avoid extra memory usage
                descriptors{i} = [];
                scores{i} = [];
            end                                                                    
        end
        
        %------------------------------------------------------------------   
        function [descriptors, scores] = extractDescriptors(this, imgSets, params, printer)
            
            printer.linebreak;
            printer.printMessage('vision:bagOfFeatures:createBagTitle');
            printer.print('-------------------------\n');
            
            bagOfFeatures.printImageSetDescription(printer,imgSets);
             
            this.printPointSelectionInfo(printer);
            
            if bagOfFeatures.isImageSet(imgSets)
                [descriptors, scores] = extractDescriptorsFromImageSet(this, imgSets, params);
            else
                [descriptors, scores] = extractDescriptorsFromImageDS(this, imgSets, params);
            end           
        end
        
        %------------------------------------------------------------------        
        % Encode a scalar image set. Use parfor if requested.
        %------------------------------------------------------------------
        function [features, varargout] = encodeScalarImageSet(this, imgSet, params)
            
            validateattributes(imgSet,{'imageSet','matlab.io.datastore.ImageDatastore'},{'scalar'},mfilename);
            
            numImages = numel(imgSet.Files);
            
            features = bagOfFeatures.allocateFeatureVector(numImages, this.VocabularySize, params.SparseOutput); 
            words    = bagOfFeatures.allocateVisualWords(numImages);
            
            numVarargout = nargout-1;            
                        
            if params.UseParallel
                if numVarargout == 1
                    % Invoke 2 output syntax because of parfor limitations
                    % with varargout indexing.                                        
                                                  
                    parfor j = 1:numImages
                        img = imgSet.readimage(j); %#ok<PFBNS>
                        [features(j,:), words(j)]  = this.encodeSingleImage(img, params); %#ok<PFBNS>                        
                    end                
                    
                    varargout{1} = words;
                else                    
                    parfor j = 1:numImages
                        img = imgSet.readimage(j); %#ok<PFBNS>
                        features(j,:)  = this.encodeSingleImage(img, params); %#ok<PFBNS>
                    end
                end
            else % do not use parfor         
                 if numVarargout == 1                                              
                                                  
                    for j = 1:numImages
                        img = imgSet.readimage(j);
                        [features(j,:), words(j)]  = this.encodeSingleImage(img, params);                       
                    end                
                    
                    varargout{1} = words;
                else                    
                    for j = 1:numImages
                        img = imgSet.readimage(j);
                        features(j,:)  = this.encodeSingleImage(img, params);
                    end
                 end
            end
           
        end
        %------------------------------------------------------------------
        % This routine computes a histogram of word occurrences for a given
        % input image.  It turns the input image into a feature vector
        %------------------------------------------------------------------
        function [featureVector, varargout] = encodeSingleImage(this, img, params)
                       
            if nargout == 2                
                [descriptors,~,locations] = this.Extractor(img);
            else
                descriptors = this.Extractor(img);
            end
                                
            opts = getSearchOptions(this);
            
            matchIndex = this.VocabularySearchTree.knnSearch(descriptors, 1, opts); % K = 1
                       
            h = histcounts(single(matchIndex), 1:this.VocabularySize+1);
            featureVector = single(h);
                     
            if strcmpi(params.Normalization,'L2')
                featureVector = featureVector ./ (norm(featureVector,2) + eps('single'));
            end
            
            if params.SparseOutput
                % use sparse storage to reduce memory consumption when
                % featureVector has many zero elements. 
                featureVector = sparse(double(featureVector));
            end
            
            if nargout == 2  
                % optionally return visual words
                varargout{1} = vision.internal.visualWords(matchIndex, locations, this.VocabularySize);                          
            end            
        end
        
        %------------------------------------------------------------------
        function clusterCenters = createVocabulary(this, descriptors, varargin)
            
            params = bagOfFeatures.parseCreateVocabularyInputs(varargin{:});
            
            numDescriptors = size(descriptors, 1);
            
            K = min(numDescriptors, this.VocabularySize); % can't ask for more than you provide
            
            if K == 0
                error(message('vision:bagOfFeatures:zeroVocabSize'))
            end
            
            if K < this.VocabularySize
                warning(message('vision:bagOfFeatures:reducingVocabSize', ...
                    K, this.VocabularySize));

                this.VocabularySize = K; 
            end                                              
            
            clusterCenters = vision.internal.approximateKMeans(descriptors, K, ...
                'Verbose', params.Verbose, 'UseParallel', params.UseParallel);                                    
            
        end
        
        %------------------------------------------------------------------
        function initializeVocabularySearchTree(this)
            
            this.VocabularySearchTree = ...
                vision.internal.Kdtree();
            
            % save the rand state prior to indexing in order to create an
            % exact copy of the tree during loadobj.
            this.KDTreeIndexState = rng;

            index(this.VocabularySearchTree, this.Vocabulary);
        end
        
        %------------------------------------------------------------------
        % This function grabs all descriptors from the images contained in
        % imageSet. Note that detection could be done first, followed by
        % selecting strongest detections and finally extraction of
        % descriptors. That would reduce number of extractions, but would
        % require to read the images twice. Which is less expensive?
        %------------------------------------------------------------------
        function [descriptors, scores] = extractDescriptorsFromSet(this, imgSet, params)
            
            descriptors = [];
            scores      = [];          
            numImages   = imgSet.Count;
            if params.UseParallel                
                parfor i = 1:numImages
                    img = imgSet.readimage(i); %#ok<PFBNS>     
                    
                    [tempDescriptors, tempScores] = ...
                        this.Extractor(img); %#ok<PFBNS>
                    descriptors = [descriptors; tempDescriptors]; 
                    scores = [scores; tempScores]; 
                end                
            else
                for i = 1:numImages
                    img = imgSet.readimage(i); % read in an image from the set
                    
                    [tempDescriptors, tempScores] = ...
                        this.Extractor(img);
                    descriptors = [descriptors; tempDescriptors]; %#ok<AGROW>
                    scores = [scores; tempScores]; %#ok<AGROW>
                end
            end
            
        end                           
        
        %------------------------------------------------------------------
        function points = determineExtractionPoints(this,grayImage)
            
            if strcmpi(this.PointSelection, 'Grid')
                points = this.createSURFPointsGrid(grayImage);
            else
                points = detectSURFFeatures(grayImage, 'MetricThreshold', 800);
            end
        end
        
        %------------------------------------------------------------------
        function points = createSURFPointsGrid(this, grayImage)            
            
            startIdx = round(this.GridStep/2);
            stopIdx  = fliplr(size(grayImage));                    
                                  
            rangeX = startIdx(1):this.GridStep(1):stopIdx(1);
            rangeY = startIdx(2):this.GridStep(2):stopIdx(2);
            
            if isempty(rangeX) || isempty(rangeY)
                
                warning(message('vision:bagOfFeatures:noGridPoints'));
                points = SURFPoints(zeros(0,2));
            else
                
                [X, Y] = meshgrid(rangeX, rangeY);
                
                % SURFPoint scale values, specified as multiples of 1.6                
                scales = single(1.6 * this.BlockWidth/32);
                                              
                % create SURFPoints object for the grid
                locations = repmat([X(:) Y(:)], numel(scales),1);
                scales    = repmat(scales, numel(X),1);                
                
                points = SURFPoints(locations, 'Scale', scales(:));
                                
            end

        end
        
        %------------------------------------------------------------------
        % Return the image descriptors and their scores.        
        %
        % When the PointSelection method is 'Grid', the scores are computed
        % using the variance of the SURF descriptors. For more details,
        % refer to figure 3 in:
        %
        %   Herbert Bay, Andreas Ess, Tinne Tuytelaars, Luc Van Gool "SURF:
        %   Speeded Up Robust Features", Computer Vision and Image
        %   Understanding (CVIU), Vol. 110, No. 3, pp. 346-359, 2008
        %
        %------------------------------------------------------------------
        function [descriptors, scores, locations] = extractDescriptorsFromImage(this, image)
            
            if ismatrix(image) % convert color images to grayscale
                grayImage = image;
            else
                grayImage = rgb2gray(image);
            end
            
            points = this.determineExtractionPoints(grayImage);
            
            % Use upright SURF features.
            descriptors = extractFeatures(grayImage, points, 'Upright', this.Upright);                      
            
            if strcmpi(this.PointSelection,'Grid')                
                scores = var(descriptors,[],2);
            else
                scores = points.Metric;
            end
            
            locations = points.Location;
        end
        
        %------------------------------------------------------------------
        function this = setParams(this, params)
            
            this.VocabularySize    = params.VocabularySize;
            this.StrongestFeatures = params.StrongestFeatures;
            this.GridStep          = params.GridStep;
            this.BlockWidth        = params.BlockWidth;
            this.PointSelection    = params.PointSelection;
            this.Upright           = params.Upright;
            
            this.UsingCustomExtractor      = params.UsingCustomExtractor;                                                     
            this.CustomExtractor           = params.CustomExtractor;      
            this.ExtractorOutputsLocations = params.ExtractorOutputsLocations;
            
            if this.UsingCustomExtractor   
                % Use the custom extractor.
                this.CustomFeatureLength  = params.CustomFeatureLength;                                                                              
                this.Extractor = @(img)this.invokeCustomExtractor(img, params.CustomExtractor);     
            else
                % Use the default SURF extractor
                this.Extractor = @(img)extractDescriptorsFromImage(this, img);                                         
            end
            
            % Vocabulary is present when loading from MAT file.
            if isfield(params, 'Vocabulary')
                this.Vocabulary = params.Vocabulary;   
            end
        end        
        
        %------------------------------------------------------------------
        % Invoke the custom extractor.
        %------------------------------------------------------------------
        function [features, featureMetrics, varargout] = invokeCustomExtractor(this, img, extractor)
            
            [features, featureMetrics, varargout{1:nargout-2}] = extractor(img);
            
            featureLength = bagOfFeatures.checkCustomExtractorSizes(features, featureMetrics, varargout{:});
            
            % Error if the feature length changes from the one we have
            % cached.
            if this.CustomFeatureLength ~= featureLength
                error(message('vision:bagOfFeatures:customInvalidFeatureLength', ...
                    this.CustomFeatureLength, featureLength));
            end
            
            % cast custom features and metric to single for clustering.
            features       = single(features);
            featureMetrics = single(featureMetrics);
            
            if nargout > 2
                % cast location data to single
                varargout{1} = single(varargout{1});
            end
        end        
                       
        %------------------------------------------------------------------
        function printPointSelectionInfo(this, printer)
            
            if this.UsingCustomExtractor                                   
                str = func2str(this.CustomExtractor);      
                if exist(str,'file')
                    % create hyperlink when extractor can be opened in
                    % editor. Otherwise print as normal string.
                    str = printer.makeHyperlink(str,sprintf('edit %s',str));
                end
                printer.printMessage('vision:bagOfFeatures:customExtractionInfo', str);
            else
                printer.printMessage('vision:bagOfFeatures:extractionInfo1', this.PointSelection);
                printer.printMessage('vision:bagOfFeatures:extractionInfo2');
                
                if strcmpi(this.PointSelection,'Grid')
                    gs = deblank(sprintf('%d ', this.GridStep));
                    bw = deblank(sprintf('%d ', this.BlockWidth));
                    
                    printer.printMessage('vision:bagOfFeatures:gridInfo',gs,bw);
                else
                    cmd = 'helpview(fullfile(docroot,''toolbox'',''vision'',''vision.map''),''bagOfFeaturesSURFInfo'')';
                    cmdstr = printer.makeHyperlink('detectSURFFeatures',cmd);
                    
                    printer.printMessage('vision:bagOfFeatures:detectorInfo',...
                        cmdstr);
                end                           
            end
            printer.linebreak;
        end               
        
        %------------------------------------------------------------------
        function printFeatureBalancingMessage(this, printer, numFeatures, setIdx, numToKeep)
            % For the Grid method, print balancing message when the number
            % of features across the image sets different. Always print the
            % message for the Detector method.
            
            setsHaveSameNumFeatures = all(numFeatures(1) == numFeatures);
            
            if ~(strcmpi(this.PointSelection, 'Grid') && setsHaveSameNumFeatures)
                printer.printMessage('vision:bagOfFeatures:balanceNumFeatures');
                printer.printMessage('vision:bagOfFeatures:minNumFeatures',...
                    setIdx, numToKeep);
                printer.printMessage('vision:bagOfFeatures:minNumFeaturesInOthers',...
                    numToKeep).linebreak;
            end
                        
        end
               
        %------------------------------------------------------------------
        function opts = getSearchOptions(this)
            opts.checks    = int32(32);
            opts.eps       = single(0);
            opts.grainSize = int32(10000);
            opts.tbbQueryThreshold = uint32(this.VocabularySize);
        end
        
    end
    
    %======================================================================
    % Custom display methods
    %======================================================================
    methods (Access = protected)
        function propgrp = getPropertyGroups(this)
            % Properties that are not relevant for custom feature
            % extraction are not displayed.
            
            propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(this);
                                
            if this.UsingCustomExtractor                                                           
                % Hide grid and detector properties for custom extractor   
                propgrp.PropertyList = rmfield(propgrp.PropertyList, ...
                    {'PointSelection','GridStep','BlockWidth','Upright'});                
            else
                % Hide custom extractor 
                propgrp.PropertyList = rmfield(propgrp.PropertyList, ...
                    {'CustomExtractor'});
                
                if strcmpi(this.PointSelection,'Detector')
                    % Hide grid related properties
                    propgrp.PropertyList = rmfield(propgrp.PropertyList, ...
                    {'GridStep','BlockWidth'});
                end                
            end
        end        
    end
    
    %======================================================================
    methods (Hidden, Static, Access = protected)
        
        %------------------------------------------------------------------
        % Returns default object settings
        %------------------------------------------------------------------
        function d = getDefaultSettings

            d.VocabularySize            = 500;
            d.StrongestFeatures         = 0.8;
            d.PointSelection            = 'Grid';
            d.GridStep                  = [8 8];
            d.BlockWidth                = [32 64 96 128];
            d.Verbose                   = true;
            d.UseParallel               = vision.internal.useParallelPreference();           
            d.CustomExtractor           = @(x)[]; % no-op function
            d.UsingCustomExtractor      = false;
            d.CustomFeatureLength       = 0;
            d.Upright                   = true;
            d.ExtractorOutputsLocations = true;
            
        end
        
        %------------------------------------------------------------------
        function checkImageSet(imgSet, name)            
            varName = 'imds'; 
            
            validateattributes(imgSet,...
                {'imageSet', 'matlab.io.datastore.ImageDatastore'}, ...
                {'nonempty'},...
                name, varName);
            
            if isa(imgSet, 'imageSet') && isanyempty(imgSet)
               error(message('vision:dims:expectedNonemptyElements', varName));
            end                          
        end
        
        %------------------------------------------------------------------
        function checkVocabularySize(vSize)
            
            validateattributes(vSize,{'double','single','uint32', ...
                'uint16', 'uint8'},{'scalar','nonempty','integer','>=',2},...
                mfilename, 'VocabularySize');
           
        end
        
        %------------------------------------------------------------------
        function checkStrongestFeatures(strongestFeatures)
            
            validateattributes(strongestFeatures,{'numeric'}, ...
                {'scalar','nonempty','real','positive','<=', 1}, ...
                mfilename, 'StrongestFeatures');
            
        end
        
        %------------------------------------------------------------------
        function checkGridStep(gridStep)
            
            validateattributes(gridStep,{'double','single','uint32', ...
                'uint16', 'uint8'},{'vector','nonempty','integer','positive'},...
                mfilename, 'GridStep');
            
            if numel(gridStep) > 2
                error(message('vision:dims:twoElementVector','GridStep'));
            end
                   
        end
        
        %------------------------------------------------------------------
        function checkBlockWidth(BlockWidth)
            
            validateattributes(BlockWidth,{'double','single','uint32', ...
                'uint16', 'uint8'},{'vector','nonempty','finite','>=', 32, 'real'},...
                mfilename, 'BlockWidth');

        end
        
        %------------------------------------------------------------------
        function supportsLocation = checkCustomExtractor(func)
            
            validateattributes(func, {'function_handle'}, {'scalar'}, ...
                mfilename, 'CustomExtractor');
                                                            
            % get num args in/out. This errors out if func does not exist.
            numIn  = nargin(func);
            numOut = nargout(func);
                                     
            % functions may have varargin/out (i.e. anonymous functions)
            isVarargin  = (numIn  < 0);
            isVarargout = (numOut < 0);            
            
            numIn  = abs(numIn);
            numOut = abs(numOut);
            
            % validate this API: [features, metric, location] = func(I)                        
            if ~isVarargin && numIn ~= 1                                     
                error(message('vision:bagOfFeatures:customInvalidNargin'));               
            end
            
            if ~isVarargout && numOut < 2
                error(message('vision:bagOfFeatures:customInvalidNargout'));
            end

            % check if custom extractor can output location data.                                    
            if isVarargout || numOut == 3  
                supportsLocation = true;
            else
                supportsLocation = false;
            end
        end        
        
        %------------------------------------------------------------------
        function checkCustomExtractorOnLoad(func)
            % check if the function is available on load. otherwise
            % issue a warning.
            try                 
                [~] = nargin(func); % errors if function not found
            catch
                str = func2str(func);
                warning(message('vision:bagOfFeatures:customExtractorMissingOnLoad',...
                    str,str));
            end
        end
        
        %------------------------------------------------------------------
        function [tf, ps] = checkAndAssignPointSelection(pointSelection)
            
            ps = validatestring(pointSelection,...
                bagOfFeatures.ValidPointSelectionOptions, mfilename, 'PointSelection');
            
            tf = true;
        end                
        
        %------------------------------------------------------------------
        function featureLength = validateCustomExtractor(imgSet, extractor) 
            
            % try the custom extractor on 1 image.
            if bagOfFeatures.isImageSet(imgSet)
                img = imgSet(1).readimage(1);
            else
                img = imgSet.readimage(1);
            end
            
            [features, metrics] = extractor(img);
   
            featureLength = bagOfFeatures.checkCustomExtractorSizes(features, metrics);
            
            % errors thrown by the extractor are reported directly to the
            % command window with a full stack to simplify debugging.
        end
        
        %------------------------------------------------------------------
        function tf = isImageSet(obj)
            tf = isa(obj,'imageSet');
        end      
        
        %------------------------------------------------------------------
        function n = getNumCategories(imgSetOrDs)
            n = max(1, height(countEachLabel(imgSetOrDs)));            
        end           
        
        %------------------------------------------------------------------
        function cats = getCategoryStrings(imgSetOrDs)
            
            tbl = countEachLabel(imgSetOrDs);
            if isempty(tbl)
                cats = cellstr('');
            else
                cats = tbl{:,1};
                
                cats = categorical(cats);
                
                cats = cellstr(cats);
            end
            
        end
        %------------------------------------------------------------------
        function featureLength = checkCustomExtractorSizes(features, featureMetrics, featureLocations)
            % Quick check on sizes and type of features and metric. Also
            % make sure the number of features is consistent with the
            % number of metrics.
            
            if ~ismatrix(features)
                error(message('vision:bagOfFeatures:customInvalidFeatures'));
            end
            
            if ~iscolumn(featureMetrics)
                error(message('vision:bagOfFeatures:customInvalidMetrics'));
            end
            
            % features and metrics must be real floats (non-sparse).
            if ~isreal(features) || isinteger(features) || issparse(features)
                error(message('vision:bagOfFeatures:customFeaturesMustBeRealFloats'));
            end
            
            if ~isreal(featureMetrics) || isinteger(featureMetrics) || issparse(featureMetrics)
                error(message('vision:bagOfFeatures:customMetricsMustBeRealFloats'));
            end
            
            [numFeatures, featureLength] = size(features);
            numMetrics = numel(featureMetrics);
            
            if featureLength == 0
                error(message('vision:bagOfFeatures:customZeroFeatureLength'));
            end
            
            % number of features and number of metrics must match
            if numFeatures ~= numMetrics
                error(message('vision:bagOfFeatures:customNumFeaturesNotEqNumMetrics'));
            end
            
            if nargin > 2
                if ~ismatrix(featureLocations)
                    error(message('vision:bagOfFeatures:customInvalidLocations'));
                end
                
                [numLocations, N] = size(featureLocations);
                if N ~= 2
                    error(message('vision:bagOfFeatures:customInvalidLocations'));
                end
                
                if ~isnumeric(featureLocations) || ~isreal(featureLocations) || issparse(featureLocations)
                    error(message('vision:bagOfFeatures:customLocationsMustBeRealNumeric'));
                end
                
                % cross validate number of features and locations
                if numFeatures ~= numLocations
                    error(message('vision:bagOfFeatures:customNumFeaturesNotEqNumLocations'));
                end
            end                       
        end
        
        %------------------------------------------------------------------
        function [imgSets, params] = parseInputs(varargin)                     
            
            d = bagOfFeatures.getDefaultSettings;
            
            parser = inputParser;
            parser.addRequired('imds', @(x)bagOfFeatures.checkImageSet(x,mfilename));
            
            parser.addParameter('VocabularySize',    d.VocabularySize,    @bagOfFeatures.checkVocabularySize);
            parser.addParameter('StrongestFeatures', d.StrongestFeatures, @bagOfFeatures.checkStrongestFeatures);
            parser.addParameter('PointSelection',    d.PointSelection,    @bagOfFeatures.checkAndAssignPointSelection);
            parser.addParameter('GridStep',          d.GridStep,          @bagOfFeatures.checkGridStep);
            parser.addParameter('BlockWidth',        d.BlockWidth,        @bagOfFeatures.checkBlockWidth);
            parser.addParameter('Verbose',           d.Verbose,           @(x)vision.internal.inputValidation.validateLogical(x,'Verbose'));                        
            parser.addParameter('UseParallel',       vision.internal.useParallelPreference());
            parser.addParameter('CustomExtractor',   d.CustomExtractor);
            parser.addParameter('Upright',           d.Upright,           @(x)vision.internal.inputValidation.validateLogical(x,'Upright'));
            
            % Parse input
            parser.parse(varargin{:});
                                    
            if bagOfFeatures.isImageSet(parser.Results.imds)                
                imgSets = parser.Results.imds(:); % vectorize array of imageSet objects
            else
                imgSets = parser.Results.imds;
            end
            
            useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);
            
            % Cache whether extractor outputs locations             
            params.ExtractorOutputsLocations = bagOfFeatures.checkCustomExtractor(parser.Results.CustomExtractor);
            
            % Set property values to the correct type and format.
            params.VocabularySize    = double(parser.Results.VocabularySize);
            params.StrongestFeatures = double(parser.Results.StrongestFeatures);
            params.GridStep          = double(parser.Results.GridStep(:)');
            params.BlockWidth        = double(parser.Results.BlockWidth(:)');
            params.Verbose           = logical(parser.Results.Verbose);
            params.UseParallel       = logical(useParallel);
            params.CustomExtractor   = parser.Results.CustomExtractor;
            params.Upright           = logical(parser.Results.Upright);
                                                               
            wasSpecified = @(name)(~any(strcmp(parser.UsingDefaults,name)));
            
            if wasSpecified('CustomExtractor')
                params.UsingCustomExtractor = true;
                
                featureLength = bagOfFeatures.validateCustomExtractor(imgSets,params.CustomExtractor);
                                                                                                               
                % Cache the feature length for size checks while invoking
                % the custom extractor later on.
                params.CustomFeatureLength = featureLength;                                
            else
                params.UsingCustomExtractor = false;
            end                                                
            
            wasPointSelectionSpecified = wasSpecified('PointSelection');
            wasGridStepSpecified       = wasSpecified('GridStep');
            wasBlockWidthSpecified     = wasSpecified('BlockWidth');                        
            wasUprightSpecified        = wasSpecified('Upright');
            
            if params.UsingCustomExtractor
                if wasPointSelectionSpecified || wasGridStepSpecified ...
                        || wasBlockWidthSpecified || wasUprightSpecified
                    warning(message('vision:bagOfFeatures:customInvalidParamCombo'));
                end
            end
            
            % Scalar expand grid step
            if isscalar(params.GridStep)
                params.GridStep = [params.GridStep, params.GridStep];
            end
            
            % Handle partial strings
            [~, params.PointSelection] = ...
                bagOfFeatures.checkAndAssignPointSelection(parser.Results.PointSelection);
            
            % Warn about ignored options
            if strcmp(params.PointSelection, 'Detector')                
                if wasGridStepSpecified || wasBlockWidthSpecified
                   warning(message('vision:bagOfFeatures:paramsIgnored'));
                end                
            end
        end
        
        %------------------------------------------------------------------
        function validateEncodeInput(in)      
            validateattributes(in, ...
                {'numeric','imageSet','matlab.io.datastore.ImageDatastore'},...
                {},'encode');
            
            if isnumeric(in)
                if ~isempty(in) % allow empty inputs
                    vision.internal.inputValidation.validateImage(in,'I');
                end            
            end
        end
        
        %------------------------------------------------------------------
        function params = parseEncodeInputs(varargin)            
                     
            defaults = bagOfFeatures.getDefaultSettings;
            
            parser = inputParser;
            parser.addRequired('imds');
            parser.addParameter('Normalization', 'L2');
            parser.addParameter('Verbose', defaults.Verbose);
            parser.addParameter('UseParallel', defaults.UseParallel);
            parser.addParameter('SparseOutput', false, @(x)vision.internal.inputValidation.validateLogical(x,'SparseOutput'));            
            
            parser.parse(varargin{:});
            
            bagOfFeatures.validateEncodeInput(parser.Results.imds);
            
            % validate params
            str = validatestring(parser.Results.Normalization,{'none','L2'},mfilename);
            
            vision.internal.inputValidation.validateLogical(parser.Results.Verbose, 'Verbose');                      
                        
            useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);                     
            
            % assign user data
            params.Normalization = str;
            params.Verbose       = logical(parser.Results.Verbose);
            params.UseParallel   = logical(useParallel);
            params.SparseOutput  = logical(parser.Results.SparseOutput);
            
            % warn about ignored options
            if isnumeric(parser.Results.imds)
                wasVerboseSpecified     = ~any(strcmp(parser.UsingDefaults,'Verbose'));
                wasUseParallelSpecified = ~any(strcmp(parser.UsingDefaults,'UseParallel'));
                
                if wasVerboseSpecified || wasUseParallelSpecified
                    warning(message('vision:imageCategoryClassifier:ignoreVerboseAndParallel'));
                end
            end
            
        end
        
        %------------------------------------------------------------------       
        function params = parseCreateVocabularyInputs(varargin)
            
            defaults = bagOfFeatures.getDefaultSettings;
            
            parser = inputParser;            
            
            parser.addParameter('Verbose',     defaults.Verbose);
            parser.addParameter('UseParallel', defaults.UseParallel);
            
            parser.parse(varargin{:});
            
            vision.internal.inputValidation.validateLogical(parser.Results.Verbose, 'Verbose');
            
            useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);     
            
            params.Verbose     = logical(parser.Results.Verbose);
            params.UseParallel = useParallel;            
        end
             
        %------------------------------------------------------------------
        function printImageSetDescription(printer,imgSets)
            cats = bagOfFeatures.getCategoryStrings(imgSets);
            
            if numel(cats) == 1 && isempty(cats{1})
                % Do not print if has single undefined category
                printer.linebreak;
                return;
            end
            
            for i = 1:numel(cats)
                printer.printMessage('vision:bagOfFeatures:imageSetDescription',i,cats{i});                
            end
            
        end
        
        %------------------------------------------------------------------
        function words = allocateVisualWords(n)
            if n > 0
                words(n,1) = vision.internal.visualWords();
            else
                words = vision.internal.visualWords.empty(0,1);
            end
        end
        
        %------------------------------------------------------------------
        function featureVector = allocateFeatureVector(m,n,isSparse)
            
            % Determine type for allocation
            if isSparse
                prototype = sparse(0);
            else
                prototype = single(0);
            end
            
            featureVector = zeros(m,n,'like',prototype);
        end
        
    end % end of Static methods
    %======================================================================
    methods (Static)      
        function createExtractorTemplate()
                       
            % Read in template code. Use full path to avoid local versions
            % of the file from being read.
            example = fullfile(toolboxdir('vision'),...
                'visionutilities','exampleBagOfFeaturesExtractor.m');
            fid = fopen(example);
            contents = fread(fid,'*char');
            fclose(fid);
            
            % Open template code in an untitled file in the editor           
            editorDoc = matlab.desktop.editor.newDocument(contents);
                       
            functionName = editorDoc.Filename;
            
            % Change the function name to the name of the untitled file
            contents = regexprep(editorDoc.Text,...
                'exampleBagOfFeaturesExtractor', functionName,'once');
            
            editorDoc.Text = contents;                            
            editorDoc.smartIndentContents;    
            editorDoc.goToLine(1);
        end
    end
    %======================================================================
    methods (Hidden, Static)
                
        % -----------------------------------------------------------------
        function this = loadobj(s)
            % reconstruct bagOfFeatures                       
            this = bagOfFeatures();    
            
            if all(isfield(s,{'CustomExtractor', 'Upright', 'ExtractorOutputsLocations'})) % added in R2015a                                                                 
                
                bagOfFeatures.checkCustomExtractorOnLoad(s.CustomExtractor);                               
                
            else
                % set to defaults if loading old version of object
                
                defaults = bagOfFeatures.getDefaultSettings();            
                
                s.UsingCustomExtractor      = defaults.UsingCustomExtractor;
                s.CustomExtractor           = defaults.CustomExtractor;                
                s.CustomFeatureLength       = defaults.CustomFeatureLength;    
                s.Upright                   = defaults.Upright;
                s.ExtractorOutputsLocations = defaults.ExtractorOutputsLocations;
            end
                                    
            
            
            % assign saved property values
            this = this.setParams(s); 
             
            if ~isempty(this.Vocabulary)
                % partially initialized versions of this object are saved
                % when UseParallel is enabled. By-pass vocabulary tree
                % creation in this situation.
                
                if isfield(s,{'KDTreeIndexState'}) % added in R2015b
                    % set the saved state prior to indexing to recreate the
                    % same KD-Tree.                    
                    sprev = rng(s.KDTreeIndexState);
                    
                    this.initializeVocabularySearchTree();
                    
                    rng(sprev); % restore current state
                else
                    % Loading object prior to   . Vocabulary must be
                    % transposed into row-major format.
                    this.Vocabulary = this.Vocabulary';
                this.initializeVocabularySearchTree();
            end
                                
            end
        end                           
    end
end
