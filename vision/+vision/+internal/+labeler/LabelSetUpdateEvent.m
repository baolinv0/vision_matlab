%LabelSetUpdateEvent holds event data sent by ROILabelSet.

% Copyright 2016 The MathWorks, Inc.
classdef LabelSetUpdateEvent < event.EventData
    properties
        Label
        OldLabel
    end
    
    methods
        function this = LabelSetUpdateEvent(label)
            this.Label = label;
        end
    end
end