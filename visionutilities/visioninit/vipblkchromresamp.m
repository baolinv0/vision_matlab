function [si, so, blkname] = vipblkchromresamp(action)
% VIPBLKCHROMRESAMP Mask dynamic dialog function for Chrominance Resampling
% block

% Copyright 1995-2006 The MathWorks, Inc.
%  $Revision $

if nargin==0, action = 'dynamic'; end

blk = gcbh;   % Cache handle to block

% get elements of the mask that affect dynamic elements
resampling   = get_param(blk,'resampling');
antialiasing = get_param(blk,'antialiasing');

% define the name that will appear on the mask
isBlkInLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
if isBlkInLibrary
  blkname = 'Chroma\nResampling';
else
  new_string = sprintf(' to\n');
  blkname = strrep(resampling,' to ',new_string);
  new_string = sprintf('\n(');
  blkname = strrep(blkname,' (',new_string);
end
  
switch action
 case 'init'
  % name input and output ports
  [si(1:2).port] = deal(1,2);
  [si(1:2).txt]  = deal('Cb','Cr');
  % name output ports
  [so(1:2).port] = deal(1,2);
  [so(1:2).txt]  = deal('Cb','Cr');
 case 'dynamic'
  % handle visibility options for the edge detector
  maskVis = get_param(blk,'MaskVisibilities');
  oldMaskVis = maskVis;

  % indices to the components on the mask
  [resampling_idx,interpolation_idx,antialiasing_idx,hcoeff_idx,...
   vcoeff_idx] = deal(1,2,3,4,5);
  % components which are always on
  maskVis{resampling_idx} = 'on';
  
  % handle dynamic cases
  if strncmp(resampling,'4:4:4',5) || ...
        strncmp(resampling,'4:2:2 to 4:2:0',14)
    maskVis{interpolation_idx} = 'off';
    maskVis{antialiasing_idx}  = 'on';
    if strcmp(antialiasing,'User-defined')
      if strncmp(resampling,'4:4:4 to 4:2:0',14)            
        maskVis{hcoeff_idx} = 'on';
        maskVis{vcoeff_idx} = 'on';
      elseif strncmp(resampling,'4:2:2 to 4:2:0',14)
        maskVis{hcoeff_idx} = 'off';
        maskVis{vcoeff_idx} = 'on';          
      else
        maskVis{hcoeff_idx} = 'on';
        maskVis{vcoeff_idx} = 'off';
      end
    else
      maskVis{hcoeff_idx} = 'off';
      maskVis{vcoeff_idx} = 'off';
    end
  else
    maskVis{interpolation_idx} = 'on';
    maskVis{antialiasing_idx}  = 'off';    
    maskVis{hcoeff_idx} = 'off';
    maskVis{vcoeff_idx} = 'off';
  end
  
  % Change the mask if necessary
  if (~isequal(maskVis, oldMaskVis))
    set_param(blk, 'MaskVisibilities', maskVis);
  end
  
 otherwise
  error(message('vision:internal:unhandledCase'));
end

