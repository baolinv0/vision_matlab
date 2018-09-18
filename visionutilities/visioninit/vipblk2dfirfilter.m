function ports = vipblk2dfirfilter()
% VIPBLK2DFIRFILTER Mask display function for 2D FIR Filter block

% Copyright 2003-2006 The MathWorks, Inc.

blk = gcbh;

filtCoeffSrc      = get_param(blk,'filtSrc');
isSeparable       = get_param(blk,'separable');
padMethod = get_param(blk, 'padType');
outsize  = get_param(blk,'outSize');
ports.type1='input';
ports.port1=1;
ports.txt1='I';

ports.type4='output';
ports.port4=1;
ports.txt4='';

if strcmp(filtCoeffSrc,'Input port')
    if (strcmp(isSeparable,'on'))
        ports.type2='input';
        ports.port2=2;
        ports.txt2='HV';
        ports.type3='input';
        ports.port3=3;
        ports.txt3='HH';
        if strcmp(outsize,'Valid')
            ports.type4='';
            ports.port4=3;
            ports.txt4='';
        else
            if strcmp(padMethod,'Constant')
                padsrc = get_param(blk, 'padSrc');
                if strcmp(padsrc,'Input port')
                    ports.type4='input';
                    ports.port4=4;
                    ports.txt4='PVal';
                else
                    ports.type4='';
                    ports.port4=3;
                    ports.txt4='';
                end
            else
                ports.type4='';
                ports.port4=3;
                ports.txt4='';
            end
        end
    else
        ports.type2='input';
        ports.port2=2;
        ports.txt2='H';
        if strcmp(outsize,'Valid')
            ports.type3='';
            ports.port3=2;
            ports.txt3='';
            ports.type4='';
            ports.port4=2;
            ports.txt4='';
        else
            if strcmp(padMethod,'Constant')
                padsrc = get_param(blk, 'padSrc');
                if strcmp(padsrc,'Input port')
                    ports.type3='input';
                    ports.port3=3;
                    ports.txt3='PVal';
                    ports.type4='';
                    ports.port4=3;
                    ports.txt4='';                    
                else
                    ports.type3='';
                    ports.port3=2;
                    ports.txt3='';
                    ports.type4='';
                    ports.port4=2;
                    ports.txt4='';                    
                end
            else
                ports.type3='';
                ports.port3=2;
                ports.txt3='';
                ports.type4='';
                ports.port4=2;
                ports.txt4='';                    
            end
        end
    end
else
    if strcmp(outsize,'Valid')
        ports.type2='';
        ports.port2=1;
        ports.txt2='';
        ports.type3='';
        ports.port3=1;
        ports.txt3='';
        ports.type4='';
        ports.port4=1;
        ports.txt4='';
    else
        if strcmp(padMethod,'Constant')
            padsrc = get_param(blk, 'padSrc');
            if strcmp(padsrc,'Input port')
                ports.type2='input';
                ports.port2=2;
                ports.txt2='PVal';
                ports.type3='';
                ports.port3=2;
                ports.txt3='';
                ports.type4='';
                ports.port4=2;
                ports.txt4='';
            else
                ports.type2='';
                ports.port2=1;
                ports.txt2='';
                ports.type3='';
                ports.port3=1;
                ports.txt3='';
                ports.type4='';
                ports.port4=1;
                ports.txt4='';
            end
        else
            ports.type2='';
            ports.port2=1;
            ports.txt2='';
            ports.type3='';
            ports.port3=1;
            ports.txt3='';
            ports.type4='';
            ports.port4=1;
            ports.txt4='';
        end
    end
end

% end of vipblk2dfirfilter.m