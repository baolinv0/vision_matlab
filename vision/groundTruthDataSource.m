classdef groundTruthDataSource < vision.internal.EnforceScalarHandle & matlab.mixin.CustomDisplay
    %groundTruthDataSource Create ground truth data source
    %   groundTruthDataSource creates a ground truth data source. Use
    %   this function to specify a data source for the <a
    %   href="matlab:help('groundTruth')">groundTruth</a> object.
    %
    %   gtSource = groundTruthDataSource(imageFiles) returns a
    %   groundTruthDataSource object for a collection of images specified
    %   in imageFiles. imageFiles is a cell array of image filenames
    %   specified as strings or character vectors.
    %
    %   gtSource = groundTruthDataSource(videoName) returns a
    %   groundTruthDataSource object from a video file. videoName is a
    %   string or character vector containing the name of the video file.
    %
    %   gtSource = groundTruthDataSource(imageSeqFolder) returns a
    %   groundTruthDataSource object for an image sequence. imageSeqFolder
    %   must be a scalar string or character vector specifying a folder
    %   containing image files. A time stamp of seconds(k) is automatically
    %   assigned to each image in the sequence, where k is the index of an
    %   image within the sequence.
    %
    %   gtSource = groundTruthDataSource(imageSeqFolder, timeStamps)
    %   returns a groundTruthDataSource object for an image sequence where
    %   each image is associated with a time stamp from timeStamps.
    %   timeStamps is a duration vector of the same length as the number of
    %   images in the sequence.
    %
    %   gtSource = groundTruthDataSource(sourceName, readerFcn, timeStamps)
    %   returns a groundTruthDataSource object with the custom reader
    %   function handle readerFcn used to load the custom data source
    %   sourceName associated with each timestamp from timeStamps. The
    %   custom reader function handle readerFcn loads an image from
    %   sourceName corresponding to the current timestamp currentTimeStamp
    %   from the timeStamps vector. It is expected to have the following
    %   syntax:
    %
    %   outputImage = readerFcn(sourceName, currentTimeStamp)
    %
    %   The output outputImage from the custom function must be a grayscale
    %   or true color image in any format supported by IMSHOW. timeStamps
    %   is a duration vector of length equal to the number of frames in the
    %   custom data source.
    %
    %   groundTruthDataSource properties:
    %       Source          - Video file name, image file names,
    %                         or custom data source names (read only)
    %       TimeStamps      - Duration vector of time stamps (read only)
    %
    %   Notes
    %   -----
    %   - Supported video file formats include all those supported by
    %     VideoReader. See <a href="matlab:help('VideoReader/getFileFormats')">VideoReader/getFileFormats</a> for the list of
    %     supported video file formats.
    %   - Supported image file formats include all those supported by
    %     imread. See <a href="matlab:help('imformats')">imformats</a> for the list of supported image file
    %     formats.
    %
    %   Example: Create data source from video file
    %   -------------------------------------------
    %   % Create a data source from video
    %   videoName = 'vipunmarkedroad.avi';
    %   dataSource = groundTruthDataSource(videoName)
    %
    %   % Create a VideoReader to read frames
    %   reader = VideoReader(videoName);
    %
    %   % Read the 5th frame in the video and display
    %   timeStamp = seconds(dataSource.TimeStamps(5));
    %   reader.CurrentTime = timeStamp;
    %   I = readFrame(reader);
    %   
    %   figure, imshow(I)
    %
    %   Example: Create a data source from image sequence
    %   -------------------------------------------------
    %   % Specify image directory containing sequence of images
    %   imageDir = fullfile(matlabroot, 'toolbox', 'vision',...
    %       'visiondata','building');
    %
    %   % Create data source for images in imageDir
    %   dataSource = groundTruthDataSource(imageDir)
    %
    %   % Read the 5th frame in the sequence
    %   I = imread(dataSource.Source{5});
    %
    %   figure, imshow(I)
    %
    %   Example: Create a data source using custom reader
    %   -------------------------------------------------
    %   % Specify image directory containing sequence of road images
    %   imageDir = fullfile(matlabroot, 'toolbox', 'vision',...
    %     'visiondata','building');
    %
    %   % Use an image data store as a custom data source
    %   imgDataStore = imageDatastore(imageDir);
    %
    %   % Write a reader function to read images from the data source. The
    %   % first input argument to readerFcn, sourceName is not used. The
    %   % 2nd input, currentTimeStamp is converted from a duration scalar
    %   % to a 1-based index suitable for the data source.
    %   readerFcn = @(~,idx)readimage(imgDataStore, seconds(idx));
    %
    %   % Create data source for images in imageDir using readerFcn
    %   dataSource = groundTruthDataSource(imageDir, readerFcn, 1:5)
    %
    %   % Read the 5th frame in the sequence
    %   I = readerFcn(imageDir, seconds(5));
    %
    %   figure, imshow(I)
    %
    %   See also groundTruth, imageLabeler, VideoReader, 
    %            imageDataStore, duration.
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties (SetAccess = private, GetAccess = public, Dependent)
        %Source 
        %   A character vector specifying video file name or custom data
        %   source name or a cell array of character vectors specifying
        %   image file names.
        Source
    end
    
    properties (SetAccess = private, GetAccess = public)
        %TimeStamps Vector of time stamps.
        %   A duration vector of time stamps. For a video file this is
        %   automatically populated to correspond to time stamps at which
        %   video frames are present. For an image collection, this is
        %   empty.
        TimeStamps   
    end
    
    properties (SetAccess = private, Hidden)
        %Reader Object to read from data source
        %   matlab.internal.VideoReader, vision.internal.labeler.ImageSequenceReader or vision.internal.labeler.CustomReader object.
        Reader         
    end
    
    properties (SetAccess = private, Hidden, Dependent)
        %SourceType Source type enumeration
        %   Enumeration for source type
        SourceType         
    end
    
    properties (Access = protected, Hidden)
        Version = ver('vision');
    end
    
    methods
        %------------------------------------------------------------------
        function this = groundTruthDataSource(varargin)
            
            parseAndPopulateInputs(this, varargin{:});
        end
        
        %------------------------------------------------------------------
        function source = get.Source(this)
            
            if isImageSequenceSource(this)
                source = this.Reader.Files;
            elseif isCustomSource(this)
                source = this.Reader.Name;
            elseif isVideoFileSource(this)
                source = fullfile(this.Reader.Path, this.Reader.Name);
            else
                source = this.Reader.Files;
            end
        end
        
        %------------------------------------------------------------------
        function sourceTypeEnum = get.SourceType(this)
            if isa(this.Reader, 'vision.internal.labeler.ImageSequenceReader')
                % Image sequence
                sourceTypeEnum = vision.internal.labeler.DataSourceType.ImageSequence;
            elseif isa(this.Reader,'vision.internal.labeler.CustomReader')
                % Custom Reader
                sourceTypeEnum = vision.internal.labeler.DataSourceType.CustomReader;
            elseif isa(this.Reader, 'matlab.internal.VideoReader')
                % Video Reader
                sourceTypeEnum = vision.internal.labeler.DataSourceType.VideoReader;
            else
                % Image Collection
                sourceTypeEnum = vision.internal.labeler.DataSourceType.ImageDatastore;
            end
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        function TF = isImageSequenceSource(this)
            TF = isequal(this.SourceType,vision.internal.labeler.DataSourceType.ImageSequence);
        end
        
        %------------------------------------------------------------------
        function TF = isVideoFileSource(this)
            TF = isequal(this.SourceType,vision.internal.labeler.DataSourceType.VideoReader);
        end
        
        %------------------------------------------------------------------
        function TF = isCustomSource(this)
            TF = isequal(this.SourceType,vision.internal.labeler.DataSourceType.CustomReader);
        end
        
        %------------------------------------------------------------------
        function TF = isImageCollection(this)
            TF = isequal(this.SourceType,vision.internal.labeler.DataSourceType.ImageDatastore);
        end
   
        %------------------------------------------------------------------
        % saveobj is implemented to ensure compatibility across releases by
        % converting the class to a struct prior to saving it. It also
        % contains a version number, which can be used to customize the
        % loading process.
        %------------------------------------------------------------------
        function that = saveobj(this)
            
            that.Source             = this.Source;
            that.TimeStamps         = this.TimeStamps;
            
            % Serialize enum as string.
            that.SourceType = string(this.SourceType);
            
            if isequal(this.SourceType, vision.internal.labeler.DataSourceType.CustomReader)
                %save the function handle for custom source
                that.Reader = this.Reader.Reader;
            end
            
            that.Version = this.Version;
        end
    end
    
    methods (Hidden, Static)
        %------------------------------------------------------------------
        function this = loadobj(that)
            
            if isequal(that.SourceType, string(vision.internal.labeler.DataSourceType.ImageSequence))
                % In 17b, cellstr for image sequences is no longer
                % supported. Use pathname to load saved object. This allows
                % to objects from 17a and beyond.
                [pathname, ~] = fileparts(that.Source{1});
                this = groundTruthDataSource(pathname, that.TimeStamps);
            elseif isequal(that.SourceType,string(vision.internal.labeler.DataSourceType.CustomReader))
                this = groundTruthDataSource(that.Source, that.Reader, that.TimeStamps);
            else
                this = groundTruthDataSource(that.Source);
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Custom Display Methods
    %----------------------------------------------------------------------
    methods (Access = protected)
        %------------------------------------------------------------------
        function displayScalarObject(this)
            
            % If the Reader does not exist, the object is not a valid
            % state. This happens if you load an object and don't have
            % access to the source anymore. When this happens, use the
            % default display.
            if isempty(this.Reader)
                displayScalarObject@matlab.mixin.CustomDisplay(this);
                return;
            end
            
            % Display header
            disp(getHeader(this))
            
            % Get source display
            if isImageSequenceSource(this)
                sourceDisp = getImageSequencePropertyDisplay(this);
            elseif isImageCollection(this)
                sourceDisp = getImageCollectionPropertyDisplay(this);
            else
                sourceDisp = getVideoPropertyDisplay(this);
            end
            
            if this.isImageCollection
                % Do not display timestamp
                alignAndDisplayNoTimestamps(this, sourceDisp);
            else
                % Get timestamp display
                timeStampDisp = getTimeStampDisplay(this);               
                alignAndDisplay(this, sourceDisp, timeStampDisp);
            end
            
            % Display footer
            disp(getFooter(this));
        end
        
        %------------------------------------------------------------------
        function sourceDisp = getImageCollectionPropertyDisplay(this) %#ok<MANU>
            
            % Grab imageDatastore file display.
            imdsDisp = evalc('disp(this.Reader)');
            imdsDisp = strsplit(imdsDisp, '\n');
            startLine = find(~cellfun(@isempty, strfind(imdsDisp, 'Files:')));
            stopLine  = find(~cellfun(@isempty, strfind(imdsDisp, '}')), 1);
            
            % Replace property name 'Files' with 'Source'.
            imdsDisp(startLine) = strrep(imdsDisp(startLine), ' Files:', 'Source:');
            
            sourceDisp = imdsDisp(startLine:stopLine);
        end
        
        %------------------------------------------------------------------
        function sourceDisp = getImageSequencePropertyDisplay(this) %#ok<MANU>
            
            % Grab imageDatastore file display.
            imdsDisp = evalc('disp(this.Reader.Reader)');
            imdsDisp = strsplit(imdsDisp, '\n');
            startLine = find(~cellfun(@isempty, strfind(imdsDisp, 'Files:')));
            stopLine  = find(~cellfun(@isempty, strfind(imdsDisp, '}')), 1);
            
            % Replace property name 'Files' with 'Source'.
            imdsDisp(startLine) = strrep(imdsDisp(startLine), ' Files:', 'Source:');
            
            sourceDisp = imdsDisp(startLine:stopLine);
        end
        
        %------------------------------------------------------------------
        function sourceDisp = getVideoPropertyDisplay(this)
            
            % Get source display from object details.
            detailsDisp = evalc('details(this)');
            detailsDisp = strsplit(detailsDisp, '\n');
            sourceDisp  = detailsDisp(~cellfun(@isempty, strfind(detailsDisp, 'Source:')));
            
            % If name is too long, clip from left and add ... so that file
            % name is visible
            nameStartInd = strfind(sourceDisp{1}, 'Source:') + numel('Source:') +1;
            vidName = this.Source;
            if nameStartInd+numel(vidName)>70
                lengthDiff = nameStartInd + numel(vidName) + 3 - 70;
                vidName(1:lengthDiff) = [];
                vidName = ['...' vidName];
            end
            sourceDispStr = sourceDisp{1};
            sourceDispStr(nameStartInd:end) = [];
            sourceDispStr = [sourceDispStr vidName];
            sourceDisp{1} = sourceDispStr;
        end
        
        %------------------------------------------------------------------
        function timeStampDisp = getTimeStampDisplay(this) %#ok<MANU>
            
            % Get timestamps display from object details.
            detailsDisp = evalc('details(this)');
            detailsDisp = strsplit(detailsDisp, '\n');
            timeStampDisp = detailsDisp(~cellfun(@isempty, strfind(detailsDisp, 'TimeStamps:')));
        end
        
        %------------------------------------------------------------------
        function alignAndDisplayNoTimestamps(~, sourceDisp)
            disp(strjoin(sourceDisp, '\n'))
        end
        
        %------------------------------------------------------------------
        function alignAndDisplay(~, sourceDisp, timeStampDisp)
            
            srcColonLocation = strfind(sourceDisp{1}, ':');
            srcColonLocation = srcColonLocation(1);
            
            tsColonLocation  = strfind(timeStampDisp{1}, ':');
            tsColonLocation  = tsColonLocation(1);
            
            if srcColonLocation < tsColonLocation
                srcNumIndent = tsColonLocation-srcColonLocation;
                srcIndent = repmat(' ', 1, srcNumIndent);
                sourceDisp = cellfun(@(x)[srcIndent x], sourceDisp, 'UniformOutput', false);
            else
                tsNumIndent = srcColonLocation-tsColonLocation;
                tsIndent = repmat(' ', 1, tsNumIndent);
                timeStampDisp = cellfun(@(x)[tsIndent x], timeStampDisp, 'UniformOutput', false);
            end
            
            disp(strjoin(sourceDisp, '\n'))
            disp(strjoin(timeStampDisp, '\n'))
        end
    end
    
    %----------------------------------------------------------------------
    % Parsing and populating properties
    %----------------------------------------------------------------------
    methods (Access = private)
        %------------------------------------------------------------------
        function inputs = parseAndPopulateInputs(this, varargin)
            
            if iscellstr(varargin{1})
                % cellstr and timestamp syntax is not supported in 17b.
                % Issue error message for this case.
                if numel(varargin) == 2
                    error(message('vision:groundTruthDataSource:TimestampsWithImageCollection'));
                end  
                isImageCollection = true;
            else
                isImageCollection = false;
            end
            
            narginchk(2,4);
            p = inputParser();
            p.addRequired('SourceName', @this.validateSource);
            
            numInputArgs = numel(varargin);
            
            if ~isImageCollection
                if numInputArgs <= 2
                    p.addOptional('Timestamps', [], @this.validateTimestamps);
                else
                    p.addRequired('CustomReaderFunction', @this.validateCustomReaderFunction);
                    p.addRequired('Timestamps', @this.validateTimestamps);
                end
            end
            
            p.parse(varargin{:});
            inputs = p.Results;

            sourceName = inputs.SourceName;
            
            if ~isImageCollection
                timeStamps = inputs.Timestamps;
            else
                timeStamps = [];
            end
            
            customReaderFunction = '';
            if numInputArgs == 3
                % Custom reader
                customReaderFunction = inputs.CustomReaderFunction;
            end
            
            initReaderAndPopulateTimestamps(this, sourceName, customReaderFunction, timeStamps);      
            
        end
        
        %------------------------------------------------------------------
        function initReaderAndPopulateTimestamps(this, sourceName, customReaderFunction, timestamps)
            
            % Convert string to char or cellstr
            if isstring(sourceName)
                if isscalar(sourceName)
                    sourceName = char(sourceName);
                else
                    sourceName = cellstr(sourceName);
                end
            end
            
            % Now sourceName is either a char vector containing a video
            % file name or directory name or a cellstr containing image
            % file names.
            isVideoName = ischar(sourceName) && ~isdir(sourceName) && isempty(customReaderFunction);
            isCustomSource = ~isVideoName && ~isempty(customReaderFunction);
            
            try
                if isVideoName
                    % videoName
                    this.Reader = matlab.internal.VideoReader(sourceName);
                    
                    if ~isempty(timestamps)
                        warning(message('vision:groundTruthDataSource:noTimestampsWithVideo'))
                    end
                    
                    % Get timestamps from the video reader
                    this.TimeStamps = this.Reader.Timestamps;
                    
                elseif isCustomSource
                    % Custom Reader
                    
                    if ~isduration(timestamps)
                        timestamps = seconds(timestamps);
                    end
                    
                    if ~iscolumn(timestamps)
                        timestamps = reshape(timestamps, numel(timestamps), 1);
                    end
                    
                    % Invoke custom reader function on 1st timestamp to
                    % validate the reader.
                    vision.internal.labeler.validation.validateCustomReaderFunction(customReaderFunction, sourceName, timestamps)
                    
                    this.TimeStamps = timestamps;
                    this.Reader = vision.internal.labeler.CustomReader(sourceName, customReaderFunction, this.TimeStamps);
                else
                    % imageNames
                    imgDataStore = imageDatastore(sourceName);
                                   
                    isDirName = ~iscell(sourceName) && isscalar(cellstr(sourceName)) && isdir(sourceName);
                    isImageSequence = isDirName || ~isempty(timestamps);
                    
                    if isImageSequence
                        
                        vision.internal.labeler.validation.validateImageSequence(imgDataStore);
                        
                        if isempty(timestamps)
                            % If no timeStamps were specified, set a default.
                            numImages = numel(imgDataStore.Files);
                            this.TimeStamps = seconds( (0 : numImages-1)' );
                        else
                            % Ensure that specified timeStamps are consistent with
                            % number of images.
                            vision.internal.labeler.validation.checkImageSequenceAndTimestampsAgreement(imgDataStore.Files,timestamps);
                            
                            if ~isduration(timestamps)
                                timestamps = seconds(timestamps);
                            end
                            
                            if ~iscolumn(timestamps)
                                timestamps = reshape(timestamps, numel(timestamps), 1);
                            end
                            
                            this.TimeStamps = timestamps;
                            
                        end
                        this.Reader = vision.internal.labeler.ImageSequenceReader(imgDataStore, this.TimeStamps);
                    else
                        % Image collection
                        vision.internal.labeler.validation.validateImageSequence(imgDataStore, false);
                        this.Reader = copy(imgDataStore);
                    end
                end
            catch baseME
                % Throw errors coming from VideoReader, ImageSequenceReader
                % or CustomReader object as if they are coming from this
                % object. These are errors related to file existence and
                % conforming files.
                if isCustomSource
                    newCauseME = MException('vision:labeler:CustomReaderFunctionCallError',...
                        vision.getMessage('vision:labeler:CustomReaderFunctionCallError', func2str(customReaderFunction)));
                    newME = addCause(baseME,newCauseME);
                else
                    newME = baseME;
                end
                
                throwAsCaller(newME)                
            end
        end
          
        %------------------------------------------------------------------
        function validateSource(~, srcName)
            
            validateattributes(srcName, {'char', 'string', 'cell'}, {'nonempty'}, mfilename, 'Data Source Name (Image Sequence, Video Name or Custom Source Name)', 1);
            
            if iscell(srcName) && ~iscellstr(srcName)
                error(message('vision:groundTruthDataSource:invalidCellType'))
            end
        end
        
        %------------------------------------------------------------------
        function validateCustomReaderFunction(~, functionName)
            
            validateattributes(functionName, {'function_handle'}, {'nonempty'}, mfilename, 'Custom Reader Function', 2);
            
        end
        
        %------------------------------------------------------------------
        function validateTimestamps(~, ts)
            
            validateattributes(ts, {'double', 'duration'},{'nonempty','vector'}, mfilename, 'Timestamps');
            
            vision.internal.labeler.validation.validateTimestamps(ts);
        end                
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        function TF = hasTimeStamps(this)
            TF = ~isempty(this.TimeStamps);
        end
    end
end
