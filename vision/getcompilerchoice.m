function choice = getcompilerchoice
% GETCOMPILERCHOICE Return currently selected compiler.
% CHOICE = GETCOMPILERCHOICE returns 1 if mex compiler is LCC, 2 if
%   compiler is Watcom and 0 otherwise.
%
%   Copyright 2009-2011 The MathWorks, Inc.

% Note: This function is called from the s-functions using IPP to check for
% compiler compatibility

if ispc
    % only check Windows platform
    compilername = getcompilername;
    if isequal(compilername, 'lcc');
        choice = 1;
    elseif isequal(compilername, 'watc');
        choice = 2;
    else
        choice = 0;
    end
else
    choice = 0;
end
end


% Possible compiler strings are: vc, vcx64, watc, lcc
% -------------------------------------------------------------------------
function compiler = getcompilername
try
    tc = rtwprivate('getCompilerForModel',bdroot);
catch  %#ok<CTCH>
    % If any error occurs here then we cannot determine the compiler:
    % treat as an unknown compiler
    tc = '';
end
if isfield(tc, 'toolChain') && ~isempty(tc.toolChain)
    compiler = tc.toolChain;
else
    compiler = 'unknown compiler';
end
end
