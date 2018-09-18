% This class is for internal use only and may change in the future.

% This class defines is a stub to override things like tool tips.

% Copyright 2017 The MathWorks, Inc.

classdef ViewSection < vision.internal.labeler.tool.sections.ViewSection
   
    methods 
        function this = ViewSection()
            this = this@vision.internal.labeler.tool.sections.ViewSection();
        end
    end
    
    methods (Access = protected)
       function addShowROILabelCheckBox(this)

            titleID = 'vision:imageLabeler:ShowROILabels';
            tag     = 'chkShowROILabel';
            toolTipID = 'vision:imageLabeler:ShowROILabelsToolTip';
            
            this.ShowROILabelCheckBox = this.createCheckBox(titleID, tag, toolTipID);
            this.ShowROILabelCheckBox.Value = true;
        end
    end 
end
    
