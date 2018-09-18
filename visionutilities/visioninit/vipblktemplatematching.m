function varargout = vipblktemplatematching(action)
% VIPBLKTEMPLATEMATCHING Mask dynamic dialog function for Template Matching Block

% Copyright 1995-2006 The MathWorks, Inc.
if nargin==0, action = 'dynamic'; end
blk = gcbh;   % Cache handle to block

switch action
    case 'icon'
        [iconStruct blkname] = get_labels(blk);
        varargout(1) = {iconStruct};
        varargout(2) = {blkname};

    case 'init'
        dtInfo = dspGetFixptDataTypeInfo(blk,15);
        varargout(1) = {dtInfo};

end

% ----------------------------------------------------------
function [ports blkname]  = get_labels(blk)   

metricStr = get_param(blk,'metric');

isBlkInLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
if isBlkInLibrary
	blkname = 'Template\nMatching';
else
    switch metricStr
        case 'Sum of absolute differences'
            blkname = 'Sum of\nAbsolute\nDifferences';
        case 'Sum of squared differences'
            blkname = 'Sum of\nSquared\nDifferences';
        case 'Maximum absolute difference'
            blkname = 'Maximum\nAbsolute\nDifference';
        otherwise
            blkname = 'Template\nMatching';
    end
end

outputMode      = get_param(blk,'output');
isBestMatchLoc  = strcmp(outputMode,'Best match location') ;
isMetricMatrix  = strcmp(outputMode,'Metric matrix') ;
isROI           = strcmp(get_param(blk,'roi'),'on');
isROIValidPort  = strcmp(get_param(blk, 'roiValid'),'on');

ports.iport1=1;
ports.itxt1='I';

ports.iport2=2;
ports.itxt2='T';

if (isBestMatchLoc && isROI)
    ports.iport3=3;
    ports.itxt3='ROI';
else
    ports.iport3=2;
    ports.itxt3='';
end

if (isMetricMatrix)
    ports.oport1=1;
    ports.otxt1='Metric';

    ports.oport2=1;
    ports.otxt2='';

    ports.oport3=1;
    ports.otxt3='';
    
    ports.oport4=1;
    ports.otxt4='';
elseif (isBestMatchLoc)
    ports.oport1=1;
    ports.otxt1='Loc';
    isNMetric = strcmp(get_param(blk,'nMetric'), 'on');
    if (isNMetric)
        ports.oport2=2;
        ports.otxt2='NMetric';
        ports.oport3=3;
        ports.otxt3='NValid';
         if (isROI && isROIValidPort)
            ports.oport4=4;
            ports.otxt4='ROIValid';
        else
            ports.oport4=1;
            ports.otxt4='';
        end
    else
        if (isROI && isROIValidPort)
            ports.oport4=2;
            ports.otxt4='ROIValid';
            ports.oport2=2;
            ports.otxt2='';
            ports.oport3=2;
            ports.otxt3='';
        else
            ports.oport4=1;
            ports.otxt4='';
            ports.oport2=1;
            ports.otxt2='';
            ports.oport3=1;
            ports.otxt3='';
        end        
    end
else
    error(message('vision:internal:unhandledCase'));
end

