function createScopeSpecificationObject(this)
%CREATESCOPESPECIFICATIONOBJECT Creates a ScopeSpecificationObject used for
%programmatic access to the Unified Scope coreblock.

%   Copyright 2015 The MathWorks, Inc.

block = this.Handle;
hScopeSpec = get_param(block,'ScopeSpecificationObject');
if isempty(hScopeSpec)
    % For newly created blocks, load() function is not called. So we
    % need to setup the Specification object. This can also happen if
    % we try to create a Scope Configuration object before the block's
    % post load function is called. One such place is a models
    % PostLoadFcn. We used to serialize ScopeSpecification before and
    % that needs to be accounted for.
    hScopeSpec = get_param(block,'ScopeSpecification');
    if isempty(hScopeSpec)
        scopeCfgString = get_param(block,'ScopeSpecificationString');
        if isempty(scopeCfgString)
            scopeCfgString = get_param(block,'DefaultConfigurationName');
        end
        hScopeSpec = eval(scopeCfgString);
    end
    % Let the specification have a handle to the COSI block
    hScopeSpec.Block = this;
    % If CurrentConfiguration is empty, create the defaults.
    if isempty(hScopeSpec.CurrentConfiguration)
        % We need to load the default configuration for this specification
        hScopeSpec.CurrentConfiguration = ...
            matlabshared.scopes.getDefaultConfigurationSet(hScopeSpec.getConfigurationFile);
    end
    this.setSpecificationObject(hScopeSpec);
end

% If Block is not set, do it now. This can happen when undoing
% block delete.
if isempty(hScopeSpec.Block)
    hScopeSpec.Block = this;
end

end

