% LabelTab Defines key UI elements of the Labeler Apps

% Copyright 2017 The MathWorks, Inc.
classdef LabelTab < vision.internal.uitools.NewAbstractTab
    
    properties (Access=protected)
        % UI
        FileSection
        ModeSection
        ViewSection
        AlgorithmSection   
        ExportSection
    end
    
    methods(Access=public)
        function this = LabelTab(tool, tabName)
            this@vision.internal.uitools.NewAbstractTab(tool,tabName);
            
            this.createWidgets();
            this.installListeners();
        end    
        
        function testers = getTesters(~)
            testers = [];
        end            
    end
    
    methods (Abstract, Access = protected)
        repo = getAlgorithmRepository(this)
    end

    %----------------------------------------------------------------------
    % Enable/Set/Get Methods
    %----------------------------------------------------------------------        
    methods(Access = public)
        
        function modeSelection = getModeSelection(this)

            if this.ModeSection.ROIButton.Value && this.ModeSection.ROIButton.Enabled
                modeSelection = 'ROI';
            elseif this.ModeSection.ZoomInButton.Value && this.ModeSection.ZoomInButton.Enabled
                modeSelection = 'ZoomIn';
            elseif this.ModeSection.ZoomOutButton.Value && this.ModeSection.ZoomOutButton.Enabled
                modeSelection = 'ZoomOut';
            elseif this.ModeSection.PanButton.Value && this.ModeSection.PanButton.Enabled
                modeSelection = 'Pan';
            else
                modeSelection = 'none';
            end
        end        
        
        function reactToModeChange(this, mode)
                        
            switch mode
                case 'ZoomIn'
                    this.ModeSection.ZoomInButton.Value = true;
                case 'ZoomOut'
                    this.ModeSection.ZoomOutButton.Value = true;
                case 'Pan'
                    this.ModeSection.PanButton.Value = true;
                case 'ROI'
                    this.ModeSection.ROIButton.Value = true;
                case 'none'
                    this.ModeSection.ZoomInButton.Value     = false;
                    this.ModeSection.ZoomOutButton.Value    = false;
                    this.ModeSection.PanButton.Value        = false;
                    this.ModeSection.ROIButton.Value        = false;
            end
        end        
        
        function enableSaveLabelDefinitionsItem(this, flag)
            this.FileSection.SaveDefinitions.Enabled = flag;
        end
        
        function enableROIButton(this, flag)
            this.ModeSection.ROIButton.Enabled = flag;
        end
        
        function enableShowLabelBoxes(this, roiFlag, sceneFlag)
            this.ViewSection.ShowROILabelCheckBox.Enabled     = roiFlag;
            this.ViewSection.ShowSceneLabelCheckBox.Enabled   = sceneFlag;            
        end
        
        function setShowROILabelBox( this, flag)
            this.ViewSection.ShowROILabelCheckBox.Value = flag;
        end

        function setShowSceneLabelBox( this, flag)
            this.ViewSection.ShowSceneLabelCheckBox.Value = flag;
        end
        
        function TF = isSceneLabelBoxEnabled(this)
            TF = this.ViewSection.ShowSceneLabelCheckBox.Value;
        end
        
        function enableAlgorithmSection(this, flag)
            if flag
                this.AlgorithmSection.Section.enableAll();
                
                % Enable Automate button only if an Algorithm is selected
                if ~isAlgorithmSelected(this.AlgorithmSection)
                    this.AlgorithmSection.AutomateButton.Enabled = false;
                end
            else
                this.AlgorithmSection.Section.disableAll();
            end
        end    
        
        function enableImportAnnotationsButton(this, flag)
            if flag
                this.FileSection.ImportAnnotationsButton.Enabled = true;
            else
                this.FileSection.ImportAnnotationsbutton.Enabled = false;
            end
        end
        
        function enableExportSection(this, flag)
            if flag
                this.ExportSection.Section.enableAll();
            else
                this.ExportSection.Section.disableAll();
            end
        end
        
        function TF = isAlgorithmSelected(this)
            TF = this.AlgorithmSection.isAlgorithmSelected;
        end        
        
        function setROIIcon(this,mode)
            setROIIcon(this.ModeSection,mode);
        end
        
    end
    
    %----------------------------------------------------------------------
    % Create Section Methods
    %----------------------------------------------------------------------    
    methods(Access=protected, Hidden)
        
        function createModeSection(this)
            this.ModeSection = vision.internal.labeler.tool.sections.ModeSection;
            this.addSectionToTab(this.ModeSection);
        end
        
        function createViewSection(this)
            this.ViewSection = vision.internal.labeler.tool.sections.ViewSection;
            this.addSectionToTab(this.ViewSection);
        end

        function createAlgorithmSection(this)
            tool = getParent(this);
            this.AlgorithmSection = vision.internal.labeler.tool.sections.AlgorithmSection(tool);
            this.addSectionToTab(this.AlgorithmSection);
        end
        
        function createExportSection(this)
            this.ExportSection = vision.internal.labeler.tool.sections.ExportSection;
            this.addSectionToTab(this.ExportSection);
        end        
    end
    
    %----------------------------------------------------------------------
    % Listeners
    %----------------------------------------------------------------------        
    methods(Access=protected, Hidden)
        
        function installListenersModeSection(this)
            this.ModeSection.ROIButton.ValueChangedFcn      = @(es,ed) roiMode(this);
            this.ModeSection.ZoomInButton.ValueChangedFcn   = @(es,ed) zoomInMode(this);
            this.ModeSection.ZoomOutButton.ValueChangedFcn  = @(es,ed) zoomOutMode(this);
            this.ModeSection.PanButton.ValueChangedFcn      = @(es,ed) panMode(this);
        end
        
        function installListenersViewSection(this)
            this.ViewSection.LayoutButton.ButtonPushedFcn           = @(es, ed) restoreDefaultLayout(getParent(this), false);
            this.ViewSection.ShowROILabelCheckBox.ValueChangedFcn   = @(es, ed) showROILabelNames(getParent(this), this.ViewSection.ShowROILabelCheckBox.Value);
            this.ViewSection.ShowSceneLabelCheckBox.ValueChangedFcn = @(es, ed) showSceneLabelNames(getParent(this), this.ViewSection.ShowSceneLabelCheckBox.Value);
        end    
        
        function installListenersExportSection(this)
            this.ExportSection.ExportAnnotationsToWS.ItemPushedFcn = @(es, ed) exportLabelAnnotationsToWS(getParent(this));
            this.ExportSection.ExportAnnotationsToFile.ItemPushedFcn = @(es, ed) exportLabelAnnotationsToFile(getParent(this));            
        end        
    end
    
    %----------------------------------------------------------------------
    % Helper Methods
    %----------------------------------------------------------------------        
    methods(Access=protected, Hidden)
        
        function popup = addAlgorithmPopupList(this)
            
            import matlab.ui.internal.toolstrip.*;
            popup = PopupList();
            
            if this.AlgorithmSection.RefreshPopupList
                
                % The repo has been refreshed, re-populate the list.
                repo = getAlgorithmRepository(this);
                popupList = this.AlgorithmSection.AlgorithmPopupList;
                
                for n = 1 : this.AlgorithmSection.NumAlgorithms
                    alg = repo.AlgorithmList{n};
                    popupList{n}.ItemPushedFcn = @(es, ed) algorithmSelected(this, alg, es);
                end
                
                for i = 1:numel(this.AlgorithmSection.AlgorithmPopupList)
                    popup.add(popupList{i});
                end 
                this.AlgorithmSection.RefreshPopupList = false;
            else
                % Return the popup as is
                popup = this.AlgorithmSection.SelectAlgorithmDropDown.Popup;
            end
        end   
        
        function algorithmSelected(this, alg, evtsrc, varargin)
            
            % Update display
            algorithmName = evtsrc.Text;
            this.AlgorithmSection.SelectAlgorithmDropDown.Text = algorithmName;
            
            % Select algorithm
            selectAlgorithm(getParent(this), alg);
        end
        
    end
    
    methods (Access = private)
        function roiMode(this)
            if this.ModeSection.ROIButton.Value
                setMode(getParent(this), 'ROI');
            end
        end
        
        function zoomInMode(this)
            if this.ModeSection.ZoomInButton.Value
                setMode(getParent(this), 'ZoomIn');
            end
        end
        
        function zoomOutMode(this)
            if this.ModeSection.ZoomOutButton.Value
                setMode(getParent(this), 'ZoomOut');
            end
        end
        
        function panMode(this)
            if this.ModeSection.PanButton.Value
                setMode(getParent(this), 'Pan');
            end
        end 
    end
    
    methods(Abstract)
        enableControls(this)
        disableControls(this)
    end
    
    methods(Abstract, Access=protected)
        createWidgets(this)
        installListeners(this)        
    end
end