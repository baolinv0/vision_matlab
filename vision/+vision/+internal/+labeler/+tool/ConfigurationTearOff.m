classdef ConfigurationTearOff < handle
    %ConfigurationTearOff Create view for Automation Configuration tearoff.
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties (Dependent)
        AutomateForward
        StartAtCurrentTime
        ImportROIs
    end
    
    properties (Access = private)
        TearOff
        Panel
        
        ForwardDirRadioButton
        ReverseDirRadioButton
        StartTimeRadioButton
        CurrentTimeRadioButton        
        ImportROIsCheckbox
        
        ToolGroup
        Invoker
        
        Listeners
    end
    
    events
        DirectionChanged
        StartTimeChanged
        ImportROIsChanged
    end
    
    methods
        %------------------------------------------------------------------
        function this = ConfigurationTearOff(toolGroup, invoker)
            
            this.Invoker    = invoker;
            this.ToolGroup  = toolGroup;
            
            layoutContent(this);
            wireCallbacks(this);
        end
        
        %------------------------------------------------------------------
        function show(this)
            if isempty(this.TearOff)
                % Create the tear off after the toolstrip app is open, to
                % avoid parenting the tear off to MATLAB desktop.
                createTearOff(this);
            end
            if ~this.TearOff.Visible
                this.ToolGroup.showTearOffDialog(this.TearOff, this.Invoker);
                
                autosizeTearOff(this);
            end
        end
        
        %------------------------------------------------------------------
        function hide(this)
            close(this.TearOff);
        end
        %------------------------------------------------------------------
        function TF = get.AutomateForward(this)
            TF = this.ForwardDirRadioButton.Selected;
        end        
        %------------------------------------------------------------------
        function TF = get.StartAtCurrentTime(this)
            TF = this.CurrentTimeRadioButton.Selected;
        end
        
        %------------------------------------------------------------------
        function TF = get.ImportROIs(this)
            TF = this.ImportROIsCheckbox.Selected;
        end
        
        %------------------------------------------------------------------
        function set.ImportROIs(this, tf)
            this.ImportROIsCheckbox.Selected = tf;
        end
    end
    
    methods( Access = private)
        %------------------------------------------------------------------
        function layoutContent(this)
            
            this.Panel = toolpack.component.TSPanel('5dlu,f:p:g,5dlu','5dlu,f:p:g,5dlu,f:p:g,5dlu');
            
            StartTimePanel = toolpack.component.TSPanel('f:p:g,100dlu',['5dlu,f:p:g,2dlu,f:p:g,1dlu,f:p:g,5dlu,' '5dlu,f:p:g,2dlu,f:p:g,1dlu,f:p:g,5dlu']);
            ImportROIPanel = toolpack.component.TSPanel('f:p:g,100dlu','5dlu,f:p:g,2dlu,f:p:g,5dlu'); % last one could be '5dlu,f:p:g,7dlu'
            addTitledBorderToPanel(StartTimePanel);
            addTitledBorderToPanel(ImportROIPanel);
            
            this.Panel.add(StartTimePanel,'xy(2,2)');
            this.Panel.add(ImportROIPanel,'xy(2,4)');
            
            label0 = toolpack.component.TSLabel(vision.getMessage('vision:labeler:AutomationDirectionLabel'));
            
            forwardRadioButton      = toolpack.component.TSRadioButton(vision.getMessage('vision:labeler:AutomationForward'));
            forwardRadioButton.Name = 'radioForwardAutomation';
            forwardRadioButton.Selected = true;
            
            reverseRadioButton      = toolpack.component.TSRadioButton(vision.getMessage('vision:labeler:AutomationReverse'), true);
            reverseRadioButton.Name = 'radioReverseAlgorithm';
            
            label = toolpack.component.TSLabel(vision.getMessage('vision:labeler:AutomationStartsAtLabel'));
            
            startRadioButton      = toolpack.component.TSRadioButton(vision.getMessage('vision:labeler:Start2EndTime'));
            startRadioButton.Name = 'radioStartConfigurationAlgorithm';
            
            currentRadioButton      = toolpack.component.TSRadioButton(vision.getMessage('vision:labeler:Current2EndTime'), true);
            currentRadioButton.Name = 'radioCurrentConfigurationAlgorithm';

            dirGroup = toolpack.component.ButtonGroup;
            dirGroup.add(forwardRadioButton);
            dirGroup.add(reverseRadioButton);            
            fromTimeGroup = toolpack.component.ButtonGroup;
            fromTimeGroup.add(startRadioButton);
            fromTimeGroup.add(currentRadioButton);
            
            importCheckBox      = toolpack.component.TSCheckBox(vision.getMessage('vision:labeler:ImportSelectedROIs'), true);
            importCheckBox.Name = 'chkImportConfigurationAlgorithm';
            
            this.ForwardDirRadioButton   = forwardRadioButton;
            this.ReverseDirRadioButton = reverseRadioButton;
            this.StartTimeRadioButton   = startRadioButton;
            this.CurrentTimeRadioButton = currentRadioButton;
            this.ImportROIsCheckbox     = importCheckBox;
            
            setToolTipText(label0, 'AutomationDirectionTooltip');
            setToolTipText(this.ForwardDirRadioButton, 'AutomationForwardTooltip');
            setToolTipText(this.ReverseDirRadioButton, 'AutomationReverseTooltip');
            
            setToolTipText(label, 'AutomationStartsAtTooltip');
            setToolTipText(this.StartTimeRadioButton, 'Start2EndTimeTooltip');
            setToolTipText(this.CurrentTimeRadioButton, 'Current2EndTimeTooltip');
            setToolTipText(this.ImportROIsCheckbox, 'ImportROIsTooltip');
            
            StartTimePanel.add(label0, 'xyw(1,2,2)');
            StartTimePanel.add(forwardRadioButton, 'xyw(1,4,2)');
            StartTimePanel.add(reverseRadioButton, 'xyw(1,6,2)');
            
            StartTimePanel.add(label, 'xyw(1,9,2)');
            StartTimePanel.add(startRadioButton, 'xyw(1,11,2)');
            StartTimePanel.add(currentRadioButton, 'xyw(1,13,2)');
            ImportROIPanel.add(importCheckBox, 'xyw(1,2,2)');
        end
        
        %------------------------------------------------------------------
        function createTearOff(this)
            
            this.TearOff = toolpack.component.TSTearOffPopup(this.Panel);
            this.TearOff.Title  = vision.getMessage('vision:labeler:AutomationConfigurationTitle');
            this.TearOff.Name   = 'tearoffConfigureAlgorithm';
            autosizeTearOff(this);
        end
        
        %------------------------------------------------------------------
        function autosizeTearOff(this)
            if ~isempty(this.TearOff) && this.TearOff.Visible
                javaMethodEDT('pack', this.TearOff.Peer.getWrappedComponent());
            end
        end
        
        %------------------------------------------------------------------
        function directionChangedCallback(this, ~, ~)
          if this.ForwardDirRadioButton.Selected
              this.StartTimeRadioButton.Text = vision.getMessage('vision:labeler:Start2EndTime');
              this.CurrentTimeRadioButton.Text = vision.getMessage('vision:labeler:Current2EndTime');
              setToolTipText(this.StartTimeRadioButton, 'Start2EndTimeTooltip');
              setToolTipText(this.CurrentTimeRadioButton, 'Current2EndTimeTooltip');
          else
              this.StartTimeRadioButton.Text = vision.getMessage('vision:labeler:End2StartTime');
              this.CurrentTimeRadioButton.Text = vision.getMessage('vision:labeler:Current2StartTime');
              setToolTipText(this.StartTimeRadioButton, 'End2StartTimeTooltip');
              setToolTipText(this.CurrentTimeRadioButton, 'Current2StartTimeTooltip');              
          end
        end
        
        %------------------------------------------------------------------
        function wireCallbacks(this)
            this.Listeners{1} = addlistener(this.ForwardDirRadioButton,     'ItemStateChanged', @this.directionChangedCallback);
            this.Listeners{1} = addlistener(this.ReverseDirRadioButton,     'ItemStateChanged', @this.directionChangedCallback);

            this.Listeners{1} = addlistener(this.StartTimeRadioButton,      'ItemStateChanged', @(es,ed)notify(this, 'StartTimeChanged'));
            this.Listeners{2} = addlistener(this.CurrentTimeRadioButton,    'ItemStateChanged', @(es,ed)notify(this, 'StartTimeChanged'));
            this.Listeners{3} = addlistener(this.ImportROIsCheckbox,        'ItemStateChanged', @(es,ed) notify(this, 'ImportROIsChanged'));
        end
    end
end

function setToolTipText(component, tooltipMsg)
tooltipStr = vision.getMessage(sprintf('vision:labeler:%s',tooltipMsg));
component.Peer.setToolTipText(tooltipStr);
end

function addTitledBorderToPanel(panel)
title = '';
etchedBorder = javaMethodEDT('createEtchedBorder','javax.swing.BorderFactory');
titledBorder = javaMethodEDT('createTitledBorder','javax.swing.BorderFactory',etchedBorder,title);
javaObjectEDT(titledBorder);
panel.Peer.setBorder(titledBorder);
end