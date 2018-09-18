function vipblklabel
% VIPBLKLABEL Mask dynamic dialog function for Label block

% Copyright 1995-2003 The MathWorks, Inc.
%  $Revision $

blk = gcbh;

outType_str = get_param(blk,'outType');

% handle visibility options for the erode/dilate block
maskVis = get_param(blk,'MaskVisibilities');
oldMaskVis = maskVis;

% indices to the components on the mask
[conn_idx,output_idx,outType_idx,lastLabel_idx] = deal(1,2,3,4);
% components which are always on
maskVis{conn_idx} = 'on';
maskVis{output_idx} = 'on';
maskVis{outType_idx} = 'on';

% handle dynamic cases
if strncmp(outType_str,'Autom',5) || strcmp(outType_str,'uint32')
  maskVis{lastLabel_idx} = 'off';
else
  maskVis{lastLabel_idx} = 'on';
end

% Change the mask if necessary
if (~isequal(maskVis, oldMaskVis))
  set_param(blk, 'MaskVisibilities', maskVis);
end

% end of vipblklabel.m