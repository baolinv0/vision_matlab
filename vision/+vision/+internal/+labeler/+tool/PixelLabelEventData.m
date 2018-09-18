% This class defines event data for modified Pixel Label data.
classdef (ConstructOnLoad) PixelLabelEventData < event.EventData
    properties
        Data;
    end
    
    methods
        function this = PixelLabelEventData(data)
            this.Data = data;
        end
    end
end