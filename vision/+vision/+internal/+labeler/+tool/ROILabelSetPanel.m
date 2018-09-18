% This class defines the panel that holds a set of ROI labels. 
classdef ROILabelSetPanel < vision.internal.labeler.tool.ScrollableList
    
    methods
        %------------------------------------------------------------------
        function this = ROILabelSetPanel(parent, position)           
            itemFactory = vision.internal.labeler.tool.ROILabelItemFactory();
            
            this = this@vision.internal.labeler.tool.ScrollableList(...
                parent, position, itemFactory);

        end
      
    end
end
