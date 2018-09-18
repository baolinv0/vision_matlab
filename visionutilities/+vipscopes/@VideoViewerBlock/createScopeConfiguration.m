function createScopeConfiguration(this)
%CREATESCOPECONFIGURATION Creates a ScopeConfiguration object used for
%programmatic access to the Unified Scope coreblock.

%   Copyright 2015 The MathWorks, Inc.

if isempty(this.ScopeConfiguration) || ~isvalid(this.ScopeConfiguration)
    % First create scope specification object, if necessary...
    createScopeSpecificationObject(this);
    block = this.Handle;
    hScopeSpec = get_param(block,'ScopeSpecificationObject');
    
    % Create it and set on coreblock via COSI block
    configClass = hScopeSpec.getConfigurationClass;
    this.ScopeConfiguration = feval(configClass,hScopeSpec);
end

end

