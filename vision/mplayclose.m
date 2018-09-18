function mplayclose(arg)
%MPLAYCLOSE Close any or all MPlay GUI instances.
%   MPLAYCLOSE closes the current MPlay viewer.
%
%   MPLAYCLOSE('all') closes all MPlay instances.

%   Copyright 2005-2007 The MathWorks, Inc.

if nargin<1
    m = uiscopes.find(0);
else
    validatestring(arg,{'all'});
    m = uiscopes.find;
end

% Return early if there are no scopes open.
if isempty(m), return; end

m = findobj(m, '-depth', 0, '-function', @(h) isMPlay(h));

if ~isempty(m)
    close(m);
end

%% ------------------------------------------------------------------------
function b = isMPlay(h)

b = strcmp(h.getAppName(true), 'MPlay');
