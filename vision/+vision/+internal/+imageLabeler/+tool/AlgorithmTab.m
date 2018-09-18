% AlgorithmTab Defines key UI elements of the Run Algorithm modal tab in
% the Image Labeler App

% Copyright 2017 The MathWorks, Inc.

classdef AlgorithmTab < vision.internal.labeler.tool.AlgorithmTab

    
    methods (Access = public)
        
        function this = AlgorithmTab(tool)
            this@vision.internal.labeler.tool.AlgorithmTab(tool);
        end
        
        function disableControls(this)
            this.ModeSection.Section.disableAll();
            this.ViewSection.Section.disableAll();
            this.SettingsSection.Section.disableAll();
            this.AlgorithmSection.Section.disableAll();
            this.CloseSection.Section.disableAll();
        end
        
        function enableControls(this)
            this.ModeSection.Section.enableAll();
            this.ViewSection.Section.enableAll();
            setAlgorithmMode(this, this.CurrentMode);
        end
    end
    
    %----------------------------------------------------------------------
    % Layout
    %----------------------------------------------------------------------
    methods (Access = protected)
        
        function createWidgets(this)
            this.createModeSection();
            this.createViewSection();
            this.createSettingsSection();
            this.createRunAlgorithmSection();
            this.createCloseSection();
        end
        
        function createCloseSection(this)
            this.CloseSection = vision.internal.imageLabeler.tool.sections.CloseSection;
            this.addSectionToTab(this.CloseSection);
        end
    end
    
    %----------------------------------------------------------------------
    % Listeners
    %----------------------------------------------------------------------
    methods (Access = protected)
    
        function installListeners(this)
            this.installListenersModeSection();
            this.installListenersViewSection();
            this.installListenersSettingsSection();
            this.installListenersRunAlgorithmSection();
            this.installListenersCloseSection();
        end 
        
        function installListenersCloseSection(this)
            this.CloseSection.AcceptButton.ButtonPushedFcn          = @(es,ed) acceptAlgorithm(getParent(this));
            this.CloseSection.CancelButton.ButtonPushedFcn          = @(es,ed) cancelAlgorithm(getParent(this));
        end

    end
end