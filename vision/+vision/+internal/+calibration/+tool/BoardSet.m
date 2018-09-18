% BoardSet Stores all information about checkerboard images
%
%    This class stores the file names from which checkerboards were 
%    extracted as well as checkerboard world points and detected key
%    points.

% Copyright 2012-2016 The MathWorks, Inc.

classdef BoardSet < handle
       
    properties(Access=private, Hidden)
        Version = ver('vision');
    end
    
    properties(GetAccess=public, SetAccess=private)
        
        FullPathNames = {};
        BoardSize = [];
        
        BoardPoints
        WorldPoints
        SquareSize
        
        BoardLabels % labels displayed in the data browser
        BoardIcons  % icons displayed in the data browser
        
        LastNonDetectedPathNames = {};
        
        NumBoards = 0;
        
        ImageSize = [];
    end
    
    properties(GetAccess=public, SetAccess=public)
       Units; % made it writable in 17a to support switch from short names to longer names in->inches
    end
    
    properties(Dependent)
        IsStereo;
    end
    
    methods
        %------------------------------------------------------------------
        function isStereo = get.IsStereo(this)
            isStereo = size(this.FullPathNames, 1) == 2;
        end        
    end
    
    %----------------------------------------------------------------------
    methods (Access=public)
        
        function this = BoardSet(fileNames, squareSize, units)

            % begin by inspecting image size consistency
            this.ImageSize     = this.checkImageSizes(fileNames);
            
            % proceed with adding the boards
            this.FullPathNames = fileNames;
            this.SquareSize    = squareSize;
            this.Units         = units;

            % set board labels by picking the file names without the path
            this.NumBoards = size(fileNames, 2);
            this.BoardLabels = cell(1, this.NumBoards);
            for i = 1:this.NumBoards
                this.BoardLabels{i} = makeLabel(this, fileNames(:, i));
            end
    
            % Detect checkerboard points
            delIdx = this.detectPointsForNewSession();
            this.deleteRejectedBoards(delIdx);
            this.generateIcons();
            
            % Derive the world points from board dimensions
            this.WorldPoints = ...
                generateCheckerboardPoints(this.BoardSize, this.SquareSize);                       
        end

        %------------------------------------------------------------------        
        function numDuplicates = addBoards(this, fileNames)
            
            % check image consistency
            this.ImageSize = this.checkImageSizes(fileNames);
            
            % proceed with adding images
            numOldImages = this.NumBoards;
            numNewImages = size(fileNames, 2);
            waitBar = ...
                vision.internal.calibration.checkerboard.DetectionProgressBar(numNewImages);
            
            numDuplicates = 0;
            this.LastNonDetectedPathNames = cell(size(fileNames, 1), 0);
            for i = 1:numNewImages
                if waitBar.Canceled
                    rollback(this, numOldImages);
                    error(message('vision:uitools:LoadingCanceledByUser'));
                end
                
                if this.isDuplicateFileName(fileNames(:, i))
                    numDuplicates = numDuplicates + 1;
                    continue;
                end
                
                if this.IsStereo
                    [points, boardSize] = detectCheckerboardPoints(...
                        fileNames{1, i}, fileNames{2, i});
                else
                    [points, boardSize] = detectCheckerboardPoints(fileNames{i});                    
                end
                
                if isequal(boardSize, this.BoardSize)
                    this.addOneBoard(fileNames(:, i), points);
                else
                    this.LastNonDetectedPathNames(:, end+1) = fileNames(:, i);
                end
                waitBar.update();
            end
            
            this.generateIcons();
        end

        %------------------------------------------------------------------
        function board = getBoard(this, boardIndex)
            board.boardSize = this.BoardSize;
            board.fileName = this.FullPathNames(:, boardIndex);
            board.label = this.BoardLabels{boardIndex};
            board.detectedPoints = this.BoardPoints(:,:,boardIndex, :);
        end
            
        %------------------------------------------------------------------
        function removeBoard(this, boardIndex)

            this.BoardLabels(boardIndex)   = [];
            this.BoardIcons(boardIndex)    = [];
            this.FullPathNames(:, boardIndex) = [];
            this.BoardPoints(:,:,boardIndex, :) = [];

            this.NumBoards = this.NumBoards - length(boardIndex);
        end
            
        %------------------------------------------------------------------
        function reset(this)
            this.FullPathNames = [];
            this.LastNonDetectedPathNames = {};
            this.BoardSize = [];
            
            this.BoardPoints = [];
            this.WorldPoints = [];
            
            this.BoardLabels = {};
            this.BoardIcons = [];
            
            this.NumBoards = 0;
        end

        %------------------------------------------------------------------
        % This method should be called after the BoardSet is loaded from a
        % MAT file to check that all the images can be found at their
        % specified locations
        %------------------------------------------------------------------
        function checkImagePaths(this, currentSessionFilePath,...
                atSavingTimeFullSessionFileName)
            
            % verify that all the images are present; adjust path if
            % necessary
            for i=1:numel(this.FullPathNames)
                if ~exist(this.FullPathNames{i},'file')
                    
                    this.FullPathNames{i} = vision.internal.uitools.tryToAdjustPath(...
                        this.FullPathNames{i}, currentSessionFilePath, ...
                        atSavingTimeFullSessionFileName);
                    
                end
            end            
        end
        
    end % public methods
    
    %----------------------------------------------------------------------
    methods (Access=private)

        function label = makeLabel(this, fileNames)
            [~,fname, ext] = fileparts(fileNames{1, 1});
            fileName1 = [fname, ext];
                                      
            if this.IsStereo
                [~,fname, ext] = fileparts(fileNames{2, 1});
                fileName2 = [fname, ext];
                label = [fileName1, ' & ', fileName2];
            else
                label = fileName1;
            end
        end
                     
        %------------------------------------------------------------------
        % checks image size consistency
        function imageSize = checkImageSizes(this, fileNames)
            
            isBrandNewSession = (this.NumBoards == 0);
            
            % get base image size
            if isBrandNewSession
                % use the very first image
                imInfoBase = imfinfo(fileNames{1});
            else
                % use an already loaded image
                imInfoBase = imfinfo(this.FullPathNames{1});
            end
            
            
            for i=1:numel(fileNames)
                imInfo = imfinfo(fileNames{i});
                
                if (imInfoBase(1).Width ~= imInfo(1).Width) || ...
                        (imInfoBase(1).Height ~= imInfo(1).Height)
                    % issue an error message
                    error(message('vision:caltool:imageSizeInconsistent'));
                end                
            end
            
            imageSize = [imInfoBase(1).Height, imInfoBase(1).Width];            
        end                
        
        %------------------------------------------------------------------
        function addOneBoard(this, fileName, points)
            % for a single camera fileName is a cell array of 1 element
            % for a stereo camera fileName is a cell array of 2 elements
            this.BoardPoints(:, :, end+1, :) = points;
            this.FullPathNames(:, end+1) = fileName;

            this.BoardLabels{end+1} = makeLabel(this, fileName);
            this.NumBoards = this.NumBoards + 1;
        end
        
        %------------------------------------------------------------------
        function rollback(this, numBoardsToKeep)
            this.FullPathNames = this.FullPathNames(1:numBoardsToKeep);
            this.BoardPoints = this.BoardPoints(:, :, 1:numBoardsToKeep);
            this.BoardLabels = this.BoardLabels(1:numBoardsToKeep);
            this.BoardIcons = this.BoardIcons(1:numBoardsToKeep);
            this.NumBoards = numBoardsToKeep;
        end
        
        %------------------------------------------------------------------
        function tf = isDuplicateFileName(this, fileName)
            tf = false;
            if any(strcmp(fileName{1}, this.FullPathNames(1, :)))
                tf = true;
                return;
            end
            
            if this.IsStereo && any(strcmp(fileName{2}, this.FullPathNames(2, :)))
                tf = true;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function delIdx = detectPointsForNewSession(this)
            if this.IsStereo
                [boardPoints, boardSize, goodBoardIdx, userCanceled] = ...
                    detectCheckerboardPoints(this.FullPathNames(1, :), ...
                    this.FullPathNames(2, :), 'ShowProgressBar', true);
            else
                [boardPoints, boardSize, goodBoardIdx, userCanceled] = ...
                    detectCheckerboardPoints(this.FullPathNames, 'ShowProgressBar', true);
            end
            
            if userCanceled
                error(message('vision:uitools:LoadingCanceledByUser'));
            end
            
            if isempty(boardPoints)
                error(message('vision:caltool:zeroBoards'));
            end
            
            delIdx = ~goodBoardIdx;
            this.BoardPoints = boardPoints;
            this.BoardSize = boardSize;
        end
        
        %------------------------------------------------------------------
        function deleteRejectedBoards(this, delIdx)
            % store file names of the images where boards were not
            % detected; this is used for reporting
            this.LastNonDetectedPathNames = this.FullPathNames(:, delIdx);
            
            this.NumBoards = size(this.BoardPoints, 3);
            this.BoardLabels(delIdx)   = [];
            this.FullPathNames(:, delIdx) = [];
        end
        
        %------------------------------------------------------------------
        function generateIcons(this)
            thumbnailHeight = 72;
            for i = 1:this.NumBoards
                if size(this.FullPathNames, 1) == 1
                    im = imread(this.FullPathNames{i});
                    im = imresize(im, [thumbnailHeight, NaN]);
                else
                    im1 = imread(this.FullPathNames{1, i});
                    im2 = imread(this.FullPathNames{2, i});
                    im = vision.internal.calibration.tool.fuseWithSeparator(...
                        imresize(im1, [thumbnailHeight, NaN]), ...
                        imresize(im2, [thumbnailHeight, NaN]));
                end
                
                javaImage = im2java2d(im);
                icon = javax.swing.ImageIcon(javaImage);
                icon.setDescription(this.BoardLabels(i));
                
                this.BoardIcons{i} = icon;
            end
        end        
        
    end
    
    %----------------------------------------------------------------------
    % saveobj and loadobj are implemented to ensure compatibility across
    % releases even if architecture of BoardSet class changes
    methods (Hidden)
       
        function thisOut = saveobj(this)
            
            thisOut = this;            
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Static, Hidden)
       
        function thisOut = loadobj(this)

            thisOut = this;            
        end
        
    end % methods(static, hidden)
    
end
