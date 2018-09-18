% Session holds the state of the Video Labeler App
%
%   This class holds the entire state of the image labeling app UI. It is
%   used to save and load the labeling session. It is also used to pass
%   data amongst other classes.

% Copyright 2017 The MathWorks, Inc.

classdef Session < vision.internal.labeler.tool.Session
    properties
        ImageFilenames = cell(0,1);
        TempDirectory
    end
    
    properties (Access = protected, Hidden)
        Version = ver('vision');
    end 
    
    properties (Access=private)
        RemoveSessionDir = false;
    end
    
    methods
        
        %------------------------------------------------------------------
        function addImagesToSession(this, imageFileNames)
            
            this.ImageFilenames = [this.ImageFilenames; imageFileNames];
            
            isPixelLabelChanged = false(size(imageFileNames));
            this.IsPixelLabelChanged = [this.IsPixelLabelChanged; isPixelLabelChanged];
            
            this.ROIAnnotations.appendSourceInformation(getNumImages(this));
            this.FrameAnnotations.appendSourceInformation(getNumImages(this));
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        function removeImagesFromSession(this, removedImageIndices)
            
            seesionDirtyFlag = (this.HasROILabels || this.HasFrameLabels) || (getNumImages(this) ~= numel(removedImageIndices));
            
            % Remove ROI Annotation Data
            removeAllAnnotations( this.ROIAnnotations, removedImageIndices);
            
            % Rename Label png files
            if this.hasPixelLabels()
                renameAndRemoveLabelMatrixFiles(this, removedImageIndices);
            end
            
            % Remove Frame Annotation Data
            removeAllAnnotations( this.FrameAnnotations, removedImageIndices);
            
            % Remove from ImageFilenames
            this.ImageFilenames(removedImageIndices) = [];
            
            % Remove from IsPixelLabelChanged
            this.IsPixelLabelChanged(removedImageIndices) = [];
            
            this.RemoveSessionDir = true;
            
            if seesionDirtyFlag
                this.IsChanged = true;
            else
                this.IsChanged = false;
            end
        end
        
        %------------------------------------------------------------------
        function renameAndRemoveLabelMatrixFiles(this, removedImageIndices)
            % This function renames the existing Label Matrix files. It
            % also removes the files corresponding to the removed images.
            
            firstRemovedImgIdx = removedImageIndices(1);
            lastImageIdx = getNumImages(this);
            offset = 0;
            
            for idx = firstRemovedImgIdx:lastImageIdx
                try
                    if ~isempty(find(removedImageIndices == idx,1))
                        fileName = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
                        if exist(fileName, 'file')
                            delete(fileName);
                        end

                        offset = offset + 1;
                    else
                        newFileIndex = idx - offset;
                        filePath = getPixelLabelAnnotation(this.ROIAnnotations, newFileIndex);
                        if ~isempty(filePath)
                            % Move file in Temp Directory
                            filePath = fullfile(this.TempDirectory, sprintf('Label_%d.png',idx));
                            newFilePath = fullfile(this.TempDirectory, sprintf('Label_%d.png',newFileIndex));
                            movefile(filePath, newFilePath, 'f');

                            setPixelLabelAnnotation(this, newFileIndex, newFilePath);
                        end                    
                    end
                catch
                    % TODO
                end
            end
        end
        
        %------------------------------------------------------------------
        function rotatedImages = rotateImages(this, imagesToBeRotatedIdx, rotationType)
            % This function rotates the requested images
            
            numImagesRotated = 0;
            
            for idx = imagesToBeRotatedIdx
                try
                    imageFileName = this.ImageFilenames{idx};
                    im = imread(imageFileName);
                    
                    if strcmpi(rotationType, 'Clockwise')
                        imRot = imrotate(im, -90);
                    elseif strcmpi(rotationType, 'CounterClockwise')
                        imRot = imrotate(im, 90);
                    end 
                    
                    imwrite(imRot, imageFileName);                    
                    
                    if hasPixelLabels(this)
                        labelFilePath = getPixelLabelAnnotation(this.ROIAnnotations, idx);
                        if ~isempty(labelFilePath)
                            labelFilePath = fullfile(this.TempDirectory, sprintf('Label_%d.png',idx));
                            labelIm = imread(labelFilePath);
                            if strcmpi(rotationType, 'Clockwise')
                                labelImRot = imrotate(labelIm, -90);
                            elseif strcmpi(rotationType, 'CounterClockwise')
                                labelImRot = imrotate(labelIm, 90);
                            end
                            imwrite(labelImRot, labelFilePath); 
                        end
                    end
                    
                        
                    [positions, names, ~, ~] = this.ROIAnnotations.queryAnnotation(idx);
                    
                    if ~isempty(positions)
                        [numRows,numCols,~] = size(im);
                        
                        newPositions = cell( size(positions,1), size(positions,2) );
                        for roiType = 1:numel(positions)
                            roiPositions = positions{roiType};
                            newROIPositions = zeros( size(roiPositions, 1) , size(roiPositions, 2) );

                            for rectRoiIdx=1:size(roiPositions, 1)
                                oldPoints = roiPositions(rectRoiIdx, :);
                                if strcmpi(rotationType, 'Clockwise')
                                    x = numRows - (oldPoints(2) + oldPoints(4));
                                    y = oldPoints(1);
                                elseif strcmpi(rotationType, 'CounterClockwise')
                                    x = oldPoints(2);
                                    y = numCols - (oldPoints(1) + oldPoints(3));
                                end
                                newPoints = [x y oldPoints(4) oldPoints(3)];
                                newROIPositions(rectRoiIdx, :) = newPoints;
                            end  
                            newPositions{roiType} = newROIPositions;
                        end
                        addROILabelAnnotations(this, idx, names, newPositions)   
                    end
                    
                    numImagesRotated = numImagesRotated + 1;
                catch 
                    rotatedImages = imagesToBeRotatedIdx(1:numImagesRotated);
                    return;
                end
            end
            
            rotatedImages = imagesToBeRotatedIdx;
            this.IsChanged = true;
        end
        %------------------------------------------------------------------
        function set.ImageFilenames(this, names)
            % always assign as column vector.
            this.ImageFilenames = reshape(names,[],1);
        end
        
        function addLabelsDefinitions(this, definitions)
            % add unique definitions to session.
            addDefinitions(this, definitions);
        end
        
        %------------------------------------------------------------------
        function addLabelData(this, definitions, labelData, indices)
            % Convert label data to struct
            labels = table2struct( labelData );
           
            % The field names correspond to the ROI and Frame Labels.
            fields = fieldnames(labels);

            % Get the ROILabel names
            areROIsPresent = any(isROI([definitions.Type]));
            if areROIsPresent

                roiLabels = definitions{[definitions.Type] == labelType.Rectangle,'Name'};
                [~,isROILabel] = intersect(fields,roiLabels,'stable');
                 
                isPixelLabel = find(strcmp(fields,'PixelLabelData'));
                
            else
                isROILabel = false(size(fields));
            end
            
            % Get the FrameLabel names
            areFrameLabelsPresent = any(isScene([definitions.Type]));
            if areFrameLabelsPresent
                frameLabels = definitions{isScene([definitions.Type]),'Name'};
                [~,isFrameLabel] = intersect(fields,frameLabels,'stable');
            else
                isFrameLabel = false(size(fields));
            end
            
            % For each row, add ROI and Frame Label Annotations.
            for n = 1 : numel(indices)
                
                positionsOrFrameLabel  = struct2cell(labels(n));
                
                if areROIsPresent
                    
                    if ~isempty(isROILabel)
                        positions = positionsOrFrameLabel(isROILabel);
                        this.ROIAnnotations.appendAnnotation(indices(n), roiLabels, positions);
                    end
                   
                    if isPixelLabel
                        positions = positionsOrFrameLabel(isPixelLabel); %#ok<FNDSB>
                                                
                        assert(numel(positions) == 1, 'Expected just 1 file');

                        if ~isempty(positions{1})
                            % only copy data if not empty.
                            % The call to copyData also updates the
                            % Annotation struct
                            this.copyData(positions{1}, indices(n));
                        end
                    end
                end
                
                if areFrameLabelsPresent
                    frLabelData = positionsOrFrameLabel(isFrameLabel);
                    this.FrameAnnotations.appendAnnotation(indices(n), frameLabels, frLabelData);
                end

            end

            this.IsChanged = true;
        
        end
        
        %------------------------------------------------------------------
        function numberOfImages = getNumImages(this)
            numberOfImages = numel(this.ImageFilenames);
        end
            
        %------------------------------------------------------------------
        function TF = hasImages(this)
            TF = numel(this.ImageFilenames) > 0;
        end
        
    end
    
    methods
        %------------------------------------------------------------------
        function labels = exportLabelAnnotations(this)
            
            % Extract label definitions
            definitions = exportLabelDefinitions(this);
            
            % Extract label annotations
            unused = [];
            roiAnnotationsTable     = this.ROIAnnotations.export2table(unused);
            frameAnnotationsTable   = this.FrameAnnotations.export2table(unused);
            
            % Create a groundTruth object
            data = horzcat(roiAnnotationsTable, frameAnnotationsTable);
            data.Properties.Description = vision.getMessage('vision:labeler:ExportTableDescription', 'Image Labeler', date);
            
            source = groundTruthDataSource(this.ImageFilenames);
            labels = groundTruth(source, definitions, data);
        end
        
        %------------------------------------------------------------------
        % Read and return session data.
        %------------------------------------------------------------------
        function [data, exceptions] = readData(this, idx)
            filename = this.ImageFilenames{idx};
            data.ImageFilename = filename;
           
                     
            exceptions = [];
            
            % Read image data.
            try
                
                data.Image = vision.internal.labeler.normalizeImageData(imread(filename));
                imageReadError = false;
            catch ME
                I = imread(fullfile(matlabroot,'toolbox','images','icons','CorruptedImage_72.png'));
                
                data.Image = I;
                
                % set image file name to missing.
                data.ImageFilenames = string(NaN);  
                
                imageReadError = true;
                exceptions = [exceptions ME];
            end

            sz = size(data.Image);
            
            % Only try to read pixel label data if TempDirectory has a path
            if ~isempty(this.TempDirectory)
                filename = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
            
                try
                    % This read may error out because we have not even draw
                    % pixel labels yet.  
                    data.LabelMatrix = imread(filename);

                    % If we do read a label matrix make sure it's the same size
                    % as I.
                    lsz = size(data.LabelMatrix);
                    if ~isequal(lsz(1:2),sz(1:2))

                        exceptions = [exceptions ...
                            MException(message('vision:labeler:PixelLabelDataSizeMismatch'))];                   
                    end

                catch 
                    data.LabelMatrix = zeros(sz(1:2),'uint8');
                end      
            
            else
                data.LabelMatrix = zeros(sz(1:2),'uint8');
            end
            
            % Pixel Label
            data.ImageIndex = idx;
            data.LabelMatrixFilename = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
            
            % Annotations
            if imageReadError
                % Do not display annotations in case of image read error.
                [positions, names, colors, shapes] = deal({},{},{},labelType.empty);
                [sceneNames, sceneColors, sceneLabelIds] = deal({},{},[]);
            else
                [positions, names, colors, shapes] = this.ROIAnnotations.queryAnnotation(idx);
                [sceneNames, sceneColors, sceneLabelIds] = this.FrameAnnotations.queryAnnotation(idx);
            end
            
            % ROI Data
            data.Names     = names;
            data.Positions = positions;
            data.Colors    = colors;
            data.Shapes    = shapes;
            
            % Scene Data
            data.SceneNames = sceneNames;
            data.SceneColors = sceneColors;
            data.SceneLabelIds = sceneLabelIds;
        end
        
        %------------------------------------------------------------------
        % This method should be called after the Image Session is loaded from a
        % MAT file to check that all the images can be found at their
        % specified locations
        %------------------------------------------------------------------
        function checkImagePaths(this, currentSessionFilePath,...
                origFullSessionFileName)
            
            % verify that all the images are present; adjust path if
            % necessary
            for i=1:numel(this.ImageFilenames)
                if ~exist(this.ImageFilenames{i},'file')
                    
                    this.ImageFilenames{i} = ...
                        vision.internal.uitools.tryToAdjustPath(...
                        this.ImageFilenames{i}, ...
                        currentSessionFilePath, origFullSessionFileName);
                    
                end
            end            
        end 
        
        % Write session data.
        %------------------------------------------------------------------
        function TF = writeData(this,L,idx)
            
            try
                imwrite(L,fullfile(this.TempDirectory,sprintf('Label_%d.png',idx)));
                this.IsPixelLabelChanged(idx) = true;
                TF = true;
            catch
                TF = false;
            end
            
        end
        
        % Write session data.
        %------------------------------------------------------------------
        function copyData(this,filename,idx)
            % copy label matrix pointed to by filename to tempdir
            try
                newFilePath = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
                copyfile(filename,newFilePath);
                setPixelLabelAnnotation(this, idx, newFilePath);
                this.IsPixelLabelChanged(idx) = true;
            catch
                % TODO
            end
            
        end
        
        % Import session data.
        %------------------------------------------------------------------
        function TF = importPixelLabelData(this)
            
            TF = true;
            
            for idx = 1:getNumImages(this)
                try
                    filePath = getPixelLabelAnnotation(this.ROIAnnotations, idx);
                    if ~isempty(filePath)
                        copyfile(filePath,this.TempDirectory,'f');
                        newFilePath = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
                        setPixelLabelAnnotation(this, idx, newFilePath);
                    end
                catch
                    setPixelLabelAnnotation(this, idx, '');
                    TF = false;
                end
            end
            
        end
        
        % Export session data.
        %------------------------------------------------------------------
        function TF = exportPixelLabelData(this,newfolder)
            
            TF = true;
            
            for idx = 1:getNumImages(this)
                try
                    filePath = getPixelLabelAnnotation(this.ROIAnnotations, idx);
                    if ~isempty(filePath)
                        copyfile(filePath,newfolder,'f');
                        newFilePath = fullfile(newfolder,sprintf('Label_%d.png',idx));
                        setPixelLabelAnnotation(this, idx, newFilePath);
                    end
                catch
                    setPixelLabelAnnotation(this, idx, '');
                    TF = false;
                end
            end
            
        end
        
        % Export session data.
        %------------------------------------------------------------------
        function refreshPixelLabelAnnotation(this)
            
            for idx = 1:getNumImages(this)
                filePath = getPixelLabelAnnotation(this.ROIAnnotations, idx);
                if ~isempty(filePath)
                    newFilePath = fullfile(this.TempDirectory,sprintf('Label_%d.png',idx));
                    setPixelLabelAnnotation(this, idx, newFilePath);
                end
            end
            
        end
        
        % Write session data.
        %------------------------------------------------------------------
        function saveSessionData(this)
            
            % Create directory for session data based on user input
            [pathstr,name,~] = fileparts(this.FileName);
            
            sessionPath = fullfile(pathstr,['.' name '_SessionData']);
            
            % This case is hit only when the images are removed. The
            % previous session data will be wiped off and the normal 
            % session saving procedure is followed.
            if this.RemoveSessionDir && isdir(sessionPath)
                rmdir(sessionPath,'s');
                this.RemoveSessionDir = false;
            end
            
            % Check for pixel labels
            if hasPixelLabels(this)
            
                % Create directory for pixel label session data
                if ~isdir(sessionPath)
                    mkdir(sessionPath)
                    if ispc
                        % Hide session data folder for Windows users
                        fileattrib(sessionPath,'+h')
                    end
                end
            
                % Copy pixel label data if it exists and has been changed
                % since last save
                for idx = 1:getNumImages(this)
                    % No try catch block here. Exception catching occurs in
                    % session manager during save session operation
                    filePath = getPixelLabelAnnotation(this.ROIAnnotations, idx);
                    if ~isempty(filePath) && this.IsPixelLabelChanged(idx)
                        copyfile(filePath,sessionPath,'f');
                        setPixelLabelAnnotation(this, idx, sessionPath);
                    end
                end
                
            else
                % No pixel label data, remove pixel label session directory
                % if it exists
                if isdir(sessionPath)
                    % No pixel labels exist, remove pixel label data and
                    % folder if it existed
                    rmdir(sessionPath,'s');
                end
            end
            
            this.IsPixelLabelChanged = false(size(this.ImageFilenames));
            
        end
        
        % Delete PixelLabelID from session data
        %------------------------------------------------------------------
        function deletePixelLabelData(this,val)
            
            for idx = 1:getNumImages(this)
                try
                    L = imread(fullfile(this.TempDirectory,sprintf('Label_%d.png',idx)));
                    L(L == val) = 0;
                    imwrite(L,fullfile(this.TempDirectory,sprintf('Label_%d.png',idx)));
                    this.IsPixelLabelChanged(idx) = true;
                catch
                    % No-op
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Replace annotations with empty annotations for the indices
        % specified in imageIndices. This is used by the automation
        % workflow to provide a clean slate of annotations during algorithm
        % execution.
        %------------------------------------------------------------------
        function replaceAnnotations(this, imageIndices, validFrameLabels)
            
            replace(this.ROIAnnotations, imageIndices);
            replace(this.FrameAnnotations, imageIndices, validFrameLabels);
        end
        
        %------------------------------------------------------------------
        % Replace annotations with empty annotations over the specified
        % indices.
        %------------------------------------------------------------------
        function replaceAnnotationsForUndo(this, imageIndices)
            
            % Replace annotations with empty annotations over the specified
            % indices
            replace(this.ROIAnnotations, imageIndices);
            replace(this.FrameAnnotations, imageIndices);
        end
        
        %------------------------------------------------------------------
        % Replace annotations with empty annotations over the specified
        % indices.
        %------------------------------------------------------------------
        function replacePixelLabels(this,indices)
            
            % Remove existing Automation folder and its contents
            rmdir(this.TempDirectory,'s');
            
            % Create automation folder again
            status = mkdir(this.TempDirectory);
            if ~status
                assert(false,'Unable to create directory for automation');
            end
            
            for idx = 1 : numel(indices)
                setPixelLabelAnnotation(this, indices(idx), '');
            end
            
        end
        
        %------------------------------------------------------------------
        % Merge annotations with previously cached annotations. This is
        % used by the automation workflow to merge annotations created
        % during automation with the rest of the session. This gets invoked
        % when the user "accepts" automation labels.
        %------------------------------------------------------------------
        function mergeAnnotations(this, imageIndices)
            
            mergeWithCache(this.ROIAnnotations, imageIndices);
            mergeWithCache(this.FrameAnnotations, imageIndices);
        end
        
        %------------------------------------------------------------------
        % Merge pixel label data with previously cached pixel label data.
        % This gets invoked when the user "accepts" automation labels.
        %------------------------------------------------------------------
        function mergePixelLabels(this, indices)
            % Merge pixel label data from autoDirectory with
            % cachedDirectory
            autoDirectory = this.TempDirectory;
            cachedDirectory = fileparts(autoDirectory);
            
            for idx = 1 : numel(indices)
                % Try to read label matrices from file if they exist
                autoLabelFile = fullfile(autoDirectory,sprintf('Label_%d.png',indices(idx)));
                cachedLabelFile = fullfile(cachedDirectory,sprintf('Label_%d.png',indices(idx)));
                    
                try
                    L = imread(cachedLabelFile);
                catch
                    L = [];
                end
                
                try
                    autoL = imread(autoLabelFile);
                    
                    if isempty(L)
                        L = zeros(size(autoL),'uint8');
                    end
                    
                    % Copy nonzero values into original label matrix
                    L(autoL > 0) = autoL(autoL > 0);
                    imwrite(L,cachedLabelFile);
                    this.IsPixelLabelChanged(indices(idx)) = true;
                    setPixelLabelAnnotation(this, indices(idx), cachedLabelFile);
                catch
                    %setPixelLabelAnnotation(this, indices(idx), '');
                end
                
            end
                
        end
        
    end
    
    methods
        %------------------------------------------------------------------
        % Reset Session Data
        %------------------------------------------------------------------   
        function resetSession(this)
            reset(this);
            this.ImageFilenames = {};
            this.IsPixelLabelChanged = false(0); % empty logical array
            if ~isempty(this.TempDirectory)
                rmdir(this.TempDirectory,'s');
            end
            this.TempDirectory = [];
        end
    end
    
    methods(Access=protected)
        
        
        %------------------------------------------------------------------
        function addData(this, data)

            % Add images to session
            addImagesToSession(this, data.DataSource.Source);
            
            definitions = data.LabelDefinitions;
            
            % add label appends data to annotation struct.
            this.addLabelData(definitions, data.LabelData, 1:height(data.LabelData))
           
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        function that = saveobj(this)
            that.ImageFilenames      =  this.ImageFilenames;
            that.FileName            =  this.FileName;
            that.ROILabelSet         =  this.ROILabelSet;
            that.FrameLabelSet       =  this.FrameLabelSet;
            that.ROIAnnotations      =  this.ROIAnnotations;
            that.FrameAnnotations    =  this.FrameAnnotations;
            that.Version             =  this.Version;
        end
        
        %------------------------------------------------------------------
        function setTempDirectory(this,foldername)
            this.TempDirectory = foldername;
        end
        
        function delete(this)
            % Delete temp directory when Session is destroyed
            if ~isempty(this.TempDirectory)
                [pathstr,name,~] = fileparts(this.TempDirectory);
                % If current temp directory is folder named Automation, the
                % app must be in the automation tab when closed. In this
                % case, delete the parent directory as well
                if strcmp(name,'Automation')
                    rmdir(pathstr,'s');
                else
                    rmdir(this.TempDirectory,'s');
                end
            end
            delete(this);
        end
        
    end
    
    methods(Static, Hidden)
        %------------------------------------------------------------------
        function this = loadobj(that)
            this = vision.internal.imageLabeler.tool.Session;
            
            this.ImageFilenames      =  that.ImageFilenames;
            this.FileName            =  that.FileName;
            this.ROILabelSet         =  that.ROILabelSet;
            this.FrameLabelSet       =  that.FrameLabelSet;
            this.ROIAnnotations      =  that.ROIAnnotations;
            this.FrameAnnotations    =  that.FrameAnnotations;
            
            configure(this.ROIAnnotations);
            configure(this.FrameAnnotations);
            
            this.IsPixelLabelChanged = false(size(this.ImageFilenames));
            
        end
    end    
end