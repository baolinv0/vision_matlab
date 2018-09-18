function onModelSave(this)
%onModelSave executes when the model is saved.  This saves the
%   ScopeCfg object in the block.
% If the scope is launched, we need to get the state every time
% the model is saved so that the latest scopecfg is saved into
% the mdl file.

%   Copyright 2015 The MathWorks, Inc.

block = this.Handle;
hScopeSpec = get_param(block,'ScopeSpecificationObject');
if isvalid(this.UnifiedScope)
    hScope = this.UnifiedScope;
    hScopeSpec = getState(hScope);
    % Updating to the latest State will delete the COSI stored in property
    % "Block". Repopulate it as otherwise features depending on it will
    % error out.
    hScopeSpec.Block = this;
    this.setSpecificationObject(hScopeSpec);
    saveScopePosition(hScopeSpec,get(hScope.Parent,'Position'));
elseif ~isempty(hScopeSpec)
    % If there is no unified scope available, make sure that the default
    % properties are pruned from the Specification's CurrentConfiguration.
    pruneDefaultProperties(hScopeSpec);
end

% All core blocks that are not in locked systems, convert their
% Specification objects to strings before the model is saved.  The
% exception is when the ScopeCfg is empty or is not an
% extmgr.ConfigurationSet.  This can happen when saving to an older release
% when the ConfigurationSet was a ConfigDb.
if ~isempty(hScopeSpec) && strcmp(get_param(bdroot(block),'Lock'),'off') && ...
        isNewConfiguration(hScopeSpec.CurrentConfiguration)
    preserve_dirty = Simulink.PreserveDirtyFlag(bdroot(block), 'blockDiagram' );  %#ok<NASGU>
    % Sync the ScopeSpecificationString with the latest scope spec.
    warnstate = warning;
    warning( 'off', 'Simulink:Commands:SetParamLinkChangeWarn' );
    set_param(block, 'ScopeSpecificationString',hScopeSpec.toString(false,true));
    warning( warnstate );  % Restore the original warning state
end

function b = isNewConfiguration(hConfigSet)

b = true;
if isa(hConfigSet, 'extmgr.ConfigurationSet')
    for indx = 1:numel(hConfigSet.Children)
        if isa(hConfigSet.Children(indx).PropertySet, 'extmgr.PropertyDb')
            b = false;
        end
    end
else
    b = false;
end

% [EOF]
