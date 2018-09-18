% This class defines event data for modified ROI Labels.
classdef (ConstructOnLoad) ROILabelEventData < event.EventData
    properties
        Data;
    end
    
    methods
        function this = ROILabelEventData(data)
            this.Data = data;
        end
    end
end