% EventData for exception handling

% Copyright 2017 The MathWorks, Inc.
classdef ExceptionEventData < event.EventData
    properties
        DlgTitle
        ME
    end
    
    methods
        function this = ExceptionEventData(dlgTitle, ME)
            this.DlgTitle = dlgTitle;
            this.ME = ME;
        end
    end
end