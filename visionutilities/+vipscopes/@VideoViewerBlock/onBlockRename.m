function onBlockRename(this)
%onBlockRename implements the 'NameChangeFcn' callback method
%   on the block. This method updated the ApplicationName on
%   the Source object to reflect the new name on the block.

%   Copyright 2015 The MathWorks, Inc.

if isvalid(this.UnifiedScope)
    % Update the Source information.
    hScope = this.UnifiedScope;
    updateSourceName(hScope.DataSource);
    % Update the title bar to reflect the new name.
    updateTitleBar(hScope);
    sendEvent(hScope,'SourceNameChanged');
end
end
