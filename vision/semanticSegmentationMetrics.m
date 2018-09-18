%semanticSegmentationMetrics Semantic segmentation quality metrics
%
%   Object encapsulating semantic segmentation quality metrics for a data
%   set. Use <a href="matlab:help('evaluateSemanticSegmentation')">evaluateSemanticSegmentation</a> to create this object.
%
%   semanticSegmentationMetrics properties:
%
%      ConfusionMatrix  -  Confusion matrix summarizing the classification
%                          results for all the labeled pixels in the data set.
%
%      NormalizedConfusionMatrix  -  Confusion matrix where the counts of
%                                    predicted pixels for each class are
%                                    divided by the number of pixels known
%                                    to belong to that class.
%
%      DataSetMetrics  -  Table of up to 5 metrics aggregated over the data
%                         set: global accuracy, mean class accuracy, mean
%                         class IoU (Jaccard index), frequency-weighted
%                         mean class IoU, and mean BF score.
%
%      ClassMetrics  -  Table of up to 3 metrics computed for each class:
%                       accuracy, IoU (Jaccard index), and mean image BF
%                       score.
%
%      ImageMetrics  -  Table where each row lists up to 5 metrics for each
%                       image in the data set: global accuracy, mean class
%                       accuracy, mean class IoU (Jaccard index), frequency-
%                       weighted mean class IoU, and mean class BF score.
%                       The order of the rows is the order of the images
%                       defined by the input <a href="matlab:help('pixelLabelDatastore')">pixelLabelDatastore</a> objects
%                       representing the data set.
%
%    See also evaluateSemanticSegmentation.

%   Copyright 2017 The MathWorks, Inc.

classdef semanticSegmentationMetrics
    
    properties (SetAccess = protected)
        %ConfusionMatrix Confusion matrix
        %   A square table where element (i,j) is the count of pixels known
        %   to belong to class i but predicted to belong to class j.
        ConfusionMatrix
        
        %NormalizedConfusionMatrix Normalized confusion matrix
        %   A square table where element (i,j) is the share (in [0,1]) of
        %   pixels known to belong to class i but predicted to belong to
        %   class j.
        NormalizedConfusionMatrix
        
        %DataSetMetrics Semantic segmentation metrics aggregated over the data set
        %    A table of up to 5 metrics aggregated over the whole data set,
        %    depending on the value of the "Metrics" parameter used with
        %    <a href="matlab:help('evaluateSemanticSegmentation')">evaluateSemanticSegmentation</a>:
        %
        %      * GlobalAccuracy: Share of correctly classified pixels
        %        regardless of class.
        %      * MeanAccuracy: Mean of the share of correctly classified
        %        pixels for each class. This is the mean of
        %        ClassMetrics.Accuracy.
        %      * MeanIoU: Mean of the intersection over union or IoU (also
        %        known as Jaccard similarity coefficient) for each class.
        %        This is the mean of ClassMetrics.IoU.
        %      * WeightedIoU: Mean of the intersection over union
        %        coefficient (IoU) for each class weighted by the number of
        %        pixels in each class.
        %      * MeanBFScore: Mean over all the images of the mean BF score
        %        for each image. This is the mean of ImageMetrics.BFScore.
        DataSetMetrics
        
        %ClassMetrics Semantic segmentation metrics for each class
        %   A table listing up to 3 metrics for each class, depending on
        %   the value of the "Metrics" parameter used with
        %   <a href="matlab:help('evaluateSemanticSegmentation')">evaluateSemanticSegmentation</a>:
        %
        %     * Accuracy: Share of correctly classified pixels in each
        %       class.
        %     * IoU: intersection over union (IoU, also known as Jaccard
        %       similarity coefficient) for each class.
        %     * MeanBFScore: Mean over all the images of the BF score for
        %       each class.
        ClassMetrics
        
        %ImageMetrics Semantic segmentation metrics for each image in the set
        %   A table where each row lists up to 5 metrics for each image in
        %   the data set, depending on the value of the "Metrics"
        %   parameter used with <a href="matlab:help('evaluateSemanticSegmentation')">evaluateSemanticSegmentation</a>:
        %
        %      * GlobalAccuracy: Share of correctly classified image pixels
        %        regardless of class.
        %      * MeanAccuracy: Mean of the share of correctly classified
        %        image pixels for each class.
        %      * MeanIoU: Mean of the intersection over union (IoU, also
        %        known as Jaccard similarity coefficient) for each class.
        %      * WeightedIoU: Average of the IoU (Jaccard index) for each
        %        class weighted by the number of image pixels in each class.
        %      * MeanBFScore: Mean of the BF score for each class.
        ImageMetrics
    end
    
    properties (Hidden = true, Access = protected)
        ActDatastore      % Cell array of PXDS to the results image files
        ExpDatastore      % Cell array of PXDS to the ground truth image files
        NumSources        % Number of data sources
        NumFiles          % Number of images in the data set
        
        UseParallel       % Whether to run the computation in parallel
        
        Verbose           % Whether to print to the Command Window
        Printer           % Message printer
        WaitBar           % Console wait bar
        
        WantGlobalAccuracy% Whether to compute the global accuracy
        WantAccuracy      % Whether to compute the mean accuracy
        WantJaccard       % Whether to compute the mean Jaccard
        WantFreqJaccard   % Whether to compute the freq-weighted Jaccard
        WantBFScore       % Whether to compute the BF score
        
        ClassNames        % Names of the classes
        NumClasses        % Number of classes in the data set
        
        ConfusionMat      % Confusion matrix for the whole data set
        ClassCardinals    % Number of pixels in each class for each image
        InterAccumulator  % Accumulator for the intersection in Jaccard for each class in the whole set
        UnionAccumulator  % Accumulator for the union in Jaccard for each class in the whole set
        BFScores          % Array of BF scores for each class in each image
        Jaccards          % Array of Jaccard coeffs for each class in each image
        ClassAccuracies   % Array of accuracies for each class in each image
        GlobalAccuracies  % Array of global accuracies for each image
    end
    
    methods
        %------------------------------------------------------------------
        function delete(obj)
            %DELETE Class destructor.
            delete(obj.WaitBar);
        end
        
        %------------------------------------------------------------------
        function tf = eq(obj1,obj2)
            %EQ Operator ==.
            tf = false;
            if isa(obj1,'semanticSegmentationMetrics') && ...
                    isa(obj2,'semanticSegmentationMetrics') && ...
                    isequal(obj1.ConfusionMatrix,obj2.ConfusionMatrix) && ...
                    isequal(obj1.NormalizedConfusionMatrix,obj2.NormalizedConfusionMatrix) && ...
                    isequal(obj1.DataSetMetrics,obj2.DataSetMetrics) && ...
                    isequal(obj1.ClassMetrics,obj2.ClassMetrics) && ...
                    isequal(obj1.ImageMetrics,obj2.ImageMetrics)
                tf = true;
            end
        end
        
        %------------------------------------------------------------------
        function tf = ne(obj1,obj2)
            %NE Operator ~=.
            tf = ~eq(obj1,obj2);
        end
        
        %------------------------------------------------------------------
        function tf = isequal(obj1,obj2)
            %ISEQUAL Determine equality.
            tf = eq(obj1,obj2);
        end
    end
    
    methods (Hidden = true, Static = true)
        %------------------------------------------------------------------
        function obj = compute(varargin)
            obj = semanticSegmentationMetrics(varargin{:});
        end
    end
    
    methods (Hidden = true, Access = protected)
        %------------------------------------------------------------------
        function obj = semanticSegmentationMetrics(varargin)
            narginchk(2,6);
            
            validateInput = @(x,name,pos) validateattributes(x, ...
                {'cell','matlab.io.datastore.PixelLabelDatastore'}, ...
                {'nonempty','vector'}, ...
                mfilename,name,pos);
            
            % pxdsResults and pxdsTruth must both either be a
            % pixelLabelDatastore object or a cell array of
            % pixelLabelDatastore objects.
            pxdsResults = varargin{1};
            pxdsTruth   = varargin{2};
            validateInput(pxdsResults,'pxdsResults',1);
            validateInput(pxdsTruth  ,'pxdsTruth'  ,2);
            
            if ~isa(pxdsResults,class(pxdsTruth))
                error(message('vision:semanticseg:mustBePXDSOrCell', ...
                    'pxdsResults','pxdsTruth'))
            end
            
            if ~isequal(numel(pxdsResults),numel(pxdsTruth))
                error(message('images:validate:unequalNumberOfElements', ...
                    'pxdsResults','pxdsTruth'))
            end
            
            if iscell(pxdsResults)
                % now we know both are cell arrays
                % with the same number of elements
                obj.ActDatastore = cell(numel(pxdsResults),1);
                obj.ExpDatastore = cell(numel(pxdsResults),1);
                % validate each scalar pxds object
                classes = obj.validatePXDSPair(pxdsResults{1},pxdsTruth{1});
                obj.ActDatastore{1} = copy(pxdsResults{1});
                obj.ExpDatastore{1} = copy(pxdsTruth{1});
                for k = 2:numel(pxdsResults)
                    obj.validatePXDSPair(pxdsResults{k},pxdsTruth{k},classes);
                    obj.ActDatastore{k} = copy(pxdsResults{k});
                    obj.ExpDatastore{k} = copy(pxdsTruth{k});
                end
            else
                % both are scalar pxds objects
                obj.validatePXDSPair(pxdsResults,pxdsTruth);
                obj.ActDatastore = {copy(pxdsResults)};
                obj.ExpDatastore = {copy(pxdsTruth)};
            end
            
            obj.ClassNames = obj.ActDatastore{1}.ClassNames;
            obj = obj.parseOptionalInputs(varargin{3:end});
            obj = obj.initializeAndAllocate();
            obj = obj.computeMetrics();
        end
        
        %------------------------------------------------------------------
        function obj = parseOptionalInputs(obj,varargin)
            parser = inputParser();
            parser.FunctionName = mfilename;
            
            % Metrics
            validMetrics = {'all','global-accuracy','accuracy', ...
                'iou','weighted-iou','bfscore',''};
            defaultMetrics = validMetrics{1};
            validateMetrics = @(x) validateattributes(x, ...
                {'char','cell','string'}, ...
                {'vector'}, ...
                mfilename,'Metrics');
            parser.addParameter('Metrics', ...
                defaultMetrics, ...
                validateMetrics);
            
            % Verbose
            defaultVerbose = true;
            validateVerbose = @(x) vision.internal.inputValidation.validateLogical(x,'Verbose');
            parser.addParameter('Verbose', ...
                defaultVerbose, ...
                validateVerbose);
            
            % UseParallel
            defaultUseParallel = vision.internal.useParallelPreference();
            validateUseParallel = @vision.internal.inputValidation.validateUseParallel;
            parser.addParameter('UseParallel', ...
                defaultUseParallel);
            
            parser.parse(varargin{:});
            inputs = parser.Results;
            
            obj.Verbose = logical(inputs.Verbose);
            obj.UseParallel = logical(validateUseParallel(inputs.UseParallel));
            metrics = matlab.images.internal.stringToChar(inputs.Metrics);
            
            % Validate the names of the metrics
            if ischar(metrics)
                metrics = {validatestring(metrics,validMetrics)};
            else
                metrics = cellfun( ...
                    @(x) validatestring(x,validMetrics), ...
                    unique(metrics), 'UniformOutput',false);
            end
            
            obj.WantGlobalAccuracy = false;
            obj.WantAccuracy       = false;
            obj.WantJaccard        = false;
            obj.WantFreqJaccard    = false;
            obj.WantBFScore        = false;
            for m = metrics
                switch m{:}
                    case validMetrics{1}
                        % 'all'
                        obj.WantGlobalAccuracy = true;
                        obj.WantAccuracy       = true;
                        obj.WantJaccard        = true;
                        obj.WantFreqJaccard    = true;
                        obj.WantBFScore        = true;
                    case validMetrics{2}
                        % 'global-accuracy'
                        obj.WantGlobalAccuracy = true;
                    case validMetrics{3}
                        % 'accuracy'
                        obj.WantAccuracy       = true;
                    case validMetrics{4}
                        % 'jaccard'
                        obj.WantJaccard        = true;
                    case validMetrics{5}
                        % 'freq'jaccard'
                        obj.WantFreqJaccard    = true;
                    case validMetrics{6}
                        % 'bfscore'
                        obj.WantBFScore        = true;
                end
            end
        end
        
        %------------------------------------------------------------------
        function obj = initializeAndAllocate(obj)
            % Initialize parameters
            obj.NumSources = numel(obj.ExpDatastore);
            obj.NumFiles = zeros(obj.NumSources,1);
            for k = 1:obj.NumSources
                obj.NumFiles(k) = numel(obj.ExpDatastore{k}.Files);
            end
            obj.NumClasses = numel(obj.ClassNames);
            
            % Allocate accumulators and other arrays
            obj.ConfusionMat = zeros(obj.NumClasses);
            if obj.WantFreqJaccard
                obj.ClassCardinals = zeros(sum(obj.NumFiles),obj.NumClasses);
            end
            if obj.WantJaccard || obj.WantFreqJaccard
                obj.InterAccumulator = zeros(obj.NumClasses,1);
                obj.UnionAccumulator = zeros(obj.NumClasses,1);
                obj.Jaccards = zeros(sum(obj.NumFiles),obj.NumClasses);
            end
            if obj.WantBFScore
                obj.BFScores = zeros(sum(obj.NumFiles),obj.NumClasses);
            end
            if obj.WantAccuracy || obj.WantGlobalAccuracy || obj.WantFreqJaccard
                obj.ClassAccuracies = zeros(sum(obj.NumFiles),obj.NumClasses);
                obj.GlobalAccuracies = zeros(sum(obj.NumFiles),1);
            end
            
            % Reset the datastores
            for k = 1:obj.NumSources
                reset(obj.ActDatastore{k});
                reset(obj.ExpDatastore{k});
            end
            
            % Create a MessagePrinter.
            obj.Printer = vision.internal.MessagePrinter.configure(obj.Verbose);
            
            % Create a Console Window wait bar.
            obj.WaitBar = vision.internal.ConsoleWaitBar( ...
                sum(obj.NumFiles), ...     % total number of iterations
                "Verbose",obj.Verbose, ... % whether to print or not
                "DisplayPeriod",2, ...     % refresh every 2 seconds
                "PrintElapsedTime",1, ...  % print elapsed time
                "PrintRemainingTime",1);   % print estimated time remaining
        end
        
        %------------------------------------------------------------------
        function obj = computeMetrics(obj)
            % Read each image and compute intermediate variables
            obj = printHeader(obj);
            if obj.UseParallel
                obj = processImagesParallel(obj);
            else
                obj = processImagesSerial(obj);
            end
            
            % Finalize metrics based on the intermediate variables
            obj = printFooter(obj);
            obj = finalizeMetrics(obj);
            obj = printDone(obj);
        end
        
        %------------------------------------------------------------------
        function obj = processImagesSerial(obj)
            % Intermediate variables used over and over in the loop
            if obj.WantJaccard || obj.WantFreqJaccard
                imageInter = zeros(obj.NumClasses,1);
                imageUnion = zeros(obj.NumClasses,1);
            end
            
            % k indexes the files across all data sets
            k = 0;
            
            % Force finish displaying wait bar when we exit this function
            % or if the user sends an interrupt signal.
            cleanUpObj = onCleanup(@() stop(obj.WaitBar));
            
            % Start displaying wait bar
            start(obj.WaitBar);
            
            % For each data set
            for s = 1:obj.NumSources
                pxdsAct = obj.ActDatastore{s};
                pxdsExp = obj.ExpDatastore{s};
                % For each file in the data set
                for f = 1:obj.NumFiles(s)
                    % Index of the current file across all data sets
                    k = k + 1;
                    
                    % Update wait bar
                    update(obj.WaitBar);
                    
                    % Read predicted and actual images
                    [act,act_info] = readimage(pxdsAct,f);
                    [exp,exp_info] = readimage(pxdsExp,f);
                    
                    if ~isequal(size(act),size(exp))
                        error(message('images:validate:unequalSizeMatrices', ...
                            act_info.Filename,exp_info.Filename))
                    end
                    
                    act_bw = images.internal.segmentation.convertToCellOfLogicals(act,obj.ClassNames);
                    exp_bw = images.internal.segmentation.convertToCellOfLogicals(exp,obj.ClassNames);
                    
                    % Incrementally build the data set confusion matrix
                    confMat = images.internal.segmentation.bwconfmat(act_bw,exp_bw);
                    obj.ConfusionMat = obj.ConfusionMat + confMat;
                    
                    % Compute the class accuracy and global
                    % accuracy metrics on individual images
                    if obj.WantAccuracy || obj.WantGlobalAccuracy
                        [obj.GlobalAccuracies(k),obj.ClassAccuracies(k,:)] = ...
                            images.internal.segmentation.accuracy(confMat);
                    end
                    
                    % Compute the IoU and weighted IoU on individual
                    % images and incrementally build the data set IoU.
                    if obj.WantJaccard || obj.WantFreqJaccard
                        for c = 1:obj.NumClasses
                            [obj.Jaccards(k,c),imageInter(c),imageUnion(c)] = ...
                                images.internal.segmentation.bwjaccard( ...
                                act_bw{c},exp_bw{c});
                        end
                        obj.InterAccumulator = obj.InterAccumulator + imageInter;
                        obj.UnionAccumulator = obj.UnionAccumulator + imageUnion;
                        if obj.WantFreqJaccard
                            obj.ClassCardinals(k,:) = nansum(confMat,2);
                        end
                    end
                    
                    % Compute the BFScore on individual images
                    if obj.WantBFScore
                        % Use 0.75% of the image diagonal as threshold.
                        % This is the value used by the paper.
                        theta = 0.75 / 100 * sqrt(size(exp,1)^2 + size(exp,2)^2);
                        for c = 1:obj.NumClasses
                            obj.BFScores(k,c) = ...
                                images.internal.segmentation.bwbfscore2( ...
                                act_bw{c},exp_bw{c},theta);
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function obj = processImagesParallel(obj)
            % Create the parallel pool *before* starting to print progress.
            % Open a parallel pool if one does not already exist.
            p = gcp;
            if isempty(p)
                % Automatic pool starts are disabled in the parallel pref.
                % Run the algo in serial instead.
                obj = processImagesSerial(obj);
                return
            end
            
            % Create a DataQueue to send progress
            % from the workers back to the client.
            queue = parallel.pool.DataQueue;
            afterEach(queue, @(~) update(obj.WaitBar));
            
            % Make local copies of parameters to 
            % avoid broadcasting obj to the workers.
            classNames = obj.ClassNames;
            numClasses = obj.NumClasses;
            numPrecedingFiles = cumsum(obj.NumFiles);
            numPrecedingFiles = [0 numPrecedingFiles(1:end-1)];
            
            wantJaccard = obj.WantJaccard;
            wantFreqJaccard = obj.WantFreqJaccard;
            wantAccuracy = obj.WantAccuracy;
            wantGlobalAccuracy = obj.WantGlobalAccuracy;
            wantBFScore = obj.WantBFScore;
            
            % Declare variables that are potentially used by the workers.
            interAccumulator = [];
            unionAccumulator = [];
            
            confusionMat = obj.ConfusionMat;
            if wantJaccard || wantFreqJaccard
                % Make a local copy only if we will use them.
                interAccumulator = obj.InterAccumulator;
                unionAccumulator = obj.UnionAccumulator;
            end
            
            % Force finish displaying wait bar when we exit this function
            % or if the user sends an interrupt signal.
            cleanUpObj = onCleanup(@() stop(obj.WaitBar));
            
            % Start displaying wait bar
            start(obj.WaitBar);
            
            idx1 = 1;
            % For each data set
            for s = 1:obj.NumSources
                pxdsAct = obj.ActDatastore{s};
                pxdsExp = obj.ExpDatastore{s};
                idx2 = idx1 - 1 + obj.NumFiles(s);
                
                % Declare broadcast variables that are
                % potentially used by the workers.
                sourceClassAcc = [];
                sourceGlobalAcc = [];
                sourceJaccard = [];
                sourceClassCardinals = [];
                sourceBFScore = [];
                
                % Make a local copy only if they are used.
                if wantAccuracy || wantGlobalAccuracy
                    sourceClassAcc = obj.ClassAccuracies(idx1:idx2,:);
                    sourceGlobalAcc = obj.GlobalAccuracies(idx1:idx2);
                end
                if wantJaccard || wantFreqJaccard
                    sourceJaccard = obj.Jaccards(idx1:idx2,:);
                    if wantFreqJaccard
                        sourceClassCardinals = obj.ClassCardinals(idx1:idx2,:);
                    end
                end
                if wantBFScore
                    sourceBFScore = obj.BFScores(idx1:idx2,:);
                end
                
                % Offset used by the counter for the wait bar.
                offset = numPrecedingFiles(s);
                
                % For each file in the data set
                parfor f = 1:obj.NumFiles(s)
                    % Send progress back to the client
                    k = f + offset;
                    send(queue,k);
                    
                    % Read predicted and actual images
                    [act,act_info] = readimage(pxdsAct,f);
                    [exp,exp_info] = readimage(pxdsExp,f);
                    
                    if ~isequal(size(act),size(exp))
                        error(message('images:validate:unequalSizeMatrices', ...
                            act_info.Filename,exp_info.Filename))
                    end
                    
                    act_bw = images.internal.segmentation.convertToCellOfLogicals(act,classNames);
                    exp_bw = images.internal.segmentation.convertToCellOfLogicals(exp,classNames);
                    
                    % Incrementally build the data set confusion matrix
                    imageConfMat = images.internal.segmentation.bwconfmat(act_bw,exp_bw);
                    confusionMat = confusionMat + imageConfMat;
                    
                    % Compute the class accuracy and global
                    % accuracy metrics on individual images
                    if wantAccuracy || wantGlobalAccuracy
                        [sourceGlobalAcc(f),sourceClassAcc(f,:)] = ...
                            images.internal.segmentation.accuracy(imageConfMat);
                    end
                    
                    % Compute the IoU and weighted IoU on individual
                    % images and incrementally build the data set IoU.
                    if wantJaccard || wantFreqJaccard
                        imageJaccard = zeros(numClasses,1);
                        imageInter = zeros(numClasses,1);
                        imageUnion = zeros(numClasses,1);
                        for c = 1:numClasses
                            [imageJaccard(c),imageInter(c),imageUnion(c)] = ...
                                images.internal.segmentation.bwjaccard( ...
                                act_bw{c},exp_bw{c});
                        end
                        sourceJaccard(f,:) = imageJaccard(:);
                        interAccumulator = interAccumulator + imageInter;
                        unionAccumulator = unionAccumulator + imageUnion;
                        if wantFreqJaccard
                            sourceClassCardinals(f,:) = nansum(imageConfMat,2);
                        end
                    end
                    
                    % Compute the BFScore on individual images
                    if wantBFScore
                        imageBFScore = zeros(numClasses,1);
                        % Default of 0.75% of image diagonal used in paper.
                        theta = 0.75 / 100 * sqrt(size(exp,1)^2 + size(exp,2)^2);
                        for c = 1:numClasses
                            imageBFScore(c) = ...
                                images.internal.segmentation.bwbfscore2( ...
                                act_bw{c},exp_bw{c},theta);
                        end
                        sourceBFScore(f,:) = imageBFScore(:);
                    end
                end % parfor
                
                if wantAccuracy || wantGlobalAccuracy
                    obj.ClassAccuracies(idx1:idx2,:) = sourceClassAcc;
                    obj.GlobalAccuracies(idx1:idx2) = sourceGlobalAcc;
                end
                if wantJaccard || wantFreqJaccard
                    obj.Jaccards(idx1:idx2,:) = sourceJaccard;
                    if wantFreqJaccard
                        obj.ClassCardinals(idx1:idx2,:) = sourceClassCardinals;
                    end
                end
                if wantBFScore
                    obj.BFScores(idx1:idx2,:) = sourceBFScore;
                end
                idx1 = idx2 + 1;
            end
            
            obj.ConfusionMat = confusionMat;
            if wantJaccard || wantFreqJaccard
                obj.InterAccumulator = interAccumulator;
                obj.UnionAccumulator = unionAccumulator;
            end
        end
        
        %------------------------------------------------------------------
        function obj = finalizeMetrics(obj)
            % 1. Confusion matrix
            % -------------------
            
            % 1.1 Confusion matrix as raw counts
            obj.ConfusionMatrix = array2table( ...
                obj.ConfusionMat, ...
                'VariableNames', obj.ClassNames, ...
                'RowNames', obj.ClassNames);
            
            % 1.2 Normalized confusion matrix
            ratios = obj.ConfusionMat;
            for i = 1:size(ratios,1)
                ratios(i,:) = ratios(i,:) / nansum(ratios(i,:));
            end
            obj.NormalizedConfusionMatrix = array2table( ...
                ratios, ...
                'VariableNames', obj.ClassNames, ...
                'RowNames', obj.ClassNames);
            
            % 2. Other Metrics
            % ----------------
            obj.ClassMetrics = table('RowNames',obj.ClassNames);
            obj.DataSetMetrics = table;
            
            % ImageMetrics is a table or, if there are
            % more than 1 source, a cell array of tables.
            if (obj.NumSources == 1)
                obj.ImageMetrics = table;
            else
                obj.ImageMetrics = cell(obj.NumSources,1);
                for s = 1:obj.NumSources
                    obj.ImageMetrics{s} = table;
                end
            end
            
            % 2.1 Global Accuracy
            if obj.WantGlobalAccuracy
                % Global accuracy for the whole set
                globalAccuracy = nansum(diag(obj.ConfusionMat)) / sum(nansum(obj.ConfusionMat,2));
                obj.DataSetMetrics.GlobalAccuracy = globalAccuracy;
                
                % Global accuracy for each image
                if (obj.NumSources == 1)
                    obj.ImageMetrics.GlobalAccuracy = obj.GlobalAccuracies;
                else
                    idx1 = 1;
                    for s = 1:obj.NumSources
                        idx2 = idx1 - 1 + obj.NumFiles(s);
                        obj.ImageMetrics{s}.GlobalAccuracy = obj.GlobalAccuracies(idx1:idx2);
                        idx1 = idx2 + 1;
                    end
                end
            end
            
            % 2.2 Accuracy
            if obj.WantAccuracy
                % Accuracy for each class
                classAccuracy = zeros(obj.NumClasses,1);
                for i = 1:obj.NumClasses
                    classAccuracy(i) = obj.ConfusionMat(i,i) / nansum(obj.ConfusionMat(i,:));
                end
                obj.ClassMetrics.Accuracy = classAccuracy;
                
                % Mean class accuracy over the whole set
                meanAccuracy = nanmean(classAccuracy);
                obj.DataSetMetrics.MeanAccuracy = meanAccuracy;
                
                % Mean class accuracy for each image
                if (obj.NumSources == 1)
                    obj.ImageMetrics.MeanAccuracy = nanmean(obj.ClassAccuracies,2);
                else
                    idx1 = 1;
                    for s = 1:obj.NumSources
                        idx2 = idx1 - 1 + obj.NumFiles(s);
                        obj.ImageMetrics{s}.MeanAccuracy = nanmean(obj.ClassAccuracies(idx1:idx2,:),2);
                        idx1 = idx2 + 1;
                    end
                end
            end
            
            % 2.3 Jaccard
            if obj.WantJaccard
                % Jaccard coeff for each class over the set
                classJaccard = obj.InterAccumulator ./ obj.UnionAccumulator;
                obj.ClassMetrics.IoU = classJaccard;
                
                % Mean class Jaccard over the whole set
                meanJaccard = nanmean(classJaccard);
                obj.DataSetMetrics.MeanIoU = meanJaccard;
                
                % Mean class Jaccard for each image
                if (obj.NumSources == 1)
                    obj.ImageMetrics.MeanIoU = nanmean(obj.Jaccards,2);
                else
                    idx1 = 1;
                    for s = 1:obj.NumSources
                        idx2 = idx1 - 1 + obj.NumFiles(s);
                        obj.ImageMetrics{s}.MeanIoU = nanmean(obj.Jaccards(idx1:idx2,:),2);
                        idx1 = idx2 + 1;
                    end
                end
            end
            
            % 2.4 Frequency-weighted Jaccard
            if obj.WantFreqJaccard
                % Frequency-weighted mean class Jaccard
                classJaccard = obj.InterAccumulator ./ obj.UnionAccumulator;
                freqWeightedJaccard = 0;
                for i = 1:obj.NumClasses
                    freqWeightedJaccard = freqWeightedJaccard + ...
                        nansum(obj.ConfusionMat(i,:)) * classJaccard(i);
                end
                freqWeightedJaccard = freqWeightedJaccard / sum(nansum(obj.ConfusionMat,2));
                obj.DataSetMetrics.WeightedIoU = freqWeightedJaccard;
                
                % Freq-weighted Jaccard for each image
                freqWeightedJaccards = obj.Jaccards .* obj.ClassCardinals;
                freqWeightedJaccards = nansum(freqWeightedJaccards,2);
                freqWeightedJaccards = freqWeightedJaccards ./ nansum(obj.ClassCardinals,2);
                if (obj.NumSources == 1)
                    obj.ImageMetrics.WeightedIoU = freqWeightedJaccards;
                else
                    idx1 = 1;
                    for s = 1:obj.NumSources
                        idx2 = idx1 - 1 + obj.NumFiles(s);
                        obj.ImageMetrics{s}.WeightedIoU = freqWeightedJaccards(idx1:idx2);
                        idx1 = idx2 + 1;
                    end
                end
            end
            
            % 2.5 BF score
            if obj.WantBFScore
                % Mean BF score for each class over the whole set
                classBFScore = nanmean(obj.BFScores,1)';
                obj.ClassMetrics.MeanBFScore = classBFScore;
                
                % Mean BF score over all the classes for the whole set
                meanBFScore = mean(nanmean(obj.BFScores,2));
                obj.DataSetMetrics.MeanBFScore = meanBFScore;
                
                % Mean BF score over all the classes for each image
                if (obj.NumSources == 1)
                    obj.ImageMetrics.MeanBFScore = nanmean(obj.BFScores,2);
                else
                    idx1 = 1;
                    for s = 1:obj.NumSources
                        idx2 = idx1 - 1 + obj.NumFiles(s);
                        obj.ImageMetrics{s}.MeanBFScore = nanmean(obj.BFScores(idx1:idx2,:),2);
                        idx1 = idx2 + 1;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function obj = printHeader(obj)
            obj.Printer.printMessage('vision:semanticseg:evaluationHeader');
            N = length(getString(message('vision:semanticseg:evaluationHeader')));
            obj.Printer.print(repmat('-',1,N));
            obj.Printer.linebreak();
            obj.Printer.printMessageNoReturn('vision:semanticseg:selectedMetrics');
            obj.Printer.print(' ');
            printComma = false;
            if obj.WantGlobalAccuracy
                obj.Printer.print('global accuracy');
                printComma = true;
            end
            if obj.WantAccuracy
                if printComma
                    obj.Printer.print(', ');
                end
                obj.Printer.print('class accuracy');
                printComma = true;
            end
            if obj.WantJaccard
                if printComma
                    obj.Printer.print(', ');
                end
                obj.Printer.print('IoU');
                printComma = true;
            end
            if obj.WantFreqJaccard
                if printComma
                    obj.Printer.print(', ');
                end
                obj.Printer.print('weighted IoU');
                printComma = true;
            end
            if obj.WantBFScore
                if printComma
                    obj.Printer.print(', ');
                end
                obj.Printer.print('BF score');
            end
            obj.Printer.print('.');
            obj.Printer.linebreak();
            obj.Printer.printMessage('vision:semanticseg:processingNImages', ...
                num2str(sum(obj.NumFiles)));
        end
        
        %------------------------------------------------------------------
        function obj = printFooter(obj)
            obj.Printer.printMessage('vision:semanticseg:finalizingResults');
        end
        
        %------------------------------------------------------------------
        function obj = printDone(obj)
            obj.Printer.print('\b ');
            obj.Printer.printMessage('vision:semanticseg:done');
            obj.Printer.printMessage('vision:semanticseg:dataSetMetrics');
            obj.Printer.linebreak();
            if obj.Verbose
                disp(obj.DataSetMetrics)
            end
        end
    end
    
    methods (Hidden = true, Access = protected, Static = true)
        %------------------------------------------------------------------
        function classes = validatePXDSPair(pxds1,pxds2,classes)
            % both must be pixelLabelDatastore objects
            pxdsType = 'matlab.io.datastore.PixelLabelDatastore';
            if ~isa(pxds1,pxdsType) || ~isa(pxds2,pxdsType)
                error(message('vision:semanticseg:mustBePXDSOrCell', ...
                    'pxdsResults','pxdsTruth'))
            end
            
            % both must have the same classes
            if (nargin < 3)
                classes = pxds1.ClassNames;
            end
            if ~isequal(classes,pxds1.ClassNames,pxds2.ClassNames)
                error(message('vision:semanticseg:mustHaveSameClasses', ...
                    'pxdsResults','pxdsTruth'))
            end
            
            % both must hold the same number of files
            if ~isequal(numel(pxds1.Files),numel(pxds2.Files))
                error(message('vision:semanticseg:mustHaveSameNumOfFiles', ...
                    'pxdsResults','pxdsTruth'))
            end
        end
    end
end
