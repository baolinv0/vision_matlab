function [b] = vipblkshear(varargin) %#ok
% VIPBLKSHEAR Mask dynamic dialog function for Shear block

% Copyright 2003-2004 The MathWorks, Inc.

if nargin==0
    action = 'dynamic';   % mask callback
else
    action = 'icon';
end

blk = gcbh;
switch action
    case 'icon'
        b = get_labels(blk);
end


% ----------------------------------------------------------
    function ports = get_labels(blk)
        ports.icon = 'Shear';
        transsrc = get_param(blk, 'src_shear');
        if strcmp(transsrc,'Input port')
            ports.port1=1;
            ports.txt1='Image';
            ports.port2=2;
            ports.txt2='S';
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

        % end of vipblkshear.m