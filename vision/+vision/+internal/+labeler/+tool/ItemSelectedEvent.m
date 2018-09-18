% This class defines event data for selected items.
classdef (ConstructOnLoad) ItemSelectedEvent < event.EventData
    properties
        % Index The index of a selected item.
        Index
    end
    
    methods
        function this = ItemSelectedEvent(idx)
            this.Index = idx;
        end
    end
end