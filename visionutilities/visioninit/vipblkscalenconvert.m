function blkname = vipblkscalenconvert(action) 
% VIPBLKSCALENCONVERT Video Processing Blockset block for image data type conversion.
% Copyright 1995-2005 The MathWorks, Inc.
%  

blkh = gcbh;

if (nargin>=1)
    blkname='';
    isBlkInLibrary = strcmp(get_param(bdroot(blkh),'BlockDiagramType'),'library');
    if isBlkInLibrary
        blkname = 'Convert Image';
    else
        outDTname = get_param(blkh,'outDT');
        TO = 'to';
        switch outDTname
            case {'double','single','int8','uint8','int16','uint16','boolean'}
                blkname = outDTname;
            case 'Fixed-point'
                WL= double(slResolve(get_param(blkh,'wordLen'),blkh,'expression'));
                FL= double(slResolve(get_param(blkh,'numFracBits'),blkh,'expression'));
                if (isempty(WL) || isempty(FL) || WL<2 || WL>16 || ...
                    abs(FL)>999 || floor(WL) ~= WL || floor(FL) ~= FL)
                    blkname = 'Fixed-point';
                else
                   isSigned = strcmp(get_param(blkh,'isSigned'),'on');
                   blkname = getDTname(WL,FL,isSigned);
                end
            case 'Inherit via back propagation'
                TO='';
                blkname = 'via back prop';
        end
        blkname = sprintf('Convert Image\n%s %s',TO,blkname);
    end
else
  % Execute dynamic dialogs
  %---------------------------------------------------------------------------
  % STEP-1: snap current states of mask items
  mask_visibles     = get_param(blkh, 'MaskVisibilities');
  old_mask_visibles = mask_visibles;
  mask_enables      = get_param(blkh, 'MaskEnables');
  old_mask_enables  = mask_enables;
  [puOUTDT,cbISSIGNED,ebWORDLEN,ebNUMFRACBITS] = deal(1,2,3,4);
 %---------------------------------------------------------------------------
  % STEP-2:
  ALWAYS_ON_ITEMS = [puOUTDT];
  mask_enables(ALWAYS_ON_ITEMS) = {'on'}; mask_enables(ALWAYS_ON_ITEMS) = {'on'}; 

  %---------------------------------------------------------------------------
  % STEP-3:
  % pop-ups/checkbox those control dynamics of other items (these might be
  % controlled by others) 
  CONTROLLED_ITEMS = [cbISSIGNED,ebWORDLEN,ebNUMFRACBITS];
  puOUTDTstr    = get_param(blkh,'outDT');    % a member of ALWAYS_ON_ITEMS
 
  %%%
  if strncmp(puOUTDTstr, 'Fixed ...',1),
      mask_visibles(CONTROLLED_ITEMS)  = {'on'};  mask_enables(CONTROLLED_ITEMS)   = {'on'};     
  else % unbounded
      mask_visibles(CONTROLLED_ITEMS)  = {'off'};  mask_enables(CONTROLLED_ITEMS)   = {'off'};
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

%%=========================================================================
function  DTname = getDTname(WL,FL,isSigned)   

if (FL==0)
    if (WL==8 || WL==16)
        if isSigned, pref = ''; else pref = 'u'; end;
        DTname = [pref 'int' num2str(WL)];
    else
        if isSigned, pref = 's'; else pref = 'u'; end;
        DTname = [pref 'fix' num2str(WL)];
    end
else
   if isSigned, pref = 's'; else pref = 'u'; end;
   if (FL>0), EnorE = 'En'; else EnorE = 'E'; end; 
   DTname = [pref 'fix' num2str(WL) '_' EnorE num2str(abs(FL))];
end

% [EOF] vipblkscalenconvert.m

