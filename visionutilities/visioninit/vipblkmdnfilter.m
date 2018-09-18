function [ports,dtInfo] = vipblkmdnfilter
% VIPBLK2DFIRFILTER Mask dynamic dialog function for Median Filter block

% Copyright 2003-2006 The MathWorks, Inc.

blk = gcbh;

ports = get_labels(blk);

dtInfo = dspGetFixptDataTypeInfo(gcbh,7);

try
    nghbood = get_param(blk,'nghbood');
    val = prod(slResolve(nghbood,blk,'expression'));
    isNHoddOdd = (rem(val,2) ~=0);
catch
    isNHoddOdd=0;
end

if isNHoddOdd
    % when nhoodsize=[r c], both r,c are odd (i.e., r*c is odd)
    % we need to make sure that
    % accumMode=prodOutputMode=outputMode=SAME_AS_INPUT
    dtInfo.accumMode=2;
    dtInfo.prodOutputMode=2;
    dtInfo.outputMode=2;
end

        

% ----------------------------------------------------------
function ports = get_labels(blk)   
padMethod = get_param(blk, 'padType');
outsize  = get_param(blk,'outSize');
ports.type1='input';
ports.port1=1;
ports.txt1='I';

ports.type3='output';
ports.port3=1;
ports.txt3='';

if strcmp(outsize,'Valid')
    ports.type2='';
    ports.port2=1;
    ports.txt2='';
else
    if strcmp(padMethod,'Constant')
        padsrc = get_param(blk, 'padSrc');
        if strcmp(padsrc,'Input port')
            ports.type2='input';
            ports.port2=2;
            ports.txt2='PVal';
        else
            ports.type2='';
            ports.port2=1;
            ports.txt2='';
        end
    else
        ports.type2='';
        ports.port2=1;
        ports.txt2='';
    end
end

% end of vipblk2dfirfilter.m
