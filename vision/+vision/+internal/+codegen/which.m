function fp = which(str)
% Locate function from the path. This is a codegen version of the which
% function.

%#codegen

myfun = 'which';
coder.extrinsic('eml_try_catch');
[errid,errmsg,fp] = eml_const(eml_try_catch(myfun,str));
eml_lib_assert(isempty(errmsg),errid,errmsg);