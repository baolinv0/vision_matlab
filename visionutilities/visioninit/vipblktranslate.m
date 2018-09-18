function [b] = vipblktranslate(varargin) %#ok
% MMBLKROTATE Mask dynamic dialog function for Translation block

% Copyright 2003-2006 The MathWorks, Inc.

if nargin==0
    action = 'dynamic';   % mask callback
else
    action = 'icon';
end

    blk = gcbh;    
switch action
case 'icon'
    ports.icon = 'Translate';
    transsrc = get_param(blk, 'src_trans');
    if strcmp(transsrc,'Input port')
        ports.port1=1;
        ports.txt1='Image';
        ports.port2=2;
        ports.txt2='Offset';
        ports.port3=2;
        ports.txt3='';
    else
        ports.port1=1;
        ports.txt1='';
        ports.port2=1;
        ports.txt2='';
        ports.port3=1;
        ports.txt3='';
    end
    b = ports;

otherwise
    error(message('vision:internal:unhandledCase'));
end

