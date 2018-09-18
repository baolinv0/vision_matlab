function so = vipblkboundarytracing(action)
% VIPBLKBOUNDARYTRACING Video Processing Blockset block for 
% boundary tracing block

% Copyright 1995-2005 The MathWorks, Inc.
%  

blkh = gcbh;
if nargin==0, action = 'dynamic'; end % only from visionanalysis
isVisionLibBlk = strcmp(action, 'icon2') || strcmp(action, 'dynamic2');
switch action
case {'icon', 'icon2'}
  so(1).port = 1;
  so(1).txt = 'Pts'; 
  
  % string
  cbOUTPUTNUMstr       = get_param(blkh,'outputNum');     % a member of ALWAYS_ON_ITEMS
  if isVisionLibBlk, cbOUTPUTNUMstr = 'off'; end % no count output port
  if (strcmp(cbOUTPUTNUMstr, 'on'))
      so(2).port = 2;
      so(2).txt = 'Count'; 
  else
      so(2).port = 1;
      so(2).txt = 'Pts';
  end     
case {'dynamic', 'dynamic2'}
    % Execute dynamic dialogs
    %---------------------------------------------------------------------------
    % STEP-1: snap current states of mask items
    mask_visibles     = get_param(blkh, 'MaskVisibilities');
    old_mask_visibles = mask_visibles;
    mask_enables      = get_param(blkh, 'MaskEnables');
    old_mask_enables  = mask_enables;
    [puCONN,puSEARCHDIR4,puSEARCHDIR8,puDIR,ebMAXNUMPIX,cbOUTPUTNUM,...
     puFILLCHOICES,ebFILLVAL] = deal(1,2,3,4,5,6,7,8);
    %---------------------------------------------------------------------------
    % STEP-2:
    if (isVisionLibBlk)
        ALWAYS_ON_ITEMS = [puCONN puDIR ebMAXNUMPIX];
    else
        ALWAYS_ON_ITEMS = [puCONN puDIR ebMAXNUMPIX  cbOUTPUTNUM puFILLCHOICES];
    end
    mask_enables(ALWAYS_ON_ITEMS) = {'on'}; mask_enables(ALWAYS_ON_ITEMS) = {'on'}; 

    %---------------------------------------------------------------------------
    % STEP-3:
    % pop-ups/checkbox those control dynamics of other items (these might be
    % controlled by others) 
    %%CONTROLLED_ITEMS = [ebXDIST,ebYDIST];
    puCONNstr    = get_param(blkh,'conn');    % a member of ALWAYS_ON_ITEMS
    if strcmp(puCONNstr,'4'), %% 4 connectivity
      mask_visibles(puSEARCHDIR4)  = {'on'};  mask_enables(puSEARCHDIR4)   = {'on'};     
      mask_visibles(puSEARCHDIR8)  = {'off'};  mask_enables(puSEARCHDIR8)   = {'off'};
    else  %% 8 connectivity
      mask_visibles(puSEARCHDIR4)  = {'off'};  mask_enables(puSEARCHDIR4)   = {'off'};     
      mask_visibles(puSEARCHDIR8)  = {'on'};  mask_enables(puSEARCHDIR8)   = {'on'};
    end 

    if (isVisionLibBlk)
        ALWAYS_OFF_ITEMS = [cbOUTPUTNUM puFILLCHOICES];
        mask_enables(ALWAYS_OFF_ITEMS) = {'on'}; mask_enables(ALWAYS_ON_ITEMS) = {'on'}; 
    else
        cbFILLCHOICESstr    = get_param(blkh,'fillChoices');    % a member of ALWAYS_ON_ITEMS
        if (strcmp(cbFILLCHOICESstr,'None') || strcmp(cbFILLCHOICESstr,'Fill with last point found') ),
          mask_visibles(ebFILLVAL)  = {'off'};  mask_enables(ebFILLVAL)   = {'off'};     
        else  %% Fill with user-defined values
          mask_visibles(ebFILLVAL)  = {'on'};  mask_enables(ebFILLVAL)   = {'on'};     
        end 
    end
    %---------------------------------------------------------------------------
    % STEP-4:
    if (~isequal(mask_visibles, old_mask_visibles))
      set_param(blkh, 'MaskVisibilities', mask_visibles);
    end
    if (~isequal(mask_enables, old_mask_enables))
      set_param(blkh, 'MaskEnables', mask_enables);
    end
end
% [EOF] vipblkboundarytracing.m

