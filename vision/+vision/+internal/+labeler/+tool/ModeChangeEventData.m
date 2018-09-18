% This class defines event data for mode change through context menu.
classdef (ConstructOnLoad) ModeChangeEventData < event.EventData
    properties
        Mode;
    end
    
    methods
        function this = ModeChangeEventData(mode)
            this.Mode = mode;
        end
    end
end