% This class is for internal use only and may change in the future.

% This class defines is a stub to override things like tool tips.

% Copyright 2017 The MathWorks, Inc.

classdef AlgorithmSection < vision.internal.labeler.tool.sections.AlgorithmSection
   
    methods 
        function this = AlgorithmSection(tool)
            this = this@vision.internal.labeler.tool.sections.AlgorithmSection(tool);
        end
    end
    
    methods (Access = protected)
        function tip = getConfigureAlgorithmToolTip(~)
            % return tool tip. Override tool tip by sub-classing and
            % reimplementing just this method.
            tip = 'vision:labeler:ConfigureAlgorithmTooltip';
        end
    end 
end
    
