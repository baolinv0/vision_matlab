% validateFixedSize Issue a compile time error if input is not fixed sized

% Copyright 2013-2014 MathWorks, Inc.

%#codegen

function validateFixedSize(var, varName)
 eml_invariant(eml_is_const(size(var)), ...
        eml_message('vision:dims:varSizeNotSupported', varName));