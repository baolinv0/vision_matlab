%PeopleDetectorACF Automation algorithm to detect people using ACF.
%   PeopleDetectorACF is an automation algorithm for detecting
%   people using Aggregated Channel Features in the Ground Truth
%   Labeler App.
%
%   See also imageLabeler, vision.labeler.AutomationAlgorithm,
%   detectPeopleACF, groundTruthLabeler

% Copyright 2017 The MathWorks, Inc.

classdef PeopleDetectorACF < vision.labeler.AutomationAlgorithm
    
    %----------------------------------------------------------------------
    % Algorithm Description
    properties(Constant)
        
        %Name
        %   Character vector specifying name of algorithm.
        Name = 'ACF People Detector';
        
        %Description
        %   Character vector specifying short description of algorithm
        Description = 'Detect people using Aggregate Channel Features (ACF).';
        
        %UserDirections
        %   Cell array of character vectors specifying directions for
        %   algorithm users to follow in order to use algorithm.
        UserDirections = {...
            vision.labeler.AutomationAlgorithm.getDefaultUserDirections('selectroidef', 'People'),...
            vision.labeler.AutomationAlgorithm.getDefaultUserDirections('rundetector', 'People'),...
            vision.labeler.AutomationAlgorithm.getDefaultUserDirections('review'),...
            vision.labeler.AutomationAlgorithm.getDefaultUserDirections('rerun'),...
            vision.labeler.AutomationAlgorithm.getDefaultUserDirections('accept')...
            };
    end
    
    %---------------------------------------------------------------------
    % Properties
    properties
        
        %Detector
        %   Classification accuracy threshold
        Detector
        
        %SettingsHandles
        %   Cell array of handles for the UIcontrol settings objects
        SettingsHandles
        
        %ACFModelIdx
        %   Index of ACF classification model to be used
        ACFModelIdx = 1
                
        %ACFModelNames
        %   Cell array of character vectors containing ACF classification
        %   models
        ACFModelNames = {
            'inria-100x41'
            'caltech-50x21'}
        
        %OverlapThreshold
        %   Overlap ratio threshold for bounding boxes
        OverlapThreshold = 0.65
        
        %ScoreThreshold
        %   Classification score threshold
        ScoreThreshold = 0
        
    end
    
    %----------------------------------------------------------------------
    % Setup
    methods
        
        function isValid = checkLabelDefinition(~, labelDef)
            
            % Only labels for rectangular ROI's are considered valid.
            isValid = labelDef.Type == labelType.Rectangle;
            
        end
        
        function isReady = checkSetup(this)
            
            % Expect there to be at least one label to automate.
            isReady = ~isempty(this.SelectedLabelDefinitions);
            
        end
        
        function settingsDialog(this)
            
            dialogSettings(1) = struct(...
                'Tag', 'ACFModelIdx',...
                'Style', 'popupmenu',...
                'String', {this.ACFModelNames},...
                'Value', this.ACFModelIdx,...
                'Range', [],...
                'PromptStr', vision.getMessage('vision:labeler:ACFPeopleModelName'));
                        
            dialogSettings(2) = struct(...
                'Tag', 'OverlapThreshold',...
                'Style', 'slider',...
                'String', this.OverlapThreshold,...
                'Value', this.OverlapThreshold,...
                'Range', [0 1],...
                'PromptStr', vision.getMessage('vision:labeler:ACFOverlapThreshold'));
            
            dialogSettings(3) = struct(...
                'Tag', 'ScoreThreshold',...
                'Style', 'edit',...
                'String',  this.ScoreThreshold,...
                'Value', this.ScoreThreshold,...
                'Range', [],...
                'PromptStr', vision.getMessage('vision:labeler:ACFClassifyScoreThreshold'));
                        
            createSettingsDialog(this, dialogSettings);
            
        end
    end
    
    %----------------------------------------------------------------------
    % Execution
    methods
        
        function initialize(this, ~)
            
            % Setup the detector for the specified model
            modelName = this.ACFModelNames{this.ACFModelIdx};
            this.Detector = peopleDetectorACF(modelName);
            
        end
        
        function automatedLabels = run(this, I)
            
            automatedLabels = [];
            
            % Detect people using aggregate channel features
            [bboxes, scores] = detect(this.Detector, I,...
                'SelectStrongest', false);

            % Apply non-maximum suppression to select the strongest bounding boxes.
            [selectedBboxes, selectedScores] = selectStrongestBbox(bboxes, scores,...
                'RatioType', 'Min',...
                'OverlapThreshold', this.OverlapThreshold);
            
            % Consider only detections that meet specified score threshold
            selectedBboxes = selectedBboxes(selectedScores > this.ScoreThreshold, :);
            
            if ~isempty(selectedBboxes)
                
                % Add the selected label at the bounding box position(s)
                automatedLabels = struct(...
                    'Type', labelType.Rectangle,...
                    'Name', this.SelectedLabelDefinitions.Name,...
                    'Position', selectedBboxes);
                
            end
            
        end
        
    end    
    
    %----------------------------------------------------------------------
    % Settings methods
    methods(Access = private)
        
        function createSettingsDialog(algObj, dialogSettings)
           
            numSettings = size(dialogSettings, 2);
            numPanels = numSettings * 2;
            
            algObj.SettingsHandles = cell(numSettings, 1);
            
            [parentDlg, dlgPanels] = createParentDialog(numSettings);
            
            for idx = 1:numSettings
               
                % Create control and prompt subpanels
                panels = createSettingPanels(dlgPanels.settings, idx, numPanels);
                
                createPrompt(panels.PromptPanel, dialogSettings(idx).PromptStr);
                algObj.SettingsHandles{idx} = createControl(panels.ControlPanel, dialogSettings(idx));
                
            end
            
            % Create the OK and Cancel buttons and define callbacks
            okBtn = createBtns(dlgPanels.btns);
            okBtn.Callback = {@acceptSettings, numSettings};

            uiwait(parentDlg);
            
            function [parentDlg, dlgPanels] = createParentDialog(numSettings)
            
                parentDlg = dialog(...
                    'Name', 'Settings',...
                    'Visible', 'off');

                % Set the size of the dialog
                width = 300;
                height = numSettings * 80 + 50;
                parentDlg.Position(3:4) = [width height];

                % Position the dialog in the center of the screen and display
                movegui(parentDlg, 'center');
                parentDlg.Visible = 'on';

                dlgPanels.settings = uipanel(...
                    'Parent', parentDlg,...
                    'Units', 'pixels',...
                    'BorderType', 'none',...
                    'Position', [0 60 width height-60]); 

                dlgPanels.btns = uipanel(...
                    'Parent', parentDlg,...
                    'Units', 'pixels',...
                    'BorderType', 'none',...
                    'Position', [0 0 width 60]);
           end
        
            function [settingPanels] = createSettingPanels(parentDlg, idx, numPanels)
            
                xLocation = 0.1;
                width = 1 - 2 * xLocation;
                height = 1/numPanels;

                % Setting prompt panel object
                promptYLocation = round((numPanels - (idx * 2 - 1))/numPanels, 2);
                settingPanels.PromptPanel = uipanel(...
                    'Parent', parentDlg,...
                    'Units', 'normalized',...
                    'BorderType', 'none',...
                    'Position', [xLocation promptYLocation width height]);

                % Setting control panel object
                controlYLocation = round((numPanels - (idx * 2))/numPanels, 2);
                settingPanels.ControlPanel = uipanel(...
                    'Parent', parentDlg,...
                    'Units', 'normalized',...
                    'BorderType', 'none',...
                    'Position', [xLocation controlYLocation width height]);
            end
        
            function createPrompt(promptPanel, promptStr)

                % Create UI Control object for the prompt
                uicontrol(...
                    'Parent', promptPanel,...
                    'Style', 'text',...
                    'HorizontalAlignment', 'left',...
                    'Units', 'normalized',...
                    'Position', [0 0 1 0.5],...
                    'String', promptStr);
            end

            function [hControl] = createControl(controlPanel, dialogSetting)
                
                % Create UI Control object for the setting control
                hControl = uicontrol(...
                    'Parent', controlPanel,...
                    'Style', dialogSetting.Style,...
                    'Units', 'normalized',...
                    'Tag', dialogSetting.Tag);
                
                switch dialogSetting.Style
                    case 'popupmenu'
                        hControl.String = dialogSetting.String(:);
                        hControl.Value = dialogSetting.Value;
                        hControl.Position = [0 0 1 0.75];
                    case 'edit'
                        hControl.String = dialogSetting.String;
                        hControl.Position = [0 0.1 0.2 0.7];
                    case 'slider'
                        hControl.Position = [0 0.3 0.85 0.5];
                        hControl.Min = dialogSetting.Range(1);
                        hControl.Max = dialogSetting.Range(2);
                        hControl.Value = dialogSetting.Value;
                        hControl.BackgroundColor = [0.9 0.9 0.9];
                        
                        % Object to display current slider value
                        hSliderDisplay = uicontrol(...
                            'Parent', controlPanel,...
                            'Style', 'text',...
                            'Units', 'normalized',...
                            'Position', [0.85 0.25 0.15 0.5],...
                            'HorizontalAlignment', 'right',...
                            'Tag', [dialogSetting.Tag 'Display'],...
                            'String', dialogSetting.Value);
                        
                        hControl.Callback = {@sliderCallback, hSliderDisplay};
                end
                
                function sliderCallback(hSlider, ~, hSliderDisplay)
                   
                    hSliderDisplay.String = round(hSlider.Value,2);
                    
                end
                
            end
            
            function [okBtn] = createBtns(btnsSection)
            
                % Button string values
                cancelBtnStr = vision.getMessage('vision:labeler:SettingsCancelButton');
                okBtnStr = vision.getMessage('vision:labeler:SettingsOKButton');

                btnWidth = max(strlength({okBtnStr cancelBtnStr})) + 5;

                % Get the center of the section
                set(btnsSection, 'Units', 'characters');
                btnsSectionWidth = get(btnsSection, 'Position');
                centerXLocation = btnsSectionWidth(3)/2;

                % OK button object
                okBtnXLocation = centerXLocation - (btnWidth + 1);
                okBtn = uicontrol('Parent', btnsSection,...
                    'Style', 'pushbutton',...
                    'Units', 'characters',...
                    'Position', [okBtnXLocation 2 btnWidth 2],...
                    'String', okBtnStr);

                % Cancel button object
                cancelBtnXLocation = centerXLocation + 1;
                uicontrol('Parent', btnsSection,...
                    'Style', 'pushbutton',...
                    'Units', 'characters',...
                    'Position', [cancelBtnXLocation 2 btnWidth 2],...
                    'String', cancelBtnStr,...
                    'Callback', 'delete(gcf)');
            end
            
            function acceptSettings(~, ~, numSettings)

                for ndx = 1:numSettings

                    setting = algObj.SettingsHandles{ndx};

                    switch setting.Style
                        case 'popupmenu'
                            algObj.(setting.Tag) = setting.Value;
                        case 'edit'
                            algObj.(setting.Tag) = str2double(setting.String);
                        case 'slider'
                            algObj.(setting.Tag) = round(setting.Value, 2);
                    end

                end

                % Close the dialog
                delete(gcf);

            end

        end
    end
end