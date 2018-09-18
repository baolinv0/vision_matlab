% This class is for internal use only and may change in the future.

% This class defines the  algorithm section which houses the buttons for
% getting into the 'algorithm mode'. This used by both imageLabeler and
% groundTruthLabeler.

% Copyright 2016-2017 The MathWorks, Inc.

classdef AlgorithmSection < vision.internal.uitools.NewToolStripSection
    
    properties
        SelectAlgorithmLabel
        SelectAlgorithmDropDown
        ConfigureButton
        ConfigureTearOff
        AutomateButton
        
        AlgorithmPopupList
        RefreshPopupList
        NewAlgorithm
        ImportAlgorithm
        
        DefaultSelectionTextID = 'vision:labeler:SelectAlgorithmDropDownTitle';
        
        AppName
    end
    
    properties (Dependent)
        NumAlgorithms
    end
    
    properties (Access=private)
        % For creating error dialogs
        GroupName
    end
    
    methods (Access = protected)
        function tip = getConfigureAlgorithmToolTip(~)
            % return tool tip. Override tool tip by sub-classing and
            % reimplementing just this method.
            tip = 'vision:labeler:ConfigureAlgorithmTooltip';
        end
    end
    
    methods
        function this = AlgorithmSection(tool)
            
            this. AppName = getInstanceName(tool);
            
            this.createSection();
            this.layoutSection(getToolGroup(tool));
            this.GroupName = getGroupName(tool);
        end
        
        function tf = isAlgorithmSelected(this)
            tf = not(strcmp(vision.getMessage(this.DefaultSelectionTextID),...
                this.SelectAlgorithmDropDown.Text));
        end
        
        function refreshAlgorithmList(this)
            import matlab.ui.internal.toolstrip.*;
            
            repo = getAlgorithmRepository(this);
            repo.refresh();
            
            this.AlgorithmPopupList = {};
            names = cell(1,repo.Count);
            for i = 1:repo.Count
                
                % custom alg names are shown as-is, i.e. if a user provides
                % a paragraph long name that is how it will show up in the
                % list.
                names{i} = repo.getAlgorithmNameByIndex(i);
                
                desc = repo.getAlgorithmDescription(i);
                
                this.AlgorithmPopupList{i} = ListItem(names{i});
                this.AlgorithmPopupList{i}.Description = desc;
                this.AlgorithmPopupList{i}.Tag = names{i};
            end
            
            % Append new/add algorithm button
            text = vision.getMessage('vision:labeler:AddAlgorithm');
            icon = matlab.ui.internal.toolstrip.Icon.NEW_16;
            
            this.AlgorithmPopupList{end+1} = ListItemWithPopup(text,icon);
            this.AlgorithmPopupList{end}.ShowDescription = false;
            this.AlgorithmPopupList{end}.Tag = 'addAlgorithm';
            
            source = fullfile(matlabroot,'toolbox','shared','controllib','general','resources','Edit_16.png');
            icon = matlab.ui.internal.toolstrip.Icon(source);
            
            this.NewAlgorithm =  ListItem(...
                vision.getMessage('vision:labeler:CreateNewAlgorithm'), ...
                icon);
            
            this.NewAlgorithm.ShowDescription = false;
            this.NewAlgorithm.Tag = 'createNewAlgorithm';
            this.NewAlgorithm.ItemPushedFcn = @(es,ed) createNewAlgorithm(this);
            
            this.ImportAlgorithm = ListItem(...
                vision.getMessage('vision:labeler:ImportAlgorithm'), ...
                matlab.ui.internal.toolstrip.Icon.IMPORT_16);
            this.ImportAlgorithm.ShowDescription = false;
            this.ImportAlgorithm.Tag = 'importAlgorithm';
            this.ImportAlgorithm.ItemPushedFcn = @(es,ed) importAlgorithmFromFile(this);
            
            defsPopup = PopupList();
            defsPopup.add(this.NewAlgorithm);
            defsPopup.add(this.ImportAlgorithm);
            this.AlgorithmPopupList{end}.Popup = defsPopup;
            
            % Append "refresh" button
            this.AlgorithmPopupList{end+1} = ListItem(...
                vision.getMessage('vision:labeler:refreshAlgList'), ...
                matlab.ui.internal.toolstrip.Icon.REFRESH_16);
            this.AlgorithmPopupList{end}.ShowDescription = false;
            this.AlgorithmPopupList{end}.Tag = 'refreshAlgList';
            this.AlgorithmPopupList{end}.ItemPushedFcn = @(es,ed) refreshAlgorithmPupup(this);
            
            % check if current buttom name still exists, other set it to
            % default.
            hasNoAlgorithms = numel(this.AlgorithmPopupList) == 2;
            doesNotHavePreviousSelection = ~ismember(this.SelectAlgorithmDropDown.Text, names );
            
            if hasNoAlgorithms || doesNotHavePreviousSelection
                % Set to default
                titleID = 'vision:labeler:SelectAlgorithmDropDownTitle';
                this.SelectAlgorithmDropDown.Text = vision.getMessage(titleID);
            end
            
        end
        
        %------------------------------------------------------------------
        % Return the number of algorithms in the list.
        %------------------------------------------------------------------
        function n = get.NumAlgorithms(this)
            n = numel(this.AlgorithmPopupList);
            
            % minus 2 for refresh and add/create items
            n = n - 2;
        end
    end
    
    methods (Access = private)
        function createSection(this)
            
            algorithmSectionTitle = getString( message('vision:labeler:AlgorithmSectionTitle') );
            algorithmSectionTag   = 'sectionAlg';
            
            this.Section = matlab.ui.internal.toolstrip.Section(algorithmSectionTitle);
            this.Section.Tag = algorithmSectionTag;
        end
        
        function layoutSection(this, toolGroup)
            
            this.addSelectAlgorithmLabel();
            this.addSelectAlgorithmDropDown();
            
            % Don't add configure button for imageLabeler
            if ~isImageLabeler(this)
                this.addConfigureButton();
                this.addConfigureTearOff(toolGroup);
            end
            this.addRunAlgorithmButton();
            
            algChoiceCol = this.addColumn();
            algChoiceCol.add(this.SelectAlgorithmLabel);
            algChoiceCol.add(this.SelectAlgorithmDropDown);
            
            if ~isImageLabeler(this)
                algChoiceCol.add(this.ConfigureButton);
            else
                algChoiceCol.addEmptyControl();
            end
            
            algRunCol = this.addColumn();
            algRunCol.add(this.AutomateButton);
        end
        
        function addSelectAlgorithmLabel(this)
            
            this.SelectAlgorithmLabel = this.createLabel('vision:labeler:SelectAlgorithmLabel');
        end
        
        function addSelectAlgorithmDropDown(this)
            
            icon    = matlab.ui.internal.toolstrip.Icon.OPEN_16;
            tag     = 'btnSelectAlgorithm';
            this.SelectAlgorithmDropDown = this.createDropDownButton(...
                icon, this.DefaultSelectionTextID, tag);
            this.refreshAlgorithmList();
            this.RefreshPopupList = true;
            toolTipID = 'vision:labeler:SelectAlgorithmDropDownToolTip';
            this.setToolTipText(this.SelectAlgorithmDropDown, toolTipID);
        end
        
        function addConfigureButton(this)
            
            icon    = matlab.ui.internal.toolstrip.Icon.SETTINGS_16;
            titleID = 'vision:labeler:ConfigureAlgorithm';
            tag     = 'btnConfigureAlgorithm';
            this.ConfigureButton = this.createButton(icon, titleID, tag);
            toolTipID = this.getConfigureAlgorithmToolTip();
            this.setToolTipText(this.ConfigureButton, toolTipID);
        end
        
        function addConfigureTearOff(this, toolGroup)
            this.ConfigureTearOff = ...
                vision.internal.labeler.tool.ConfigurationTearOff(toolGroup, this.ConfigureButton);
            addlistener(this.ConfigureTearOff, 'StartTimeChanged', @(es,ed)updateDefaultConfiguration(this));
        end
        
        function updateDefaultConfiguration(this)
            % Import ROIs should be checked if start at current time is
            % selected.
            this.ConfigureTearOff.ImportROIs = this.ConfigureTearOff.StartAtCurrentTime;
        end
        
        function addRunAlgorithmButton(this)
            
            source  = fullfile(matlabroot,'toolbox','vision','vision',...
                '+vision','+internal','+labeler','+tool','+icons',...
                'Automate_24px.png');
            icon    = matlab.ui.internal.toolstrip.Icon(source);
            titleID = 'vision:labeler:RunAlgorithmButtonTitle';
            tag     = 'btnRunAlgorithm';
            this.AutomateButton = this.createButton(icon, titleID, tag);
            toolTipID = 'vision:labeler:RunAlgorithmButtonToolTip';
            this.setToolTipText(this.AutomateButton, toolTipID);
        end
        
        %------------------------------------------------------------------
        % Creating a new algorithm from the app opens a template for a user
        % to fill out.
        %------------------------------------------------------------------
        function createNewAlgorithm(this)
            
            if isImageLabeler(this)
                vision.labeler.AutomationAlgorithm.openTemplateInEditor('nontemporal');
            else
                vision.labeler.AutomationAlgorithm.openTemplateInEditor('temporal');
            end
        end
        
        function importAlgorithmFromFile(this)
            
            selectFileTitle = vision.getMessage('vision:uitools:SelectFileTitle');
            [fileName, pathName, filterIndex] = uigetfile('*.m', selectFileTitle);
            
            userCanceled = (filterIndex == 0);
            if userCanceled
                return;
            end
            
            packageStrings = regexp(pathName, '+\w+', 'match');
            
            if ~isempty( packageStrings )
                index = regexp(pathName, '+\w+');
                removeStr = pathName(index(1):end);
                pathName = strrep(pathName, removeStr, '');
            else
                %Check if it is a class
                index = regexp(pathName, '@\w+');
                if ~isempty(index)
                    removeStr = pathName(index(1):end);
                    pathName = strrep(pathName, removeStr, '');
                end
            end
            
            for i = 1:numel(packageStrings)
                packageStrings{i} = strrep(packageStrings{i}, '+', '');
            end
            
            fileString = strsplit( fileName, '.' );
            clasStrings =  [packageStrings fileString{1}];
            className = strjoin(clasStrings, '.');
            
            try
                metaClass = meta.class.fromName(className);
            catch
                errorMessage = vision.getMessage('vision:labeler:NotAnAutomationAlgorithm',className);
                dialogName   = getString( message('vision:labeler:NotAnAutomationAlgorithmDlg') );
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg); 
                return;
            end
            
            if isempty(metaClass)
                
                cancelButton    = vision.getMessage('vision:uitools:Cancel');
                addToPathButton = vision.getMessage('vision:labeler:addToPath');
                cdButton        = vision.getMessage('vision:labeler:cdFolder');
                
                msg = vision.getMessage(...
                    'vision:labeler:notOnPathQuestionAlgImport', className, pathName);
                
                buttonName = questdlg(msg, ...
                    getString(message('vision:labeler:notOnPathTitle')),...
                    cdButton, addToPathButton, cancelButton, cdButton);
                
                switch buttonName
                    case cdButton
                        cd(pathName);
                    case addToPathButton
                        addpath(pathName);
                    otherwise
                        return;
                end
                metaClass = meta.class.fromName(className);
            end
            
            if isempty(metaClass)
                errorMessage = vision.getMessage('vision:labeler:NotAnAutomationAlgorithm',className);
                dialogName   = getString( message('vision:labeler:NotAnAutomationAlgorithmDlg') );
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg); 
                return;
            end
            
            repo = getAlgorithmRepository(this);
            
            % Check if the algorithm already exists in the repository. If
            % yes, then throw a warning to the user.
            if ~any(ismember(repo.AlgorithmList, className))
                % Check here if the package root of the current file
                % imported is vision.labeler. If this is the case skip the
                % append operation. It is assumed here that, if the
                % codepath has reached till here, it means either the user
                % has chosen add to path or change current folder. Hence,
                % this vision.labeler package is not the same as the
                % one already in the system path.
                if ~strcmp( strjoin(packageStrings, '.'), repo.PackageRoot)
                    repo.appendImportedAlgorithm(className, pathName);
                end
            else
                errorMessage = vision.getMessage('vision:labeler:AlgorithmExistsMessage',className);   
                dialogName   = getString( message('vision:labeler:AlgorithmExistsTitle') );
                dlg = vision.internal.uitools.ErrorDlg(this.getGroupName(), errorMessage, dialogName);
                wait(dlg); 
                return;
            end
            
            this.refreshAlgorithmList();
            this.RefreshPopupList = true;
        end
        
        function refreshAlgorithmPupup(this)
            this.refreshAlgorithmList();
            this.RefreshPopupList = true;
        end
        
        function repo = getAlgorithmRepository(this)
            
            if isImageLabeler(this)
                repo = vision.internal.imageLabeler.ImageLabelerAlgorithmRepository.getInstance();
            else
                repo = vision.internal.labeler.VideoLabelerAlgorithmRepository.getInstance();
            end
        end
        
        function tf = isImageLabeler(this)
            tf = strcmpi(this.AppName, 'imageLabeler');
        end
        
        function grpName = getGroupName(this)
            grpName = this.GroupName;
        end
    end
end