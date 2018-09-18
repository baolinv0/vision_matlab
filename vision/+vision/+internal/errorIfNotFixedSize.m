function errorIfNotFixedSize(x, name)
% errorIfNotFixedSize throws an error during codegen if x is not fixed
% size. Use this for checking parameter values that do not need to support
% variable size values.

%#codegen
if ~isempty(coder.target)
    % compile time error if x is not fixed sized
    eml_invariant(eml_is_const(size(x)), ...
                  eml_message('vision:validation:notFixedSize',...
                  name));
end