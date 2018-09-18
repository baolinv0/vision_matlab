%groundTruth Object for storing ground truth labels
%
%   groundTruth is used to store ground truth labels for a collection of
%   images, a video, a sequence of images, or a custom data source.
%
%   gTruth = groundTruth(dataSource, labelDefs, labelData) returns gTruth,
%   an object containing ground truth labels. dataSource is a
%   groundTruthDataSource object describing a collection of images, video,
%   image sequence, or custom data source. labelDefs is a table as
%   described in the LabelDefinitions property below. labelData is a table
%   or timetable of label data as described in the LabelData property
%   below.
%
%   groundTruth properties:
%   DataSource          - A <a href="matlab:help('groundTruthDataSource')">groundTruthDataSource</a> object. 
%
%   LabelDefinitions    - A table of definitions for ROI and Scene label
%                         categories containing two to four columns: Name,
%                         Type, PixelLabelID, and Description (optional).
%                         * Name is a character vector specifying the name
%                           of the label category.
%                         * Type is a labelType enumeration specifying the
%                           type of label category.
%                         * PixelLabelID specifies the pixel label values
%                           used to represent a label category.
%                           PixelLabelID is required when any Type is
%                           labelType.PixelLabel. PixelLabelID values must
%                           be a scalar, column vector, or M-by-3 matrix of
%                           integer valued label IDs. 
%                         * Description is a character vector describing
%                           the label category.
%
%                         For example, a label definition table with 3 label
%                         categories:
%
%                          Name        Type       PixelLabelID
%                         ______    __________    ____________
%
%                         'Cars'    Rectangle     []          
%                         'Lane'    Line          []          
%                         'Road'    PixelLabel    [3] 
%
%                         LabelDefinitions is read-only.
%
%   LabelData           - Label data for each ROI and Scene label organized
%                         in a table or timetable. Each column holds labels
%                         for Rectangle, Line, or Scene labels for a single
%                         label category. For PixelLabel labels, a single
%                         column named 'PixelLabelData' is used to hold the
%                         label data for all label categories of
%                         labelType.PixelLabel. 
%
%                         The table has as many rows as there are images or
%                         timestamps in the data source. LabelData is a
%                         timetable when Source is a groundTruthDataSource
%                         with timestamps. Otherwise it is a table.
%                         LabelData is read-only.
%
%                         The label type determines the storage format of
%                         label data:
%
%                         labelType.Rectangle
%                         -------------------
%                         Labels in each row are stored as M-by-4
%                         matrices of [x, y, width, height] bounding box
%                         locations.
%
%                         labelType.Line
%                         --------------
%                         Labels in each row are stored as M-by-1 cell
%                         arrays. Each element of the cell array holds
%                         [x, y] locations for points used to mark the
%                         polyline.
%
%                         labelType.PixelLabel
%                         --------------------
%                         Pixel label data for all label categories is
%                         represented by a single label matrix. The label
%                         matrix must be stored on disk as an uint8 image,
%                         and the image filename must be specified as a
%                         character vector in the LabelData table. The
%                         label matrix must have 1 or 3 channels. For a
%                         3-channel label matrix, the RGB pixel values
%                         represent label IDs.
%
%                         labelType.Scene
%                         ---------------
%                         Labels are stored as logical values representing
%                         presence or absence of the scene label.
%
%                         labelType.Custom
%                         ----------------
%                         Labels are stored as provided in the table.                       
%
%   groundTruth methods:
%   selectLabels        - Return groundTruth object for selected labels.
%
%   Notes
%   -----
%   - Use VideoReader, imageDatastore, or custom reader function to access
%     images from the original data source.
%   - groundTruth created using a video data source is guaranteed to remain
%     consistent only for the same computer platform since it relies on 
%     video reading capabilities of the Operating System. If cross-platform  
%     use is required convert the video into a sequence of image files with
%     associated time stamps.
%   - Ground truth data that is not an ROI (Rectangle, Line, PixelLabel) or
%     Scene label can be added to groundTruth by providing a label
%     definition whose labelType is Custom.
%   - Create training data for an object detector from arrays of
%     groundTruth objects using the <a href="matlab:help('objectDetectorTrainingData')">objectDetectorTrainingData</a> function.
%   
%   Example 1: Create ground truth for stop signs and cars
%   ------------------------------------------------------
%   % Create a data source from a collection of images
%   data = load('stopSignsAndCars.mat');
%   imageFilenames = data.stopSignsAndCars.imageFilename(1:2)
%   imageFilenames = fullfile(toolboxdir('vision'), 'visiondata', imageFilenames);
%   dataSource = groundTruthDataSource(imageFilenames);
%     
%   % Define labels used to specify ground truth
%   names = {'stopSign'; 'carRear'};
%   types = [
%       labelType('Rectangle')
%       labelType('Rectangle')
%       ];
% 
%   labelDefs = table(names, types, 'VariableNames', {'Name', 'Type'})
% 
%   % Initialize label data for rectangle ROIs.
%   numRows = numel(imageFilenames);
%   stopSignTruth = {[856   318    39    41]; [445   523    52    54]};
%   carRearTruth = {[398   378   315   210]; [332   633   691   287]};
% 
%   % Construct table of label data
%   labelData = table(stopSignTruth, carRearTruth, 'VariableNames', names)
% 
%   % Create groundTruth object.
%   gTruth = groundTruth(dataSource, labelDefs, labelData)
%
%   Example 2: Create ground truth for lanes
%   ----------------------------------------
%   % Create a data source from video
%   dataSource = groundTruthDataSource({'stopSignTest.jpg'});
%
%   % Define labels used to specify ground truth
%   names = {'Lane'};
%   types = [labelType('Line')];
%   labelDefs = table(names, types, 'VariableNames', {'Name', 'Type'})
%
%   % 2 lane markers to the first frame.
%   laneMarkerTruth{1} = {[257 254;311 180] [327 183;338 205;374 250]};
%
%   % Construct table of label data
%   labelData = table(laneMarkerTruth, 'VariableNames', names)
%
%   % Create groundTruth object
%   gTruth = groundTruth(dataSource, labelDefs, labelData)
%
%   Example 3: Create ground truth for pixel labels
%   -----------------------------------------------
%   % Create data source
%   dataSource = groundTruthDataSource({'visionteam.jpg'});
%   
%   % Define pixel labels for Person and Background.
%   names = {'Person';'Background'};
%   types = [labelType('PixelLabel'); labelType('PixelLabel')];
%
%   % Define pixel label IDs. Label IDs 1 and 2 correspond to Person and
%   % Background, respectively.
%   pixelLabelID = {1; 2};
%
%   labelDefs = table(names, types, pixelLabelID, ...
%                     'VariableNames', {'Name', 'Type', 'PixelLabelID'})
%
%   % Specify location of pixel label data for visionteam.jpg
%   dataFile = {'pixelLabeledVisionTeam.jpg'}
%   
%   % Construct table of label data for pixel label data
%   labelData = table(dataFile, 'VariableNames', {'PixelLabelData'})
%
%   % Create groundTruth object
%   gTruth = groundTruth(dataSource, labelDefs, labelData)
%   
%   See also groundTruthDataSource, labelType, objectDetectorTrainingData, 
%            timetable.

% Copyright 2016-2017 The MathWorks, Inc.

classdef groundTruth < handle
    
    properties (Dependent)
        %DataSource Data source specifies as a groundTruthDataSource object
        %   A groundTruthDataSource object describing the video file, image
        %   sequence  or custom data source for the ground truth data.
        DataSource
    end
    
    properties (SetAccess = private, GetAccess = public)
        %LabelDefinitions Table of label definitions
        %   A table of definitions for ROI and Scene label categories
        %   containing two to four columns: Name, Type, PixelLabelID, and
        %   Description (optional). Name is a character vector specifying
        %   the name of the label category. Type is a labelType enumeration
        %   specifying the type of label category. PixelLabelID specifies
        %   the pixel label values used to represent a label category.
        %   PixelLabelID is required when any Type is labelType.PixelLabel.
        %   Description is a character vector describing the label
        %   category. LabelDefinitions is read-only.
        LabelDefinitions
        
        %LabelData A table or timetable of label data
        %   A table or timetable of label data with each column containing
        %   labels for a single label category. LabelData is a timetable
        %   when the data source has timestamps. Otherwise it is a table.
        %   The height of LabelData table is the number of timestamps or
        %   images in the data source. The width is equal to the number of
        %   label categories defined in LabelDefinitions when there are no
        %   labelType.PixelLabel label types. When a labelType.PixelLabel
        %   type is present, the width of LabelData is the number of
        %   non-pixel-label type labels plus 1.
        LabelData
    end
    
    properties (Access = protected, Hidden)
        %Version
        %   Version number to allow compatible load and save.
        Version = ver('vision');
    end
    
    properties (Access = private)
        %DSource Private container for DataSource.
        DSource
    end
    
    properties(Access = private, Dependent)
        %SourceType The type of datasource.
        SourceType
    end
    
    methods
        %------------------------------------------------------------------
        function this = groundTruth(dataSource, labelDefs, labelData)
            
            this.DataSource         = dataSource;
            this.LabelDefinitions   = vision.internal.labeler.validation.checkLabelDefinitions(labelDefs);
            this.LabelData          = vision.internal.labeler.validation.checkLabelData(labelData, this.DataSource, this.LabelDefinitions);
        end
        
        %------------------------------------------------------------------
        function gTruth = selectLabels(this, labels)
            %selectLabels Select ground truth data for a set of labels.
            %   gtLabel = selectLabels(gTruth, labelNames) returns a new
            %   groundTruth object with only the labels specified by
            %   labelNames. labelNames can be a cell array of character
            %   vectors.
            %
            %   gtLabel = selectLabels(gTruth, types) returns a new
            %   groundTruth object with all labels of type labelType.
            %   types is a labelType enumeration.
            
            % Handle array indexing for this method
            if numel(this)>1
                for n = 1 : numel(this)
                    gTruth(n) = selectLabels(this(n), labels); %#ok<AGROW>
                end
                return;
            end
            
            % Validate input and convert to label names.
            labelNames = validateLabelNameOrType(this, labels);
            
            % Find column indices into LabelData.
            indexList = labelName2Index(this, labelNames);
            
            % Construct groundTruth object with selected labels.
            dataSource  = this.DataSource;
            labelDefs   = this.LabelDefinitions(indexList,:);
            labelData   = this.LabelData(:, labelNames);
            gTruth = groundTruth(dataSource, labelDefs, labelData);
        end
        
        %------------------------------------------------------------------
        function set.DataSource(this, dataSource)
            dataSource = validateDataSource(this, dataSource);
            
            % dataSource can be empty if the groundTruth object was loaded
            % from a source that could not be found. 
            % LabelData can be empty if the object is being constructed
            % on load and the LabelData isn't set up yet.
            if ~isempty(dataSource) && ~isempty(this.LabelData) && hasTimeStamps(dataSource)
                vision.internal.labeler.validation.checkTimes(this.LabelData, dataSource);
                
                % Ensure that source times match exactly with dataSource.
                % Across platforms, videos may provide slightly different
                % time stamps. In that case, modify labelData to use row
                % times from the source.
                this.LabelData.Time = dataSource.TimeStamps;
            end               

            
            this.DSource = dataSource;
            
        end
        
        %------------------------------------------------------------------
        function dataSource = get.DataSource(this)
            dataSource = this.DSource;
        end
        
        %------------------------------------------------------------------
        function type = get.SourceType(this)
            type = this.DSource.SourceType;
        end
    end
    
    methods (Hidden)
        %------------------------------------------------------------------
        % saveobj is implemented to ensure compatibility across releases by
        % converting the class to a struct prior to saving it. It also
        % contains a version number, which can be used to customize the
        % loading process.
        %------------------------------------------------------------------
        function that = saveobj(this)
            
            that.DataSource         = saveobj(this.DataSource);
            that.LabelDefinitions   = table2struct(this.LabelDefinitions);
            if hasTimeStamps(this.DataSource)
                that.LabelData = table2struct(timetable2table(this.LabelData));
            else
                that.LabelData = table2struct(this.LabelData);
            end
            
            that.Version   = this.Version;
        end
    end
    
    methods (Hidden, Static)
        %------------------------------------------------------------------
        function this = loadobj(that)
            
            that = updatePreviousVersion(that);
            
            % Use the new enum type as the SourceType.
            switch that.DataSource.SourceType
                case "VideoReader"
                    that.SourceType = vision.internal.labeler.DataSourceType.VideoReader;
                case "ImageSequence"
                    that.SourceType = vision.internal.labeler.DataSourceType.ImageSequence;
                case "CustomReader"
                    that.SourceType = vision.internal.labeler.DataSourceType.CustomReader;
                case "ImageDatastore"
                    that.SourceType = vision.internal.labeler.DataSourceType.ImageDatastore;
                otherwise
                    error('Unknown source');
            end
                                   
            % First load label definitions and label data.
            labelDefs = struct2table(that.LabelDefinitions, 'AsArray', true);
            if isfield(that.LabelDefinitions, 'PixelLabelID')
                % struct2table puts scalars as numeric scalars into table,
                % whereas we expect PixelLabelID to be cell arrays. Convert
                % to cell if required.
                if ~iscell(labelDefs.PixelLabelID)
                    labelDefs.PixelLabelID = num2cell(labelDefs.PixelLabelID);
                end
            end
            labelData = struct2table(that.LabelData, 'AsArray', true);
            if that.SourceType ~= vision.internal.labeler.DataSourceType.ImageDatastore
                labelData  = table2timetable(labelData);
            end
           
            if any(labelDefs.Type == labelType.PixelLabel)
                % Try to locate pixel label data files.
                labelData.PixelLabelData = tryToAdjustFilePaths(labelData.PixelLabelData);
            end
            
            % Try to find the source on the file system.
            try               
                
                if isequal(that.SourceType, vision.internal.labeler.DataSourceType.ImageSequence)
                    
                    % We don't know the exact location of the MAT-file.
                    % Assume pwd and try searching the file system for the
                    % path.
                    that.DataSource.Source = tryToAdjustFilePaths(that.DataSource.Source);
                    
                elseif isequal(that.SourceType, vision.internal.labeler.DataSourceType.VideoReader)
                    % We don't know the exact location of the MAT-file.
                    % Assume pwd and try searching the file system for the
                    % path.
                    pathName = pwd;
                    [~,fileName,ext] = fileparts(that.DataSource.Source);
                    fileName = strcat(fileName,ext);
                    absoluteFileName = fullfile(pathName, fileName);
                    that.DataSource.Source = vision.internal.uitools.tryToAdjustPath(that.DataSource.Source, pathName, absoluteFileName);
                   
                elseif isequal(that.SourceType, vision.internal.labeler.DataSourceType.ImageDatastore)
            
                    that.DataSource.Source = tryToAdjustFilePaths(that.DataSource.Source);
                else
                    % Custom Reader
                    % Don't do anything here. The custom data source name
                    % should not be modified. If a problem occurs, the
                    % groundTruthDataSource call below will issue an error.
                end
            catch
                    % Don't do anything here. If tryToAdjustPath issues an
                    % error, break out. checkIfSourceExists will issue the
                    % necessary warning.
            end
            
            % Check if sources exist, warn if they don't.
            isOnPath = groundTruth.checkIfSourceExists(that);
          
            if isOnPath
                
                try
                    dataSource = groundTruthDataSource.loadobj(that.DataSource);
                catch ME
                    % Create a "broken" object that needs to be modified by
                    % the user.
                    this = groundTruth([], labelDefs, labelData);
                    warning(ME.message);
                    return;
                end
                
                this = groundTruth(dataSource, labelDefs, labelData);
            else
                
                % Create a "broken" object that needs to be modified by the
                % user.
                this = groundTruth([], labelDefs, labelData);
                
            end
        end
    end
    
    methods (Access = private, Static)
        %------------------------------------------------------------------
        function isOnPath = checkIfSourceExists(that)
            
            if isempty(that.DataSource)
                isOnPath = false;
                return;
            end
            
            if isequal(that.SourceType, vision.internal.labeler.DataSourceType.ImageSequence)
                % Check that each file in the list of image names exists.
                sourceName = that.DataSource.Source;
                fileOnPathIndices = cellfun(@(fName)exist(fName,'file')==2,sourceName);
                isOnPath = all(fileOnPathIndices);
                
                % If not provide a warning...
                if ~isOnPath
                    dirName = fileparts(sourceName{1});
                    isDirOnPath = exist(dirName, 'dir');
                    
                    if ~isDirOnPath
                        % that either the directory cannot be found,
                        warning(message('vision:groundTruth:badImageDirSource', dirName))
                    else
                        % or that one or more images cannot be found.
                        warning(message('vision:groundTruth:badImageNameSource', dirName))
                    end
                end
            elseif isequal(that.SourceType, vision.internal.labeler.DataSourceType.VideoReader)
                sourceName = that.DataSource.Source;
                isOnPath = exist(sourceName,'file')==2;
                if ~isOnPath
                    warning(message('vision:groundTruth:badVideoSource', sourceName))
                end
            elseif isequal(that.SourceType, vision.internal.labeler.DataSourceType.ImageDatastore)
                % Check that each file in the list of image names exists.
                isOnPath = checkFilenames(that.DataSource.Source);
            else
                % Custom Reader 
                % Assume that the custom data source is on path. If not, we
                % will error out later.
                isOnPath = true;
            end
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function dataSource = validateDataSource(~, dataSource)
            
            %dataSource must be a groundTruthDataSource object or empty.
            if ~isempty(dataSource)
                
                validateattributes(dataSource, ...
                    {'groundTruthDataSource'}, {'scalar'}, 'groundTruth');
                
            end
            
        end
        
        %------------------------------------------------------------------
        function labels = validateLabelNameOrType(this, labels)
            
            validateattributes(labels, ...
                {'char', 'string', 'cell', 'labelType'}, ...
                {'nonempty','vector'}, mfilename, 'label names or types');
            
            if isstring(labels) || ischar(labels)
                labels = cellstr(labels);
            end
            
            if ~(iscellstr(labels) || isa(labels, 'labelType'))
                error(message('vision:groundTruth:invalidLabelSpecification'))
            end
            
            if isa(labels, 'labelType') && ~isscalar(labels)
                error(message('vision:groundTruth:invalidLabelSpecification'))
            end
            
            allLabelNames = this.LabelDefinitions.Name;
            
            if isa(labels, 'labelType')
                labType = labels;
                labels = allLabelNames( this.LabelDefinitions.Type == labType );
                if isempty(labels)
                    error(message('vision:groundTruth:typeNotPresent', char(labType)))
                end
            end
            
            % Expect the list of labels provided to be unique
            labels = unique(labels);
        end
        
        %------------------------------------------------------------------
        function indexList = labelName2Index(this, labelNames)
            
            allLabelNames = this.LabelDefinitions.Name;
            
            % Find column indices into LabelData.
            indexList = zeros(numel(labelNames),1);
            for n = 1 : numel(labelNames)
                idx = find( strcmp(allLabelNames, labelNames{n}) );
                if ~isscalar(idx)
                    error(message('vision:groundTruth:labelNotFound',labelNames{n}))
                end
                indexList(n) = idx;
            end
        end
    end
end

%--------------------------------------------------------------------------
function that = updatePreviousVersion(that)
% 17a version in ADST did not have SourceType property. Add it using new
% class type.
if strcmp(that.Version.Version, '1.0')
    if isa(that.DataSource.SourceType, 'driving.internal.videoLabeler.DataSourceType')
        % ADST is installed
        type = string(that.DataSource.SourceType);
    else
        % ADST not installed. In this case ValueNames contains the enum type.
        type = string(that.DataSource.SourceType.ValueNames{1});
    end
    
    that.DataSource.SourceType = type;
end
end

%--------------------------------------------------------------------------
function isOnPath = checkFilenames(sourceName)
% check if files exist.
fileOnPathIndices = cellfun(@(fName)exist(fName,'file')==2,sourceName);
isOnPath = all(fileOnPathIndices);

% If not provide a warning...
if ~isOnPath
    error(message('vision:groundTruth:badImageFiles'));
end
end

%--------------------------------------------------------------------------
function newSource = tryToAdjustFilePaths(newSource)
% try to adjust the path for a list of sources
pathName  = pwd;
for i = 1:numel(newSource)
    
    % fileparts only works if the file separators are
    % correct for the specific platform
    newSourceName = regexprep(newSource{i}, '[\\/]',filesep);
    [~,fileName,ext] = fileparts(newSourceName);
    
    fileName = strcat(fileName,ext);
    absoluteFileName = fullfile(pathName, fileName);
    newSource{i} = vision.internal.uitools.tryToAdjustPath(newSource{i}, pathName, absoluteFileName);
    
end
end
