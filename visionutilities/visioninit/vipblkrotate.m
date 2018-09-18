function [b] = vipblkrotate(varargin) %#ok
% MMBLKROTATE Mask dynamic dialog function for Rotation/Translation block

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
        ports.icon = 'Rotate';
        anglesrc = get_param(blk, 'src_angle');
        if strcmp(anglesrc,'Input port')
            ports.port1=1;
            ports.txt1='Image';
            ports.port2=2;
            ports.txt2='Angle';
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


        % end of vipblk2dpad.m
