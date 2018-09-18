classdef ImageCaptureTab < vision.internal.uitools.AbstractTab
% ImageCaptureTab Defines key UI elements of the Image Capture Tab of Camera Calibrator App
%
%    This class defines all key UI elements and sets up callbacks that
%    point to methods inside the CameraCalibrationTool class.
    
% Copyright 2014 The MathWorks, Inc.

    properties (Access=private)
        %% Device Section
        DeviceComboBox
        PropertiesButton
        PropertiesPanel
        
        %% Settings Section
        CaptureIntervalEdit
        CaptureIntervalSlider
        
        % Number of images 
        NumImagesCaptureEdit
        NumImagesCaptureSlider

        SaveLocationEdit
        CurrentSaveLocation
        BrowseButton
        
        %% Capture Section
        CaptureButton
        
        %% Close Section
        CloseButton
        
        %% Listeners
        CaptureIntervalSliderListener
        CaptureIntervalEditListener
        SaveLocationEditListener
        NumImagesCaptureEditListener
        NumImagesCaptureSliderListener
        
        % Track button status
        CurrentButtonState
    end
    
    properties (GetAccess=public, SetAccess=private)
        % Current status of Image Capture Tab 
        CaptureFlag
        
        % Store device name
        SavedCamera
        
        % All images that image capture tab has acquired in a session
        % (emptied when you close Image Capture Tab).
        Images
        
        % Corresponds to images captured in current Start/Stop
        NumImagesCaptured
        
        % Flag to indicate if any images were captured since tab was open
        AnyImagesCaptured
        
        % Icons for images to show up in the Data Browser
        ImageIcons
        
        % Labels for images to show up in the Data Browser
        ImageLabels
        
        % Index where the unsaved images begin.
        StartIndex
        
        % Timer object for capture
        TimerObj
        
        % Timer object for status text
        StatusTimerObj
        TimeRemaining
        
        % @TODO: Timer object for countdown
    end
    
    properties (Access=private)
        CameraObject = []
        PreviewObject
        
        ToolGroupName
    end
    
    properties (Constant)
        MinInterval = 1
        MaxInterval = 60
        MinImages = 2
        MaxImages = 100
    end
    
    events
        % Event for Closing Image Capture Tab.
        CloseTab
    end
    
    methods (Access=public)
        % Constructor
        function this = ImageCaptureTab(tool)
            this = this@vision.internal.uitools.AbstractTab(tool, ...
                        vision.getMessage('vision:caltool:ImageCaptureTabName'), ...
                        vision.getMessage('vision:caltool:ImageCaptureTab'));
            this.CaptureFlag = false;
            this.ToolGroupName = tool.getGroupName();
            this.AnyImagesCaptured = false;
            
            % Initialize
            this.reset();
            
            this.createWidgets();
            this.installListeners();
        end
        
        % Implement as inheriting from AbstractTab - do not see use at all
        % now.
        function testers = getTesters(~)
            testers = [];
        end
        
        % Creates and starts a preview.
        function createDevice(this)
            if strcmpi(this.SavedCamera, this.DeviceComboBox.SelectedItem)
                constructWithResolution = true;
            else
                constructWithResolution = false;
                this.PropertiesPanel = [];
            end
            this.updateDeviceSection(this.DeviceComboBox, constructWithResolution);
        end
        
        % Close preview
        function closePreview(this)
            if ~isempty(this.CameraObject) && isvalid(this.CameraObject)
                closePreview(this.CameraObject); % Stops the timer
            end
        end
        
        % Preview
        function preview(this)
            if ~isempty(this.CameraObject) && isvalid(this.CameraObject)
                [width, height] = this.getResolution;
                tool = this.getParent;
                drawImage(tool.ImagePreviewDisplay, width, height);
                replaceImage(tool.ImagePreviewDisplay, width, height);
                preview(this.CameraObject, tool.ImagePreviewDisplay.ImHandle);
            end
        end        
        
        % Update property states.
        function updatePropertyStates(this)
            % Disable ability to change devices if images have been
            % captured.
            if this.AnyImagesCaptured
                this.DeviceComboBox.Enabled = false;
                this.DeviceComboBox.Peer.setToolTipText(vision.getMessage('vision:caltool:DisabledCameraDropDownToolTip'));
                if ~isempty(this.PropertiesPanel)
                    this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.Enabled = false;
                    this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.Peer.setToolTipText(vision.getMessage('vision:caltool:DisabledResolutionDropDownToolTip'));
                end
            else
                this.DeviceComboBox.Enabled = true;
                this.DeviceComboBox.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledCameraDropDownToolTip'));
                if ~isempty(this.PropertiesPanel)
                    this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.Enabled = true;
                    this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledResolutionDropDownToolTip'));
                end
            end
        end
        
        function resetAll(this)
            this.AnyImagesCaptured = false;
            
            % Reset properties panel here. 
            this.PropertiesPanel = [];
            this.SavedCamera = [];
            
            reset(this);
        end
    end

    methods (Access=private)

        function createWidgets(this)
        % Creates the widgets on the toolstrip
            
            %% Create Device Widgets
            createDeviceWidgets(this);
             
            %% Create Settings Widgets
            createSettingsWidgets(this);

            %% Create Capture Widgets
            createCaptureWidgets(this);
            
            %% Create Close Widgets
            createCloseWidgets(this);
            
            %% Update button states.
            updateButtonStates(this, this.CurrentButtonState);
            
        end
        
        function createDeviceWidgets(this)
            %% Toolstrip sections
            deviceSection = toolpack.desktop.ToolSection('DeviceSection',...
                vision.getMessage('vision:caltool:DeviceSection'));
            
            devicePanel = toolpack.component.TSPanel(...
                '10px,f:p,10px,f:p,10px',...
                '10px,f:p,10px,f:p,10px');
            devicePanel.Name = 'DevicePanel';
            
            % Device drop down
            deviceLabel = toolpack.component.TSLabel(vision.getMessage('vision:caltool:DeviceDropDown'));
            
            % Get available webcams
            cams = this.enumerateCameras;
            
            this.DeviceComboBox = toolpack.component.TSComboBox(cams);
            this.DeviceComboBox.Name = 'DeviceCombo';
            this.DeviceComboBox.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledCameraDropDownToolTip'));
            
            % Create buttons.
            this.PropertiesButton = toolpack.component.TSButton(vision.getMessage('vision:caltool:PropertiesButton'),toolpack.component.Icon.SETTINGS_16);
            this.PropertiesButton.Name = 'PropertiesButton';
            this.PropertiesButton.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledCameraPropertiesToolTip'));
            
            % Add labels to panel.
            devicePanel.add(deviceLabel, 'xy(2,2)');
            devicePanel.add(this.DeviceComboBox, 'xy(4,2)');
            devicePanel.add(this.PropertiesButton, 'xyw(2,4,3)');
            
            % Add the section to the Panel.
            add(deviceSection, devicePanel);
            tab = this.getToolTab();
            add(tab,deviceSection);            
        end
        
        function createSettingsWidgets(this)
            settingsSection = toolpack.desktop.ToolSection('Settings',...
                vision.getMessage('vision:caltool:SettingsSection'));

            % Create the panel.
            settingsPanel = toolpack.component.TSPanel('10px,f:p,5px,f:p,5px,f:p,5px,f:p,10px', '1px,f:p,3px,f:p,3px,f:p,1px');            
            
            % Create Save location widgets.
            saveLocationLabel = toolpack.component.TSLabel(vision.getMessage('vision:caltool:SaveLocationEdit'));
            if (this.hasWritePermissions(pwd, false))
                startDir = pwd;
            else
                startDir = '';
            end
            this.CurrentSaveLocation = startDir;
            this.SaveLocationEdit = toolpack.component.TSTextField(startDir, 4);
            this.SaveLocationEdit.Name = 'SaveLocationEdit';
            this.SaveLocationEdit.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledSaveLocationToolTip'));
            this.BrowseButton = toolpack.component.TSButton(vision.getMessage('vision:caltool:BrowseButton'), toolpack.component.Icon.OPEN_16);
            this.BrowseButton.Name = 'BrowseButton';
            this.BrowseButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            this.BrowseButton.Peer.setToolTipText(vision.getMessage('vision:caltool:BrowseButtonToolTip'));
            
            add(settingsPanel, saveLocationLabel, 'xy(2,2)');
            add(settingsPanel, this.SaveLocationEdit, 'xyw(4,2,3)');
            add(settingsPanel, this.BrowseButton, 'xy(8,2)');
            
            % Create the label.
            captureIntervalLabel = toolpack.component.TSLabel(vision.getMessage('vision:caltool:CaptureIntervalEdit'));
            
            % Create slider component for capture interval control.
            defValue = 5;
            
            % Set slider tick spacing and create label table.
            this.CaptureIntervalSlider = toolpack.component.TSSlider(this.MinInterval, this.MaxInterval, defValue);
            this.CaptureIntervalSlider.MajorTickSpacing = 5;
            this.CaptureIntervalSlider.MinorTickSpacing = 1;
            this.CaptureIntervalSlider.Name = 'CaptureIntervalSlider';
            this.CaptureIntervalSlider.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledCaptureIntervalToolTip'));
            
            % Create text field to enter slider.
            this.CaptureIntervalEdit = toolpack.component.TSTextField(num2str(defValue), 5);
            this.CaptureIntervalEdit.Name = 'CaptureIntervalEdit';
            this.CaptureIntervalEdit.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledCaptureIntervalToolTip'));
            
            add(settingsPanel, captureIntervalLabel, 'xy(2,4)');
            add(settingsPanel, this.CaptureIntervalEdit, 'xy(4,4)');
            add(settingsPanel, this.CaptureIntervalSlider, 'xy(6,4)');
            
            % Create number images to capture label
            numImagesCaptureLabel = toolpack.component.TSLabel(vision.getMessage('vision:caltool:ImagesToCaptureEdit'));
            this.NumImagesCaptureEdit = toolpack.component.TSTextField(num2str(20), 4);
            this.NumImagesCaptureEdit.Name = 'NumImagesCaptureEdit';
            this.NumImagesCaptureEdit.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledNumImagesCaptureToolTip'));

            % Create slider component for num images to capture control.
            defValue = 20;
            
            % Set slider tick spacing and create label table.
            this.NumImagesCaptureSlider = toolpack.component.TSSlider(this.MinImages, this.MaxImages, defValue);
            this.NumImagesCaptureSlider.MajorTickSpacing = 5;
            this.NumImagesCaptureSlider.MinorTickSpacing = 1;
            this.NumImagesCaptureSlider.Name = 'NumImagesCapture';
            this.NumImagesCaptureSlider.Peer.setToolTipText(vision.getMessage('vision:caltool:EnabledNumImagesCaptureToolTip'));
            
            add(settingsPanel, numImagesCaptureLabel, 'xy(2,6)');
            add(settingsPanel, this.NumImagesCaptureEdit, 'xy(4,6)');
            add(settingsPanel, this.NumImagesCaptureSlider, 'xy(6,6)');
            
            % Add the section to the Panel.
            add(settingsSection, settingsPanel);
            tab = this.getToolTab();
            add(tab,settingsSection);            
        end
        
        function createCaptureWidgets(this)
            this.CaptureButton = toolpack.component.TSButton(vision.getMessage('vision:caltool:StartCaptureButton'),toolpack.component.Icon.RUN_24);
            this.CaptureButton.Name = 'CaptureButton';
            this.CaptureButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            if isempty(this.CurrentSaveLocation)
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:DisabledStartCaptureButtonToolTip'));
            else
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:StartCaptureButtonToolTip'));
            end
            
            capturePanel = toolpack.component.TSPanel('f:p','f:p');
            capturePanel.Name = 'CapturePanel';
            add(capturePanel,this.CaptureButton,'xy(1,1)');
            
            captureSection = toolpack.desktop.ToolSection('CaptureSection', ...
                                    vision.getMessage('vision:caltool:CaptureSection'));
            add(captureSection,capturePanel);            
            tab = this.getToolTab();
            add(tab, captureSection);            
        end
        
        function createCloseWidgets(this)
            this.CloseButton = toolpack.component.TSButton(vision.getMessage('vision:caltool:CloseImageCaptureButton'),toolpack.component.Icon.CLOSE_24);
            this.CloseButton.Name = 'CloseButton';
            this.CloseButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            this.CloseButton.Peer.setToolTipText(vision.getMessage('vision:caltool:CloseButtonToolTip'));
            
            closePanel = toolpack.component.TSPanel('f:p','f:p');
            closePanel.Name = 'ClosePanel';
            add(closePanel,this.CloseButton,'xy(1,1)');
            
            closeSection = toolpack.desktop.ToolSection('CloseSection', ...
                                                        vision.getMessage('vision:caltool:CloseSection'));
            
            add(closeSection,closePanel);            
            tab = this.getToolTab();
            add(tab,closeSection);
        end
                
        function installListeners(this)
            
            % Device Section
            addlistener(this.DeviceComboBox,'ActionPerformed',@(~,evt)this.updateDeviceSection(evt.Source));
            addlistener(this.PropertiesButton,'ActionPerformed',@(~,~) this.cameraPropertiesCallback());
            
            % Settings Section
            this.CaptureIntervalSliderListener = addlistener(this.CaptureIntervalSlider,'StateChanged',@(hobj,evt)updateCaptureIntervalSlider(this,hobj));
            this.CaptureIntervalEditListener = addlistener(this.CaptureIntervalEdit,'TextEdited',@(hobj,evt)updateCaptureIntervalEdit(this,hobj));

            this.NumImagesCaptureEditListener = addlistener(this.NumImagesCaptureEdit,'TextEdited',@(hobj,evt)updateNumImagesCaptureEdit(this,hobj));
            this.NumImagesCaptureSliderListener = addlistener(this.NumImagesCaptureSlider,'StateChanged',@(hobj,evt)updateNumImagesCaptureSlider(this,hobj));
            
            this.SaveLocationEditListener = addlistener(this.SaveLocationEdit,'TextEdited',@(hobj, evt)this.updateSaveLocationEditCallback(hobj));
            
            % Browse button
            addlistener(this.BrowseButton,'ActionPerformed',@(es,ed)browseCallback(this));
            
            % Capture button.
            addlistener(this.CaptureButton,'ActionPerformed',@(es,ed)capture(this));
            
            % Add listener for Closing image capture tab.
            addlistener(this.CloseButton,'ActionPerformed',@(es,ed)closeTab(this));
        end
        
    end
    
    
    %% Callback methods
    methods(Access=private)
        
        % Capture button callback
        function capture(this)
            if (~this.hasWritePermissions(this.SaveLocationEdit.Text, true))
                return;
            end
            
            % Error for image size inconsistencies.
            parent = getParent(this);
            currentSession = parent.getSession;
            if currentSession.hasAnyBoards
                imInfoBase = imfinfo(currentSession.BoardSet.FullPathNames{1});
                [width, height] = getResolution(this);
                if (imInfoBase.Width ~= width) || ...
                        (imInfoBase.Height ~= height)
                    % issue an error message
                    uiwait(errordlg(vision.getMessage('vision:caltool:imageSizeInconsistent'), ...
                        vision.getMessage('vision:caltool:GenericErrorTitle'), ...
                        'modal'));
                    return;
                end  
            end
            
            this.CaptureFlag = ~this.CaptureFlag;
            
            % Update the icons
            updateCaptureIcon(this);

            % Update toolstrip status.
            updateToolstripStatus(this);
            
            if this.CaptureFlag 
                % Mode: Starting a Capture
                this.TimerObj = internal.IntervalTimer(this.CaptureIntervalSlider.Value);
                addlistener(this.TimerObj, 'Executing', @(src, event)this.getSnapshot(src, event)); 
                start(this.TimerObj);
                
                % Start the status timer obj.
                this.TimeRemaining = this.CaptureIntervalSlider.Value;
                this.StatusTimerObj = internal.IntervalTimer(1);
                addlistener(this.StatusTimerObj, 'Executing', @(src, event)this.statusTimerCallback(src, event)); 
                start(this.StatusTimerObj);                
                
                % Update status text.
                this.setStatusText();
            else
                % Mode: Stopping a capture
                % Stop and delete timer object.
                this.stopTimers;
                
                % No images captured, return.
                if (this.NumImagesCaptured==0)
                    this.reset();
                    return;
                end
                
                % Save images to file
                lastFileID = this.getLastFileID;
                fullPathFileNames = cell(1,this.NumImagesCaptured);
                for idx = 1:this.NumImagesCaptured
                    fName = strcat('Image', num2str(lastFileID+idx), '.png');
                    fullPathFileName = fullfile(this.SaveLocationEdit.Text, fName);
                    % Index into Images array.
                    index = this.StartIndex + idx - 1;
                    imwrite (this.Images(:,:,:,index), fullPathFileName, 'png');
                    % Update the image strip.
                    this.makeLabel(fName, index);
                    
                    % Create cell of full path file names.
                    fullPathFileNames{idx} = fullPathFileName;
                    
                    % Create the icon.
                    icon = this.createIcon(this.Images(:,:,:,index), this.ImageLabels(index));
                    this.ImageIcons{index} = icon;
                    
                    % Append images to the strip.
                    this.appendImagesToStrip(false);
                end
                
                % @TODO: Run detection and add to BoardSet
                parent = getParent(this);
                currentSession = parent.getSession;
                prevBoardCount = 0;
                if currentSession.hasAnyBoards
                    prevBoardCount = currentSession.BoardSet.NumBoards;
                end
                parent.addImagesFromCameraToSession(fullPathFileNames);
                
                % Get the new board count.
                currentBoardCount = 0;
                if currentSession.hasAnyBoards
                    currentBoardCount = currentSession.BoardSet.NumBoards;
                end                
                numBoardsAdded = currentBoardCount - prevBoardCount;
                if (numBoardsAdded)
                    this.AnyImagesCaptured = true;
                    this.updatePropertyStates();
                end
                
                % Remove status text.
                this.setStatusText();
                
                % Reset Capture settings.
                this.reset();
            end

        end
        
        function setStatusText(this)
            
            %% Set status text
           statusStr{1} = vision.getMessage ('vision:caltool:NumImagesAcquired',...
                                        num2str(this.NumImagesCaptured), this.NumImagesCaptureEdit.Text);
           if (this.TimeRemaining == 1)
               statusStr{2} = vision.getMessage ('vision:caltool:NextCaptureCountdownSingular',...
                                                 num2str(this.TimeRemaining));
           else
               statusStr{2} = vision.getMessage ('vision:caltool:NextCaptureCountdownPlural',...
                                                 num2str(this.TimeRemaining));
           end               
           
           % Combine the two messages.
           statusStr = strjoin(statusStr, '       ');
           md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
           f = md.getFrameContainingGroup(this.ToolGroupName);
           if this.CaptureFlag
               javaMethodEDT('setStatusText', f, statusStr);
           else
               javaMethodEDT('setStatusText', f, '');
           end
        end
        
        function cams = enumerateCameras(this)
            % Initialize Button status flag.
            this.CurrentButtonState = false;
            
            % Find the location of webcam.
            webcamLoc = which('webcam.m');
            expectedLoc = fullfile(matlabroot, 'toolbox', 'matlab', 'webcam');
            if strcmpi(expectedLoc, fileparts(webcamLoc))
                cams = {vision.getMessage('vision:caltool:NoWebcamsDetected')};
                uiwait(errordlg(vision.getMessage('vision:caltool:SupportPkgNotInstalledMsg'), ...
                    vision.getMessage('vision:caltool:GenericErrorTitle'), ...
                    'modal'));
                return;
            end
            
            % Get available webcams
            try
                cams = webcamlist;
                if isempty(cams)
                    cams = {vision.getMessage('vision:caltool:NoWebcamsDetected')};
                    return;
                end                
            catch excep
                cams = {vision.getMessage('vision:caltool:NoWebcamsDetected')};
                uiwait(errordlg(excep.message, ...
                    vision.getMessage('vision:caltool:GenericErrorTitle'), ...
                    'modal'));
                return;
            end
            
            % Cameras available - so enable them.
            this.CurrentButtonState = true;
        end
        
        function getSnapshot(this, ~, evt)
            % Acquire an image and store it. 
            imgCount = evt.ExecutionCount;
            
            if isempty(this.Images)
                this.Images(:,:,:,1) = snapshot(this.CameraObject);
            else
                this.Images(:,:,:,end+1) = snapshot(this.CameraObject);
            end
            if isempty(this.StartIndex)
                this.StartIndex = size(this.Images, 4);
            end
            
            this.NumImagesCaptured = this.NumImagesCaptured + 1;
            this.makeLabel; % Updates the require label to ImageLabels.
            
            % Create icons
            this.generateIcons;
            
            % Append images to the strip.
            this.appendImagesToStrip(true);
            
            % Update status text.
            this.setStatusText();
            
            % Check if we have acquired completely.
            if (imgCount >= this.NumImagesCaptureSlider.Value)
                % Call capture to STOP acquisition.
                capture(this);
            end
        end
        
        function statusTimerCallback(this, ~, ~)
            % Initiate countdown.
            this.TimeRemaining = this.TimeRemaining - 1;
            
            % Reset time.
            if (this.TimeRemaining==0)
                % Update status text.
                this.setStatusText();                
                this.TimeRemaining = this.CaptureIntervalSlider.Value;
            end
            
            % Update status text.
            this.setStatusText();
        end
        
        function appendImagesToStrip(this, showLatest)
            % Update the image strip.
            parent = getParent(this);
            
            % Append image icons with existing board icons.
            currentSession = parent.getSession;
            if showLatest
                if currentSession.hasAnyBoards
                    parent.updateImageStrip([currentSession.BoardSet.BoardIcons this.ImageIcons], length(currentSession.BoardSet.BoardIcons)+length(this.ImageIcons)-1);
                else
                    parent.updateImageStrip(this.ImageIcons, length(this.ImageIcons)-1);
                end
            else
                if currentSession.hasAnyBoards
                    parent.updateImageStrip([currentSession.BoardSet.BoardIcons this.ImageIcons], length(currentSession.BoardSet.BoardIcons));
                else
                    parent.updateImageStrip(this.ImageIcons);
                end
            end
        end
        
        function fileID = getLastFileID(this)
            fileID = 0;
            out = dir(fullfile(this.SaveLocationEdit.Text, 'Image*.png'));
            if ~isempty(out)
                [~, fname]= cellfun(@fileparts, {out.name}, 'UniformOutput', false);
                fNum = cellfun(@(s) (str2double(s(6:end))), fname, 'UniformOutput', false);
                fileID = max([fNum{:}]);
            end
        end
        
        function stopTimers(this)
            % Stop timer object.
            if ( ~isempty(this.TimerObj) && isvalid(this.TimerObj) )
                stop(this.TimerObj);
                this.TimerObj = [];
            end 
            
            % Stop status timer object.
            if ( ~isempty(this.StatusTimerObj) && isvalid(this.StatusTimerObj) )
                stop(this.StatusTimerObj);
                this.StatusTimerObj = [];
            end             
        end
        
        function closeTab(this)
            % Reset the images.
            this.reset();
            
            % Delete the Camera Object.
            if (~isempty(this.CameraObject) && isvalid(this.CameraObject) )
                delete(this.CameraObject);
            end
            
            % Delete timer object.
            this.stopTimers;
            
            % Notify listener of Close operation.
            notify(this,'CloseTab');
        end
        
        function reset(this)
            % Reset the images.
            this.NumImagesCaptured = 0;
            this.Images = uint8([]);
            this.ImageIcons = [];
            this.ImageLabels = [];
            this.StartIndex = [];            
        end
        
        function browseCallback(this)
            
            % Call to select directory
            path = uigetdir(this.SaveLocationEdit.Text, vision.getMessage('vision:caltool:FolderOpenDialogTitle'));
            if ~path % No selection was made.
                return;
            end

            if hasWritePermissions(this, path, true)
                % Update the path in the text field.
                this.SaveLocationEdit.Text = path;
                this.CurrentSaveLocation = this.SaveLocationEdit.Text;
                this.CaptureButton.Enabled = true;
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:StartCaptureButtonToolTip'));
                return;
            end
        end
        
        function tf = hasWritePermissions(~, path, throwError)

            tf = false;
            % Create random folder name to try writing.
            [~, tempFolderName] = fileparts(tempname);

            dirExists = exist(path, 'dir');
            if (dirExists)
                writable = mkdir(fullfile(path, tempFolderName));
                if writable
                    % Delete the temp dir.
                    rmdir(fullfile(path, tempFolderName));
                    tf = true;
                    return;
                end
                % @TODO: Error here.
                if throwError
                    uiwait(errordlg(vision.getMessage('vision:caltool:PathWithInvalidPermissionsMsg'), ...
                        vision.getMessage('vision:caltool:PathWithInvalidPermissionsTitle'), ...
                        'modal'));
                end
                return;
            end            

            % Error.
            if throwError
                uiwait(errordlg(vision.getMessage('vision:caltool:InvalidPathMsg'), ...
                    vision.getMessage('vision:caltool:InvalidPathTitle'), ...
                    'modal'));
            end
        end
        
        function generateIcons(this)
            
            % Loop over images to generate icons.
            numImages = size(this.Images, 4);
            for idx = 1:numImages
                icon = this.createIcon(this.Images(:,:,:,idx), this.ImageLabels(idx));
                this.ImageIcons{idx} = icon;
            end
        end
        
        function icon = createIcon(~, im, label)
                thumbnailHeight = 72;
                im = imresize(im, [thumbnailHeight, NaN]);
                
                javaImage = im2java2d(im);
                icon = javax.swing.ImageIcon(javaImage);
                icon.setDescription(label);            
        end
            
        function makeLabel(this, varargin)
            if (nargin>1)
                fileName = varargin{1};
                loc = varargin{2};
                [~, fname, ext] = fileparts(fileName);
                label = [fname, ext];
                this.ImageLabels{loc} = label;
            else
                label = 'Not yet saved to disk';
                this.ImageLabels{end+1} = label;
            end
        end        
        
        function updateCaptureIntervalEdit(this, obj)
            % Move slider position to otsu level and update text.
            val = floor(str2double(obj.Text));
            
            if isnan(val)
                % TODO: Do we need an unnecessary error message?
                this.CaptureIntervalEdit.Text = num2str(this.CaptureIntervalSlider.Value);
                return;
            end
            
            % Valid value - continue
            if val > this.MaxInterval
                val = this.MaxInterval;
            elseif val < this.MinInterval
                val = this.MinInterval;
            end            
            this.CaptureIntervalEdit.Text = num2str(val);
            this.CaptureIntervalSlider.Value = val;
        end
        
        function updateCaptureIntervalSlider(this, ~)
            % Update text.
            this.CaptureIntervalEdit.Text = num2str(this.CaptureIntervalSlider.Value);
        end        
        
        function updateNumImagesCaptureEdit(this, obj)
            % Min and Max are 1 and 100. 
            val = floor(str2double(obj.Text));

            if isnan(val)
                % TODO: Do we need an unnecessary error message?
                this.NumImagesCaptureEdit.Text = num2str(this.NumImagesCaptureSlider.Value);
                return;
            end
            
            % Valid value - Continue
            if val < this.MinImages
                val = this.MinImages;
            elseif val > this.MaxImages
                val = this.MaxImages;
            end
            
            this.NumImagesCaptureEdit.Text = num2str(val);
            this.NumImagesCaptureSlider.Value = val;
            
        end             
        
        function updateNumImagesCaptureSlider(this, ~)
            % Update text.
            this.NumImagesCaptureEdit.Text = num2str(this.NumImagesCaptureSlider.Value);
        end            
        

        function updateSaveLocationEditCallback(this, evt)
            if this.hasWritePermissions(evt.Text, true)
                this.SaveLocationEdit.Text = evt.Text;
                this.CurrentSaveLocation = this.SaveLocationEdit.Text;
                this.CaptureButton.Enabled = true;
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:StartCaptureButtonToolTip'));                
            else
                this.SaveLocationEdit.Text = this.CurrentSaveLocation;
            end
        end            
                        
        function updateDeviceSection(this, devComboBox, varargin)
            % If no device exists, do nothing and return.
            if ismember(devComboBox.SelectedItem, {vision.getMessage('vision:caltool:SPPKGNotInstalled'), vision.getMessage('vision:caltool:NoWebcamsDetected')})
                % Empty the properties panel.
                this.PropertiesPanel = [];
                return;
            end
            
            % Create device
            try
                if (~isempty(this.CameraObject) && isvalid(this.CameraObject) )
                    delete(this.CameraObject);
                    this.CameraObject = [];
                    this.PropertiesPanel = [];
                    this.closePreview();
                end
                if (nargin==3)
                    useResolution = varargin{1};
                    if useResolution
                        this.CameraObject = webcam(devComboBox.SelectedIndex, 'Resolution', this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.SelectedItem);
                    else
                        this.CameraObject = webcam(devComboBox.SelectedIndex);
                    end
                else
                    this.CameraObject = webcam(devComboBox.SelectedIndex);
                end
                this.preview();
                % Save the device.
                this.SavedCamera = devComboBox.SelectedItem;
                
                % Create properties panel.
                this.createPropertiesPanel();
                
                % Disable buttons
                this.updateButtonStates(true);                
            catch excep
                % The camera is in use by another application. 
                uiwait(errordlg(excep.message, ...
                    vision.getMessage('vision:caltool:CameraInUseTitle'), ...
                    'modal'));
                
                % Disable buttons
                this.updateButtonStates(false);
            end
        end
        
        function updateButtonStates(this, flag)
            this.PropertiesButton.Enabled = flag;
            this.CaptureIntervalSlider.Enabled = flag;
            this.CaptureIntervalEdit.Enabled = flag;
            this.NumImagesCaptureSlider.Enabled = flag;
            this.NumImagesCaptureEdit.Enabled = flag;
            this.BrowseButton.Enabled = flag;
            this.SaveLocationEdit.Enabled = flag;
            this.CaptureButton.Enabled = flag;
        end
        
        function updateToolstripStatus(this)
            this.DeviceComboBox.Enabled = ~this.CaptureFlag;
            this.CaptureIntervalSlider.Enabled = ~this.CaptureFlag;
            this.CaptureIntervalEdit.Enabled = ~this.CaptureFlag;
            this.PropertiesButton.Enabled = ~this.CaptureFlag;
            this.BrowseButton.Enabled = ~this.CaptureFlag;
            this.CloseButton.Enabled = ~this.CaptureFlag;
            this.NumImagesCaptureSlider.Enabled = ~this.CaptureFlag;
            this.NumImagesCaptureEdit.Enabled = ~this.CaptureFlag;
            this.SaveLocationEdit.Enabled = ~this.CaptureFlag;
        end
        
        function updateCaptureIcon(this)
            if this.CaptureFlag
                % Currently capture started, hence show STOP icon.
                this.CaptureButton.Icon = toolpack.component.Icon.END_24;
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:StopCaptureButtonToolTip'));
            else
                % Currently stop initiated, hence show START icon.
                this.CaptureButton.Icon = toolpack.component.Icon.RUN_24;
                this.CaptureButton.Peer.setToolTipText(vision.getMessage('vision:caltool:StartCaptureButtonToolTip'));
            end
        end       
        
        function cameraPropertiesCallback(this)
            this.createPropertiesPanel();
            this.PropertiesPanel.popup.Floating = false;
            this.PropertiesPanel.popup.show(this.PropertiesButton,'SOUTH');
            this.updatePropertyStates();
        end
        
        function createPropertiesPanel(this)
            tool = this.getParent;            
            if isempty(this.PropertiesPanel)
                this.PropertiesPanel = vision.internal.calibration.tool.CameraPropertiesPanel(this.CameraObject, tool.ImagePreviewDisplay);
            else
                this.PropertiesPanel.updateCameraObject(this.CameraObject, tool.ImagePreviewDisplay);
            end
        end
                
        function [width, height] = getResolution(this)
            res = this.CameraObject.Resolution;
            idx = strfind(res, 'x');
            width = str2double(res(1:idx-1));
            height = str2double(res(idx+1:end));
        end
    end
end