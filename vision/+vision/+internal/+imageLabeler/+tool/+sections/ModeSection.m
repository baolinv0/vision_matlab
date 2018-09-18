% This class is for internal use only and may change in the future.

% This is just a stub to customize things like tool tips.

% Copyright 2017 The MathWorks, Inc.

classdef ModeSection < vision.internal.labeler.tool.sections.ModeSection
   
    methods (Access = protected)
        function tip = getROIButtonToolTip(~)     
           tip = 'vision:imageLabeler:ROIButtonTooltip';
        end
    end
end