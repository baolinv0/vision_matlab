function exst = exist(file)
% Determine whether file exists on path. This is a codegen version of the
% exist function.

%#codegen
myfun = 'exist';
coder.extrinsic('eml_try_catch');
[errid,errmsg,exst] = eml_const(eml_try_catch(myfun,file,'file'));        
eml_lib_assert(isempty(errmsg),errid,errmsg);
