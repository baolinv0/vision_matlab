%PixelLabelDatastore An object for storing a collection of pixel label data.
%
%   PixelLabelDatastore is created using the pixelLabelDatastore
%   function. Use a PixelLabelDatastore to represent and read data from a
%   collection of semantic segmentation results or pixel label data stored
%   in a groundTruth object.
%
%   PixelLabelDatastore Properties:
%
%      Files          - A cell array of file names
%      ClassNames     - A cell array of class names
%      ReadSize       - Upper limit on the number of images returned by the
%                       read method
%      ReadFcn        - Function handle used to read files
%
%   PixelLabelDatastore Methods:
%
%      hasdata        - Returns true if there is more data to read.
%      read           - Reads the next consecutive file.
%      reset          - Resets the datastore to the start of the data.
%      preview        - Reads the first image from the datastore.
%      readimage      - Reads a specified image from the datastore.
%      readall        - Reads all pixel label data from the datastore.
%      partition      - Returns a new datastore that represents a single.
%                       partitioned portion of the original datastore.
%      numpartitions  - Returns an estimate for a reasonable number of
%                       partitions to use with the partition function,
%                       according to the total data size.
%      countEachLabel - Counts the number of pixel labels for each class.
%
% Example - Read and display pixel label data.
% --------------------------------------------
% % Location of image and pixel label data
% dataDir = fullfile(toolboxdir('vision'), 'visiondata');
% imDir = fullfile(dataDir, 'building');
% pxDir = fullfile(dataDir, 'buildingPixelLabels');
% 
% % Create image datastore
% imds = imageDatastore(imDir);
% 
% % Create pixel label datastore. 
% classNames = ["sky" "grass" "building" "sidewalk"];
% pixelLabelID = [1 2 3 4];
% pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
% 
% % Read image and pixel label data. read(pxds) returns a categorical
% % matrix, C. C(i,j) is the categorical label assigned to I(i,j).
% I = read(imds);
% C = read(pxds);
% 
% % Display the label categories in C
% categories(C)
% 
% % Overlay pixel label data on the image and display.
% B = labeloverlay(I, C);
% figure
% imshow(B)
%
% See also pixelLabelDatastore, imageDatastore, groundTruth, semanticseg,
%          evaluateSemanticSegmentation, imageLabeler.

% Copyright 2017 The MathWorks, Inc.
classdef PixelLabelDatastore <  ...
        matlab.io.datastore.CustomReadDatastore & ...
        matlab.io.datastore.internal.ScalarBase & ...
        matlab.mixin.CustomDisplay
    
    properties(Dependent)
        %Files -
        % Cell array of file names.
        Files 
    end
    
    properties(Dependent, SetAccess = private)
        %ClassNames -
        % A cell array of the names of the classes.
        ClassNames
    end
    
    properties(Dependent)
        %ReadSize -
        % Number of image files for one read.
        ReadSize
    end
    
    properties(Hidden, SetAccess = private)
        %LabelDefinitions A table with two columns: Name, PixelLabelID.
        %                 Holds label name to pixel label ID mappings.
        LabelDefinitions
        
        %CategoricalCache A cell array of cached categoricals for each
        %                 label definition table. This is used to create
        %                 the categorical during each read and acts as a
        %                 look-up table.
        CategoricalCache 
    end
    
    properties(Hidden, Access = private)
        %ImageDatastore Datastore used to read data.
        ImageDatastore
        
        %DefaultReadFcn Copy of default image datastore read function.
        DefaultReadFcn
        
        %UsingDefaultReadFcn True if the default read function is used.
        UsingDefaultReadFcn logical
    end
    
    methods(Hidden, Access = private)
        %------------------------------------------------------------------
        function this = PixelLabelDatastore(location, labelDefinitions, varargin)
            
            if isa(location, 'matlab.io.datastore.ImageDatastore')
                % used by partition method. assignments will already be set
                % in input datastore.Labels. Tack on label definitions.
                this.ImageDatastore = location;
                this.LabelDefinitions = labelDefinitions;
                this.CategoricalCache = varargin{1};
            else
                assignments = varargin{1};
                params      = varargin{2};
                try
                    this.ImageDatastore = imageDatastore(location, ...
                        'IncludeSubfolders', params.IncludeSubfolders, ...
                        'ReadSize', params.ReadSize);
                catch ME
                    throwAsCaller(ME)
                end
                
                initializeLabelDefinitions(this, labelDefinitions, assignments);
                
                initializeCategoricalCache(this);
            end
            
            this.DefaultReadFcn      = this.ImageDatastore.ReadFcn;
            this.UsingDefaultReadFcn = true;
            
            this.SplitterName = 'matlab.io.datastore.splitter.WholeFileCustomReadSplitter';
            % Signature for initFromReadFcn:
            %    initFromReadFcn(ds, readFcn, files, fileSizes, includeSubfolders)
            %
            %  - files, fileSizes - Pass files and file sizes to initialization of the splitter,
            %    so we don't lookup the path and verify the existence of
            %    files; NB: fileSizes is not passed here because the
            %    internal datastore already stores the files.
            %    imageDatastore to do the reading.
            %  - includeSubfolders - true/false to include recursive sub-folders
            
            initFromReadFcn(this, this.ImageDatastore.ReadFcn, this.ImageDatastore.Files);

        end
        
        %------------------------------------------------------------------
        function initializeLabelDefinitions(this, labelDefinitions, assignments)
            
            if ~iscell(labelDefinitions)
                labelDefinitions = {labelDefinitions};
            end
            this.LabelDefinitions = labelDefinitions;
            
            % set file assignments to label definitions: assignments(k)
            % maps file(k) to labelDefinitions( assignments(k) ).
            if isscalar(assignments)
                assert(numel(this.LabelDefinitions) == 1);
                assignments = ones(numel(this.ImageDatastore.Files),1);
            end
            this.ImageDatastore.Labels = assignments;
        end
        
        %------------------------------------------------------------------
        function initializeCategoricalCache(this)
            this.CategoricalCache = cell(1,numel(this.LabelDefinitions));
            
            % use first label definition to define categorical order
            catord = this.LabelDefinitions{1}.Name;
            
            for i = 1:numel(this.CategoricalCache)
                
                this.CategoricalCache{i} = ...
                    matlab.io.datastore.PixelLabelDatastore.labeldef2cat(...
                    this.LabelDefinitions{i});
                
                % Maintain the same categories order across label
                % definitions.
                this.CategoricalCache{i} = reordercats(...
                    this.CategoricalCache{i}, catord);
                
            end
        end
        
        function updateReadFcnIfRequired(this, readFcn)

            this.UsingDefaultReadFcn = matlab.io.datastore.PixelLabelDatastore.isDefaultReadFcn(readFcn);

           % update ImageDatastore's read function';,.
            if this.UsingDefaultReadFcn
                this.ImageDatastore.ReadFcn = this.DefaultReadFcn;
            else
                this.ImageDatastore.ReadFcn = readFcn;
            end
        end
             
    end
    
    methods(Hidden, Access = protected)
        %------------------------------------------------------------------
        function validateReadFcn(this,readFcn)
            % validateReadFcn is called from set.ReadFcn
            import matlab.io.datastore.ImageDatastore;
            import matlab.io.datastore.internal.validators.validateCustomReadFcn;
            validateCustomReadFcn(readFcn, false, 'pixelLabelImageDatastore');
            
            
            % Set the private IsReadFcnDefault value
            updateReadFcnIfRequired(this, readFcn);
        end
        
        %------------------------------------------------------------------
        function validateCategorical(this,C)
            % If the user specified a custom reader, check that the
            % categorical created by it is valid.
            if ~isa(C, 'categorical')
                error(message('vision:semanticseg:invalidCustomReadFcnOutput'));
            end
            
            % Should have the same categories.
            if ~isempty(setxor(categories(C), this.ClassNames))
                names = sprintf('%s, ', this.ClassNames{:});
                error(message('vision:semanticseg:unexpectedClassNames', names(1:end-2)));
            end
        end
        
        %------------------------------------------------------------------
        function aCopy = copyElement(this)
            
            imdsCopy = copy(this.ImageDatastore);
            
            aCopy = matlab.io.datastore.PixelLabelDatastore(...
                imdsCopy, this.LabelDefinitions, this.CategoricalCache);
        end
    end
    
    methods
        
        %------------------------------------------------------------------
        function C = readall(this)
            %readall Read all of the files from the datastore.
            %   C = readall(pxds) reads all of the files from pxds. C is a
            %   cell array containing all the pixel label data in pxds.
            
            L = readall(this.ImageDatastore);
            info.Label = this.ImageDatastore.Labels;
            C = this.label2categorical(L, info);
        end
        
        %------------------------------------------------------------------
        function C = preview(this)
            %preview Read the first image from the datastore.
            %   C = preview(pxds) always reads the first pixel label data
            %   file from the datastore. C is a categorical matrix.
            %
            %   preview does not affect the state of the datastore.
            %
            % Example
            % -------
            % % Location of image and pixel label data
            % dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            % pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            % % Create pixel label datastore.
            % classNames = ["sky" "grass" "building" "sidewalk"];
            % pixelLabelID = [1 2 3 4];
            % pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %            
            % C = read(pxds);             
            % rgb = label2rgb(uint8(C));
            % figure
            % imshow(rgb);                
           
            [L, info] = readimage(this.ImageDatastore,1);
            C = this.label2categorical(L, info);
        end
        
        %------------------------------------------------------------------
        function TF = hasdata(this)
            %hasdata Returns true if there is unread data in the PixelLabelDatastore.
            %   TF = hasdata(pxds) returns true if the datastore has one or
            %   more images available to read with the read method.
            %   read(pxds) returns an error when hasdata(pxds) returns
            %   false.
            %
            % Example
            % -------
            % % Location of image and pixel label data
            % dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            % pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            % % Create pixel label datastore.
            % classNames = ["sky" "grass" "building" "sidewalk"];
            % pixelLabelID = [1 2 3 4];
            % pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %
            % while hasdata(pxds)
            %     C = read(pxds);             % Read data
            %     rgb = label2rgb(uint8(C));  % Convert pixel labels to RGB image.
            %     imshow(rgb);                % See images in a loop.
            %     pause(1)                    % Pause between images.
            % end
            % reset(pxds);                    % Reset to beginning.
            % C = read(pxds);                 % Read from the beginning.
            
            TF = this.ImageDatastore.hasdata();
        end
        
        %------------------------------------------------------------------
        function n = numpartitions(this, varargin)
            %numpartitions Returns an estimate of a reasonable number of partitions.
            %
            %   N = numpartitions(pxds) returns the default number of
            %   partitions for a given PixelLabelDatastore, pxds, which is
            %   the total number of files.
            %
            %   N = numpartitions(pxds,pool) returns a reasonable number of
            %   partitions to parallelize pxds over the parallel pool based
            %   on the total number of files and the number of workers in
            %   pool.
            %
            %   The number of partitions obtained from numpartitions is
            %   recommended as an input to PARTITION function.
            
            try
                n = numpartitions(this.ImageDatastore, varargin{:});
            catch ME
                throwAsCaller(ME)
            end
        end
        
        %------------------------------------------------------------------
        function subds = partition(this, varargin)
            %partition Returns a partitioned portion of the PixelLabelDatastore.
            %   subds = partition(pxds, N, index) partitions pxds into N
            %   parts and returns the partitioned PixelLabelDatastore,
            %   subds, corresponding to index. An estimate for a reasonable
            %   value for N can be obtained by using the NUMPARTITIONS
            %   function.
            %
            %   subds = partition(pxds,'Files',index) partitions pxds by
            %   files in the Files property and returns the partition
            %   corresponding to index.
            %
            %   subds = partition(pxds,'Files',filename) partitions pxds by
            %   files and returns the partition corresponding to filename.
            
            try
                subimds = partition(this.ImageDatastore, varargin{:});
                subds = matlab.io.datastore.PixelLabelDatastore(subimds, this.LabelDefinitions, this.CategoricalCache);
            catch ME
                throwAsCaller(ME)
            end
        end
        
        %------------------------------------------------------------------
        function [C, info] = read(this)
            %read Read the next pixel label data file from the datastore.
            %   C = read(pxds) reads the next consecutive image from pxds.
            %   By default, C is a categorical matrix where each element
            %   C(i,j) defines a categorical label. 
            %
            %   When the ReadSize property of PixelLabelDatastore is greater
            %   than 1, C is a cell array of categorical matrices.
            %
            %   read(pxds) errors if there is not data in pxds. 
            %
            %   [C, info] = read(pxds) also returns a structure with
            %   additional information about C. The fields of info are:
            %      Filename - Name of the file from which the data was read
            %      FileSize - Size of the file in bytes
            %      
            %   When the ReadSize property of PixelLabelDatastore is
            %   greater than 1, the fields of info are:            
            %      Filename - A cell array of filenames
            %      FileSize - A vector of file sizes           
            %
            % Example
            % -------
            %   % Location of image and pixel label data
            %   dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            %   imDir = fullfile(dataDir, 'building');
            %   pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            %   % Create image datastore
            %   imds = imageDatastore(imDir);
            %
            %   % Create pixel label datastore.
            %   classNames = ["sky" "grass" "building" "sidewalk"];
            %   pixelLabelID = [1 2 3 4];
            %   pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %
            %   % Read image and pixel label data. read(pxds) returns a categorical
            %   % matrix, C. C(i,j) is the categorical label assigned to I(i,j).
            %   I = read(imds);
            %   C = read(pxds);
            %
            %   % Display the label categories in C
            %   categories(C)
            %
            %   % Overlay pixel label data on the image and display.
            %   B = labeloverlay(I, C);
            %   figure
            %   imshow(B)
            
            % Call read on imds. This calls either the default ReadFcn or
            % a custom one.
            [C, info] = read(this.ImageDatastore);
            
            if this.UsingDefaultReadFcn
                C = this.label2categorical(C, info);
            else
                % The custom reader is responsible for converting image
                % data to a categorical. Check that the result is a
                % categorical and has the expected categories.
                this.validateCategorical(C);
            end
            
            if nargout == 2
                info = rmfield(info, 'Label');
            end
        end
        
        %------------------------------------------------------------------
        function [C, info] = readimage(this,i)
            %readimage Read a specified pixel label data file from the datastore.
            %   C = readimage(pxds,k) reads the k-th file from pxds.
            %   By default, C is a categorical matrix where each element
            %   C(i,j) defines a categorical label.               
            %
            %   [C, info] = readimage(pxds, k) also returns a structure with
            %   additional information about C. The fields of info are:
            %      Filename - Name of the file from which the data was read
            %      FileSize - Size of the file in bytes
            %                  
            % Example
            % -------
            %   % Location of image and pixel label data
            %   dataDir = fullfile(toolboxdir('vision'), 'visiondata');          
            %   pxDir = fullfile(dataDir, 'buildingPixelLabels');                       
            %
            %   % Create pixel label datastore.
            %   classNames = ["sky" "grass" "building" "sidewalk"];
            %   pixelLabelID = [1 2 3 4];
            %   pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %          
            %   C = readimage(pxds,2);
            %             
            %   rgb = label2rgb(I, uint8(C));
            %   figure
            %   imshow(rgb)
            
            validateattributes(i, {'numeric'},...
                {'vector', 'positive', '<=', numel(this.ImageDatastore.Files)}, ...
                mfilename, 'i')
            
            if isscalar(i)
                % Call readimage on imds. This calls either the default ReadFcn
                % or a custom one.
                [C, info] = readimage(this.ImageDatastore,i);
                
                if this.UsingDefaultReadFcn
                    C = this.label2categorical(C, info);
                else
                    % The custom reader is responsible for converting image
                    % data to a categorical. Check that the result is a
                    % categorical and has the expected categories.
                    this.validateCategorical(C);
                end
                
                if nargout == 2
                    info = rmfield(info, 'Label');
                end
            else
                % Create datastore partition via a copy and index. This is
                % faster than constructing a new datastore with the new
                % files.
                subds = copy(this.ImageDatastore);
                subds.Files = this.ImageDatastore.Files(i);
                subds.Labels = this.ImageDatastore.Labels(i);
                C = readall(subds);
                
                info.Label = subds.Labels;
                if this.UsingDefaultReadFcn
                    C = this.label2categorical(C, info);
                else
                    % The custom reader is responsible for converting image
                    % data to a categorical. Check that the result is a
                    % categorical and has the expected categories.
                    this.validateCategorical(C);
                end
               
            end
        end
        
        %------------------------------------------------------------------
        function reset(this)
            %reset Rest the datastore to the start of the data.
            %   reset(pxds) resets pxds to the beginning of the datastore.
            %
            % Example
            % -------
            % % Location of image and pixel label data
            % dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            % pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            % % Create pixel label datastore.
            % classNames = ["sky" "grass" "building" "sidewalk"];
            % pixelLabelID = [1 2 3 4];
            % pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %
            % while hasdata(pxds)
            %     C = read(pxds);             % Read data
            %     rgb = label2rgb(uint8(C));  % Convert pixel labels to RGB image.
            %     imshow(rgb);                % See images in a loop.
            %     pause(1)                    % Pause between images.
            % end
            % reset(pxds);                    % Reset to beginning.
            % C = read(pxds);                 % Read from the beginning.
            
            this.ImageDatastore.reset();
        end
        
        %------------------------------------------------------------------
        function shuffle(this, ord)
            labels = this.ImageDatastore.Labels;
            this.ImageDatastore.Files  = this.ImageDatastore.Files(ord);
            this.ImageDatastore.Labels = labels(ord);
        end
        
        %------------------------------------------------------------------
        function files = get.Files(this)
            files = this.ImageDatastore.Files;
        end
        
        %------------------------------------------------------------------
        function set.Files(~, ~)
            % Setting the Files will invalidate LabelDefinitions.
            error(message('vision:semanticseg:pxdsFilesNotSettable'));
        end
        
        %------------------------------------------------------------------
        function sz = get.ReadSize(this)
            sz = this.ImageDatastore.ReadSize;
        end
        
        %------------------------------------------------------------------
        function set.ReadSize(this, sz)
            this.ImageDatastore.ReadSize = sz;
        end
        
        %------------------------------------------------------------------
        function names = get.ClassNames(this)
            names = this.LabelDefinitions{1}.Name;
        end
        
        %------------------------------------------------------------------
        function s = saveobj(this)
            s.ImageDatastore   = saveobj(this.ImageDatastore);
            s.LabelDefinitions = this.LabelDefinitions;
            s.CategoricalCache = this.CategoricalCache;
            s.Version          = 1;
        end

        %------------------------------------------------------------------
        function tbl = countEachLabel(this)
            %countEachLabel Counts the number of pixel labels for each class.
            %
            % tbl = countEachLabel(pxds) counts the occurrence of each
            % pixel label for all images represented by pxds. The output
            % tbl is a table with the following variables names:
            %
            %   Name            - The pixel label class name.
            %
            %   PixelCount      - The number of pixels of a given class.
            %
            %   ImagePixelCount - The total number of pixels in images that
            %                     had an instance of the given class.
            %
            % Class Balancing
            % ---------------
            % The output of countEachLabel can be used to calculate class
            % weights for class balancing, for example:
            %
            %   * Uniform class balancing weights each class such that each
            %     has a uniform prior probability:
            %
            %        numClasses = height(tbl)
            %        prior = 1/numClasses;
            %        classWeights = prior./tbl.PixelCount
            %
            %   * Inverse frequency balancing weights each class such that
            %     underrepresented classes are given higher weight:
            %
            %        totalNumberOfPixels = sum(tbl.PixelCount)
            %        frequency = tbl.PixelCount / totalNumberOfPixels;
            %        classWeights = 1./frequency
            %
            %   * Median frequency balancing weights each class using the
            %     median frequency. The weight for each class c is defined
            %     as median(imageFreq)/imageFreq(c) where imageFreq(c) is
            %     the number of pixels of a given class divided by the
            %     total number of pixels in images that had a instance of
            %     the given class c.
            %
            %        imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount
            %        classWeights = median(imageFreq) ./ imageFreq
            %
            % The calculated class weights can be passed to the
            % pixelClassificationLayer. See example below.
            %
            % Example
            % --------
            % % Setup of data location.
            % dataDir = fullfile(toolboxdir('vision'), 'visiondata');
            % imDir = fullfile(dataDir, 'building');
            % pxDir = fullfile(dataDir, 'buildingPixelLabels');
            %
            % % Create pixel label datastore.
            % classNames = ["sky" "grass" "building" "sidewalk"];
            % pixelLabelID = [1 2 3 4];
            % pxds = pixelLabelDatastore(pxDir, classNames, pixelLabelID);
            %
            % % Tabulate pixel label counts in dataset.
            % tbl = countEachLabel(pxds)
            %
            % % Class balancing using uniform prior weighting.
            % prior = 1/numel(classNames);
            % uniformClassWeights = prior./tbl.PixelCount
            %
            % % Class balancing using inverse frequency weighting.
            % totalNumberOfPixels = sum(tbl.PixelCount);
            % frequency = tbl.PixelCount / totalNumberOfPixels;
            % invFreqClassWeights = 1./frequency
            %
            % % Class balancing using median frequency weighting.
            % freq = tbl.PixelCount ./ tbl.ImagePixelCount
            % medFreqClassWeights = median(freq) ./ freq
            %
            % % Pass the class weights to the pixel classification layer.
            % layer = pixelClassificationLayer('ClassNames', tbl.Name, ...
            %     'ClassWeights', medFreqClassWeights)
            %
            % See also pixelClassificationLayer, pixelLabelImageSource,
            %          imageDatastore.
        
            % Make a copy so we do not dirty the state.
            pxdsCopy = copy(this);
            pxdsCopy.reset();
            
            % Read in batches to improve performance.
            pxdsCopy.ReadSize = 64; 
            
            counts = zeros(1,numel(this.ClassNames));
            N      = zeros(1,numel(this.ClassNames));
            while hasdata(pxdsCopy)
                C = read(pxdsCopy);
                if ~iscell(C)
                    C = {C};
                end
                for i = 1:numel(C)
                    countMatrix = countcats(C{i});
                    
                    tmp = sum(countMatrix,2)';
                    counts = counts + tmp;
                    
                    Q = repelem(numel(C{i}), 1, numel(this.ClassNames));
                    idx = find(tmp > 0);
                    
                    % accumulate number of total pixels in images that have
                    % class idx
                    N(idx) = N(idx) + Q(idx);
                    
                end
            end                     
            
            tbl = table();
            tbl.Name            = this.ClassNames;
            tbl.PixelCount      = counts';
            tbl.ImagePixelCount = N';            
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        % Hidden method used for resizing label matrices in
        % pixelLabelImageSource.
        function C = resizeRead(this, outputSize)
            [L, info] = read(this.ImageDatastore);
            
            if iscell(L)
                L = cellfun(...
                    @(x)matlab.io.datastore.PixelLabelDatastore.resizeLabelMatrix(x, outputSize), ...
                    L, 'UniformOutput', false);
            else
                L = matlab.io.datastore.PixelLabelDatastore.resizeLabelMatrix(L, outputSize);
            end
            C = this.label2categorical(L, info);
        end
        
        %------------------------------------------------------------------
        % Hidden method used for reading just the data. 
        function [L,info] = readNumeric(this, indices)
            if nargin == 1
                [L,info] = read(this.ImageDatastore);
            else
                % Create datastore partition via a copy and index. This is
                % faster than constructing a new datastore with the new
                % files.
                subds = copy(this.ImageDatastore);
                subds.Files = this.ImageDatastore.Files(indices);
                subds.Labels = this.ImageDatastore.Labels(indices);
                L = readall(subds);
                info.Label = subds.Labels;
            end
        end
        
        %------------------------------------------------------------------
        % Hidden method used to remove files. Used in datasource
        % distribute.
        function removeFiles(this, toRemove)
            this.ImageDatastore.Files(toRemove) = [];
        end
        
        %------------------------------------------------------------------
        function C = label2categorical(this, L, info)
            if ~iscell(L)
                % When only 1, datastore returns numeric result.
                L = {L};
            end
            
            C = cell(numel(L), 1);
            
            for i = 1:numel(L)
                C{i} = matlab.io.datastore.PixelLabelDatastore.label2cat(...
                    L{i}, this.CategoricalCache{info.Label(i)});
            end
            
            if numel(C) == 1
                % return array if only 1 image.
                C = C{1};
            end
        end
        
    end
    
    methods(Hidden, Static)
        %------------------------------------------------------------------
        function this = loadobj(s)
            imds = matlab.io.datastore.ImageDatastore.loadobj(s.ImageDatastore);
            this = matlab.io.datastore.PixelLabelDatastore(imds, s.LabelDefinitions, s.CategoricalCache);
        end
        
        %------------------------------------------------------------------
        function c = labeldef2cat(labeldef)
            % convert label definition table into categorical.
            classset = labeldef.Name;
            valueset = labeldef.PixelLabelID;
            classes = cell(numel(classset),1);
            
            isRGBPixelLabelID = size(valueset{1},2) == 3;
            if isRGBPixelLabelID
                % RGB label matrix
                valueset = matlab.io.datastore.PixelLabelDatastore.rgb2labelID(valueset);
                
                % create a 24-bit look-up table (24 bits are all that's
                % required to store 3 uint8 pixel values). This consumes 64
                % MB, but allows for fast label to categorical conversion.
                L = uint32(0):uint32(2^24-1); 
            else
                L = uint8(0):uint8(255);
            end
            
            % replicate class names for each value
            for j = 1:numel(valueset)
                values = valueset{j};
                classes(j) = {repelem(classset(j), numel(values), 1)};
            end
            
            valueset = vertcat(valueset{:});
            classes  = vertcat(classes{:});
            
            c = categorical(L, valueset, classes);
            
        end
        
        %------------------------------------------------------------------
        function C = label2cat(L, categoricalCache)
            % Convert a label matrix into a categorical.
           
            if size(L,3) == 3
                % RGB label matrix
                L = matlab.io.datastore.PixelLabelDatastore.rgb2labelmatrix(L);
                C = categoricalCache(uint32(L)+1);
            else
                % index into cache. use uint16 to avoid overflow w/ uint8.
                C = categoricalCache(uint16(L)+1);
            end
          
        end
        
        %------------------------------------------------------------------
        function L = rgb2labelmatrix(rgb)
            % convert input rgb label matrix to single channel label matrix
            rgb = uint32(rgb);
            rgb(:,:,1) = bitshift(rgb(:,:,1), 16);
            rgb(:,:,2) = bitshift(rgb(:,:,2), 8);
            
            L = bitor( bitor(rgb(:,:,1), rgb(:,:,2)), rgb(:,:,3) );
        end
        
        %------------------------------------------------------------------
        function v = rgb2labelID(rgb)
            % rgb is cell array of M-by-3 matrices. output is cell array of
            % N-by-1 vectors.
            v = cell(numel(rgb), 1);
            for i = 1:numel(rgb)
                
                m = uint32(rgb{i});
                
                % pack uint8 RGB values into uint32 by bit shifting R and B
                % pixel vals.
                m(:,1) = bitshift(m(:,1), 16);
                m(:,2) = bitshift(m(:,2), 8);
                
                v{i} = bitor( bitor(m(:,1), m(:,2)), m(:,3) );
            end
        end
        
        %------------------------------------------------------------------
        function limds = create(location, classes, values, params)
            % limds = create(files, classes, values) returns a
            % PixelLabelDatastore provided a cellstr of filenames
            assert(iscellstr(classes));
            assert(iscell(values));
            labelDefinitions = table(...
                reshape(classes,[],1), ...
                reshape(values,[],1), ...
                'VariableNames', {'Name', 'PixelLabelID'});
            labelDefAssignments = 1;
            limds = matlab.io.datastore.PixelLabelDatastore(...
                location, labelDefinitions, labelDefAssignments, params);
        end
        
        %------------------------------------------------------------------
        function [limds, imds] = createFromGroundTruth(gTruthArray, params)
            % limds = createFromGroundTruth(gTruthArray) returns a
            % PixelLabelDatastore for reading pixel labeled images.
            %
            %  C = read(limds) returns categorical matrix representing the
            %  pixel label data.
            
            src = {};
            
            labelDefAssignments = [];
            numGroundTruth = numel(gTruthArray);
            labelDefinitions = cell(numGroundTruth,1);
            
            % extract all label definition tables.
            for i = 1:numGroundTruth
                % strip out Type column and only keep labelType.PixelLabel
                defs = gTruthArray(i).LabelDefinitions;
                defs(gTruthArray(i).LabelDefinitions.Type ~= labelType.PixelLabel, :) = [];
                defs(:,2) = [];
                labelDefinitions{i} = defs;
            end
            
            % Fill label def assignments. This maps each file to a label
            % definition table. Required if we shuffle all files to find a
            % files label definition table.
            for i = 1:numGroundTruth
                tmp = gTruthArray(i).LabelData.PixelLabelData;
                
                src = [src; tmp]; %#ok<AGROW>
                
                labelDefAssignments = [labelDefAssignments; repelem(i, numel(tmp),1)]; %#ok<AGROW>
                
            end
            
            % remove for missing labels
            missing = strcmp('', src);
            src(missing) = [];
            labelDefAssignments(missing) = [];
            
            % store which groundTruth object corresponds to each image as a Label in
            % the imageDatastore. This is a simple way to map a specific image to it's
            % corresponding groundTruth object.
            limds = matlab.io.datastore.PixelLabelDatastore(src, labelDefinitions, labelDefAssignments, params);
            
            if nargout == 2
                % Construct image datastore to hold groundTruth data source
                isrc = {};
                for i = 1:numGroundTruth
                    isrc = [isrc; gTruthArray(i).DataSource.Source]; %#ok<AGROW>
                end
                
                % remove images that don't have labels.
                isrc(missing) = [];
                
                imds = imageDatastore(isrc);
            end
        end
        
        %------------------------------------------------------------------
        function isDefault = isDefaultReadFcn(readFcn)
            % check if default.
            fcnInfo = functions(readFcn);
            pvtFile = fullfile(fileparts(mfilename('fullpath')), 'private', 'readDatastoreImage.m');
            tf = isfield(fcnInfo, 'file') && isequal(fcnInfo.file, pvtFile);
            isDefault = tf && isfield(fcnInfo, 'parentage') && isequal(fcnInfo.parentage, {'readDatastoreImage'});
        end
        
        %------------------------------------------------------------------
        function imOut = resizeLabelMatrix(L,outputSize)
           
            ippResizeSupportedWithCast = isa(L,'int8') || isa(L,'uint16') || isa(L,'int16');
            ippResizeSupportedForType = isa(L,'uint8') || isa(L,'single');
            ippResizeSupported = ippResizeSupportedWithCast || ippResizeSupportedForType;
                            
            if ippResizeSupportedWithCast
                L = single(L);
            end
            
            if ippResizeSupported
                imOut = nnet.internal.cnnhost.resizeImage2D(L,outputSize,'nearest',false);
            else
                imOut = imresize(L,'OutputSize',outputSize,'method','nearest','Antialias',false);
            end
            
        end
    end
end
