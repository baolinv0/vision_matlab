% This is a factory class that creates instances of InstructionsItem objects.
classdef InstructionsItemFactory < vision.internal.labeler.tool.ListItemFactory       
    methods(Static)
        function item = create(parent, idx, data)
            item =vision.internal.labeler.tool.InstructionsItem(parent, idx, data);
        end                
    end            
end