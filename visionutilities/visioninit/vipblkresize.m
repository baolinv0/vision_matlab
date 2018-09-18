function varargout = vipblkresize(action)
% DSPBLKRESIZE Video Processing Blockset resize block helper function.

% Copyright 1995-2006 The MathWorks, Inc.

if nargin==0, action = 'dynamic'; end
blk = gcbh;
useROIChecked = strcmp(get_param(blk,'useROI'),'on');
useAntialias  = strcmp(get_param(blk,'antialias'),'on');
mode = get_param(blk, 'specify');
interpMethod = get_param(blk, 'interp_method');
isRoiEnabled = (strcmp(mode,'Number of output rows and columns') ...
    && (strcmp(interpMethod,'Nearest neighbor') ...
        || strcmp(interpMethod,'Bilinear') ...
        || strcmp(interpMethod,'Bicubic')) ...
    && (~useAntialias) && useROIChecked);


switch action
 case 'init'
  varargout = {dspGetFixptDataTypeInfo(blk,47)};
  
 case 'icon'
  % Port labels
  if isRoiEnabled
      s.i1 = 1; s.i1s = 'Image'; 
      s.i2 = 2; s.i2s = 'ROI';
      roiFlagExists = strcmp(get_param(blk,'roiFlag'),'on');
      if (roiFlagExists)
        s.o1 = 1; s.o1s = 'Out';
        s.o2 = 2; s.o2s = 'Flag';          
      else
        s.o1 = 1; s.o1s = '';
        s.o2 = 1; s.o2s = '';          
      end
  else
    s.i1 = 1; s.i1s = '';
    s.i2 = 1; s.i2s = '';
    s.o1 = 1; s.o1s = '';
    s.o2 = 1; s.o2s = '';
  end
  varargout = {s};
  
 otherwise
  error(message('vision:internal:unhandledCase'));
end
