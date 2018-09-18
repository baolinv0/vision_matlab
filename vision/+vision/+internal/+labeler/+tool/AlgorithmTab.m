% AlgorithmTab Defines key UI elements of the Run Algorithm modal tab in
% the Labeler Apps

% Copyright 2017 The MathWorks, Inc.

classdef AlgorithmTab < vision.internal.uitools.NewAbstractTab


    properties (Access = protected)
        % UI
        ModeSection
        ViewSection
        SettingsSection
        AlgorithmSection
        CloseSection
        
        % Flag
        IsSettingsNeeded = true
        
        % undorun, run, stop
        CurrentMode = 'undorun'
    end
    
    methods (Access = public)
        function this = AlgorithmTab(tool)
            tabName = getString( message('vision:labeler:AlgorithmTab') );
            this@vision.internal.uitools.NewAbstractTab(tool,tabName);
            
            this.createWidgets();
            this.installListeners();
        end
        
        function testers = getTesters(~)
            testers = [];
        end
        
        function disableSettings(this)
            this.IsSettingsNeeded = false;
            this.SettingsSection.Section.disableAll();
        end
        
        function enableSettings(this)
            this.IsSettingsNeeded = true;
            this.SettingsSection.Section.enableAll();
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
        
        function setAlgorithmMode(this, mode)
            
            switch mode
                case 'run'
                    this.AlgorithmSection.RunButton.Enabled     = false;
                    this.AlgorithmSection.StopButton.Enabled    = true;
                    this.AlgorithmSection.UndoRunButton.Enabled = false;
                    this.SettingsSection.SettingsButton.Enabled = false;
                    this.CloseSection.Section.disableAll();
                    
                case 'stop'
                    
                    this.AlgorithmSection.RunButton.Enabled     = false;
                    this.AlgorithmSection.StopButton.Enabled    = false;
                    this.AlgorithmSection.UndoRunButton.Enabled = true;
                    this.SettingsSection.SettingsButton.Enabled = false;
                    this.CloseSection.Section.enableAll();
                    
                case 'undorun'
                    
                    this.AlgorithmSection.RunButton.Enabled     = true;
                    this.AlgorithmSection.StopButton.Enabled    = false;
                    this.AlgorithmSection.UndoRunButton.Enabled = false;
                    this.SettingsSection.SettingsButton.Enabled = this.IsSettingsNeeded && true;
                    this.CloseSection.AcceptButton.Enabled      = false;
                    this.CloseSection.CancelButton.Enabled      = true;
                    
                otherwise
                    
                    assert(false, 'Unrecognized switch expression')
                    
            end
            
            this.CurrentMode = mode;
        end
        
        function flag = hasUnsavedChanges(this)
            flag = strcmp(this.CurrentMode, 'stop');
        end
    end
    
    %----------------------------------------------------------------------
    % Layout
    %----------------------------------------------------------------------
    methods (Access = protected)
        
        function createModeSection(this)
            this.ModeSection = vision.internal.labeler.tool.sections.ModeSection;
            this.addSectionToTab(this.ModeSection);
        end
        
        function createViewSection(this)
            this.ViewSection = vision.internal.labeler.tool.sections.ViewSection;
            this.addSectionToTab(this.ViewSection);
        end
        
        function createSettingsSection(this)
            this.SettingsSection = vision.internal.labeler.tool.sections.SettingsSection;
            this.addSectionToTab(this.SettingsSection);
        end
        
        function createRunAlgorithmSection(this)
            this.AlgorithmSection = vision.internal.labeler.tool.sections.RunAlgorithmSection;
            this.addSectionToTab(this.AlgorithmSection);
        end      
    end
    
    %----------------------------------------------------------------------
    % Listeners
    %----------------------------------------------------------------------
    methods (Access = protected)

        function installListenersModeSection(this)
            this.ModeSection.ROIButton.ValueChangedFcn      = @(es,ed) roiMode(this);
            this.ModeSection.ZoomInButton.ValueChangedFcn   = @(es,ed) zoomInMode(this);
            this.ModeSection.ZoomOutButton.ValueChangedFcn  = @(es,ed) zoomOutMode(this);
            this.ModeSection.PanButton.ValueChangedFcn      = @(es,ed) panMode(this);
        end
        

        function installListenersViewSection(this)
            this.ViewSection.LayoutButton.ButtonPushedFcn           = @(es, ed) restoreDefaultLayout(getParent(this), true);
            this.ViewSection.ShowROILabelCheckBox.ValueChangedFcn   = @(es, ed) showROILabelNames(getParent(this), this.ViewSection.ShowROILabelCheckBox.Value);
            this.ViewSection.ShowSceneLabelCheckBox.ValueChangedFcn = @(es, ed) showSceneLabelNames(getParent(this), this.ViewSection.ShowSceneLabelCheckBox.Value);
        end  
        
        function installListenersSettingsSection(this)
            this.SettingsSection.SettingsButton.ButtonPushedFcn = @(es,ed) openSettingsDialog(getParent(this));
        end
        
        function installListenersRunAlgorithmSection(this)
            this.AlgorithmSection.RunButton.ButtonPushedFcn     = @(es,ed) setAlgorithmModeAndExecute(this, 'run');
            this.AlgorithmSection.StopButton.ButtonPushedFcn    = @(es,ed) setAlgorithmModeAndExecute(this, 'stop');
            this.AlgorithmSection.UndoRunButton.ButtonPushedFcn = @(es,ed) setAlgorithmModeAndExecute(this, 'undorun');
        end
        
        
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
        
        function setAlgorithmModeAndExecute(this, mode)
            
            tool = getParent(this);
            
            switch mode
                case 'run'
                    % Run algorithm can exit in the following ways:
                    % * Algorithm setup fails
                    % * Algorithm completes running successfully.
                    % * Algorithm errors/halts mid-way.
                    % * Algorithm is stopped by the user.
                    
                    % Update UI
                    setAlgorithmMode(this, mode);
                    
                    % Check if algorithm is ready
                    setupSucceeded = setupAlgorithm(tool);
                    
                    if ~setupSucceeded
                        % If setup failed, stay in run mode.
                        setAlgorithmMode(this, 'undorun');
                        return;
                    end
                    
                    % If setup succeeded, run the algortithm, then
                    % move to the state with undo-run button active.
                    
                    % Use onCleanup to reset the App in case of CTRL+C
                    % being issued.
                    onDone = onCleanup(@()setAlgorithmMode(this, 'stop'));
                    
                    % Run algorithm
                    runAlgorithm(tool);
                    
                case 'stop'
                    
                    % Update UI
                    setAlgorithmMode(this, mode);
                    
                    % Stop the algorithm
                    stopAlgorithm(tool);
                    
                case 'undorun'
                    
                    % Undo algorithm run unless user cancels
                    userCanceled = undorunAlgorithm(tool);
                    
                    if ~userCanceled
                        setAlgorithmMode(this, mode);
                    end
                    
                otherwise
                    assert(false, 'Unknown algorithm mode')
            end
        end        
    end
    
    methods(Abstract, Access=protected)
        createWidgets(this)
        installListeners(this)        
    end    
end