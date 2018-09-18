function [si, so, blkname] = vipblkcolorconv(varargin)
% VIPBLKCOLORCONV Mask dynamic dialog function for the Color Space Conversion
% block

% Copyright 1995-2005 The MathWorks, Inc.
%  $Revision $

blk = gcbh;   % Cache handle to block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Backward compatibility:
% Before 2007a, this block only supports separate RGB ports.
% From 2007a, this block supports one N-D port or separate RGB ports and
% the default is N-D. To be compatible with old models, parameter
% conversionActive is introduced. This parameter has the values of 
% the parameter conversion.  The parameter conversion has a new (default) value 
% of 'Obsolete', and is invisible.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~strcmp(get_param(blk,'tag'),'vipblks_tmp_nd_forward_compat')
    if ~strcmp(get_param(blk,'conversion'),'Obsolete')
        set_param(blk, 'imagePorts', 'Separate color signals');
        set_param(blk, 'conversionActive', get_param(blk, 'conversion'));
        set_param(blk, 'conversion', 'Obsolete');
    end
end

conversion = get_param(blk,'conversionActive');
rec        = get_param(blk,'rec');

if nargin == 0 % handle mask visibilities
  
  maskVis = get_param(blk,'MaskVisibilities');
  oldMaskVis = maskVis;
  
  % indices to the components on the mask
  [conversion_idx,conversionActive_idx,wp_idx,rec_idx,sys_idx,imagePorts_idx] = deal(1,2,3,4,5,6);
  
  % Parameter conversion_idx is used for backward compatibility
  % It is invisible.
  maskVis{conversion_idx} = 'off';
  
  % components which are always on
  maskVis{conversionActive_idx} = 'on';
  maskVis{imagePorts_idx} = 'on';
  
  % handle dynamic cases
  if strfind(conversion,'L*a*b*')
    maskVis{wp_idx} = 'on';
  else
    maskVis{wp_idx} = 'off';
  end

  if strfind(conversion,'Y''CbCr')
    maskVis{rec_idx} = 'on';
    if strfind(rec,'709')
      maskVis{sys_idx} = 'on';
    else
      maskVis{sys_idx} = 'off';
    end    
  else
    maskVis{rec_idx} = 'off';
    maskVis{sys_idx} = 'off';
  end

  % Change the mask if necessary
  if (~isequal(maskVis, oldMaskVis))
    set_param(blk, 'MaskVisibilities', maskVis);
  end
  
else % 'icon'
  
  % define the name that will appear on the mask
  isND = strcmp(get_param(blk,'imagePorts'), 'One multidimensional signal');
  isBlkInLibrary = strcmp(get_param(bdroot(blk),'BlockDiagramType'),'library');
  if isBlkInLibrary
    blkname = 'Color Space\n Conversion';
    [si(1:3).txt]  = deal('','','');
    [so(1:3).txt]  = deal('','','');
    
    if isND % One multidimensional signal
      [si(1:3).port] = deal(1,1,1);
      [so(1:3).port] = deal(1,1,1);
    else
      [si(1:3).port] = deal(1,2,3);
      [so(1:3).port] = deal(1,2,3);
    end
    
  else
    new_string = sprintf(' to\n');
    blkname = strrep(conversion,' to ',new_string);
    
    if isND % One multidimensional signal
      [si(1:3).port] = deal(1,1,1);
      [si(1:3).txt]  = deal('','','');
    
      [so(1:3).port] = deal(1,1,1);
      [so(1:3).txt]  = deal('','','');
      
    else    % Separate color signals
      % name input and output ports
      switch conversion
       case 'R''G''B'' to Y''CbCr'
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('R''','G''','B''');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('Y''','Cb','Cr');
       case 'R''G''B'' to intensity'
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('R''','G''','B''');
        [so(1:3).port] = deal(1,1,1);
        [so(1:3).txt]  = deal('I''');
       case 'Y''CbCr to R''G''B'''
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('Y''','Cb','Cr');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('R''','G''','B''');
       case 'HSV to R''G''B'''
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('H','S','V');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('R''','G''','B''');
       case 'R''G''B'' to HSV'
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('R''','G''','B''');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('H','S','V');
       case 'XYZ to sR''G''B'''
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('X','Y','Z');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('R''','G''','B''');    
       case 'sR''G''B'' to XYZ'
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('R''','G''','B''');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('X','Y','Z');
       case 'L*a*b* to sR''G''B'''
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('L*','a*','b*');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('R''','G''','B''');    
       case 'sR''G''B'' to L*a*b*'
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('R''','G''','B''');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('L*','a*','b*');
       otherwise
        [si(1:3).port] = deal(1,2,3);
        [si(1:3).txt]  = deal('E1','E2','E3');
        [so(1:3).port] = deal(1,2,3);
        [so(1:3).txt]  = deal('E1','E2','E3');
      end
    end
    
  end
end

% end of vipblkcolorconv.m
