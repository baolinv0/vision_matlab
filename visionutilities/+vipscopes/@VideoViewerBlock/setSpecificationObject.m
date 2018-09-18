function setSpecificationObject(this,hScopeSpec)
%SETSPECIFICATIONOBJECT set_param call on ScopeSpecificationObject and
%ensure that older version of ScopeSpecification param is cleared.

%   Copyright 2015 The MathWorks, Inc.

this.ScopeSpecificationObject = hScopeSpec;
if ~isempty(this.ScopeSpecification)        
    this.ScopeSpecification = [];
end