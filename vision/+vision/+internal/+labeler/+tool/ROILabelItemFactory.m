% This is a factory class that creates instances of ROILabelItem objects.
classdef ROILabelItemFactory < vision.internal.labeler.tool.ListItemFactory       
    methods(Static)
        function item = create(parent, idx, data)
            item = vision.internal.labeler.tool.ROILabelItem(parent, idx, data);
        end                
    end            
end