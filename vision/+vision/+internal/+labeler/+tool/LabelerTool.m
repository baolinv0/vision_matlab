% This class is for internal use only and may change in the future.

% LabelerTool Base class for labeling apps with automation.
classdef LabelerTool < vision.internal.uitools.NewToolStripApp
    
    
    %----------------------------------------------------------------------
    % Abstract Properties
    %----------------------------------------------------------------------
    properties(Abstract, Constant, Access = protected)
        % ToolName Official name of app, e.g Ground Truth Labeler
        ToolName
        
        % InstanceName Name used to manage instance. Each client should set
        %              this to the name used for the app, e.g. groundTruthLabeler.
        InstanceName
        
        % SupportedROILabelTypes Array of ROI labelTypes the app supports.
        % This defines the type of ROIs that are allowed when defining ROI
        % labels.
        SupportedROILabelTypes
    end
    
    %----------------------------------------------------------------------
    % Common Displays
    %----------------------------------------------------------------------
    properties(Access = protected)
        ROILabelSetDisplay
        FrameLabelSetDisplay
        InstructionsSetDisplay
        LegendDisplay
    end
    
    %----------------------------------------------------------------------
    % Tabs
    %----------------------------------------------------------------------
    properties
        % LabelTab Main app tab
        LabelTab
        
        % AlgorithmTab Modal algorithm tab
        AlgorithmTab
        
        % SemanticTab Contextual tab for semantic labelling
        SemanticTab
        
        % Currently active tab. Use this to handle common updates for both
        % tabs like zoom/pan updates.
        ActiveTab
    end
    
    %----------------------------------------------------------------------
    % Automation algorithm properties
    %----------------------------------------------------------------------
    properties
        IsStillRunning = false
        StopRunning = false
        
        %AlgorithmSetupHelper Manages algorithm setup and validation.
        AlgorithmSetupHelper
    end
    
    %----------------------------------------------------------------------
    % Exception Handling
    %----------------------------------------------------------------------
    properties
        %Exception Dialog handles
        ExceptionDialogHandles = {};
    end
    
    %----------------------------------------------------------------------
    % Abstract Methods
    %----------------------------------------------------------------------
    methods(Abstract, Access = protected)
        configureDisplays(this)
        addDisplaysToApp(this)
        doTileLayout(this)
        updateTileLayout(this, showInstructions)
        
        % idx = getCurrentIndex(this) returns the index of the selected
        % frame or images.
        getCurrentIndex(this)
        
        % Reset focus to appropriate display
        resetFocus(this)
    end
    
    methods(Abstract)
        doLoadSession(this)
    end
    
    %----------------------------------------------------------------------
    % Abstract Algorithm Execution Methods
    %----------------------------------------------------------------------
    methods (Abstract)
        % User clicks Automate
        startAutomation(this)
        
        % Use clicks Run, so execute checkSetup
        setupSucceeded = setupAlgorithm(this)
        
        % User clicked Run and checkSetup completed. Run the algorithm
        runAlgorithm(this)
        
        % User clicks Stop
        stopAlgorithm(this)
        
        % User clicks Undo Run
        userCanceled = undorunAlgorithm(this)
        
        % User clicks Accept
        acceptAlgorithm(this, varargin)
        
        % User clicks Cancel
        cancelAlgorithm(this)
        
    end
    
    % Session stuff
    methods(Access = public)
        
        %------------------------------------------------------------------
        function loadSession(this)
            %This method loads the session from an existing MAT file
            
            % First check if we need to save anything before we wipe
            % existing data
            isCanceled = this.processSessionSaving();
            if isCanceled
                return;
            end
            
            selectFileTitle = vision.getMessage('vision:uitools:SelectFileTitle');
            
            % File directory
            persistent fileDir;
            
            if isempty(fileDir) || ~exist(fileDir, 'dir')
                fileDir = pwd();
            end
            
            [fileName,pathName,userCanceled] = vision.internal.labeler.tool.uigetmatfile(fileDir, selectFileTitle);
            
            % Return if user aborted.
            if userCanceled || isempty(fileName)
                return;
            else
                % preserve the last path for next time
                fileDir = pathName;
            end
            
            this.setStatusText(vision.getMessage('vision:labeler:LoadSessionStatus', fileName));
            
            this.doLoadSession(pathName, fileName);
            
            this.setStatusText('');
            
        end
        
        %------------------------------------------------------------------
        function success = saveSession(this, fileName)
            
            % If we didn't save the session before, ask for the filename
            if nargin < 2
                if isempty(this.Session.FileName) || ~exist(this.Session.FileName, 'file')
                    fileName = vision.internal.uitools.getSessionFilename(...
                        this.SessionManager.DefaultSessionFileName);
                    if isempty(fileName)
                        success = false;
                        return;
                    end
                else
                    fileName = this.Session.FileName;
                end
            end
            
            if hasPixelLabels(this.Session)
                finalize(this);
            end
            
            this.SessionManager.saveSession(this.Session, fileName);
            
            [~, fileName] = fileparts(fileName);
            
            this.ToolGroup.Title = getString(message(...
                'vision:labeler:ToolTitleWithSession', this.ToolName, fileName));
            
            this.Session.IsChanged = false;
            success = true;
            
            this.setStatusText(vision.getMessage('vision:labeler:SaveSessionStatus', fileName));
            
        end
        
        %------------------------------------------------------------------
        function saveSessionAs(this)
            % This method provides the save as functionality
            fileName = vision.internal.uitools.getSessionFilename(...
                this.SessionManager.DefaultSessionFileName);
            if ~isempty(fileName)
                [pathstr,name,~] = fileparts(fileName);
                sessionPath = fullfile(pathstr,[name '_SessionData']);
                % Save as can overwrite a variable
                if isdir(sessionPath)
                    rmdir(sessionPath,'s');
                end
                
                if ~isempty(this.Session.IsPixelLabelChanged)
                    sz = size(this.Session.IsPixelLabelChanged);
                    this.Session.IsPixelLabelChanged = true(sz);
                end
                
                this.saveSession(fileName);
                this.Session.IsChanged = false;
            end
            
        end
        
        %------------------------------------------------------------------
        function show(this)
            % Block User Interaction
            setWaiting(this.ToolGroup, true);
            
            % Hide View Tab
            this.ToolGroup.hideViewTab();
            
            % Remove Document bar
            this.removeDocumentTabs();
            
            % Update controls on label tab
            this.updateUI();
            
            % Hide Algorithm Tab
            this.hideModalAlgorithmTab();
            
            % Hide pixel label Tab
            this.hideContextualSemanticTab();
            
            % Disable Data Browser panel
            this.ToolGroup.disableDataBrowser();
            
            % Position tool correctly
            [x,y,w,h] = imageslib.internal.apputil.ScreenUtilities.getInitialToolPosition;
            setPosition(this.ToolGroup, x, y, w, h);
            
            % Open the Tool
            this.ToolGroup.open();
            
            % Create default window layout
            this.createDefaultLayout();
            
            drawnow();
            
            % Resume User Interaction
            setWaiting(this.ToolGroup, false);
            
        end
        
        %------------------------------------------------------------------
        function closeAppInstance(this, group)
            if nargin == 1
                % TODO this is required by test for connector. it also
                % forces this method to be public. Check w/ Bert to see if
                % the connector test can avoid calling this method.
                group = this.ToolGroup;
            end
            
            % First check if we need to save anything before we wipe
            % existing data
            if ~this.StopRunning
                isCanceled = this.processSessionSaving();
                
                if isCanceled
                    group.vetoClose;
                    return;
                end
            end
            
            if ~this.IsStillRunning
                
                % Clients may customize close operations using the
                % closeAllFigures method.
                closeAllFigures(this);
                
                group.approveClose;
                this.deleteToolInstance();
                
            else
                this.StopRunning = true;
                return;
            end
        end
        
        %------------------------------------------------------------------
        % Update Session with ROI Annotations.
        %
        %
        %------------------------------------------------------------------
        function [index,labelNames,labelPositions,labelColors,labelShapes] = ...
                updateROIsAnnotations(this, roiLabelData)
            
            % Unpack data.
            labelNames     = {roiLabelData.Label};
            labelPositions = {roiLabelData.Position};
            labelColors    = {roiLabelData.Color};
            labelShapes    = [roiLabelData.Shape];
            
            % Get current index
            index = getCurrentIndex(this);
            
            % Update session
            this.Session.addROILabelAnnotations(index, labelNames, labelPositions);
            
            this.Session.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        % Set temporary directory for writing pixel label data
        %
        %
        %------------------------------------------------------------------
        function foldername = setTempDirectory(this)

            [~,name] = fileparts(tempname);
            foldername = [tempdir 'Labeler_' name];
            
            status = mkdir(foldername);
            if ~status
                foldername = vision.internal.labeler.tool.selectDirectoryDialog(name);
            end
            
            setTempDirectory(this.Session,foldername);
        end
        
        function name = getInstanceName(this)
            name = this.InstanceName;
        end
        
        %------------------------------------------------------------------
        function reconfigureROILabelSetDisplay(this)
            % Hide helper text for ROI labels.
            if this.Session.NumROILabels >= 1
                hideHelperText(this.ROILabelSetDisplay);
            end
            
            % Update ROI label display
            this.ROILabelSetDisplay.deleteAllItems();
            for n = 1 : this.Session.NumROILabels
                roiLabel = this.Session.queryROILabelData(n);
                this.ROILabelSetDisplay.appendItem(roiLabel);
                this.ROILabelSetDisplay.selectLastItem();
            end
        end
        
        %------------------------------------------------------------------
        function reconfigureFrameLabelSetDisplay(this)
            % Hide helper text for frame labels.
            if this.Session.NumFrameLabels >= 1
                hideHelperText(this.FrameLabelSetDisplay);
            end
            
            reset(this.LegendDisplay);
            
            % Update frame label display
            this.FrameLabelSetDisplay.deleteAllItems();
            for n = 1 : this.Session.NumFrameLabels
                frameLabel = this.Session.queryFrameLabelData(n);
                this.FrameLabelSetDisplay.appendItem(frameLabel);
                this.FrameLabelSetDisplay.selectLastItem();
                this.LegendDisplay.onLabelAdded(frameLabel.Label, frameLabel.Color);
            end
            
            % Update frame label status
            idx = getCurrentIndex(this);
            if ~isempty(idx)
                [~,~,labelIDs] = this.Session.queryFrameLabelAnnotation(idx);
                updateFrameLabelStatus(this.FrameLabelSetDisplay, labelIDs);
                this.LegendDisplay.update(labelIDs);
            end
        end
        
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        % Attach undo/redo call back to quick access bar buttons. Note
        % you must call call this method before calling open(ToolGroup) in
        % your app.
        %------------------------------------------------------------------
        function configureQuickAccessBarUndoRedoButton(this, toolComponent)
            % toolComponent is a component of the app that exposes an undo
            % and redo method by inheriting from 
            
            undoAction = com.mathworks.toolbox.shared.controllib.desktop.TSUtils.getAction('My Undo', javax.swing.ImageIcon);
            javaMethodEDT('setEnabled', undoAction, false); % Initially disabled
            undoListener = addlistener(undoAction.getCallback, 'delayed', @toolComponent.undo);
            
            redoAction = com.mathworks.toolbox.shared.controllib.desktop.TSUtils.getAction('My Redo', javax.swing.ImageIcon);
            javaMethodEDT('setEnabled', redoAction, false); % Initially disabled
            redoListener = addlistener(redoAction.getCallback, 'delayed', @toolComponent.redo);
            
            % Register the actions with the Undo/Redo buttons on QAB
            ctm = com.mathworks.toolstrip.factory.ContextTargetingManager;
            ctm.setToolName(undoAction, 'undo')
            ctm.setToolName(redoAction, 'redo')
            
            % Set the context actions BEFORE opening the ToolGroup
            ja = javaArray('javax.swing.Action', 1);
            c = this.ToolGroup.Peer.getWrappedComponent;
            ja(1) = undoAction;
            ja(2) = redoAction;
            c.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.CONTEXT_ACTIONS, ja);
            
            % Store actions/listeners into toolComponent
            toolComponent.UndoAction = undoAction;
            toolComponent.RedoAction = redoAction;
            toolComponent.UndoListener = undoListener;
            toolComponent.RedoListener = redoListener;
            
        end
        
        %------------------------------------------------------------------
        function updateUI(this)
            % update UI to reflect current state of app.
            % TODO move common code from GTL here.
        end
        
        %------------------------------------------------------------------
        function showModalAlgorithmTab(this, hasReverseAutomation)
            
            if hasReverseAutomation
                isAutomationFwd = IsAutomateForward(this.LabelTab);
                updateIcons(this.AlgorithmTab, isAutomationFwd);
            end
            show(this.AlgorithmTab);
            hide(this.LabelTab);
            hideContextualSemanticTab(this);
            this.ActiveTab = this.AlgorithmTab;
        end
        
        %------------------------------------------------------------------
        function hideModalAlgorithmTab(this)
            
            show(this.LabelTab);
            hide(this.AlgorithmTab);
            this.ActiveTab = this.LabelTab;
        end
        
        %------------------------------------------------------------------
        function showContextualSemanticTab(~)
            % groundTruthLabeler has no semantic tab, so do nothing.
            
            % imageLabeler derived class will specialize this method.
        end
        
        %------------------------------------------------------------------
        function hideContextualSemanticTab(~)
            % groundTruthLabeler has no semantic tab, so do nothing.
            
            % imageLabeler derived class will specialize this method.
        end
        
        %------------------------------------------------------------------
        function finalize(~)
            % imageLabeler derived class will specialize this method.
        end
        
        %------------------------------------------------------------------
        % closeAllFigures Method for removing all app figures.
        %------------------------------------------------------------------
        function closeAllFigures(this)
            % close displays
            close(this.ROILabelSetDisplay);
            close(this.FrameLabelSetDisplay);
            close(this.InstructionsSetDisplay);
        end
        
        %----------------------------------------------------------------------
        function [success, gTruth, pathName, fullName, fileName] = importLabelAnnotationsPreWork(this, source)

            % File directory
            persistent fileDir;
            gTruth = [];
            success = true;
            pathName = '';
            fullName = '';
            fileName = '';
            switch source
                case 'file'
                    if isempty(fileDir) || ~exist(fileDir, 'dir')
                        fileDir = pwd();
                    end
                    
                    % Open File Open dialog.
                    importAnnotations = vision.getMessage('vision:labeler:ImportAnnotations');
                    fromFile = vision.getMessage('vision:labeler:FromFile');
                    title = sprintf('%s %s', importAnnotations, fromFile);
                    
                    [fileName,pathName,userCanceled] = vision.internal.labeler.tool.uigetmatfile(fileDir, title);
                    
                    % Return if user aborted.
                    if userCanceled || isempty(fileName)
                        return;
                    end
                    
                    % Get the directory chosen
                    fileDir = pathName;
                    
                    try
                        gTruth = loadGroundTruthFromFile(this, fileName, pathName);
                    catch
                        errorMessage = getString( message('vision:labeler:UnableToLoadAnnotationsDlgMessage',fileName) );
                        dialogName   = getString( message('vision:labeler:UnableToLoadAnnotationsDlgName') );
                        dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                        wait(dlg);
                        success = false;
                        return;
                    end
                    fullName = fullfile(pathName, fileName);
                    
                case 'workspace'
                    variableTypes = {'groundTruth'};
                    variableDisp =  {'Ground Truth'};
                    [gTruth,gTruthVar,isCanceled] = vision.internal.uitools.getVariablesFromWS(variableTypes, variableDisp);
                    
                    if isCanceled
                        return
                    end
                    
                    pathName = pwd;
                    fullName = pwd;
                    fileName = gTruthVar;
            end
            
            if ~isscalar(gTruth)
                errorMessage = getString( message('vision:labeler:ImportLabelsNotScalarGroundTruth', fileName) );
                dialogName   = getString( message('vision:labeler:UnableToLoadAnnotationsDlgName') );
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg);
                
                drawnow;
                success = false;
                return;
            end
            
            if ~isa(gTruth.DataSource, 'groundTruthDataSource')
                errorMessage = getString( message('vision:labeler:invalidDataSource', fileName) );
                dialogName   = getString( message('vision:labeler:UnableToLoadAnnotationsDlgName') );
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg);
                
                drawnow;
                success = false;
                return;
            end
          
        end

        %----------------------------------------------------------------------
        function gTruth =  loadGroundTruthFromFile(~, fileName, pathName)
            
            % Load the MAT-file.
            temp = load(fullfile(pathName,fileName),'-mat');
            
            % The MAT-file is expected to return a struct with a single
            % field whose value is of type table.
            fields = fieldnames(temp);
            gTruth = temp.(fields{1});
            
            if ~isa(gTruth, 'groundTruth')
                % gTruth must be a groundTruth object. Error if it is not.
                % This error is caught and an appropriate dialog is thrown.
                error(message('vision:labeler:UnableToLoadAnnotationsDlgMessage', fileName));
            end
        end
        
        %----------------------------------------------------------------------
        function [gTruthReg, gTruthCustom] = splitRegularAndCustomLabels(this, gTruth)
            
            gTruthCustom = [];
            if height(gTruth.LabelDefinitions) > 1
                
                % Step-1: Get definition:
                
                % To export label def, there must be at least one regular
                % labels; otherwise export button is not enabled. So if there
                % is a custom label, label def table must have at least two
                % rows
                [labelDefTable, customLabelDef] = ...
                    splitRegularAndCustomLabelDefs(this, gTruth.LabelDefinitions);
                
                % Step-1: Get Data
                hasCustomData = ~isempty(customLabelDef);
                [labelDataTable, customLabelDataTable] = ...
                    splitRegularAndCustomLabelDataTable(this, ...
                    gTruth.LabelData, hasCustomData);
                
                % Step-1: Form final oputput
                gTruthReg = groundTruth(gTruth.DataSource, labelDefTable, labelDataTable);
                
                if hasCustomData
                    gTruthCustom.CustomLabelName = customLabelDef.CustomLabelName;
                    gTruthCustom.CustomLabelDesc = customLabelDef.CustomLabelDesc;
                    gTruthCustom.CustomLabelData = customLabelDataTable;
                end
            else
                gTruthReg = gTruth;
            end
        end
        
        %----------------------------------------------------------------------
        function [regLabelDataTable, customLabelDataTable] = ...
                splitRegularAndCustomLabelDataTable(~, ...
                LabelDataTable, hasCustomData)
            if hasCustomData
                regLabelDataTable = LabelDataTable(:,1:(end-1));
                customLabelDataTable = LabelDataTable(:, end);
            else
                regLabelDataTable = LabelDataTable;
                customLabelDataTable = [];
            end
        end
        
        %----------------------------------------------------------------------
        function [labelDefTable, customLabelDef] = splitRegularAndCustomLabelDefs(~, definitions)
            
            customLabelDef = [];
            
            % To export label def, there must be at least one regular
            % labels; otherwise export button is not enabled. So if there
            % is a custom label, label def table must have at least two
            % rows
            if height(definitions) > 1 % hasCustomDisplay(this)
                % if there is custom label, it must be the last row
                customLabelDefCell_tmp = table2cell(definitions(end,:));
                if ~isempty(customLabelDefCell_tmp) && (customLabelDefCell_tmp{2}==labelType.Custom)
                    % built-in labels are all but last row
                    labelDefTable = definitions(1:(end-1),:);
                    customLabelDef.CustomLabelName = customLabelDefCell_tmp{1};
                    % Description is optional
                    if length(customLabelDefCell_tmp) > 2
                        customLabelDef.CustomLabelDesc = customLabelDefCell_tmp{3};
                    else
                        customLabelDef.CustomLabelDesc = '';
                    end
                else
                    labelDefTable = definitions;
                end
            else
                labelDefTable = definitions;
            end
        end
        
    end
    
    %----------------------------------------------------------------------
    % Session Handling
    %----------------------------------------------------------------------
    methods(Access = protected)
        function isCanceled = processSessionSaving(this)
            
            isCanceled = false;
            
            sessionChanged = this.Session.IsChanged;
            
            yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
            cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
            
            if sessionChanged
                if isInAlgoMode(this) && algoNeedsSaving(this)
                    selection = this.askForSavingOfAlgSession();
                else
                    selection = this.askForSavingOfSession();
                end
            else
                selection = no;
            end
            
            switch selection
                case yes
                    success = this.saveSession();
                    if ~success
                        isCanceled = true;
                    end
                case no
                    
                case cancel
                    isCanceled = true;
            end
        end
        
        %------------------------------------------------------------------
        function doAppClientActions(this, group, event)
            if strcmp(event.EventData.EventType, 'CLOSING') && ...
                    group.isClosingApprovalNeeded
                
                this.closeAppInstance(group);
            elseif strcmp(event.EventData.EventType, 'ACTIVATED')
                % app gains focus
                doAppActivated(this);
            elseif strcmp(event.EventData.EventType, 'DEACTIVATED')
                % app loses focus
                doAppDeactivated(this);
            end
            
        end
        
        %------------------------------------------------------------------
        function doAppActivated(~)
            % labelers should implement this
        end
        
        %------------------------------------------------------------------
        function doAppDeactivated(~)
            % labelers should implement this
        end
        
        %------------------------------------------------------------------
        function doCloseApp(this, group, event)
            if strcmp(event.EventData.EventType, 'CLOSING') && ...
                    group.isClosingApprovalNeeded
                
                this.closeAppInstance(group);
            end
        end
    end
    
    %----------------------------------------------------------------------
    % App Layout
    %----------------------------------------------------------------------
    methods(Access = protected, Sealed)
        function createDefaultLayout(this)
            % This method is called when this.show is invoked. It
            % configures the displays, adds them to the app, and does the
            % default layout.
            %
            % NB: The order of the following operations is fixed (which is
            % why this method is SEALED).
            
            configureDisplays(this);
            
            addDisplaysToApp(this)
            
            doTileLayout(this);
        end
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function doTileLayoutForStandardLabelerDefaultView(this, ...
                mainDisplay, showInstructionsFlag)
            % Arrange the app displays in the standard view. The input
            % mainDisplay is the display that holds the video or image
            % displays in the labeling app.
            %
            % The tile layout is very sensitive to the order figures are
            % made visible. The tile layout uses a 2x3 grid, with the
            % following tile IDs:
            %
            % |      |     |     |
            % |  0   |  1  |  2  |
            % |------|----- ------
            % |  3   |  4  |  5  |
            % |      |     |     |
            %
            % Tiles 1 and 4, and 2 and 5 will be merged. After merging the
            % tiles have the following tile IDs
            %
            % |      |     |     |
            % |  0   |     |     |
            % |------|  1  -  2  -
            % |  3   |     |     |
            % |      |     |     |
            %
            % For the default view, width of tile 2 (and 5 since they are
            % merged) is set to zero.
            %
            % When showInstructionsFlag is true, width of tile 2 is set to
            % 0.2 (normalized). It is used for instructions display.
            drawnow; % make sure figures are rendered before tiling figures.
            
            % Disable closing of app figures. This still allows a user to
            % arrange the figures anyway they want in the app.
            
            prop= com.mathworks.widgets.desk.DTClientProperty.PERMIT_USER_CLOSE;
            stateFALSE = java.lang.Boolean.FALSE;
            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            grpname = this.getGroupName();
            
            drawnow; % This is important: getClient calls fail without this.
            md.getClient(this.ROILabelSetDisplay.Name, grpname).putClientProperty(prop, stateFALSE);
            md.getClient(this.FrameLabelSetDisplay.Name, grpname).putClientProperty(prop, stateFALSE);
            md.getClient(mainDisplay.Name, grpname).putClientProperty(prop, stateFALSE);
            md.getClient(this.InstructionsSetDisplay.Name, grpname).putClientProperty(prop, stateFALSE);
            
            
            % Figure must be made visible first before setting the layout
            % for robust tile arrangement.
            % The order of making figures visible will define the tile IDs
            % assigned to each figure.
            makeFigureVisible(this.ROILabelSetDisplay);
            makeFigureVisible(mainDisplay);
            
            if nargin==2
                showInstructionsFlag = false;
            end
            
            if (~showInstructionsFlag)
                makeFigureInvisible(this.InstructionsSetDisplay);
            else
                makeFigureVisible(this.InstructionsSetDisplay);
            end
            
            makeFigureVisible(this.FrameLabelSetDisplay);
            
            % drawnow after makeFigureVisible is critical to ensure
            % proper rendering. Otherwise the subsequent call to
            % setDocumentArrangement will sometimes mess up the layout.
            drawnow()
            
            % Set the initial tile layout (3x2)
            md.setDocumentArrangement(grpname, md.TILED, java.awt.Dimension(3,2))
            
            % setDocumentRowSpan(row,col,span)
            % make tiles 1 and 4 span 2 rows. This area is for the main
            % video display.
            md.setDocumentRowSpan(grpname, 0, 1, 2);
            
            % make tiles 2 and 5 span 2 rows. This area is for help
            % instructions.
            md.setDocumentRowSpan(grpname, 0, 2, 2);
            
            if (showInstructionsFlag)
                % Instructions panel view, set width to 0.2
                md.setDocumentColumnWidths(grpname, [0.2, 0.6 0.2]);
            else
                % Default view, set width of tile 2 to zero
                md.setDocumentColumnWidths(grpname, [0.2, 0.8]);
            end
            
            
            % Set each client to its own tile
            md.setClientLocation(this.ROILabelSetDisplay.Name,grpname,...
                com.mathworks.widgets.desk.DTLocation.create(0));
            md.setClientLocation(mainDisplay.Name,grpname,...
                com.mathworks.widgets.desk.DTLocation.create(1));
            md.setClientLocation(this.InstructionsSetDisplay.Name,grpname,...
                com.mathworks.widgets.desk.DTLocation.create(2));
            md.setClientLocation(this.FrameLabelSetDisplay.Name,grpname,...
                com.mathworks.widgets.desk.DTLocation.create(3));
            
            % Make sure everything is rendered properly, this is essential
            % to lock the 3x2 layout, otherwise it will change to 2x2
            % automatically.
            drawnow()
        end
    end
    
    %----------------------------------------------------------------------
    % Tool Instance Management
    %----------------------------------------------------------------------
    methods (Access = public, Hidden)
        
        %------------------------------------------------------------------
        function addToolInstance(this)
            imageslib.internal.apputil.manageToolInstances('add',...
                this.InstanceName, this);
        end
        
        %------------------------------------------------------------------
        % This method is used for testing
        %------------------------------------------------------------------
        function setClosingApprovalNeeded(this, in)
            this.ToolGroup.setClosingApprovalNeeded(in);
        end
        
        %------------------------------------------------------------------
        function deleteToolInstance(this)
            imageslib.internal.apputil.manageToolInstances('remove', ...
                this.InstanceName, this);
            delete(this);
        end
    end
    
    %----------------------------------------------------------------------
    % Automation Algorithm Infrastructure
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function selection = askForSavingOfAlgSession(this)
            
            grpName  = getGroupName(this);
            
            dlg = vision.internal.labeler.tool.AlgSaveSessionDlg(grpName);
            wait(dlg);
            
            if dlg.IsAcceptSave
                % Accept algorithm results
                this.acceptAlgorithm();
                
                % Yes, save the session
                selection = getString(message('MATLAB:uistring:popupdialogs:Yes'));
            elseif dlg.IsNo
                % No, don't save the session
                selection = getString(message('MATLAB:uistring:popupdialogs:No'));
            elseif dlg.IsCancel
                % Cancel
                selection = getString(message('MATLAB:uistring:popupdialogs:Cancel'));
            end
        end
        %------------------------------------------------------------------
        function  flag = isInAlgoMode(this)
            flag = (this.ActiveTab == this.AlgorithmTab);
        end
        
        %------------------------------------------------------------------
        function flag = algoNeedsSaving(this)
            flag =this.AlgorithmTab.hasUnsavedChanges;
        end
        
        %------------------------------------------------------------------
        function selectAlgorithm(this, algorithmClass)
            % User selects an algorithm with classname algorithmClass
            
            if isempty(algorithmClass)
                return;
            end
            
            % Configure dispatcher for selected algorithm
            configureDispatcher(this.AlgorithmSetupHelper, algorithmClass);
            
            % Update controls to enable automate button
            enableAlgorithmSection(this.LabelTab, true);
        end
        
        %------------------------------------------------------------------
        function openSettingsDialog(this)
            % User clicks Settings

            closeExceptionDialogs(this);
            
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            
            try
                doSettings(algorithm);
            catch ME
                dlgTitle = vision.getMessage('vision:labeler:ErrorInSettingsTitle');
                showExceptionDialog(this, ME, dlgTitle);
            end
        end
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function freezeLabelPanels(this)
            
            %TODO handle pixel labels
            
            % Disable items corresponding to invalid labels
            
            invalidROILabelIdx = this.AlgorithmSetupHelper.InvalidROILabelIndices;
            this.ROILabelSetDisplay.unselectToBeDisabledItems(invalidROILabelIdx);
            for idxr = 1 : numel(invalidROILabelIdx)
                this.ROILabelSetDisplay.disableItem(invalidROILabelIdx(idxr));
            end
            
            invalidFrameLabelIdx = this.AlgorithmSetupHelper.InvalidFrameLabelIndices;
            this.FrameLabelSetDisplay.unselectToBeDisabledItems(invalidFrameLabelIdx);
            for idxf = 1 : numel(invalidFrameLabelIdx)
                this.FrameLabelSetDisplay.disableItem(invalidFrameLabelIdx(idxf));
            end
            
            % Make panels uneditable.
            freeze(this.ROILabelSetDisplay);
            freeze(this.FrameLabelSetDisplay);
            if isempty(this.AlgorithmSetupHelper.ValidFrameLabelNames)
                freezeOptionPanel(this.FrameLabelSetDisplay);
            end
            
        end
        
        %------------------------------------------------------------------
        function unfreezeLabelPanels(this)
            
            %TODO handle pixel labels
            
            this.ROILabelSetDisplay.enableAllItems();
            this.FrameLabelSetDisplay.enableAllItems();
            
            unfreeze(this.ROILabelSetDisplay);
            unfreeze(this.FrameLabelSetDisplay);
            if this.Session.NumFrameLabels >= 1
                unfreezeOptionPanel(this.FrameLabelSetDisplay);
            end
        end
        
        %------------------------------------------------------------------
        function addInstructionsPanel(this)
            
            instructions = getInstructions(this);
            
            if isempty(instructions)
                return;
            end
            
            for n = 1:numel(instructions)
                this.InstructionsSetDisplay.appendItem(instructions{n});
            end
            
            % Show instructions panel for the selected algorithm
            
            % Set Figure title to the selected Algorithm name
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            setFigureTitle(this.InstructionsSetDisplay, algorithm.Name);
            updateTileLayout(this,true);
            
            % set focus back to image display
            resetFocus(this);
            
        end
        
        %------------------------------------------------------------------
        function instructions = getInstructions(this)
            % Find list of instructions to display. Also, return a status
            % flag which is set to true when the UserDirections property of
            % AutomationAlgorithm is empty
            
            algorithm = this.AlgorithmSetupHelper.AlgorithmInstance;
            
            instructions = algorithm.UserDirections;
            
            if ischar(instructions) || isstring(instructions)
                instructions = cellstr(instructions);
            end
            
            if ~iscell(instructions) || isequal(instructions,{''})
                instructions = {};
            end
        end
        
        %------------------------------------------------------------------
        function removeInstructionsPanel(this)
            
            % Delete all instructions before closing the Instructions
            % panel. Otherwise, the items gets added to the last created
            % panel.
            this.InstructionsSetDisplay.deleteAllItems();
            
            updateTileLayout(this,false);
            
            % set focus back to image display
            resetFocus(this);
            
        end
        
        %------------------------------------------------------------------
        function selectionStruct = getSelectedLabelDefinitions(this)
            
            selectionStruct = [];
            
            hasPixelLabel = false;
            
            % Add selected ROI label definition
            roiSelectionIdx = this.ROILabelSetDisplay.CurrentSelection;
            if roiSelectionIdx
                roiLabelDef = queryROILabelData(this.Session, roiSelectionIdx);
                
                roiDefStruct.Type = roiLabelDef.ROI;
                roiDefStruct.Name = roiLabelDef.Label;
                
                % Add PixelLabelID field if needed.
                hasPixelLabel = roiDefStruct.Type == labelType.PixelLabel;
                if hasPixelLabel
                    roiDefStruct.PixelLabelID = roiLabelDef.PixelLabelID;
                end
                
                selectionStruct = cat(2,selectionStruct,roiDefStruct);
            end
            
            % Add selected frame label definition
            frSelectionIdx = this.FrameLabelSetDisplay.CurrentSelection;
            if frSelectionIdx
                frLabelDef = queryFrameLabelData(this.Session, frSelectionIdx);
                frDefStruct.Type = labelType.Scene;
                frDefStruct.Name = frLabelDef.Label;
                
                if hasPixelLabel
                    frDefStruct.PixelLabelID = [];
                end
                
                selectionStruct = cat(2,selectionStruct,frDefStruct);
            end
        end
        
    end
    %----------------------------------------------------------------------
    % Exception Handling
    %----------------------------------------------------------------------
    methods (Access = protected)
        %------------------------------------------------------------------
        function showExceptionDialog(this, ME, dlgTitle, varargin)
            
            this.ExceptionDialogHandles{end+1} = vision.internal.labeler.tool.ExceptionDialog(...
                getGroupName(this), dlgTitle, ME, 'normal', varargin{:});
        end
        
        %------------------------------------------------------------------
        function closeExceptionDialogs(this)
            
            for n = 1 : numel(this.ExceptionDialogHandles)
                close(this.ExceptionDialogHandles{n});
            end
            this.ExceptionDialogHandles = {};
        end
    end
    
    %----------------------------------------------------------------------
    % Load callbacks
    %----------------------------------------------------------------------    
    methods (Access = public)
        function loadLabelDefinitionsFromFile(this)
            
            % Warn the user about current label deletion
            proceed = this.issueImportWarning('Label Definitions');
            
            if ~proceed
                return;
            end
            
            
            % File directory
            persistent fileDir;
            
            if isempty(fileDir) || ~exist(fileDir, 'dir')
                fileDir = pwd();
            end
            
            % Open File Open dialog.
            importDefinitions = vision.getMessage('vision:labeler:ImportDefinitions');
            fromFile = vision.getMessage('vision:labeler:FromFile');
            title = sprintf('%s %s', importDefinitions, fromFile);
            
            [fileName,pathName,userCanceled] = vision.internal.labeler.tool.uigetmatfile(fileDir, title);
            
            % Return if user aborted.
            if userCanceled || isempty(fileName)
                return;
            end
            
            % Get the directory chosen
            fileDir = pathName;
            
            this.setStatusText(vision.getMessage('vision:labeler:LoadLabelDefinitionStatus', fileName));
            % Load definitions from selected file.
            this.doLoadLabelDefinitionsFromFile(fullfile(pathName,fileName));
            this.setStatusText('');
        end
    end
    
    methods (Access = public)
        function exportLabelDefinitions(this, labelDefs)
            
            if nargin == 1
                labelDefs = exportLabelDefinitions(this.Session);
            end
            
            [fileName, pathName, proceed] = uiputfile('*.mat', ...
                vision.getMessage('vision:labeler:SaveLabelDefinitions'));
            if proceed
                try
                    save(fullfile(pathName,fileName), 'labelDefs');
                catch
                    errorMessage = getString( message('vision:labeler:UnableToSaveDefinitionsDlgMessage') );
                    dialogName   = getString( message('vision:labeler:UnableToSaveDlgName') );
                    dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                    wait(dlg);
                end
            end
        end        
    end

    %----------------------------------------------------------------------
    % View Callbacks
    %----------------------------------------------------------------------
    methods (Access = public)

        function restoreDefaultLayout(this, showInstructions)
            
            % Disable App Interaction
            setWaiting(this.ToolGroup, true);
            
            % Restore default layout
            doTileLayout(this,showInstructions);
            
            % Re-enable App Interaction
            setWaiting(this.ToolGroup, false);
        end
        
        function showSceneLabelNames(this, showSceneLabel)
            
            if showSceneLabel
                show(this.LegendDisplay);
            else
                hide(this.LegendDisplay);
            end
            
            % Sync the different tabs
            setShowSceneLabelBox(this.LabelTab, showSceneLabel);
            setShowSceneLabelBox(this.AlgorithmTab, showSceneLabel);
            
            % set focus back to image display
            resetFocus(this);
        end    
    end
    %----------------------------------------------------------------------
    % Helper Methods
    %----------------------------------------------------------------------     
    methods (Access=protected)
        function proceedFurther = issueImportWarning(this, warningMessage)
            
            hasAnyLabelDefs = this.ROILabelSetDisplay.NumItems>0 || this.FrameLabelSetDisplay.NumItems>0;
            
            if hasAnyLabelDefs
                % Issue import warning dialog before load operation
                dialogName      = vision.getMessage('vision:labeler:ImportDialog');
                displayMessage  = vision.getMessage('vision:labeler:ImportWarningDisplay', warningMessage);
                dlg = vision.internal.uitools.QuestDlg(this.getGroupName(), displayMessage, dialogName);
                wait(dlg);
                
                if dlg.IsNo
                    proceedFurther = false;
                else
                    proceedFurther = true;
                end
            else
                proceedFurther = true;
            end
        end
        
        function deleteAllItemsLabelSetDisplay(this)
            deleteAllItems(this.ROILabelSetDisplay);
            deleteAllItems(this.FrameLabelSetDisplay);            
        end
        
        function handleLoadDefinitionError(this, fullFileName, toolName)
            [~,fileName,ext] = fileparts(fullFileName);
            fileName = strcat(fileName,ext);
            errorMessage = getString( message('vision:labeler:UnableToLoadDefinitionsDlgMessage',fullFileName, fileName, toolName) );
            dialogName   = getString( message('vision:labeler:UnableToLoadDefinitionsDlgName') );
            dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
            wait(dlg);

            setWaiting(this.ToolGroup, false);
            drawnow();            
        end
    end
end