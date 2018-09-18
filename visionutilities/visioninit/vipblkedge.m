function [si,so,blkname,dtInfo]= vipblkedge

% VIPBLKEDGE Mask initialization function for Edge Detection block

% Copyright 2003-2005 The MathWorks, Inc.

blk = gcbh;   % handle to block

% get elements of the mask that affect dynamic elements
outputTypeStr = get_param(blk,'outputType');
methodStr = get_param(blk,'method');

isBlkInLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
if isBlkInLibrary
	blkname = 'Edge\nDetection';
else
	blkname = methodStr;
end

userDefinedThresholdStr = get_param(blk,'userDefinedThreshold');
thresholdSourceStr = get_param(blk,'thresholdSource');

dtInfo = dspGetFixptDataTypeInfo(blk,15);

si(1).port = 1; si(1).txt  = 'I';
if ~strcmp(methodStr,'Canny')
    if    strcmp(thresholdSourceStr, 'Input port') && ...
         ~strcmp(outputTypeStr,'Gradient components') && ...
          strcmp(userDefinedThresholdStr, 'on')
      si(2).port = 2; si(2).txt = 'Th';
    else
      si(2).port = 1; si(2).txt = 'I';
    end
else
    if    strcmp(thresholdSourceStr, 'Input port') && ...
          strcmp(userDefinedThresholdStr, 'on')
      si(2).port = 2; si(2).txt = 'Th';
    else
      si(2).port = 1; si(2).txt = 'I';
    end
end    

if strcmp(methodStr,'Canny') || strcmp(outputTypeStr,'Binary image')
  [so(1:3).port] = deal(1,1,1);
  [so(1:3).txt]  = deal('Edge','Edge','Edge');
elseif strcmp(outputTypeStr,'Gradient components')
  [so(1:3).port] = deal(1,2,1);
  if strcmp(methodStr,'Roberts')
    [so(1:3).txt]  = deal('G45','G135','G45');
  else
    [so(1:3).txt]  = deal('Gv','Gh','Gv');      
  end
else % both
  [so(1:3).port] = deal(1,2,3);
  so(1).txt  = 'Edge';
  if strcmp(methodStr,'Roberts')    
    [so(2:3).txt]  = deal('G45','G135');
  else
    [so(2:3).txt]  = deal('Gv','Gh');
  end
end

% end of vipblkedge.m

