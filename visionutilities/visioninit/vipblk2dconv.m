function [dtInfo] = vipblk2dconv(action)
% VIPBLK2DCONV Mask dynamic dialog function for 2D Convolution block

% Copyright 1995-2006 The MathWorks, Inc.
if nargin==0, action = 'dynamic'; end
blk = gcbh;   % Cache handle to block

switch action

    case 'init'
        dtInfo = dspGetFixptDataTypeInfo(blk,15);

    otherwise
        error(message('vision:internal:unhandledCase'));
end
