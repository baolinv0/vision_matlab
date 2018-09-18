function registerVisionUtilityExtensions(ext)
%registerVisionUtilityExtensions

%   Copyright 2016 The MathWorks, Inc.

uiscopes.addDataHandler(ext,'Streaming','Video','scopeextensions.VideoMLStreamingHandler');

% [EOF]
