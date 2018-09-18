function tf = isCodegen()
% Determine if MATLAB Coder is in use

%#codegen

tf = ~isempty(coder.target);
