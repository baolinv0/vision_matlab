function removePreShowCallback(this)
%   Copyright 2015 The MathWorks, Inc.

if this.PreShowCallbackExists
    mdlRoot = bdroot(this.Handle);
    obj = get_param(mdlRoot,'Object');
    obj.removeCallback('PreShow',['Scope',num2hex(this.Handle)]);
    this.PreShowCallbackExists = false;
end

end