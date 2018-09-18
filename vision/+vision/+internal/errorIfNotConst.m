function errorIfNotConst(x, name)
% errorIfNotConst throws an error during codegen if x is not const.

%#codegen
if ~isempty(coder.target)
    % compile time error if x is not const
    eml_invariant(eml_is_const(x), ...
                  eml_message('vision:validation:notConst',...
                  name));
end