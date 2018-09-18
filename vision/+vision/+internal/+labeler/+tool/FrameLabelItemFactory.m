% This is a factory class that creates instances of FrameLabelItem objects.
classdef FrameLabelItemFactory < vision.internal.labeler.tool.ListItemFactory       
    methods(Static)
        function item = create(parent, idx, data)
            item = vision.internal.labeler.tool.FrameLabelItem(parent, idx, data);
        end                
    end            
end