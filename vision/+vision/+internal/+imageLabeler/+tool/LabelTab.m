% LabelTab Defines key UI elements of the Image Labeler App

% Copyright 2017 The MathWorks, Inc.
classdef LabelTab < vision.internal.labeler.tool.LabelTab
    
    properties(Access = private)
        Parent
        TabGroup
        Tab
    end
    
    methods (Access = public)
        function this = LabelTab(tool)
            tabName = getString( message('vision:imageLabeler:LabelingTab') );
            this@vision.internal.labeler.tool.LabelTab(tool,tabName);
        end
        
        function enableControls(this)
            this.FileSection.Section.enableAll();
            this.ModeSection.Section.enableAll();
            this.ViewSection.Section.enableAll();
            this.AlgorithmSection.Section.enableAll();
            this.ExportSection.Section.enableAll();
        end

        function disableControls(this)
            this.FileSection.ImportAnnotationsButton.Enabled = false;  
            this.ModeSection.Section.disableAll();
            this.ViewSection.ShowROILabelCheckBox.Enabled = false;
            this.ViewSection.ShowSceneLabelCheckBox.Enabled = false;
            this.AlgorithmSection.Section.disableAll();
            this.ExportSection.Section.disableAll();
        end
        
        function disableAllControls(this)
            this.FileSection.Section.disableAll();
            this.ModeSection.Section.disableAll();
            this.ViewSection.Section.disableAll();
            this.AlgorithmSection.Section.disableAll();
            this.ExportSection.Section.disableAll();
        end
        
    end
    
    %----------------------------------------------------------------------
    % Layout
    %----------------------------------------------------------------------
    methods (Access = protected)
        function createWidgets(this)
            this.createFileSection();
            this.createModeSection();
            this.createViewSection();
            this.createAlgorithmSection();
            this.createExportSection();
        end
    end
    
    methods (Access = protected)
        function createFileSection(this)
            this.FileSection = vision.internal.imageLabeler.tool.sections.FileSection;
            this.addSectionToTab(this.FileSection);
        end        
        
        function createExportSection(this)
            this.ExportSection = vision.internal.imageLabeler.tool.sections.ExportSection;
            this.addSectionToTab(this.ExportSection);
    end

        function createModeSection(this)
            this.ModeSection = vision.internal.imageLabeler.tool.sections.ModeSection;
            this.addSectionToTab(this.ModeSection);
        end
    
        function createAlgorithmSection(this)
            tool = getParent(this);
            this.AlgorithmSection = vision.internal.imageLabeler.tool.sections.AlgorithmSection(tool);
            this.addSectionToTab(this.AlgorithmSection);
        end
        
        function createViewSection(this)
            this.ViewSection = vision.internal.imageLabeler.tool.sections.ViewSection();
            this.addSectionToTab(this.ViewSection);
        end
    end

    
    %----------------------------------------------------------------------
    % Listeners
    %----------------------------------------------------------------------
    methods(Access=protected)
        function installListeners(this)
            this.installListenersFileSection();
            this.installListenersModeSection();
            this.installListenersViewSection();
            this.installListenersAlgorithmSection();
            this.installListenersExportSection();
        end        
    end
    
    methods (Access = private)
        function installListenersFileSection(this)
            this.FileSection.NewSessionButton.ButtonPushedFcn  = @(es,ed) newSession(getParent(this));
            this.FileSection.LoadImagesDirectory.ItemPushedFcn = @(es,ed) loadImage(getParent(this));
            this.FileSection.LoadImagesDatastore.ItemPushedFcn = @(es,ed) loadImageFromDataStore(getParent(this));
            this.FileSection.LoadDefinitions.ItemPushedFcn     = @(es,ed) loadLabelDefinitionsFromFile(getParent(this));
            this.FileSection.LoadSession.ItemPushedFcn         = @(es,ed) loadSession(getParent(this));
            this.FileSection.SaveSession.ItemPushedFcn         = @(es,ed) saveSession(getParent(this));
            this.FileSection.SaveAsSession.ItemPushedFcn       = @(es,ed) saveSessionAs(getParent(this));
            this.FileSection.SaveDefinitions.ItemPushedFcn     = @(es, ed) exportLabelDefinitions(getParent(this));
            this.FileSection.ImportAnnotationsFromWS.ItemPushedFcn   = @(es,ed) importLabelAnnotations(getParent(this),'workspace');
            this.FileSection.ImportAnnotationsFromFile.ItemPushedFcn = @(es,ed) importLabelAnnotations(getParent(this),'file');
        end
        
        function installListenersAlgorithmSection(this)
            this.AlgorithmSection.SelectAlgorithmDropDown.DynamicPopupFcn   = @(es,ed) addAlgorithmPopupList(this);
            this.AlgorithmSection.AutomateButton.ButtonPushedFcn            = @(es,ed) startAutomation(getParent(this));
        end
    end    
    
    methods (Access = protected)
        function repo = getAlgorithmRepository(~)
            
            repo = vision.internal.imageLabeler.ImageLabelerAlgorithmRepository.getInstance();
        end 
        
    end
end