% This class defines event data for modified items.
classdef (ConstructOnLoad) ItemModifiedEvent < event.EventData
    properties
        % Index The index of a modified item.
        Index;
        Data;
    end
    
    methods
        function this = ItemModifiedEvent(idx, data)
            this.Index = idx;
            this.Data = data;
        end
    end
end