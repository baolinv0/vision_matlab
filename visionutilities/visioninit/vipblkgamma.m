function vipblkgamma
% VIPBLKGAMMA Mask dynamic dialog function for Gamma Correction block

% Copyright 1995-2004 The MathWorks, Inc.
%  $Revision $

blk = gcbh;
linearSegment_str = get_param(blk,'linearSegment');

% handle visibility options for the top/bottom hat filtering blocks
maskVis = get_param(blk,'MaskVisibilities');
oldMaskVis = maskVis;

% indices to the components on the mask
[operation_idx, gamma_idx, linearSegment_idx, breakPoint_idx] = deal(1,2,3,4);

% components which are always on
maskVis{operation_idx} = 'on';
maskVis{gamma_idx} = 'on';
maskVis{linearSegment_idx} = 'on';

% handle dynamic cases
if strcmp(linearSegment_str,'on')
  maskVis{breakPoint_idx} = 'on';
else
  maskVis{breakPoint_idx} = 'off';
end

% Change the mask if necessary
if (~isequal(maskVis, oldMaskVis))   
  set_param(blk, 'MaskVisibilities', maskVis);
end

