% This class defines the panel that holds a set of frame labels. 
classdef FrameLabelSetPanel < vision.internal.labeler.tool.ScrollableList
    
    methods
        %------------------------------------------------------------------
        function this = FrameLabelSetPanel(parent, position)           
            itemFactory = vision.internal.labeler.tool.FrameLabelItemFactory();
            
            this = this@vision.internal.labeler.tool.ScrollableList(... // 
                parent, position, itemFactory);

            % Enable multi-select support for this list
            % this.MultiSelectSupport = true;
        end
      
       
    end
end
