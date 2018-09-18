% This class defines event data for selected items.
classdef (ConstructOnLoad) ImageRotateEvent < event.EventData
    properties
        % Index The index of a selected item.
        Index
        % RotationType Clockwise or counterclockwise
        RotationType
    end
    
    methods
        function this = ImageRotateEvent(idx, rotType)
            this.Index = idx;
            this.RotationType = rotType;
        end
    end
end