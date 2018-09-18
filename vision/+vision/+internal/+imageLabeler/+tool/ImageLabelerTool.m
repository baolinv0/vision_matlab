% This class is for internal use only and may change in the future.

% ImageLabelerTool Main class for Image Labeler
%
%   To invoke the tool, follow these steps:
%       tool = vision.internal.imageLabeler.tool.ImageLabelerTool;
%       tool.show();

% Copyright 2015-2017 The MathWorks, Inc.

classdef ImageLabelerTool < vision.internal.labeler.tool.LabelerTool
    
    properties(Access = protected,Constant)
        % ToolName Official name of app, e.g Ground Truth Labeler
        ToolName = vision.getMessage('vision:imageLabeler:ToolTitle');
        
        % InstanceName Name used to manage tool instance.
        InstanceName = 'imageLabeler';
        
        % SupportedROILabelTypes Array of ROI labelTypes the app supports.
        % This defines the type of ROIs that are allowed when defining ROI
        % labels.
        SupportedROILabelTypes = [labelType.Rectangle labelType.PixelLabel];
    end
    
    properties (Access = protected)
        %StopAlgRun     Flag for stopping algorithm run.
        StopAlgRun = true;
    end
    
    %----------------------------------------------------------------------
    % Displays
    %----------------------------------------------------------------------
    properties(Access = protected)
        % LabeledImageBrowserDisplay The display that shows the image,
        %                            image labels, and image browswer.
        LabeledImageBrowserDisplay
        
    end
    
    methods(Access = public)
        function this = ImageLabelerTool()
            
            % Generate a temporary, unique name for the tool.
            [~,name] = fileparts(tempname);
            
            this.ToolGroup = matlab.ui.internal.desktop.ToolGroup(...
                this.ToolName, name);
            
            % Build a tab group to hold app tabs.
            this.TabGroup = matlab.ui.internal.toolstrip.TabGroup();
            
            % Add the tab group to the tool group.
            this.ToolGroup.addTabGroup(this.TabGroup);
            
            % Add the main tab to this tab group.
            this.LabelTab       = vision.internal.imageLabeler.tool.LabelTab(this);
            this.SemanticTab    = vision.internal.labeler.tool.SemanticTab(this);
            this.AlgorithmTab   = vision.internal.imageLabeler.tool.AlgorithmTab(this);
            
            % When the app starts up, the Label Tab is active.
            this.ActiveTab = this.LabelTab;
            
            % Add Session Manager
            this.SessionManager = vision.internal.imageLabeler.tool.ImageLabelerSessionManager;
            
            % Create Session
            this.Session = vision.internal.imageLabeler.tool.Session;
            
            % Add Automation Setup manager
            this.AlgorithmSetupHelper = vision.internal.labeler.tool.AlgorithmSetupHelper(this.InstanceName);
            addlistener(this.AlgorithmSetupHelper, 'CaughtExceptionEvent', @(src,evt) this.showExceptionDialog(evt.ME, evt.DlgTitle));
            
            % Add App Figure Managers
            this.LabeledImageBrowserDisplay = vision.internal.imageLabeler.tool.LabeledImageBrowserDisplay();
            this.ROILabelSetDisplay     = vision.internal.labeler.tool.ROILabelSetDisplay(this.InstanceName);
            this.FrameLabelSetDisplay   = vision.internal.labeler.tool.FrameLabelSetDisplay(this.InstanceName);
            this.InstructionsSetDisplay = vision.internal.labeler.tool.InstructionsSetDisplay();                     
            
            % Add scene label legend display
            hFig = this.LabeledImageBrowserDisplay.Fig;
            this.LegendDisplay = vision.internal.labeler.tool.FrameLabelLegendDisplay(hFig);
            
            % Add doc link
            this.ToolGroup.setContextualHelpCallback(@(es, ed) doc('imageLabeler'));
            
            % Add undo/redo to callbacks quick-access bar
            this.configureQuickAccessBarUndoRedoButton(this.LabeledImageBrowserDisplay);
                
            % Handle closing of the app
            this.setClosingApprovalNeeded(true);
            addlistener(this.ToolGroup, 'GroupAction', @(es,ed)doAppClientActions(this, es, ed));
           
            
            % Add tool to array of instances
            this.addToolInstance();
            
        end
       
        function doLoadLabelDefinitionsFromFile(this,fileName)

            setWaiting(this.ToolGroup, true);
            try
                % Load the MAT-file.
                temp = load(fileName,'-mat');
                
                % The MAT-file is expected to return a struct with a single
                % field whose value is of type table.
                fields = fieldnames(temp);
                definitions = temp.(fields{1});
                
                definitions = vision.internal.labeler.validation.checkLabelDefinitions(definitions);
                
                if ismember('PixelLabelData', definitions.Name)
                    % PixelLabelData is reserved for all pixel label ROI.
                    errordlg(...
                        vision.getMessage('vision:labeler:LabelDefContainsPixelLabelDataMsg'),...
                        vision.getMessage('vision:labeler:LabelNameInvalidDlgName'),...
                        'modal');
                    setWaiting(this.ToolGroup, true);
                    return
                end
                
                % Delete the current definitions
                deleteAllItemsLabelSetDisplay(this);
                
                % Update session data
                this.Session.loadLabelDefinitions(definitions);

            catch
                handleLoadDefinitionError(this, fileName, vision.getMessage('vision:imageLabeler:ToolTitle'));
                return;
            end
            
            reconfigureROILabelSetDisplay(this);
            
            reconfigureFrameLabelSetDisplay(this);
            
            if hasImages(this.Session)
                % Update Display
                drawImage(this, this.getCurrentIndex(), false);
            end
            
            updateUI(this);
            
            setWaiting(this.ToolGroup, false);
        end         
        
    end
    
    %----------------------------------------------------------------------
    % App Layout
    %----------------------------------------------------------------------
    methods (Access = protected)
        
        function configureDisplays(this)
            
            configure(this.LabeledImageBrowserDisplay, ...
                @this.doImageSelected, ...
                @this.doImageRemoved, ...
                @this.doImageRotate, ...
                @this.doLabelIsChanged, ...
                @this.doFigKeyPress, ...
                @this.doModeChange, ...
                @this.doDisableAppForPolygon, ...
                @this.doEnableAppForPolygon);
            
            % Configure label set display
            configure(this.ROILabelSetDisplay, ...
                @this.doROILabelSelectionCallback, ...
                @this.doROILabelAdditionCallback, ...
                @this.doROILabelModificationCallback, ...
                @this.doROILabelDeletionCallback, ...
                @this.doFigKeyPress);
            
            % Configure frame label set display
            configure(this.FrameLabelSetDisplay, ...
                @this.doFrameLabelCallback, ...
                @this.doFrameUnlabelCallback, ...
                @this.doFrameLabelSelectionCallback, ...
                @this.doFrameLabelAdditionCallback, ...
                @this.doFrameLabelModificationCallback, ...
                @this.doFrameLabelDeletionCallback, ...
                @this.doFigKeyPress);
            
        end
        
        %------------------------------------------------------------------
        function addDisplaysToApp(this)
            addFigureToApp(this.LabeledImageBrowserDisplay, this);
            
            addFigureToApp(this.FrameLabelSetDisplay, this);
            
            addFigureToApp(this.ROILabelSetDisplay, this);
            
            addFigureToApp(this.InstructionsSetDisplay, this);
        end
        
        %------------------------------------------------------------------
        function doAppActivated(this)
            if ~isvalid(this)
                return
            end
            % labelers should implement this
            if this.Session.HasROILabels && this.Session.hasImages()...
                    && strcmp(this.LabelTab.getModeSelection, 'ROI')
                drawnow; % flush any pending callbacks before enableing drawing.
                this.LabeledImageBrowserDisplay.enableDrawing();
            end
        end
        
        %------------------------------------------------------------------
        function doAppDeactivated(this)
            if ~isvalid(this)
                return
            end
             if this.Session.HasROILabels && this.Session.hasImages() ...
                     && strcmp(this.LabelTab.getModeSelection, 'ROI')
                drawnow; % flush any pending callbacks before disabling drawing.
                 this.LabeledImageBrowserDisplay.disableDrawing();
             end
        end
        
        %------------------------------------------------------------------
        function doTileLayout(this, varargin)
            doTileLayoutForStandardLabelerDefaultView(this, ...
                this.LabeledImageBrowserDisplay, varargin{:})
        end
        
        %------------------------------------------------------------------
        function updateTileLayout(this, showInstructions)
            
            % Make sure figures are rendered before tiling
            drawnow;
            
            grpName = getGroupName(this);
            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            
            layoutChanged = md.getDocumentTiledDimension(grpName)~=java.awt.Dimension(3,2);
            
            % If the layout changed, we need to retile all figures.
            % Otherwise, we only need to update the instruction set display
            % figure.
            if layoutChanged
                doTileLayout(this, showInstructions);
            else
                if showInstructions
                    % Instructions panel view, set width to 0.2
                    md.setDocumentColumnWidths(grpName, [0.2, 0.6 0.2]);
                    makeFigureVisible(this.InstructionsSetDisplay);
                    drawnow();
                    
                    md.setClientLocation(this.InstructionsSetDisplay.Name,grpName,...
                        com.mathworks.widgets.desk.DTLocation.create(2));
                else
                    % Default view, set width of tile 2 to zero
                    makeFigureInvisible(this.InstructionsSetDisplay);
                    drawnow();
                    
                    md.setDocumentColumnWidths(grpName, [0.2, 0.8]);
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function updateUI(this)
            
            % Flag which indicates labels exist or not in the app
            anyLabels = this.Session.HasROILabels || this.Session.HasFrameLabels;
            
            if getNumImages(this.Session)
                
                % Enable label tab controls
                enableControls(this.LabelTab);
                enableControls(this.SemanticTab);
                
                % Enable ROI button if needed
                enableROIButton(this.LabelTab,this.Session.HasROILabels);
                enableROIButton(this.SemanticTab,this.Session.HasROILabels);
                enableROIButton(this.AlgorithmTab,this.Session.HasROILabels);
                
                modeSelection = this.LabelTab.getModeSelection;
                this.setMode(modeSelection);                
                
                % Enable Show Label Checkboxes
                enableShowLabelBoxes(this.LabelTab, ...
                    this.Session.hasRectangularLabels, ...
                    this.Session.HasFrameLabels);                
                enableShowLabelBoxes(this.AlgorithmTab, ...
                    this.Session.hasRectangularLabels, ...
                    this.Session.HasFrameLabels);                
                
                % Make alg section enabled only if labels exist and images are
                % loaded.
                enableAlgFlag = anyLabels && getNumImages(this.Session);
                enableAlgorithmSection(this.LabelTab,enableAlgFlag);
                
                % Enable export section
                enableExportSection(this.LabelTab,anyLabels)                
            else
                disableControls(this.LabelTab);
                disableControls(this.SemanticTab);
            end
            
            % Enable label definition save option if needed
            if anyLabels
                enableSaveLabelDefinitionsItem(this.LabelTab,true);
            else
                enableSaveLabelDefinitionsItem(this.LabelTab,false);
            end
            
            % Enable import annotations.
            enableImportAnnotationsButton(this.LabelTab, true);
            
            % Make frame label panel interactive if needed
            if this.Session.HasFrameLabels && getNumImages(this.Session)
                this.FrameLabelSetDisplay.unfreezeOptionPanel();
            else
                this.FrameLabelSetDisplay.freezeOptionPanel();
            end
            
            % Show Semantic Tab
            if ~hasPixelLabels(this.Session)
                hideContextualSemanticTab(this);
            end
        end
        
        %------------------------------------------------------------------
        function doDisableAppForPolygon(this,~,~)
            
            % Disable Toolstrip
            disableAllControls(this.LabelTab);
            disableControls(this.SemanticTab);
            disableControls(this.AlgorithmTab);
            
            % Disable Browser
            freezeBrowserInteractions(this.LabeledImageBrowserDisplay);
            
            % Make panels uneditable.
            freeze(this.ROILabelSetDisplay);
            disableAllItems(this.ROILabelSetDisplay);
            freeze(this.FrameLabelSetDisplay);
            disableAllItems(this.FrameLabelSetDisplay);
            freezeOptionPanel(this.FrameLabelSetDisplay);
        end
        
        %------------------------------------------------------------------
        function doEnableAppForPolygon(this,~,~)
            
            unfreezeLabelPanels(this);
            
            algorithmTab = getTab(this.AlgorithmTab);
            if any(strcmp(this.ToolGroup.TabNames,algorithmTab.Tag))
                enableControls(this.AlgorithmTab);
                freezeLabelPanels(this);
                % Disable settings in algorithm tab if needed.
                if ~hasSettingsDefined(this.AlgorithmSetupHelper)
                    disableSettings(this.AlgorithmTab);
                else
                    enableSettings(this.AlgorithmTab);
                end
            end
            
            unfreezeBrowserInteractions(this.LabeledImageBrowserDisplay);
            
            this.updateUI();
        end
        
        %------------------------------------------------------------------
        function showContextualSemanticTab(this)
            
            show(this.SemanticTab);
            this.ActiveTab = this.SemanticTab;
        end
        
        %------------------------------------------------------------------
        function hideContextualSemanticTab(this)
            
            % Hide the semantic tab if it's present
            semanticTab = getTab(this.SemanticTab);
            if any(strcmp(this.ToolGroup.TabNames,semanticTab.Tag))
                hide(this.SemanticTab);
            end
            
            % Figure out which tab is now active.
            labelTab = getTab(this.LabelTab);
            selectedTab = this.ToolGroup.SelectedTab;
            
            % SelectedTab is empty at construction. At this time, only the
            % label tab must be visible
            if isempty(selectedTab) || strcmp(labelTab.Tag, selectedTab)
                this.ActiveTab = this.LabelTab;
            else
                this.ActiveTab = this.AlgorithmTab;
            end
        end
        
        %------------------------------------------------------------------
        function resetFocus(this)
            
            grabFocus(this.LabeledImageBrowserDisplay);
        end
        
        %------------------------------------------------------------------
        function finalize(this)
            
            finalize(this.LabeledImageBrowserDisplay);
        end
        
        %------------------------------------------------------------------
        function reset(this)
            [data, ~] = this.Session.readData(getCurrentIndex(this));
            resetPixelLabeler(this.LabeledImageBrowserDisplay,data);
        end
    end
    
    %----------------------------------------------------------------------
    % Labeled Image Display Callbacks
    %----------------------------------------------------------------------
    methods(Access = protected)
        function doImageSelected(this, varargin)
            
            % Finalize any label information.
            finalize(this);
            
            evtData = varargin{2};
            
            % Do not draw on Multi-Selection
            if ~isempty(evtData.Index) && numel(evtData.Index) == 1
                this.drawImage(evtData.Index, false);
            end
        end
        
        function doImageRemoved(this, varargin)
            
            setWaiting(this.ToolGroup, true);
            
            evtData = varargin{2};
            
            removedImageIndices = evtData.Index;
            
            if ~isempty(removedImageIndices)
                removeImagesFromSession(this.Session, removedImageIndices);

                % The pixel labeler needs to be reset since it contains stale
                % information about a image that was deleted. The newIdx chosen
                % is in sync with the method used to calculate the index when
                % selecting the image, in the event of images being removed.
                newIdx = min(max(removedImageIndices), getNumImages(this.Session));       
                if newIdx > 0
                    drawImage(this, newIdx, true);
                else
                    % Reset Image Browser Display
                    reset(this.LabeledImageBrowserDisplay);   

                    % The labeling mode needs to be set since the 
                    % LabeledImageBrowserDisplay is reset and the current
                    % Labeler information is empty. Also, the current label is
                    % selected, hence a label selection callback does not work
                    % here unless a new label is selected.
                    labelID = this.ROILabelSetDisplay.CurrentSelection;

                    if labelID > 0
                        % Query label information from session
                        roiLabel = this.Session.queryROILabelData(labelID);

                        setLabelingMode(this, roiLabel.ROI);

                        this.LabeledImageBrowserDisplay.updateLabelSelection(roiLabel);

                    end
                end

                updateUI(this);
            end
            
            setWaiting(this.ToolGroup, false);
        end        
        
        function doImageRotate(this, varargin)
            % Rotate the image based on the context menu choice
            
            setWaiting(this.ToolGroup, true);
            
            % Finalize any label information.
            finalize(this);
            
            evtData = varargin{2};
            imagesToBeRotatedIdx = evtData.Index;
            rotationType = evtData.RotationType;
            
            if ~isempty(imagesToBeRotatedIdx)
                displayMessage = vision.getMessage('vision:imageLabeler:RotateImageWarning');
                dialogName = vision.getMessage('vision:imageLabeler:RotateImage');
                dlg = vision.internal.uitools.QuestDlg(this.getGroupName(), displayMessage, dialogName);
                wait(dlg);
                
                if dlg.IsYes
                    currentImageIdx = imagesToBeRotatedIdx(1);
                    rotatedImages = rotateImages(this.Session, imagesToBeRotatedIdx, rotationType);
                    
                    if ~isempty(find(rotatedImages==currentImageIdx, 1))
                        clearImage(this.LabeledImageBrowserDisplay);
                        drawImage(this, currentImageIdx, true);
                    end
                    
                    numRotateImg = numel(rotatedImages);
                    numImgToBeRotated = numel(imagesToBeRotatedIdx);
                    if (numRotateImg > 0)  && numRotateImg < numImgToBeRotated
                        errorMessage = vision.getMessage('vision:imageLabeler:RotateImageErrorSome');
                        dialogName   = vision.getMessage('vision:imageLabeler:RotateImage');
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                    elseif numRotateImg == 0
                        errorMessage = vision.getMessage('vision:imageLabeler:RotateImageErrorAll');
                        dialogName   = vision.getMessage('vision:imageLabeler:RotateImage');
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                    end
                end
            end
            
            setWaiting(this.ToolGroup, false);
            
        end
        
        %------------------------------------------------------------------
        function drawImage(this, idx, forceRedraw)
            if ~hasImages(this.Session)
                return;
            end
            
            [data, exceptions] = this.Session.readData(idx);
            
            if ~isempty(exceptions)
                msg = sprintf('%s\n', exceptions(:).message);
                errorMessage = vision.getMessage('vision:imageLabeler:ReadDataError',msg);
                dialogName   = vision.getMessage('vision:imageLabeler:ReadDataErrorTitle');
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg)                
            end
            
            data.ForceRedraw = forceRedraw;
            draw(this.LabeledImageBrowserDisplay, data);
            
            % Update the Frame Label Display
            updateFrameLabelStatus(this.FrameLabelSetDisplay, data.SceneLabelIds);
            
            % Update legend display
            % Sync the image axes since a new image is drawn every time
            % an image is selected which blows off the previous axes
            syncImageAxes(this.LabeledImageBrowserDisplay, this.LegendDisplay);
            if isSceneLabelBoxEnabled(this.LabelTab)
                show(this.LegendDisplay);
            end
            this.LegendDisplay.update(data.SceneLabelIds);
        end
        
        %------------------------------------------------------------------
        function doLabelIsChanged(this, ~, data)
            % Handle ROI label changes for rectangles and pixel label
            % types.
            
            % Write label matrix to temp file
            if isa(data,'vision.internal.labeler.tool.PixelLabelEventData')
                
                % Update annotations and write label matrix only when there
                % are valid labelType.PixelLabel labels
                if hasPixelLabels(this.Session)
                    updatePixelLabelAnnotations(this, data.Data);
                end
                
            else
                updateROIsAnnotations(this, data.Data);
            end
            
        end
        
        %------------------------------------------------------------------
        % Update Session with Pixel Label Annotations.
        %
        %
        %------------------------------------------------------------------
        function updatePixelLabelAnnotations(this, labelData)
            
            % Check for empty temp directory
            if isempty(this.Session.TempDirectory)
                % Create tempdir folder with unique name
                foldername = setTempDirectory(this);
                if ~isempty(foldername)
                    % Update label matrix filename
                    labelData.Position = fullfile(foldername,labelData.Position);
                    setLabelMatrixFilename(this.LabeledImageBrowserDisplay,labelData.Position);
                end
            end
            
            % Unpack data.
            labelNames     = labelData.Label;
            labelPositions = labelData.Position;
            index          = labelData.Index;
            
            TF = writeData(this.Session,labelNames,index);
            
            % Catch error writing data, prompt user for new directory, move
            % all temp data over to new directory, delete old directory,
            % and then write current label matrix into new directory
            if ~TF
                oldDirectory = this.Session.TempDirectory;
                [~,name] = fileparts(tempname);
                foldername = vision.internal.labeler.tool.selectDirectoryDialog(name);
                if ~isempty(foldername)
                    % Update label matrix filename
                    labelData.Position = fullfile(foldername,labelData.Position);
                    setLabelMatrixFilename(this.LabeledImageBrowserDisplay,labelData.Position);
                end
                setTempDirectory(this.Session,foldername);
                importPixelLabelData(this.Session);
                if isdir(oldDirectory)
                    rmdir(oldDirectory,'s');
                end
                writeData(this.Session,labelNames,index);
            end
            
            % Update session
            setPixelLabelAnnotation(this.Session, index, labelPositions);
            
        end
        
        %------------------------------------------------------------------
        function idx = getCurrentIndex(this)
            idx = getCurrentImageIndex(this.LabeledImageBrowserDisplay);
        end
        
        %------------------------------------------------------------------
        function doFigKeyPress(this,~,src)
            
            modifierKeys = {'control','command'};
            
            keyPressed = src.Key;
            modPressed = src.Modifier;
            
            if strcmp(modPressed, modifierKeys{ismac()+1})
                switch keyPressed
                    case 'a'
                        this.LabeledImageBrowserDisplay.selectAllROIs();
                    case 'c'
                        this.LabeledImageBrowserDisplay.copySelectedROIs();
                    case 'v'
                        this.LabeledImageBrowserDisplay.pasteSelectedROIs();
                    case 'x'
                        this.LabeledImageBrowserDisplay.cutSelectedROIs();
                    case 'y'
                        this.LabeledImageBrowserDisplay.redo();
                    case 'z'
                        this.LabeledImageBrowserDisplay.undo();
                    case 's'
                        this.saveSession();
                    case 'o'
                        this.loadSession();
                end
            else
                isAltPressed = strcmp(modPressed, 'alt');
                
                if isAltPressed
                    switch keyPressed
                        case 'uparrow'
                            this.FrameLabelSetDisplay.selectPrevItem();
                        case 'downarrow'
                            this.FrameLabelSetDisplay.selectNextItem();
                    end
                else
                    
                    switch keyPressed
                        case 'uparrow'
                            this.ROILabelSetDisplay.selectPrevItem()
                        case 'downarrow'
                            this.ROILabelSetDisplay.selectNextItem();
                        case {'rightarrow', 'leftarrow', 'home', 'end', 'pagedown', 'pageup'}
                            % navigate image browser. Does shift select
                            % behavior as well.
                            this.LabeledImageBrowserDisplay.doBrowserKeyPress(src);
                        case {'delete','backspace'}
                            this.LabeledImageBrowserDisplay.deleteSelectedROIs();
                        case 'return'
                            finalize(this);
                    end
                end
            end
        end
        
    end
    
    %----------------------------------------------------------------------
    % ROI Label Definition Callbacks
    %----------------------------------------------------------------------
    methods
        
        function doROILabelAdditionCallback(this, varargin)
            
            % This callback handles the addition of a new ROI Label.
            
            % Launch ROI Label definition dialog
            dlg = vision.internal.labeler.tool.ROILabelDefinitionDialog(...
                this.getGroupName(),this.Session.ROILabelSet, this.SupportedROILabelTypes);
            
            % Set PixelLabelData as an invalid label name. It is reserved
            % for all pixel label in the groundTruth LabelData table.
            dlg.InvalidLabelNames = {'PixelLabelData'};
            
            wait(dlg);
            
            if ~dlg.IsCanceled
                
                % update session here
                roiLabel = dlg.getDialogData();
                
                if ~this.Session.isValidName( roiLabel.Label )
                    errorMessage = vision.getMessage('vision:labeler:LabelNameExistsDlgMsg',roiLabel.Label);
                    dialogName   = getString( message('vision:labeler:LabelNameExistsDlgName') );
                    errordlg(errorMessage, dialogName, 'modal');
                    return;
                end
                           
                if roiLabel.ROI == labelType.PixelLabel
                    % Determine pixel label id for new label.
                    roiLabel.PixelLabelID = this.Session.getPixelLabels();
                end
                
                % color is automatically generated inside
                roiLabel = this.Session.addROILabel(roiLabel);
                
                if this.ROILabelSetDisplay.NumItems == 0
                    hideHelperText(this.ROILabelSetDisplay);
                end
                
                % update display. When new items get added, it will become
                % the new selection.
                this.ROILabelSetDisplay.appendItem( roiLabel );
                this.ROILabelSetDisplay.selectLastItem();
            end
            
            this.updateUI();
        end
        
        function doROILabelModificationCallback(this, ~, data)
            % This callback is called when an ROI Label is modified.
            labelID = data.Index;
            roiLabel = this.Session.ROILabelSet.queryLabel(labelID);
            
            % Launch ROI Label definition dialog
            dlg = vision.internal.labeler.tool.ROILabelDefinitionDialog(...
                this.getGroupName(),roiLabel, this.SupportedROILabelTypes);
            wait(dlg);
            
            if ~dlg.IsCanceled
                
                % update session here
                roiLabel = dlg.getDialogData();
                
                % update display.
                this.ROILabelSetDisplay.modifyItem(labelID, roiLabel);
                
                this.Session.ROILabelSet.updateLabelDescription(labelID, roiLabel.Description);
                this.Session.IsChanged = true;
            end
        end
        
        function doROILabelDeletionCallback(this, ~, data)
            % This callback is called when an ROI Label is deleted.
             
            displayMessage = vision.getMessage('vision:labeler:DeletionDefinitionWarning');
            dialogName = 'Warning';
            dlg = vision.internal.uitools.QuestDlg(this.getGroupName(), displayMessage, dialogName);
            wait(dlg);
            
            if dlg.IsYes
                % Update session data
                labelID = data.Index;
                roiLabel = queryROILabelData(this.Session, labelID);
                
                if hasImages(this.Session) && roiLabel.ROI == labelType.PixelLabel
                    
                    finalize(this);
                    deletePixelLabelData(this.Session,roiLabel.PixelLabelID);
                    deletePixelLabelData(this.LabeledImageBrowserDisplay,roiLabel.PixelLabelID);
                    
                end
                
                this.Session.deleteROILabel(labelID);
                
                % Update label display
                this.ROILabelSetDisplay.deleteItem(data);
                
                % Perform actions when a specifc ROI label is removed.
                %  * reset undo/redo and purge clipboard because these
                %    could hold mixed ROI labesl
                this.LabeledImageBrowserDisplay.cleanupForROIRemoved(roiLabel.ROI);
                
                this.updateUI();
                
                % Update Display
                drawImage(this, this.getCurrentIndex(), false)      

            end
        end
        
        function doROILabelSelectionCallback(this, varargin)
            % This callback is called when an ROI Label is selected
            labelID = this.ROILabelSetDisplay.CurrentSelection;
            
            % Query label information from session
            roiLabel = this.Session.queryROILabelData(labelID);
            
            % Set to Label Mode irrespective of what mode was chosen before
            setMode(this, 'ROI'); 
            
            setLabelingMode(this, roiLabel.ROI)
            
            if roiLabel.ROI == labelType.Rectangle
                finalize(this);
            end
            
            this.updateUI();
            
            % Update label selection on video display
            this.LabeledImageBrowserDisplay.updateLabelSelection(roiLabel);
        end
        
    end
    
    %----------------------------------------------------------------------
    % Frame Label Definition Callbacks
    %----------------------------------------------------------------------
    methods
        function doFrameLabelAdditionCallback(this, ~, ~)
            % This callback handles the addition of a new frame label.
            
            % Launch frame label definition dialog
            dlg = vision.internal.labeler.tool.FrameLabelDefinitionDialog(...
                this.getGroupName(),this.Session.FrameLabelSet);
            
            % PixelLabelData is reserved for all pixel label ROIs. 
            dlg.InvalidLabelNames = {'PixelLabelData'};
            
            wait(dlg);
            
            if ~dlg.IsCanceled
                
                frameLabel = dlg.getDialogData();
                
                if ~this.Session.isValidName( frameLabel.Label )
                    errorMessage = vision.getMessage('vision:labeler:LabelNameExistsDlgMsg',frameLabel.Label);
                    dialogName   = getString( message('vision:labeler:LabelNameExistsDlgName') );
                    dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                    wait(dlg);
                    return;
                end
                
                % color is automatically generated inside.
                frameLabel = this.Session.addFrameLabel(frameLabel);
                
                if this.FrameLabelSetDisplay.NumItems<1
                    hideHelperText(this.FrameLabelSetDisplay);
                end
                
                % update display. When new items get added, it will become
                % the new selection.
                this.FrameLabelSetDisplay.appendItem( frameLabel );
                this.FrameLabelSetDisplay.selectLastItem();
                
                this.LegendDisplay.onLabelAdded(frameLabel.Label, frameLabel.Color);
                if getNumImages(this.Session) == 0
                    hide(this.LegendDisplay);
                end
            end
            
            this.updateUI();
        end
        
        function doFrameLabelSelectionCallback(~, varargin)
            % This callback is called when a Frame Label is selected.
            
            % TODO should this be removed?
        end
        
        function doFrameLabelModificationCallback(this, ~, data)
            % This callback is called when a Frame Label is modified.
            
            labelID = data.Index;
            frameLabel = this.Session.FrameLabelSet.queryLabel(labelID);
            
            % Launch frame label definition dialog
            dlg = vision.internal.labeler.tool.FrameLabelDefinitionDialog(...
                this.getGroupName(),frameLabel);
            wait(dlg);
            
            if ~dlg.IsCanceled
                
                frameLabel = dlg.getDialogData();
                
                % update display.
                this.FrameLabelSetDisplay.modifyItem(labelID, frameLabel);
                
                this.LegendDisplay.onLabelModified(labelID, frameLabel.Label);
                
                this.Session.FrameLabelSet.updateLabelDescription(labelID, frameLabel.Description);
                this.Session.IsChanged = true;
            end
        end
        
        function doFrameLabelDeletionCallback(this, ~, data)
            % This callback is called when a Frame Label is deleted.
            
            displayMessage = vision.getMessage('vision:labeler:DeletionDefinitionWarning');
            dialogName = 'Warning';
            dlg = vision.internal.uitools.QuestDlg(this.getGroupName(), displayMessage, dialogName);
            wait(dlg);
            
            if dlg.IsYes
                labelID = data.Index;
                this.Session.deleteFrameLabel(labelID);
                this.FrameLabelSetDisplay.deleteItem( data );
                
                this.LegendDisplay.onLabelRemoved(labelID);
                
                this.updateUI();
            end
        end
        
        function doFrameLabelCallback(this, ~, data)
            % This callback is called when a user labels a frame or frame
            % interval.
            
            updateFrameLabelData(this, data, 'add');
        end
        
        function doFrameUnlabelCallback(this, ~, data)
            % This callback is called a user removes a frame label
            
            updateFrameLabelData(this, data, 'delete');
        end
        
        function updateFrameLabelData(this, data, addOrDelete)
            
            indices = this.LabeledImageBrowserDisplay.SelectedImageIndex;
            
            frameLabel = this.Session.queryFrameLabelData(data.LabelID);
            
            % add to the session data
            for i = 1:numel(indices)
                switch addOrDelete
                    case 'add'
                        addFrameLabelAnnotation(this.Session, indices(i), frameLabel.Label);
                        this.FrameLabelSetDisplay.checkFrameLabel(data.LabelID);
                    case 'delete'
                        deleteFrameLabelAnnotation(this.Session, indices(i), frameLabel.Label);
                        this.FrameLabelSetDisplay.uncheckFrameLabel(data.LabelID);
                end
            end
            
            % Update status for current index
            [~,~,ids] = queryFrameLabelAnnotation(this.Session, indices(1));
            this.LegendDisplay.update(ids);
        end
        
    end
    
    
    %----------------------------------------------------------------------
    % Pixel Label Mode Change Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % When one of the pixel label buttons on the toolstrip is pressed,
        % this method updates the PixelLabeler to change mode.
        %------------------------------------------------------------------
        function setPixelLabelMode(this, mode)
            setPixelLabelMode(this.LabeledImageBrowserDisplay, mode);
        end
        
        %------------------------------------------------------------------
        % When marker size slider on the toolstrip is changed, this method
        % updates the PixelLabeler to change the MarkerSize property.
        %------------------------------------------------------------------
        function setPixelLabelMarkerSize(this, sz)
            setPixelLabelMarkerSize(this.LabeledImageBrowserDisplay, sz);
        end
        
        %------------------------------------------------------------------
        % When the label opacity slider is changes, this method updates the
        % PixelLabeler to change the label opacity.
        %------------------------------------------------------------------
        function setPixelLabelAlpha(this, alpha)
            setPixelLabelAlpha(this.LabeledImageBrowserDisplay, alpha);
        end
        
    end
    
    
    %----------------------------------------------------------------------
    % Mode Change Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % When one of the mode buttons on the toolstrip is pressed, this
        % method updates the VideoDisplay to change mode.
        %------------------------------------------------------------------
        function setMode(this, mode)
            
            this.LabeledImageBrowserDisplay.setMode(mode);

            % Sync the different Tabs
            % If the mode is none, it means the button states should be ROI
            % button true and disabled and the all the other ones should be 
            % disabled. In this case it would be safe to assume to set the 
            % ROI button to true, but still disabled. This would allow to
            % perform the sync without any case checking.
            if strcmpi(mode, 'none')
                mode = 'ROI';
            end
            this.LabelTab.reactToModeChange(mode);
            this.SemanticTab.reactToModeChange(mode);
            this.AlgorithmTab.reactToModeChange(mode);
            
            % set focus back to image display
            resetFocus(this);
        end
        
        function setLabelingMode(this, mode)
            setLabelingMode(this.LabeledImageBrowserDisplay,mode);
            if mode == labelType.PixelLabel
                setROIIcon(this.LabelTab,'pixel');
                setROIIcon(this.SemanticTab,'pixel');
                showContextualSemanticTab(this);
                this.TabGroup.SelectedTab = getTab(this.SemanticTab);
            else
                setROIIcon(this.LabelTab,'roi');
                setROIIcon(this.SemanticTab,'roi');
                hideContextualSemanticTab(this);
            end
        end
        
        %------------------------------------------------------------------
        % When a mode change is requested through a context menu click,
        % this method will first take care of the toolstrip button updates
        % (press the appropriate mode button, unpress the others) and then
        % update the VideoDisplay to handle the changed mode.
        %------------------------------------------------------------------
        function doModeChange(this, ~, data)
            
            mode = data.Mode;
            this.ActiveTab.reactToModeChange(mode);
            
            % If there are no ROI labels, ignore the request to ROI mode.
            if ~this.Session.HasROILabels && strcmpi(mode, 'ROI')
                mode = 'none';
            end
            
            setMode(this, mode);
        end        
    end
    
    %----------------------------------------------------------------------
    % Export Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function exportLabelAnnotationsToWS(this)
            
            setWaiting(this.ToolGroup, true);
            
            resetWait = onCleanup(@()setWaiting(this.ToolGroup, false));
            
            finalize(this);

            variableName  = 'gTruth';
            
            if hasPixelLabels(this.Session)
                dlgTitle = vision.getMessage('vision:uitools:ExportTitle');
                toFile = false;
                exportDlg = vision.internal.labeler.tool.ExportPixelLabelDlg(...
                    this.getGroupName, variableName, dlgTitle, this.Session.getPixelLabelDataPath, toFile);
                wait(exportDlg);
                if ~exportDlg.IsCanceled
                    this.Session.setPixelLabelDataPath(exportDlg.VarPath);
                    TF = exportPixelLabelData(this.Session,exportDlg.CreatedDirectory);
                    if ~TF
                        errorMessage = getString( message('vision:labeler:UnableToExportDlgMessage') );
                        dialogName   = getString( message('vision:labeler:UnableToExportDlgName') );
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                        return;
                    end
                end
                    
                format = 'groundTruth';
            else
                allowTableFormatChoice = ~this.Session.hasSceneLabels();
                exportDlg = vision.internal.imageLabeler.tool.ExportDlg(this.getGroupName, variableName, allowTableFormatChoice);
                wait(exportDlg);
                format = exportDlg.VarFormat;
            end
            
            if ~exportDlg.IsCanceled
                varName = exportDlg.VarName;
                this.setStatusText(vision.getMessage('vision:labeler:ExportToWsStatus', varName));
                
                if strcmpi(format, 'groundTruth')
                    labels = exportLabelAnnotations(this.Session);
                    if hasPixelLabels(this.Session)
                        refreshPixelLabelAnnotation(this.Session);
                    end
                    assignin('base', varName, labels);
                    evalin('base', varName);
                else
                    % create table output
                    labels = exportLabelAnnotations(this.Session);
                    labels = labels.selectLabels(labelType.Rectangle);
                    tbl = table(labels.DataSource.Source,'VariableNames', {'imageFilename'});
                    tbl = [tbl labels.LabelData];
                    
                    assignin('base', varName, tbl);
                    evalin('base', varName);
                end
                this.setStatusText('');            
            end
            drawnow;
        end
        
        %------------------------------------------------------------------
        function exportLabelAnnotationsToFile(this)
            
            setWaiting(this.ToolGroup, true);
            
            resetWait = onCleanup(@()setWaiting(this.ToolGroup, false));
            
            finalize(this);
            
            if hasPixelLabels(this.Session)
                variableName = 'gTruth';
                dlgTitle = vision.getMessage('vision:labeler:ExportLabelsToFile');
                toFile = true;
                exportDlg = vision.internal.labeler.tool.ExportPixelLabelDlg(...
                    this.getGroupName, variableName, dlgTitle, this.Session.getPixelLabelDataPath, toFile);
                wait(exportDlg);
                proceed = ~exportDlg.IsCanceled;
                if proceed
                    TF = exportPixelLabelData(this.Session,exportDlg.CreatedDirectory);
                    
                    pathName = exportDlg.VarPath;
                    this.Session.setPixelLabelDataPath(pathName);
                    fileName = exportDlg.VarName;
                    
                    if ~TF
                        errorMessage = getString( message('vision:labeler:UnableToExportDlgMessage') );
                        dialogName   = getString( message('vision:labeler:UnableToExportDlgName') );
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                        return;
                    end
                end
                
            else
                [fileName, pathName, proceed] = uiputfile('*.mat', ...
                    vision.getMessage('vision:labeler:ExportLabels'));
            end
            
            if proceed
                this.setStatusText(vision.getMessage('vision:labeler:ExportToFileStatus', fileName));
                
                gTruth = exportLabelAnnotations(this.Session); %#ok<NASGU>
                if hasPixelLabels(this.Session)
                    refreshPixelLabelAnnotation(this.Session);
                end
                try
                    save(fullfile(pathName,fileName), 'gTruth');
                catch
                    errorMessage = getString( message('vision:labeler:UnableToExportDlgMessage') );
                    dialogName   = getString( message('vision:labeler:UnableToExportDlgName') );
                    dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                    wait(dlg);
                end
                
                this.setStatusText('');
                
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Load Callbacks
    %----------------------------------------------------------------------
    methods
        function loadImage(this)
           
            % Get image file names
            [fileNames, isUserCanceled] = imgetfile('MultiSelect', true);
            if isUserCanceled || isempty(fileNames)
                return;
            end
            
            doLoadImages(this, fileNames);
            
        end
        
        function loadImageFromDataStore(this)
           
            % Load images from a ImageDataStore variable in workspace
            variableTypes = {'matlab.io.datastore.ImageDatastore'};
            variableDisp =  {'ImageDatastore'};
            [imds,~,isCanceled] = vision.internal.uitools.getVariablesFromWS(variableTypes, variableDisp);
            
            if isCanceled
                return
            end
            
            if ~isempty(imds.Files)
                doLoadImages(this, imds.Files);
            end
        end
        
        function doLoadImages(this, fileNames)
            
            setWaiting(this.ToolGroup, true);
            
            this.setStatusText(vision.getMessage('vision:imageLabeler:LoadImageStatus'));
            
            turnOffWaiting = onCleanup(@()setWaiting(this.ToolGroup, false));
            
            uniqueImageFileNames = setdiff(unique(...
                [this.Session.ImageFilenames; reshape(fileNames,[],1)], 'stable'),...
                this.Session.ImageFilenames, 'stable');
            
            numImagesBeforeAdd = getNumImages(this.Session);
            
            % Add images to session
            addImagesToSession(this.Session, uniqueImageFileNames);
            
            numImagesAfterAdd = getNumImages(this.Session);
            
            % Select an Image to display
            if numImagesAfterAdd > numImagesBeforeAdd
                % Add images to the Browser
                imageData.Filenames = uniqueImageFileNames;
                appendImage(this.LabeledImageBrowserDisplay, imageData);
                selectImageByIndex(this.LabeledImageBrowserDisplay, numImagesBeforeAdd+1);
            end
            
            this.updateUI();
            
            this.setStatusText('');            
        end
    end
    
    %----------------------------------------------------------------------
    % View Callbacks
    %----------------------------------------------------------------------
    methods
        function showROILabelNames(this, showROILabelFlag)
            % Disable the ROI label display in Video Display
            showROILabelNames(this.LabeledImageBrowserDisplay, showROILabelFlag);
            
            % Sync the different tabs
            setShowROILabelBox(this.LabelTab, showROILabelFlag);
            setShowROILabelBox(this.AlgorithmTab, showROILabelFlag);
            
            % set focus back to image display
            resetFocus(this);
        end
    end
    
    %----------------------------------------------------------------------
    % Import Callbacks
    %----------------------------------------------------------------------
    methods
        
        function importLabelAnnotations(this, source)
            
            setWaiting(this.ToolGroup, true);
            
            this.setStatusText(vision.getMessage('vision:labeler:ImportLabelAnnotationsStatus'));
            
            setWaitingToFalseAtExit = onCleanup(@()setWaiting(this.ToolGroup, false));
            
            [success, gTruth] = importLabelAnnotationsPreWork(this, source);
             
            if ~success || isempty(gTruth)
                return;
            end
            
            % Validate gTruth            
            notValid = ~isscalar(gTruth) ...
                || ~isImageCollection(gTruth.DataSource);
            
            if notValid
                errorMessage = vision.getMessage('vision:imageLabeler:ImportLabelsInvalidGroundTruth');
                dialogName = vision.getMessage('vision:labeler:ImportError');
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg);
                
                return;
            end
            
            [gTruth, ~] = splitRegularAndCustomLabels(this, gTruth);         
             
            isPixelLabelType = gTruth.LabelDefinitions.Type == labelType.PixelLabel;
            hasPixelLabels = any(isPixelLabelType);
            currentSessionHasPixelLabels = this.Session.hasPixelLabels;
            
            % canImportLabels 
            %   * always true if only rectangles
            %   * for pixel label, TRUE if existing pixel labels match
            %     those being imported or existing session has no pixels
            %     labels.
            currentDefinitions = exportLabelDefinitions(this.Session);
            
            if hasPixelLabels
                
                % Check for empty temp directory
                if isempty(this.Session.TempDirectory)
                    % Create tempdir folder with unique name
                    setTempDirectory(this);
                end
                
                % Check that PixelLabelID is 1:numel(pixelLabelTypes)
                id = gTruth.LabelDefinitions{isPixelLabelType,'PixelLabelID'};
                
                % Must be scalars.
                allScalarLabelIDs = all(cellfun(@(x)isscalar(x), id));
                anyLabelIDAreZero = any(cellfun(@(x)x==0, id));
                
                if ~allScalarLabelIDs || anyLabelIDAreZero
                    errorMessage = 'Pixel label IDs must be scalars and be between 1 and 255.';
                    dialogName = 'Invalid PixelLabelID';
                    dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                    wait(dlg);

                    return;
                end
                
                if currentSessionHasPixelLabels
                    
                    
                    labelDefinitions   = gTruth.LabelDefinitions;
                    
                    % keep only pixel labels
                    currentPixelDefinitions = currentDefinitions( currentDefinitions.Type == labelType.PixelLabel, :);
                    labelDefinitions = labelDefinitions( labelDefinitions.Type == labelType.PixelLabel, :);
                    
                    if height(currentPixelDefinitions) ~= height(labelDefinitions)
                        
                        errorMessage = vision.getMessage('vision:labeler:ImportIncompatibleGroundTruthNameMismatch');
                        dialogName = vision.getMessage('vision:labeler:ImportError');
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                        return
                        
                    else
                        % check if names and pixel label ids match.
                        currentPixelDefinitions = sortrows(currentPixelDefinitions, 'Name');
                        labelDefinitions   = sortrows(labelDefinitions,   'Name');
                        
                        namesMatch = isequal(currentPixelDefinitions.Name, labelDefinitions.Name);
                        idsMatch   = isequal(currentPixelDefinitions.PixelLabelID, labelDefinitions.PixelLabelID);

                        canImportLabels = namesMatch && idsMatch;
                        
                        if ~namesMatch
                            errorMessage = vision.getMessage('vision:labeler:ImportIncompatibleGroundTruthNameMismatch');                            
                            dialogName = vision.getMessage('vision:labeler:ImportError');
                            dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                            wait(dlg);
                            return;
                        end
                        
                        if ~idsMatch
                            errorMessage = vision.getMessage('vision:labeler:ImportIncompatibleGroundTruthLabelIDMismatch');                            
                            dialogName = vision.getMessage('vision:labeler:ImportError');
                            dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                            wait(dlg);
                            return;
                        end
                    end
                    
                else
                    canImportLabels = true;
                end
            else
                % only rectangles. safe to add into session
                canImportLabels = true;
            end
            
            assert(canImportLabels, 'Internal Error');
                      
            % Merge gTruth into session. 
            %   * Rectangles are merged into existing session.
            %   * Pixel labels are only added if they match exactly the
            %     current set of pixel labels. IF there is any overlap
            %     between imported pixel label data and current session,
            %     then user is asked if they want to replace or keep
            %     originals.
            % 
             
            if hasImages(this.Session)
                % merge into session
                
                images = gTruth.DataSource.Source;
                currentImages = this.Session.ImageFilenames;
                labelData = gTruth.LabelData;
                
                % The the images in both current session and gTruth being
                % imported.
                [overlap, currentIndices, imageIdx] = intersect(currentImages, images, 'stable');
                
               
                % Should pixel lable data be replace or should the original
                % be kept. This is only required when existing session and
                % imported groundTruth have an overlap of image files.
                if hasPixelLabels && currentSessionHasPixelLabels

                    if ~isempty(overlap)
                        
                        replace = vision.getMessage('vision:labeler:ImportReplaceButtonPixelLabel');
                        keep    = vision.getMessage('vision:labeler:ImportKeepButtonPixelLabel');
                        cancel  = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
                        dlgMessage = vision.getMessage('vision:labeler:ImportReplaceOrKeepPixelLabel');
                        dlgTitle   = vision.getMessage('vision:labeler:ImportReplaceOrKeepPixelLabelTitle');
                        selection = questdlg(dlgMessage, dlgTitle, ...
                            replace, keep, cancel, replace);
                        
                        if isempty(selection) % dialog was destroyed with a click
                            selection = cancel;
                        end
                        
                        switch selection
                            case replace
                                % nothing to do                           
                            case keep
                                % set all PixelLabelData for overlapping
                                % images to '' to keep originals.
                                labelData{imageIdx,'PixelLabelData'} = {''};
             
                            case cancel
                                % Abort import
                                return;
                        end                                        
                    end

                end
                
                % add new rectangle label definitions and scene labels.
                % pixel labels are always the same.
                
                % find unique rectangle/scene labels in gTruth to add to session.
                isRectOrScene = (gTruth.LabelDefinitions.Type == labelType.Rectangle) ...
                    | (gTruth.LabelDefinitions.Type == labelType.Scene);
                
                currentRectDef  = currentDefinitions(...
                    currentDefinitions.Type == labelType.Rectangle ...
                    | currentDefinitions.Type == labelType.Scene ,:);  
              
                rectOrSceneDefinitions = gTruth.LabelDefinitions(isRectOrScene,:);
                [~, idx]        = setdiff(rectOrSceneDefinitions.Name, currentRectDef.Name);
                newDefinitions  = rectOrSceneDefinitions(idx,:);
                
                if ~isempty(newDefinitions)
                    % only add if there are new rectangles to add.
                    addLabelsDefinitions(this.Session, newDefinitions);
                end
                
                % add new images
                [newImages, newIdx] = setdiff(images, currentImages, 'stable');
                
                newIndices = [];
                newData = [];
                if ~isempty(newImages)
                    
                    % this adds images and updates annotation structs to
                    % correct size.
                    newIndices = getNumImages(this.Session) + (1:numel(newImages));
                    addImagesToSession(this.Session, newImages);
                    newData = labelData(newIdx,:);
                   
                end
                
                labelDataForExistingImages = [];
                if ~isempty(currentIndices)
                    % data to update existing images with.
                    labelDataForExistingImages = labelData(imageIdx,:);
   
                end
                
                % If data needs to be merged
                if ~isempty(newIndices)
                    labelData   = [labelDataForExistingImages; newData];
                    indices     = [currentIndices; newIndices];
                else
                    labelData   = labelDataForExistingImages;
                    indices     = currentIndices;
                end
                
                addLabelData(this.Session, gTruth.LabelDefinitions, labelData, indices);
           
                
            else
                % Add labels to blank session.
                this.Session.loadLabelAnnotations(gTruth);
            end
  
            reconfigureUI(this);
            
            this.setStatusText('');
            
        end
        
        %------------------------------------------------------------------
        function reconfigureUI(this)
            % called after load session or import labels
            
            if hasImages(this.Session)
                this.LabeledImageBrowserDisplay.loadImages(this.Session.ImageFilenames);
            end
            
            % Update the display with the Labels
            reconfigureROILabelSetDisplay(this);
            
            % Select first image.
            if hasImages(this.Session)
                selectImageByIndex(this.LabeledImageBrowserDisplay, 1);
            end
            
            reconfigureFrameLabelSetDisplay(this);
            
            this.updateUI();
        end
    end
    
    %----------------------------------------------------------------------
    % Session Callbacks
    %----------------------------------------------------------------------
    methods
        function doLoadSession(this, pathName, fileName, varargin)
            
            % Indicate that this is going to take some time
            setWaiting(this.ToolGroup, true);
            
            % proceed with loading new session.
            loadedSession = this.SessionManager.loadSession(pathName, fileName);
            
            if isempty(loadedSession)
                setWaiting(this.ToolGroup, false);
                return;
            end
            
            
            % User has commited to load by not pushing cancel and the
            % current session is good to wipe.
            %
            % Delete Labels only after succesfully loading the
            % session. Otherwise, if the user cancels out from
            % loading the session their current labels will be
            % deleted.
            this.cleanSession();
            
            this.Session = loadedSession;
            
            % Set temp directory if session has pixel labels
            if hasPixelLabels(this.Session)
                setTempDirectory(this);
            end
            
            % Import any pixel label data
            TF = importPixelLabelData(this.Session);
            
            % If error importing pixel label data, prompt user for new
            % directory
            if ~TF
                oldDirectory = this.Session.TempDirectory;
                [~,name] = fileparts(tempname);
                foldername = vision.internal.labeler.tool.selectDirectoryDialog(name);
                setTempDirectory(this.Session,foldername);
                importPixelLabelData(this.Session);
                if isdir(oldDirectory)
                    rmdir(oldDirectory,'s');
                end
            end
            
            reconfigureUI(this);
            
            % Set session file name as name in title bar of app
            [~, fileName] = fileparts(fileName);
            this.ToolGroup.Title = getString(message(...
                'vision:labeler:ToolTitleWithSession', this.ToolName, fileName));
            
            setWaiting(this.ToolGroup, false);
            
        end
        
        %------------------------------------------------------------------
        function newSession(this)
            
            % Indicate that this is going to take some time
            setWaiting(this.ToolGroup, true);
            
            this.setStatusText(vision.getMessage('vision:imageLabeler:NewSessionStatus'));
            
            % First check if we need to save anything before wiping the
            % existing data
            isCanceled = this.processSessionSaving();
            
            if isCanceled
                setWaiting(this.ToolGroup, false);
                return;
            end    
            
            this.cleanSession();
            
            this.setStatusText('');
            
            setWaiting(this.ToolGroup, false);
        end
        
        %------------------------------------------------------------------
        function cleanSession(this)
            % Reset labelling mode
            setMode(this, 'ROI');
            
            % Delete the current definitions
            deleteAllItemsLabelSetDisplay(this);
            
            % Reset Legend Display
            reset(this.LegendDisplay);
            
            % Reset Session
            resetSession(this.Session);
            
            % Reset Image Browser Display
            reset(this.LabeledImageBrowserDisplay);
            
            % Reset Semantic Tab
            resetDrawingTools(this.SemanticTab);
            
            this.ToolGroup.Title = this.ToolName; 
            
            this.updateUI();
        end
        
    end
    
    %----------------------------------------------------------------------
    % Automation Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function startAutomation(this)
            % Set up app for automation
            %   * Check if the algorithm is valid
            %   * Instantiate algorithm
            %   * Check label definitions
            %   * Prepare the UI
            %   * Open the automate tab
            
            success = tryToSetupAlgorithm(this);
            
            % Open Algorithm tab if successful and user still wants to
            % continue.
            if success
                
                % Show spinning wheel
                setWaiting(this.ToolGroup, true);
                resetWait = onCleanup(@()setWaiting(this.ToolGroup, false));
                
                % Disable settings in algorithm tab if needed.
                if ~hasSettingsDefined(this.AlgorithmSetupHelper)
                    disableSettings(this.AlgorithmTab);
                else
                    enableSettings(this.AlgorithmTab);
                end
                
                % Open automate tab.
                showModalAlgorithmTab(this, false);
                
                % Initialize algorithm mode to control run section controls
                setAlgorithmMode(this.AlgorithmTab, 'undorun');
                
                % Add algorithm instructions
                addInstructionsPanel(this);
                
                setSemanticTabForAutomation(this);

            end
        end
        
        %------------------------------------------------------------------
        function setupSucceeded = setupAlgorithm(this)
            
            setWaiting(this.ToolGroup, true);
            
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            
            % Tell the algorithm which label definitions have been selected
            selections = getSelectedLabelDefinitions(this);
            setSelectedLabelDefinitions(algorithm, selections);
            
            % Check if user has completed algorithm setup
            try
                setupSucceeded = verifyAlgorithmSetup(algorithm);
            catch ME
                % If there was an error, show the user what the error was
                % and abort.
                setWaiting(this.ToolGroup, false);
                
                dlgTitle = vision.getMessage('vision:labeler:CantVerifyAlgorithmTitle');
                showExceptionDialog(this, ME, dlgTitle);
                
                setupSucceeded = false;
                return;
            end
            
            % If setup failed, tell the user their setup is incomplete and
            % abort.
            if ~setupSucceeded
                
                setWaiting(this.ToolGroup, false);
                
                %Launch dialog stating setup is incomplete
                errorMessage = vision.getMessage('vision:labeler:IncompleteAlgorithmSetupMessage');
                dialogName = vision.getMessage('vision:labeler:IncompleteAlgorithmSetupTitle');
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg);
                
                return;
            end
            
            setWaiting(this.ToolGroup, false);
        end
        
        %------------------------------------------------------------------
        function runAlgorithm(this)
            
            %--------------------------------------------------------------
            % Do Verify Setup and Initialize
            %--------------------------------------------------------------
            finalize(this);
            
            closeExceptionDialogs(this);
            
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            
            % However the algorithm run goes, exit cleanly (including
            % CTRL+C).
            onDone = onCleanup(@this.cleanupPostAlgorithmRun);

            this.StopAlgRun = false;
            
            % Freeze browser interactions
            freezeBrowserInteractions(this.LabeledImageBrowserDisplay);
            
            % Freeze drawing tools
            freezeDrawingTools(this.LabeledImageBrowserDisplay);
            
            % Get indices of images to automate over
            imageIndices = this.LabeledImageBrowserDisplay.VisibleImageIndices;
            
            % Display first image
            firstImageIndex = imageIndices(1);
            this.LabeledImageBrowserDisplay.selectImageByIndex(firstImageIndex);
            
            % Run algorithms initialize() method on the first image
            success = initializeAlgorithm(this, firstImageIndex);
            
            if ~success
                return;
            end
            
            %--------------------------------------------------------------
            % Do Run
            %--------------------------------------------------------------
            
            % make the display behave correctly when the algorithm iterates
            % through images.
            this.LabeledImageBrowserDisplay.algorithmRunSetup()
            teardown = onCleanup(@()this.LabeledImageBrowserDisplay.algorithmRunTearDown());
            
            for idx = imageIndices
                
                if this.StopAlgRun
                    % User clicked stop, execute terminate and exit.
                    break;
                end
                
                this.LabeledImageBrowserDisplay.selectImageByIndex(idx);

                % Read image
                data = this.Session.readData(idx);
                I = data.Image;
                imSize = [size(I,1) size(I,2)];
                % Run user algorithm and retrieve labels
                try
                    [labels,isValid] = doRun(algorithm, I);
                    labels = checkUserLabels(this, labels, isValid, imSize);
                catch ME
                    dlgTitle = vision.getMessage('vision:labeler:CantRunAlgorithmTitle');
                    showExceptionDialog(this, ME, dlgTitle);
                    return;
                end
                
                % Add to session
                this.Session.addAlgorithmLabels(idx, labels);
                
                % Update display
                reset(this);
                drawImage(this, idx, false);
                drawnow('limitrate')
            end

            %--------------------------------------------------------------
            % Terminate
            %--------------------------------------------------------------
            try
                terminate(algorithm);
            catch ME
                dlgTitle = vision.getMessage('vision:labeler:CantTerminateAlgorithmTitle');
                showExceptionDialog(this, ME, dlgTitle);
                return;
            end
            
        end
        
        %------------------------------------------------------------------
        function stopAlgorithm(this)
            
            this.StopAlgRun = true;
        end
        
        %------------------------------------------------------------------
        function userCanceled = undorunAlgorithm(this)
            
            userCanceled = showUndoRunDialog(this);
            
            if ~userCanceled
                
                closeExceptionDialogs(this);
                finalize(this);
                
                setWaiting(this.ToolGroup, true);
                
                imageIndices = this.LabeledImageBrowserDisplay.VisibleImageIndices;
                replaceAnnotationsForUndo(this.Session, imageIndices);
                
                if hasPixelLabels(this.Session)
                    replacePixelLabels(this.Session,imageIndices);
                end
                
                reset(this);
                
                % Display first image
                this.LabeledImageBrowserDisplay.selectImageByIndex(imageIndices(1));
                
                % Draw the image since the display will not fire an event
                % upon selection since only one image exists in the browser
                % display and it has already been selected
                if imageIndices == 1
                    drawImage(this, imageIndices(1), false);
                end
                
                setWaiting(this.ToolGroup, false);
            end
        end
        
        %------------------------------------------------------------------
        function acceptAlgorithm(this)
            
            closeExceptionDialogs(this);
            finalize(this);
            
            % Save automation results
            imageIndices = this.LabeledImageBrowserDisplay.VisibleImageIndices;
            mergeAnnotations(this.Session, imageIndices);
            
            if hasPixelLabels(this.Session)
                mergePixelLabels(this.Session,imageIndices);
            end
            
            
            removeInstructionsPanel(this);
            
            endAutomation(this);
        end
        
        %------------------------------------------------------------------
        function cancelAlgorithm(this)
            
            closeExceptionDialogs(this);
            finalize(this);
            
            % Cancel the automation results
            uncacheAnnotations(this.Session);
            
            removeInstructionsPanel(this);
            
            endAutomation(this);
        end
        
        %------------------------------------------------------------------
        function setSemanticTabForAutomation(this)
            % Check if ROI Label is still active
            labelID = this.ROILabelSetDisplay.CurrentSelection;
            
            if labelID > 0 && this.Session.queryROILabelData(labelID).ROI == labelType.PixelLabel
                showContextualSemanticTab(this);
            else
                hideContextualSemanticTab(this);
            end
        end
        
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function success = tryToSetupAlgorithm(this)
            % Before opening the algorithm tab, check the following:
            %   * Is an algorithm selected?
            %   * Is the selected algorithm on path?
            %   * Is the algorithm valid?
            %
            % Once these checks are made, instantiate the algorithm and
            % check that there are consistent labels for the automation
            % algorithm. Update the label panels and video display.
            
            % Close any exception dialogs
            closeExceptionDialogs(this);
            
            % Show spinning wheel
            setWaiting(this.ToolGroup, true);
            
            success         = false;
            
            % Make sure an algorithm is selected
            if ~this.LabelTab.isAlgorithmSelected
                setWaiting(this.ToolGroup, false);
                errorMessage = vision.getMessage('vision:labeler:SelectAlgorithmFirst');
                dialogName = vision.getMessage('vision:labeler:SelectAlgorithmFirstTitle');
                
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg);
                return;
            end
            
            % Make sure the algorithm is on path, help the user with path
            % set up if needed.
            if ~isAlgorithmOnPath(this.AlgorithmSetupHelper)
                setWaiting(this.ToolGroup, false);
                return;
            end
            
            % Make sure the algorithm is a valid AutomationAlgorithm class.
            if ~isAlgorithmValid(this.AlgorithmSetupHelper)
                setWaiting(this.ToolGroup, false);
                return;
            end
            
            % Instantiate the algorithm.
            if ~instantiateAlgorithm(this.AlgorithmSetupHelper)
                setWaiting(this.ToolGroup, false);
                return;
            end
            
            % Populate GroundTruth
            finalize(this);
            gTruth = exportLabelAnnotations(this.Session);
            setAlgorithmLabelData(this.AlgorithmSetupHelper, gTruth);
            
            % Make sure label definitions in the app are consistent with
            % what the app expects.
            [roiLabelDefs,frameLabelDefs] = getLabelDefinitions(this.Session);
            if ~checkValidLabels(this.AlgorithmSetupHelper, roiLabelDefs, frameLabelDefs)
                setWaiting(this.ToolGroup, false);
                return;
            end
            
            % Set up folder for automation pixel label data
            if hasPixelLabels(this.Session)
                newdir = fullfile(this.Session.TempDirectory,'Automation');
                status = mkdir(newdir);
                if status
                    setTempDirectory(this.Session,newdir)
                else
                    return;
                end
            end
            
            % Setup is complete! If we reach this point, algorithm setup
            % was successful.
            success = true;
            
            oCU = onCleanup(@()setWaiting(this.ToolGroup, false));
            
            % Update ROI and Frame Label Panels.
            freezeLabelPanels(this);
            
            % Update Current Display
            reset(this);
            
            % Update image list display
            filterSelectedImages(this.LabeledImageBrowserDisplay);
            
            % Cache annotations
            cacheAnnotations(this.Session);
            
            % Update Session to only those labels that are part of the
            % algorithm run
            imageIndices        = this.LabeledImageBrowserDisplay.VisibleImageIndices;
            validFrameLabels    = this.AlgorithmSetupHelper.ValidFrameLabelNames;
            replaceAnnotations(this.Session, imageIndices, validFrameLabels);
            
            % Update image display
            this.LabeledImageBrowserDisplay.selectImageByIndex(imageIndices(1));
            
            % Refresh frame label display
            [~,~,labelIDs] = this.Session.queryFrameLabelAnnotation(imageIndices(1));
            updateFrameLabelStatus(this.FrameLabelSetDisplay, labelIDs);
            this.LegendDisplay.update(labelIDs);
        end
        
        %------------------------------------------------------------------
        function cleanupPostAlgorithmRun(this)
            
            % Stop running the algorithm
            this.StopAlgRun = true;
            
            % Restore browser interactions
            unfreezeBrowserInteractions(this.LabeledImageBrowserDisplay);
            
            % Restore image display interactions
            unfreezeDrawingTools(this.LabeledImageBrowserDisplay);
        end
        
        %------------------------------------------------------------------
        function success = initializeAlgorithm(this, imageIndex)
            
            success = true;
            
            setWaiting(this.ToolGroup, true);
            
            data = this.Session.readData(imageIndex);
            I = data.Image;
            
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            
            try
                doInitialize(algorithm, I);
            catch ME
                success = false;
                
                dlgTitle = vision.getMessage('vision:labeler:CantInitializeAlgorithmTitle');
                showExceptionDialog(this, ME, dlgTitle);
                return;
            end
            
            setWaiting(this.ToolGroup, false);
        end
        
        %------------------------------------------------------------------
        function endAutomation(this)
            
            setWaiting(this.ToolGroup, true);
            resetWait = onCleanup(@()setWaiting(this.ToolGroup, false));
                        
            % Remove folder for automation pixel label data
            if hasPixelLabels(this.Session)
                % Get parent directory for automation folder
                temppath = this.Session.TempDirectory;
                pathstr = fileparts(temppath);
                setTempDirectory(this.Session,pathstr);
                
                % Remove automation folder
                if isdir(temppath)
                    rmdir(temppath,'s');
                end
            end
            
            hideContextualSemanticTab(this);
            hideModalAlgorithmTab(this);
            
            unfreezeLabelPanels(this);
            
            % Update image display
            reset(this);
            restoreAllImages(this.LabeledImageBrowserDisplay);
            drawImage(this, this.getCurrentIndex(), false);
            
            setSemanticTabForAutomation(this);
        end
        
        %------------------------------------------------------------------
        function userLabels = checkUserLabels(this, userLabels, isValid, imSize)
            % userLabels is a struct with fields Name, Type and Position
            
            % The labels have already been checked for type and position
            % consistency. We only need to check that the label names and
            % types match up with the definitions.
            
            if isValid
                validROILabelNames      = this.AlgorithmSetupHelper.ValidROILabelNames;
                validFrameLabelNames    = this.AlgorithmSetupHelper.ValidFrameLabelNames;
                
                if iscategorical(userLabels)
                    
                    isValidCategorical = ~isempty(userLabels) && all(size(userLabels)==imSize);
                    if ~isValidCategorical
                        error(message('vision:labeler:invalidCategoricalFromUser'));
                    end
                    
                    % Are there any categories not among our valid label
                    % names?
                    categorySet = categories(userLabels);
                    unknownCats = setdiff(categorySet, validROILabelNames);
                    
                    % Remove these categories from the categorical
                    if ~isempty(unknownCats)
                        userLabels = removecats(userLabels, unknownCats);
                    end

                else
                    for n = 1 : numel(userLabels)
                        
                        % Is the label name one of the valid ROI labels?
                        isValidROI = any( strcmp(userLabels(n).Name, validROILabelNames) );
                        
                        % Is the ROI label of the same type as specified in the
                        % definitions?
                        if isValidROI
                            roiLabel    = this.Session.queryROILabelData(userLabels(n).Name);
                            isValidROI  = isequal(roiLabel.ROI, userLabels(n).Type);
                        end
                        
                        % Is the label name one of the valid Frame labels?
                        % Is the frame label of the labelType.Scene type?
                        isValidFr = any( strcmp(userLabels(n).Name, validFrameLabelNames) ) ...
                            && isequal(userLabels(n).Type, labelType.Scene);
                        
                        isValid = xor(isValidROI, isValidFr);
                    end
                end
                
            end
            
            if ~isValid
                error(message('vision:labeler:invalidLabelFromUser'));
            end
        end
        
        %------------------------------------------------------------------
        function userCanceled = showUndoRunDialog(this)
            
            % Check settings
            s = settings;
            showUndoRun = s.vision.imageLabeler.ShowUndoRunDialog.ActiveValue;
            
            if ~showUndoRun
                userCanceled = false;
                return;
            end
            
            userCanceled = vision.internal.labeler.tool.undoRunDialog(getGroupName(this), this.InstanceName);
        end
    end
    
end
