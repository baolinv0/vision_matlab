function onBlockDelete(this)
%onBlockDelete implements the callback method 'DeleteFcn' on
%   the block.
%   Copyright 2015 The MathWorks, Inc.

% We do not want to listen to the scope closing when we are
% shutting down.
bHandle = this.Handle;
hScopeSpec = get_param(bHandle,'ScopeSpecificationObject');
hScopeSpec.ScopeCloseListener = [];
hScopeSpec.ScopeExtensionListener = [];
% Delete the UI associated with the block when the block is
% deleted, if there is one.
if isvalid(this.UnifiedScope)
    % UnifiedScope Spec might be outdated
    this.UnifiedScope.Specification.Block = hScopeSpec.Block;
    % Close signal selector associated with floating scope
    close(this.UnifiedScope);
end

if ~isempty(this.ScopeConfiguration ) && isvalid(this.ScopeConfiguration)
    delete(this.ScopeConfiguration);
    this.ScopeConfiguration = [ ];
end

% Remove any model-root preshow callbacks that might have been added
this.removePreShowCallback();
end
