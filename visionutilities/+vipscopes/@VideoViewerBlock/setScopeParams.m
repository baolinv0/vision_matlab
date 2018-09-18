function setScopeParams(this,varargin)
%setScopeParams Set all of the scope parameters.
%   Copyright 2015 The MathWorks, Inc.

    if ~isempty(this.ScopeSpecificationObject)
        setScopeParams( this.ScopeSpecificationObject );
    end
    
end
