% This class is for internal use only and may change in the future.

% This class defines the videoLabeler settings section in the
% algorithm tab which houses the buttons to change algorithm settings.

% Copyright 2016 The MathWorks, Inc.

classdef SettingsSection < vision.internal.uitools.NewToolStripSection
    
    properties
        SettingsButton
    end
    
    methods
        function this = SettingsSection()
            this.createSection();
            this.layoutSection();
        end
    end
    
    methods (Access = private)
        function createSection(this)
            
            settingsSectionTitle = vision.getMessage('vision:labeler:Settings');
            settingsSectionTag   = 'sectionSettings';
            
            this.Section = matlab.ui.internal.toolstrip.Section(settingsSectionTitle);
            this.Section.Tag = settingsSectionTag;
        end
        
        function layoutSection(this)
            
            this.addSettingsButton();
            
            settingsCol = this.addColumn();
            settingsCol.add(this.SettingsButton);
        end
        
        function addSettingsButton(this)
            
            icon    = matlab.ui.internal.toolstrip.Icon.SETTINGS_24;
            titleID = 'vision:labeler:Settings';
            tag     = 'btnSettings';
            this.SettingsButton = this.createButton(icon, titleID, tag);
            toolTipID = 'vision:labeler:SelectSettingsAlgorithmTooltip';
            this.setToolTipText(this.SettingsButton, toolTipID);
        end
    end
end