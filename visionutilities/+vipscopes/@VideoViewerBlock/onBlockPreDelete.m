function onBlockPreDelete(this)
% onBlockPreDelete implements the callback method
% 'PreDeleteFcn' on the block.

%   Copyright 2015 The MathWorks, Inc.

% Do not allow Scope block deletion when the Scope is being
% launched
bHandle = this.Handle;
hScopeSpec = get_param(bHandle,'ScopeSpecificationObject');
if isempty(hScopeSpec)
    return;
end
if hScopeSpec.IsLaunching
    error(message('Spcuilib:scopes:ErrorPreDelete'));
end

% Make sure we use latest scope configuration for cut/paste and
% delete/undo delete of block.
if isvalid(this.UnifiedScope)
    hScope = this.UnifiedScope;
    hScopeSpec = getState(hScope);
    % Let the specification have a handle to the COSI block
    hScopeSpec.Block = this;
    setSpecificationObject(this,hScopeSpec);
    % Update position property of ScopeCfg object before
    % deleting. Do not call saveScopePosition which forces a set_param
    hScopeSpec.Position = get(hScope.Parent,'Position');
end
end
