classdef WasSelectedEventData < event.EventData
    properties
        WasSelected
    end
    
    methods
        function this = WasSelectedEventData(wasSelected)
            this.WasSelected = wasSelected;
        end
    end
end