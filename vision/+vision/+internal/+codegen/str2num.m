function [value, isValid] = str2num(str)
% Call STR2NUM for compile time constants.

coder.extrinsic('eml_try_catch');

%#codegen
if isempty(coder.target())
    out = vision.internal.codegen.locstr2num(str);
else
    myfun = 'vision.internal.codegen.locstr2num';    
    [errid,errmsg,out] = eml_const(eml_try_catch(myfun,str));
    eml_lib_assert(isempty(errmsg),errid,errmsg);
end

value   = out.Value;
isValid = out.IsValid;