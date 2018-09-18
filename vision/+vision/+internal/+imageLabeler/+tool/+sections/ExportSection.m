% This class is for internal use only and may change in the future.

% This class defines the image labeler export section. This is just a stub
% to customize things like tool tips.

% Copyright 2017 The MathWorks, Inc.

classdef ExportSection < vision.internal.labeler.tool.sections.ExportSection
    methods (Access = protected)
        function toolTipID = getExportButtonToolTip(~)
            % return tool tip. 
            toolTipID = 'vision:imageLabeler:ExportAnnotationsToolTip';
        end
    end
end