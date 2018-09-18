%imageCategoryClassifier Predict image category.
%   imageCategoryClassifier is returned by trainImageCategoryClassifier 
%   function. It contains an SVM classifier trained to recognize an image
%   category. Use of the imageCategoryClassifier requires that you have 
%   the Statistics and Machine Learning Toolbox.
%
%   imageCategoryClassifier methods:
%      predict  - Predict image category
%      evaluate - Returns prediction results and confusion matrix for input image sets
%
%   imageCategoryClassifier properties:
%      Labels        - A cell array of category labels
%      NumCategories - Number of trained categories
%
%   Notes:
%   ------
%   - imageCategoryClassifier supports parallel computing using
%     multiple MATLAB workers. Enable parallel computing using the
%     <a href="matlab:preferences('Computer Vision System Toolbox')">preferences dialog</a>.
%
%   Example
%   -------
%   % Load two image categories
%   setDir = fullfile(toolboxdir('vision'),'visiondata','imageSets');
%   imds = imageDatastore(setDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
%
%   % Split data into a training and test set. Pick 30% of images from
%   % each label for training and the remainder (70%) for testing.
%   [trainingSet, testSet] = splitEachLabel(imds, 0.3, 'randomize'); 
%
%   % Create bag of visual words
%   bag = bagOfFeatures(trainingSet);
%
%   % Train a classifier
%   categoryClassifier = trainImageCategoryClassifier(trainingSet, bag);
% 
%   % Evaluate the classifier on test images and display the confusion matrix
%   confMatrix = evaluate(categoryClassifier, testSet)
%
%   % Average accuracy
%   mean(diag(confMatrix))
%
%   % You can apply the newly trained classifier to categorize new images
%   img = imread(fullfile(setDir, 'cups', 'bigMug.jpg'));
%   [labelIdx, scores] = predict(categoryClassifier, img);
%   % Display the string label
%   categoryClassifier.Labels(labelIdx)
% 
%   See also imageDatastore, bagOfFeatures, trainImageCategoryClassifier,
%      fitcecoc

% Copyright 2014 MathWorks, Inc.

% References:
%    Gabriella Csurka, Christopher R. Dance, Lixin Fan, Jutta Willamowski,
%    Cedric Bray "Visual Categorization with Bag of Keypoints", 
%    Workshop on Statistical Learning in Computer Vision, ECCV, 2004.

classdef imageCategoryClassifier < vision.internal.EnforceScalarHandle

    properties
        % A cell array of category labels
        Labels;
    end
    
    properties (GetAccess = public, SetAccess = private)        
        % Number of trained categories
        NumCategories;
    end
    
    properties (Access = private)
        % Bag of features object used during the training
        Bag;
        % Multi-class classifier produced using fitcecoc function
        Classifier
        % Options passed into fitcecoc
        LearnerOptions
    end
    
    %-----------------------------------------------------------------------
    methods       

        %------------------------------------------------------------------
        function [label, score] = predict(this, img, varargin)
            %predict Predict image category
            %
            %  [labelIdx, score] = predict(categoryClassifier, I) returns
            %  the predicted label index and score. labelIdx corresponds to
            %  the index of an image set used to train the bag of features.
            %  The 1-by-N score vector provides negated average binary loss
            %  per class of an SVM multi-class classifier that uses the
            %  error correcting output codes (ECOC) approach. N is a number
            %  of classes. labelIdx corresponds to the class with lowest
            %  average binary loss.
            %
            %  [labelIdx, score] = predict(categoryClassifier, imds)
            %  returns M-by-1 predicted labelIdx indices and M-by-N scores
            %  for M images in the ImageDatastore object, imds. N is
            %  number of classes.
            %
            %  [...] = predict(...) specifies additional name-value pairs
            %  described below:          
            %
            %  'Verbose'      Set true to display progress information.
            %                  
            %                 Default: true
            %
            %  Example
            %  -------
            %  % Load two image categories            
            %   setDir = fullfile(toolboxdir('vision'),'visiondata','imageSets');
            %   imds = imageDatastore(setDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
            %
            %   % Split data into a training and test data. Pick 30% of images from
            %   % each label for training data and the remainder (70%) for testing.
            %   [trainingSet, testSet] = splitEachLabel(imds, 0.3, 'randomize');
            %      
            %  % Create bag of visual words
            %  bag = bagOfFeatures(trainingSet);
            %
            %  % Train a classifier
            %  categoryClassifier = trainImageCategoryClassifier(trainingSet, bag);
            %
            %  % Predict category label for one of the images in testDs
            %  img = readimage(testSet, 1);
            %  [labelIdx, score] = predict(categoryClassifier, img);
            %  categoryClassifier.Labels(labelIdx)
                        
            vision.internal.requiresStatisticsToolbox(mfilename);
            isImageDs  = isa(img, 'matlab.io.datastore.ImageDatastore');
            isImageSet = isa(img, 'imageSet');
            
            params = imageCategoryClassifier.parseCommonParameters(...
                isImageSet || isImageDs, varargin{:}); 
            
            if isImageSet || isImageDs
                printer = vision.internal.MessagePrinter.configure(params.Verbose);
                
                this.printPredictHeader(printer); 
                
                numImages = numel([img.Files]);                
                 
                if isImageSet
                    numImgSets = numel(img);                                       
                    
                    % Display image set information
                    printer.printMessage('vision:imageCategoryClassifier:predictImageSets', numImgSets);
                    
                    this.printCategories(printer, numImgSets, ...
                        'vision:imageCategoryClassifier:imageSetDescription',...
                        {img.Description});
                    
                   [labelClass, scoreClass] = getPredictionOutputClasses(this, img(1));
              
                    label = zeros(numImages, 1, labelClass);
                    score = zeros(numImages, this.NumCategories, scoreClass);
                    outIdx = 1;
                    for i=1:numImgSets
                        imgSet = img(i);
                        
                        count = imgSet.Count;
                        
                        printer.printMessageNoReturn('vision:imageCategoryClassifier:predictStart',count,i);
                        
                        indices = outIdx:outIdx+count-1;
                        
                        [label(indices), score(indices, :)] = ...
                            this.predictScalarImageSet(imgSet, params.UseParallel);
                        
                        outIdx = outIdx+count;
                        
                        printer.printMessage('vision:imageCategoryClassifier:predictDone');
                    end
                                        
                else % image datastore
                     
                    printer.printMessageNoReturn('vision:imageCategoryClassifier:predictStartDS',numImages);
                    
                    [label, score] = this.predictScalarImageSet(img, params.UseParallel);
                    
                    printer.printMessage('vision:imageCategoryClassifier:predictDone');       
                    
                end
                printer.printMessage('vision:imageCategoryClassifier:predictFinished').linebreak;
                
            else
                vision.internal.inputValidation.validateImage(img,'I');
                [label, score] = this.predictImage(img);
            end            
            
        end % end of predict

        %------------------------------------------------------------------
        function [confMat, knownLabel, predictedLabel, score] = evaluate(this, testSets, varargin)
            %evaluate Evaluate the classifier on a collection of images
            %  confMat = evaluate(classifier, imds) returns a normalized 
            %  confusion matrix, confMat. Row indices of confMat correspond 
            %  to known labels, while columns correspond to the predicted
            %  labels. classifier is an imageCategoryClassifier returned
            %  by trainImageCategoryClassifier. imds is a ImageDatastore
            %  object.
            %
            %  [confMat, knownLabelIdx, predictedLabelIdx, score] =
            %  evaluate(classifier, imds) additionally returns
            %  knownLabelIdx, predictedLabelIdx, and M-by-N score. M is a
            %  total number of images in imds and N is the number of image
            %  categories. Each predictedLabelIdx index corresponds to the
            %  class with largest value in score output.
            %
            %  [...] = evaluate(..., Name, Value ) specifies additional
            %  name-value pairs described below:         
            %
            %  'Verbose'      Set true to display progress information.
            %                  
            %                 Default: true
            %
            %   Example
            %   -------
            %   setDir = fullfile(toolboxdir('vision'),'visiondata','imageSets');
            %   imds = imageDatastore(setDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
            %
            %   % Split data into a training and test data. Pick 30% of images from
            %   % each label for training and the remainder (70%) for testing.
            %   [trainingSet, testSet] = splitEachLabel(imds, 0.3, 'randomize');
            %
            %   % Create bag of visual words
            %   bag = bagOfFeatures(trainingSet);
            %
            %   % Train a classifier
            %   categoryClassifier = trainImageCategoryClassifier(trainingSet, bag);
            % 
            %   % Evaluate the classifier on test images and display the confusion matrix
            %   confMatrix = evaluate(categoryClassifier, testSet)
            %
            %   % Average accuracy
            %   mean(diag(confMatrix))            
            
            vision.internal.requiresStatisticsToolbox(mfilename);
            
            varName = 'imds';
            
            validateattributes(testSets,...
                {'imageSet', 'matlab.io.datastore.ImageDatastore'}, ...
                {'nonempty','vector'}, mfilename, varName);
                      
            isImageSet = isa(testSets, 'imageSet'); 
            
            params  = imageCategoryClassifier.parseCommonParameters(true, varargin{:});
            
            printer = vision.internal.MessagePrinter.configure(params.Verbose);
            
            this.printEvaluateHeader(printer);
            
            numImages = numel([testSets.Files]);
             
            if isImageSet
                % Check num categories against testSets
                if imageCategoryClassifier.getNumCategories(testSets) ~= this.NumCategories
                    error(message('vision:imageCategoryClassifier:testSetsAndClassifierMustBeCompatible'));
                end
                
                if isanyempty(testSets)
                    error(message('vision:dims:expectedNonemptyElements', varName));
                end
            
                [labelClass, scoreClass] = getPredictionOutputClasses(this, testSets(1));
                                               
                % preallocate
                knownLabel     = zeros(numImages, 1, labelClass);
                predictedLabel = zeros(numImages, 1, labelClass);
                score          = zeros(numImages, this.NumCategories, scoreClass);
                
                testIndex = 1;
                for categoryIndex = 1:this.NumCategories
                    
                    imageSet = testSets(categoryIndex); % process each image set
                    
                    printer.printMessageNoReturn('vision:imageCategoryClassifier:evalCategory',imageSet.Count,categoryIndex);
                    
                    [predicted, categoryScore] = this.predict(imageSet, ...
                        'UseParallel', params.UseParallel,'Verbose',false);
                    
                    actual = repmat(categoryIndex, imageSet.Count, 1);
                    
                    fillIdx = testIndex:testIndex+imageSet.Count-1;
                    
                    knownLabel(fillIdx, :)     = actual;
                    predictedLabel(fillIdx, :) = predicted;
                    score(fillIdx, :)          = categoryScore;
                    
                    testIndex = testIndex + imageSet.Count;
                    
                    printer.printMessage('vision:imageCategoryClassifier:evalCategoryDone');
                end
            else
                % image datastore
                % Check num categories against testSets
                if imageCategoryClassifier.getNumCategories(testSets) ~= this.NumCategories
                    error(message('vision:imageCategoryClassifier:testSetsAndClassifierMustBeCompatibleDS'));
                end
                
                printer.printMessageNoReturn('vision:imageCategoryClassifier:evalCategoryDS',numImages);
                
                [predictedLabel, score] = this.predict(testSets, ...
                    'UseParallel', params.UseParallel,'Verbose',false);
                
                knownLabel = cast(categorical(testSets.Labels), 'like', predictedLabel);
                
                printer.printMessage('vision:imageCategoryClassifier:evalCategoryDone');
            end
            
            printer.linebreak;
            printer.printMessage('vision:imageCategoryClassifier:evalFinished').linebreak;
            printer.printMessage('vision:imageCategoryClassifier:evalDispConfMat').linebreak;
            
            % Display the results as a confusion matrix
            confMat = confusionmat(knownLabel, predictedLabel);
            confMat = bsxfun(@rdivide,confMat,sum(confMat,2)); % sum rows to get totals for actual labels
            
            this.printConfusionMatrix(printer, confMat);
          
            printer.printMessage('vision:imageCategoryClassifier:evalAvgAccuracy',...
                sprintf('%.2f',mean(diag(confMat)))).linebreak;                                                                    
        end   
        
        % -----------------------------------------------------------------
        function set.Labels(this, labels)
            
            validateattributes(labels, {'cell'},{'vector'},...
                mfilename,'Labels');
                                    
            if ~iscellstr(labels)
                error(message('vision:imageCategoryClassifier:descriptionMustBeAllStrings'));
            end                        
            
            if this.NumCategories ~= numel(labels) %#ok<MCSUP>
                error(message('vision:imageCategoryClassifier:numCategoriesMustMatch'));
            end
            
            this.Labels = labels;
        end
        
        %------------------------------------------------------------------
        function s = saveobj(this)
            s.Labels         = this.Labels;
            s.NumCategories  = this.NumCategories;                                                  
            s.Classifier     = this.Classifier;                        
            s.LearnerOptions = this.LearnerOptions;
                     
            % Invoke customized saveobj for bagOfFeatures
            s.Bag = saveobj(this.Bag);                         
        end
             
    end % end public methods    
    
    %======================================================================
    methods (Hidden, Static)
 
        % -----------------------------------------------------------------
        function this = create(imgSet, bag, varargin)
            this = imageCategoryClassifier(imgSet, bag, varargin{:});
        end
        
        % -----------------------------------------------------------------
        function params = parseCommonParameters(isImageSet, varargin)
            
            % use parallel only if imds or imageSet and user has enabled
            % preference.
            shouldUseParallel = isImageSet && vision.internal.useParallelPreference();
            
            parser = inputParser();
            parser.addParameter('Verbose', true);
            parser.addParameter('UseParallel', shouldUseParallel);
            
            parser.parse(varargin{:});
            
            vision.internal.inputValidation.validateLogical(parser.Results.Verbose,'Verbose');
                        
            useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);                        
            
            params.Verbose     = logical(parser.Results.Verbose);
            params.UseParallel = logical(useParallel);
            
            
            % warn about ignored options
            if ~isImageSet
                wasVerboseSpecified     = ~any(strcmp(parser.UsingDefaults,'Verbose'));
                wasUseParallelSpecified = ~any(strcmp(parser.UsingDefaults,'UseParallel'));
                
                if wasVerboseSpecified || wasUseParallelSpecified
                    warning(message('vision:imageCategoryClassifier:ignoreVerboseAndParallel'));
                end
            end
        end
        
        %------------------------------------------------------------------
        function params = parseInputs(varargin)
            
            parser = inputParser();
            parser.addParameter('Verbose', true);
            parser.addParameter('SVMOptions', []);
            parser.addParameter('LearnerOptions', templateSVM(), @imageCategoryClassifier.checkTemplateSVM);
            parser.addParameter('UseParallel', vision.internal.useParallelPreference());
            
            parser.parse(varargin{:});
            
            vision.internal.inputValidation.validateLogical(parser.Results.Verbose,'Verbose');
            
            useParallel = vision.internal.inputValidation.validateUseParallel(parser.Results.UseParallel);
            
            params.Verbose        = logical(parser.Results.Verbose);
            params.SVMOptions     = parser.Results.SVMOptions;
            params.LearnerOptions = parser.Results.LearnerOptions;
            params.UseParallel    = logical(useParallel);
            
        end
        
        %------------------------------------------------------------------
        function tf = checkTemplateSVM(template)
            
            validateattributes(template, {'classreg.learning.FitTemplate'},...
                {'scalar'}, mfilename);
            
            if ~strcmp(template.Method, 'SVM')
               error(message('vision:imageCategoryClassifier:mustBeSVMTemplate')); 
            end
            
            tf = true;            
        end
        
        %------------------------------------------------------------------
        function this = loadobj(s)
            
            this = imageCategoryClassifier();     
            
            % Invoke customized loadobj for bagOfFeatures
            this.Bag = bagOfFeatures.loadobj(s.Bag);
            
            % Set remaining properties
            this.Labels         = s.Labels;
            this.NumCategories  = s.NumCategories;                                                                     
            this.LearnerOptions = s.LearnerOptions;
                        
            if isa(s.Classifier, 'ClassificationECOC')  
                % Before R2015a, the full model was saved. Use the compact
                % version now.                
                this.Classifier = compact(s.Classifier); % removes training vectors.
            else
                this.Classifier = s.Classifier;
            end
        end   
        
        %------------------------------------------------------------------
        function tf = isImageSet(in)
            tf = isa(in, 'imageSet');
        end
        
        %------------------------------------------------------------------
        function n = getNumCategories(imgSetOrDs)
            n = max(1, height(countEachLabel(imgSetOrDs)));            
        end 
    end
    
    %======================================================================
    methods (Access = protected)
       
        %------------------------------------------------------------------
        % Constructor
        function this = imageCategoryClassifier(imgSet, bag, varargin)
            if nargin ~= 0
                params = imageCategoryClassifier.parseInputs(varargin{:});
                
                varName = 'imds';
                
                validateattributes(bag, {'bagOfFeatures'}, {'nonempty'}, mfilename, 'bag');
                validateattributes(imgSet, {'imageSet', 'matlab.io.datastore.ImageDatastore'}, ...
                    {'nonempty','vector'}, mfilename, varName);
                
                if imageCategoryClassifier.isImageSet(imgSet)
                    if isanyempty(imgSet)
                        error(message('vision:dims:expectedNonemptyElements', varName));
                    end
                    this.NumCategories = numel(imgSet); 
                    this.setLabelsFromImageSetDescriptions(imgSet);
                    
                    if this.NumCategories < 2
                        error(message('vision:imageCategoryClassifier:atLeastTwoElementSet'));
                    end
                    
                else % image datastore
                                                        
                    undefined = isundefined(categorical(imgSet.Labels));
                    if isempty(imgSet.Labels) || any(undefined)
                        error(message('vision:imageCategoryClassifier:undefinedLabels'));
                    end                                   
                    
                    this.setNumCategoriesAndLabelsFromImageDs(imgSet);
                    
                    if this.NumCategories < 2
                        error(message('vision:imageCategoryClassifier:atLeastTwoUniqueLabels'));
                    end
                    
                end                               
                              
                this.LearnerOptions = params.LearnerOptions;                                
                
                this.Bag = bag;
                
                printer = vision.internal.MessagePrinter.configure(params.Verbose);
                
                this.printHeader(printer);
                
                % Train an error correcting output mode (ECOC) SVM classifier
                [fvectors, labels] = this.createFeatureVectors(imgSet, printer, params);
                this.trainEcocClassifier(fvectors, labels, params.UseParallel);
                
                this.printFooter(printer);
            end
        end % end of Constructor
                        
        %------------------------------------------------------------------
        function [fvectors, labels] = createFeatureVectors(this, imgSet, ...
                printer, params)
                                
            numImages = numel([imgSet.Files]);
            
            if imageCategoryClassifier.isImageSet(imgSet) % TODO refactor and move to internal
                % initialize outputs                
                fvectors  = zeros(numImages, this.Bag.VocabularySize);
                labels    = zeros(numImages, 1);
                
                % Note that the loop could be avoided since encode() can handle
                % an array of image sets, but then we wouldn't be able to print
                % out progress until the entire encoding process was finished.
                outIdx = 1;
                for cIdx=1:this.NumCategories
                    printer.printMessageNoReturn('vision:imageCategoryClassifier:encodingFeatures',cIdx);
                    count = imgSet(cIdx).Count;
                    
                    % Encode each category
                    fvectors(outIdx:outIdx+count-1,:) = this.Bag.encode(imgSet(cIdx), ...
                        'UseParallel', params.UseParallel,'Verbose',false);
                    labels(outIdx:outIdx+count-1,:) = cIdx;
                    outIdx = outIdx+count;
                    
                    printer.printMessage('vision:imageCategoryClassifier:encodingFeaturesDone');
                end
                
            else % image data store
                
                printer.printMessageNoReturn('vision:imageCategoryClassifier:encodingFeaturesDS',numImages);
                
                fvectors = this.Bag.encode(imgSet, 'UseParallel', params.UseParallel, 'Verbose', false);
                
                printer.printMessage('vision:imageCategoryClassifier:encodingFeaturesDone');
                
                % output labels as indices
                labels = double(categorical(imgSet.Labels));                
            end
            
            printer.linebreak;
        end % createSamples
        
        %------------------------------------------------------------------
        function trainEcocClassifier(this, fvectors, labels, useParallel)
                        
        opts = statset('UseParallel', useParallel);
            
            this.Classifier = fitcecoc(fvectors, labels, ...
                'Learners', this.LearnerOptions, ...
                'Coding',   'onevsall', ...
                'Prior',    'uniform', ...
                'Options',  opts);
            
            % Remove training data from classifier
            this.Classifier = compact(this.Classifier);
            
        end % trainClassifier   
        
        %------------------------------------------------------------------
        function setNumCategoriesAndLabelsFromImageDs(this, imgSet)
            
            labels        = categorical(imgSet.Labels);            
            numCategories = numel(categories(labels));
           
            % image datastore. Store labels as strings to preserve
            % behavior of string only labels. This may be enhanced in
            % the future to support other label types.
            labels = categories(labels);
            labels = reshape(labels,1,[]); % preserve row vector                                 
            
            this.NumCategories = numCategories;
            this.Labels = labels;
                
        end
        
        %------------------------------------------------------------------
        function setLabelsFromImageSetDescriptions(this, imgSet)
            % Set labels based on Description property of the image sets.
            % Use index value as label if an image set has an empty
            % Description.
                        
            labels = {imgSet(:).Description};
            
            empty = strcmpi(labels,'');
            
            indexAsLabel  = arrayfun(@(x)sprintf('%d',x),...
                1:this.NumCategories,'UniformOutput',false);
            
            labels(empty) = indexAsLabel(empty);            
            
            this.Labels = labels;
            
        end
         
        %------------------------------------------------------------------
        % predict for a single image set.
        function [label, score] = predictScalarImageSet(this, imgSet, useParallel)
            
            validateattributes(imgSet, ...
                {'imageSet', 'matlab.io.datastore.ImageDatastore'}, ...
                {'scalar'}, mfilename);
                       
            featureVectors = this.Bag.encode(imgSet, 'Verbose', false, ...
                'UseParallel', useParallel);
            
            % we are using negated average binary loss as a score
            opts = statset('UseParallel', useParallel);
            [label, score] = predict(this.Classifier, featureVectors,...
                'Options',  opts);
        end
        
        %------------------------------------------------------------------
        % predict for a single image
        function [label, score] = predictImage(this, img)
            
            featureVector = this.Bag.encode(img);
            
            % we are using average binary loss as a score
            [label, score] = predict(this.Classifier, featureVector);
            
        end % end of predict               
        
        %------------------------------------------------------------------
        function [labelClass, scoreClass] = getPredictionOutputClasses(this, imgSet)
            
            numImages = numel([imgSet.Files]);
            
            if numImages > 1
                % get the output class of labels and scores by calling
                % the classifier.
                [label, score] = predict(this, imgSet.readimage(1));
                labelClass = class(label);
                scoreClass = class(score);
            else
                labelClass = 'double';
                scoreClass = 'double';
            end
        end
    end
    
    %======================================================================
    % Verbose printing methods
    methods (Hidden, Access = protected)
        
        %------------------------------------------------------------------
        function printHeader(this, printer)
            printer.linebreak;
            printer.printMessage('vision:imageCategoryClassifier:startTrainingTitle', this.NumCategories);            
            printer.print('--------------------------------------------------------\n');            
            this.printCategories(printer, this.NumCategories, ...
                'vision:imageCategoryClassifier:categoryDescription', ...
                this.Labels);
        end
        
        %------------------------------------------------------------------
        function printEvaluateHeader(this, printer)            
            printer.linebreak;
            printer.printMessage('vision:imageCategoryClassifier:startEval',this.NumCategories);
            printer.print('-------------------------------------------------------\n\n');
            this.printCategories(printer,...
                this.NumCategories, ...
                'vision:imageCategoryClassifier:categoryDescription',...
                this.Labels);            
        end
        
        %------------------------------------------------------------------
        function printPredictHeader(this, printer)
            printer.linebreak;
            printer.printMessage('vision:imageCategoryClassifier:predictTitle');
            printer.print('---------------------------------------------------------------------\n\n');
            
            % Display the categories for which this classifier is trained
            this.printCategories(printer, this.NumCategories,...
                'vision:imageCategoryClassifier:categoryDescription', ...
                this.Labels);
        end
        
        %------------------------------------------------------------------
        function printCategories(~,printer,numSets, msgID, labels)
            for i = 1:numSets
                printer.printMessage(msgID, i, labels{i});                
            end
            printer.linebreak;
        end
        
        %------------------------------------------------------------------
        function printFooter(~, printer)
            cmd = printer.makeHyperlink('evaluate','help imageCategoryClassifier/evaluate');
            printer.printMessage('vision:imageCategoryClassifier:finishedTraining',cmd);
            printer.linebreak;
        end
        
        %------------------------------------------------------------------
        function printConfusionMatrix(this,printer,confMat)

            % exit early if not verbose
            if ~isa(printer,'vision.internal.VerbosePrinter')
                return
            end
            
            labels = this.Labels;
            
            % column widths for data elements
            minColWidth   = 4; % accommodates "0.00" output (%.2f)
            maxLabelWidth = max(cellfun(@(x)numel(x),labels))+1;                                                 
            
            % define format for row and column headings
            fmt = sprintf('%%-%ds   ', max(maxLabelWidth,numel('KNOWN')));
            
            % print column heading
            colHeading = sprintf([fmt '%s '],'KNOWN','|');
            sz = numel(colHeading);
            for j = 1:numel(labels)                
                colWidth = max(numel(labels{j}), minColWidth);
                format   = sprintf('%%-%ds   ', colWidth);
                colHeading = sprintf(['%s' format], colHeading, labels{j});                
            end
            
            printer.linebreak;
            
            % center PREDICTED over row data
            centeringIdx = floor((numel(colHeading)-sz)/2 + sz) - 5; % -5 for numel('PREDICTED')/2
            
            printer.print('%sPREDICTED\n',repmat(' ',1,centeringIdx)); 
            printer.print('%s\n',colHeading);
            
            % add "----" between column headings and data
            printer.print('%s\n',repmat('-',1,numel(colHeading)));
            
            % print rows of the table
            for i = 1:numel(labels)
                
                % print row heading
                printer.print([fmt '%s '],labels{i},'|');
                
                % print the data
                for j = 1:numel(labels)
                    colWidth = max(numel(labels{j}),minColWidth);
                    format   = sprintf('%%-%d.2f   ',colWidth);
                    printer.print(format,confMat(i,j));                    
                end
                printer.linebreak;
            end
           printer.linebreak;
        end                 
    end          
end
