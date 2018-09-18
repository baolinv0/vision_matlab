function [b] = vipblkcomposite(varargin) 
% VIPBLKCOMPOSITE Mask dynamic dialog function for Compositing block

% Copyright 2003-2006 The MathWorks, Inc.

if nargin==0
    action = 'dynamic';   % mask callback
else
    action = 'icon';
end

blk = gcbh;   

switch action    
case 'icon'
    operatn = get_param(blk,'operation');
    inLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
    if inLibrary
        ports.icon = 'Compositing'; 
    else
        if (strcmp(operatn,'Blend'))
            ports.icon = 'Blend';
        elseif (strcmp(operatn,'Binary mask'))
            ports.icon = 'Binary\nmask';
        else
            ports.icon = 'Highlight';
        end
    end    
    ports.port1=1;
    ports.txt1='Image1';
    ports.port2=2;
    ports.txt2='Image2';
    extraPort = 0;
    if (strcmp(operatn,'Blend'))
        bFacSource = get_param(blk,'bFacSrc');
        if (strcmp(bFacSource,'Input port'))
            ports.port3=3;
            ports.txt3='Factor';
            extraPort = 1;
        end
    elseif (strcmp(operatn,'Binary mask'))
        mFacSource = get_param(blk,'mFacSrc');
        if (strcmp(mFacSource,'Input port'))
            extraPort = 1;
            ports.port3=3;
            ports.txt3='Mask';
        end
    else
        ports.port2=2;
        ports.txt2='Mask';   
        extraPort = 0;
    end
    co_src = get_param(blk, 'source');
    if  strcmp(co_src,'Input port')
        if (extraPort == 1)
            ports.port4=4;
            ports.txt4='Location';
        else
            ports.port3=3;
            ports.txt3='Location';
            ports.port4=3;
            ports.txt4='';
        end
    else
        if (extraPort == 1)
            ports.port4=3;
            ports.txt4='';
        else
            ports.port3=2;
            ports.txt3='';
            ports.port4=2;
            ports.txt4='';
        end
    end
    b = ports;
otherwise
    error(message('vision:internal:unhandledCase'));
end


% end of vipblkcomposite.m
