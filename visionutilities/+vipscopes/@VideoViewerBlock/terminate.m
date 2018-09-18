function terminate(this)
%TERMINATE Terminate method for Unified Scope coreblock.

%   Copyright 2015 The MathWorks, Inc.

block = this.Handle;
if isvalid(this.UnifiedScope)
    hSource = this.UnifiedScope.DataSource;
    rto = get_param(block,'RunTimeObject');
    
    hSource.RunTimeBlock = rto;
    % Cache the final raw data.
    hSource.RawDataCache = getRawData(hSource);
    % Clear any cached num inputs in source
    hSource.CachedNumInputs = [];
    
    % Update Text
    if (this.UpdateCount ~= -1)
        updateSimulationTime(hSource);
        updateText(hSource);
    end
    
end

% mdlTerminate on the Specification is used to update the enabledness of
% menus or other widgets.
hScopeSpec = get_param(block,'ScopeSpecificationObject');
if ~isempty(hScopeSpec)
    mdlTerminate(hScopeSpec);
end

end

