% LoadStereoImagesDlg Dialog for loading stereo images.

% Copyright 2014 The MathWorks, Inc.

classdef LoadStereoImagesDlg < vision.internal.uitools.OkCancelDlg
    properties
        Dir1 = '';
        Dir2 = '';
        
        FileNames = {};
        
        SquareSize;
        Units;
    end
    
    properties(Access=private)                  
        Prompt1Pos = [10, 98, 280, 20];
        ButtonSize = [60, 20];
        
        DirSelector1;
        DirSelector2;
        SizeSelector;
    end
    
    methods
        function this = LoadStereoImagesDlg(groupName, initialDir1, ...
                initialDir2, initSquareSize, initUnits)            
            if nargin < 2
                initialDir1 = pwd();
            end
            
            if nargin < 3
                initialDir2 = pwd();                
            end
            
            if nargin < 4
                initSquareSize = 25;                                
            end
            
            if nargin < 5
                initUnits = 'millimeters';
            end                        
            
            dlgTitle = vision.getMessage('vision:caltool:LoadStereoImagesTitle');
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);
            
            this.DlgSize = [400, 240];
            createDialog(this);
            addDirSelectors(this, initialDir1, initialDir2);
            addSquareSizeSelector(this, initSquareSize, initUnits);
        end        
        
        %------------------------------------------------------------------
        function disableSquareSize(this)
            disable(this.SizeSelector);
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function addDirSelectors(this, initialDir1, initialDir2)
            import vision.internal.calibration.tool.*;
            
            this.Prompt1Pos(2) = this.DlgSize(2) - 30;
            this.DirSelector1 = DirectorySelector(...
                vision.getMessage('vision:caltool:StereoFolder1Prompt'), ...
                this.Prompt1Pos, this.Dlg, initialDir1);
            set(this.DirSelector1.BrowseButton, 'Callback', @this.onBrowse1);
            
            selectorPos2 = this.Prompt1Pos;
            selectorPos2(2) = selectorPos2(2) - 80;
            this.DirSelector2 = DirectorySelector(...
                vision.getMessage('vision:caltool:StereoFolder2Prompt'), ...
                selectorPos2, this.Dlg, initialDir2);
            set(this.DirSelector2.BrowseButton, 'Callback', @this.onBrowse2);
        end
        
        %------------------------------------------------------------------
        function addSquareSizeSelector(this, initSquareSize, initUnits)
            location = [10, 48];
            this.SizeSelector = ...
                vision.internal.calibration.tool.SquareSizeSelector(...
                   this.Dlg, location, initSquareSize, initUnits);
        end
    end
    
    methods(Access=protected)          
        %------------------------------------------------------------------
        function onBrowse1(this, ~, ~)
            this.DirSelector1.doBrowse();
            if ~this.DirSelector2.IsModifiedUsingBrowse                
                parentDir = vision.internal.getParentDir(this.DirSelector1.SelectedDir);      
                set(this.DirSelector2.TextBox, 'String', parentDir);
            end
        end
        
        %------------------------------------------------------------------
        function onBrowse2(this, ~, ~)
            this.DirSelector2.doBrowse();
            if ~this.DirSelector1.IsModifiedUsingBrowse
                parentDir = vision.internal.getParentDir(this.DirSelector2.SelectedDir);
                set(this.DirSelector1.TextBox, 'String', parentDir);
            end
        end
        
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            this.Dir1 = this.DirSelector1.SelectedDir;
            this.Dir2 = this.DirSelector2.SelectedDir;
            
            if areFoldersBad(this);
                return;
            end
            
            fileNames1 = vision.internal.getAllImageFilesFromFolder(this.Dir1);
            fileNames2 = vision.internal.getAllImageFilesFromFolder(this.Dir2);
            
            if areFileNamesBad(this, fileNames1, fileNames2)
                return;
            end
                        
            this.FileNames = [fileNames1; fileNames2];     
            
            [this.SquareSize, this.Units] = getSizeAndUnits(this.SizeSelector);
            if this.SquareSize <= 0 || isnan(this.SquareSize)
                errordlg(getString(message('vision:caltool:invalidSquareSize')));
                return;
            end
            close(this);
        end               
        
        %------------------------------------------------------------------
        function tf = areFoldersBad(this)
            errorDlgTitle = vision.getMessage(...
                'vision:caltool:LoadingStereoImagesFailedTitle');
            errorMsg = vision.internal.calibration.tool.checkStereoFolders(...
                this.Dir1, this.Dir2);

            if isempty(errorMsg)
                tf = false;
            else
                tf = true;
                errordlg(getString(errorMsg), errorDlgTitle, 'modal');                
            end
        end
        
        %------------------------------------------------------------------
        function tf = areFileNamesBad(this, fileNames1, fileNames2)
            errorDlgTitle = vision.getMessage(...
                'vision:caltool:LoadingStereoImagesFailedTitle');
            errorMsg = vision.internal.calibration.tool.checkStereoFileNames(...
                fileNames1, fileNames2, this.Dir1, this.Dir2);
            
            if isempty(errorMsg)
                tf = false;
            else
                tf = true;
                errordlg(getString(errorMsg), errorDlgTitle, 'modal');
            end
        end
    end
end

            
