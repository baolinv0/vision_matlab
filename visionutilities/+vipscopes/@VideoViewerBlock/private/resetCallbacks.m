function resetCallbacks(blk,uMethod)
% Resets the user callbacks to NULL if already defined.User
% Callbacks are called from core blocks API.

%   Copyright 2015 The MathWorks, Inc.

uCallback = get_param(blk,uMethod);
if strncmp(uCallback,'scopeext',8) || strncmp(uCallback,'simscope',8)
    set(blk,uMethod,'');
end
end
