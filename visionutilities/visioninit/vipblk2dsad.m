function varargout = vipblk2dsad(action)
% VIPBLK2DCONV Mask dynamic dialog function for 2D Convolution block

% Copyright 1995-2006 The MathWorks, Inc.
if nargin==0, action = 'dynamic'; end
blk = gcbh;   % Cache handle to block

switch action
    case 'icon'
        iconStruct = get_labels(blk);
        varargout(1) = {iconStruct};

    case 'init'
        dtInfo = dspGetFixptDataTypeInfo(blk,7);
        varargout(1) = {dtInfo};

end

% ----------------------------------------------------------
function ports  = get_labels(blk)   
outputMode      = get_param(blk,'output');
isRoi           = get_param(blk,'roi');
isMinIndx       = strcmp(outputMode,'Minimum SAD value index') ;

ports.iport1=1;
ports.itxt1='I';

ports.iport2=2;
ports.itxt2='Template';

if (isMinIndx && strcmp(isRoi,'on'))
    ports.iport3=3;
    ports.itxt3='ROI';
else
    ports.iport3=2;
    ports.itxt3='';
end
if strcmp(outputMode,'SAD values')
    ports.oport1=1;
    ports.otxt1='Val';

    ports.oport2=1;
    ports.otxt2='';

    ports.oport3=1;
    ports.otxt3='';
elseif strcmp(outputMode,'Minimum SAD value index')
    ports.oport1=1;
    ports.otxt1='Idx';
    nearbyVal = get_param(blk,'nearbyPel');
    if strcmp(nearbyVal,'on')
        ports.oport2=2;
        ports.otxt2='NVals';
        ports.oport3=3;
        ports.otxt3='NValid';
    else
        ports.oport2=1;
        ports.otxt2='';
        ports.oport3=1;
        ports.otxt3='';
    end
else
    error(message('vision:internal:unhandledCase'));
end

