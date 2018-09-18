% This class is for internal use only and may change in the future.

% This class defines the videoLabeler view section.

% Copyright 2016 The MathWorks, Inc.

classdef ViewSection < vision.internal.uitools.NewToolStripSection
    
    properties
        LayoutButton
        ShowROILabelCheckBox
        ShowSceneLabelCheckBox
    end
    
    methods
        function this = ViewSection()
            this.createSection();
            this.layoutSection();
        end
    end
    
    methods (Access = protected)
        function createSection(this)
            
            viewSectionTitle = getString( message('vision:labeler:ViewSection') );
            viewSectionTag   = 'sectionView';
            
            this.Section = matlab.ui.internal.toolstrip.Section(viewSectionTitle);
            this.Section.Tag = viewSectionTag;
        end
        
        function layoutSection(this)
            
            this.addLayoutButton();
            this.addShowROILabelCheckBox();
            this.addShowSceneLabelCheckBox();
            
            col = this.addColumn();
            col.add(this.LayoutButton);
            col.add(this.ShowROILabelCheckBox);
            col.add(this.ShowSceneLabelCheckBox);
        end
        
        function addLayoutButton(this)
            
            import matlab.ui.internal.toolstrip.Icon.*;
            
            icon    = LAYOUT_16;
            titleID = 'vision:labeler:DefaultLayout';
            tag     = 'btnDefaultLayout';
            this.LayoutButton = this.createButton(icon, titleID, tag);
            this.LayoutButton.Enabled = true;
            toolTipID = 'vision:labeler:DefaultLayoutToolTip';
            this.setToolTipText(this.LayoutButton, toolTipID);                
        end
        
        function addShowROILabelCheckBox(this)

            titleID = 'vision:labeler:ShowROILabels';
            tag     = 'chkShowROILabel';
            toolTipID = 'vision:labeler:ShowROILabelsToolTip';
            
            this.ShowROILabelCheckBox = this.createCheckBox(titleID, tag, toolTipID);
            this.ShowROILabelCheckBox.Value = true;
        end
        
        function addShowSceneLabelCheckBox(this)
            
            titleID     = 'vision:labeler:ShowSceneLabels';
            tag         = 'chkShowSceneLabel';
            toolTipID   = 'vision:labeler:ShowSceneLabelsToolTip';
            
            this.ShowSceneLabelCheckBox = this.createCheckBox(titleID, tag, toolTipID);
            this.ShowSceneLabelCheckBox.Value = true;
        end
    end
end
