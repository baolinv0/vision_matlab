function vipblkhatfilter(varargin)
% VIPBLKHATFILTER Mask dynamic dialog function for Top-hat/Bottom-hat 
%                 subsystem based blocks
%

% Copyright 1995-2006 The MathWorks, Inc.
%  $Revision $

blk = gcbh;
imgtype_str  = get_param(blk,'imgtype');
nhoodsrc_str = get_param(blk,'nhoodsrc');

if nargin == 0 % handle mask visibilities
  % handle visibility options for the top/bottom hat filtering blocks
  maskVis = get_param(blk,'MaskVisibilities');
  oldMaskVis = maskVis;
  
  % indices to the components on the mask
  [imgtype_idx nhoodsrc_idx,nhood_idx] = deal(1,2,3);   %#ok
  % components which are always on
  maskVis{nhoodsrc_idx} = 'on';
  
  % handle dynamic cases
  if strncmp(nhoodsrc_str,'Input',5)
    maskVis{nhood_idx} = 'off';
  else
    maskVis{nhood_idx} = 'on';
  end
  
  % Change the mask if necessary
  if (~isequal(maskVis, oldMaskVis))   
    set_param(blk, 'MaskVisibilities', maskVis);
  end

elseif strcmp(varargin{1}, 'init')  % handle subsystem re-organization
  
  blkname = get(blk,'MaskType');
  csys    = gcb; % get full path to the block
    
  morph_blk = [];
  if strcmp(blkname, 'Top-hat')
    morph_blk  = 'Opening';
    sum_inputs = '|-+';        % type of operation for the Sum block
    not_pos = [355 34 385 66]; % position of the NOT block
    istophat = true;
  elseif strcmp(blkname, 'Bottom-hat')
    morph_blk  = 'Closing';
    sum_inputs = '|+-';
    not_pos = [360 119 390 151];
    istophat = false;
  end
  
  % If necessary, grow a port for neighborhood
  if strncmp(nhoodsrc_str,'Input',5)
    if ~isblk_present('In 2')
      set_param([csys '/' morph_blk],'nhoodsrc','Input');
      second_inport_pos = [145 68 175 82];
      add_block('built-in/Inport', [csys '/In 2'], 'Position',...
                second_inport_pos);    
      add_line(csys, 'In 2/1', [morph_blk '/2'],'autorouting','on');
    end
  else
    if isblk_present('In 2')
      delete_line(csys, 'In 2/1', [morph_blk '/2']);
      set_param([csys '/' morph_blk],'nhoodsrc','Specify via');
      delete_block([csys '/In 2']);
    end
  end
  
  % Handle changes to input image type
  if strncmp(imgtype_str,'Inte',4)
    if ~isblk_present('Subtract') % already must be in binary mode
      % remove setup for binary input
      if istophat
        delete_line(csys, [morph_blk '/1'], 'Not/1');
        delete_line(csys, 'Not/1', 'And/1');
        delete_line(csys, 'In 1/1', 'And/2');
      else % bottom hat
        delete_line(csys, [morph_blk '/1'], 'And/1');
        delete_line(csys, 'Not/1', 'And/2');
        delete_line(csys, 'In 1/1', 'Not/1');    
      end
      delete_line(csys, 'And/1', 'Frame Conversion/1');  
      delete_block([csys '/Not']);
      delete_block([csys '/And']);
      
      % add blocks and lines for intensity input
      subtract_pos = [440 45 470 75];
      add_block('built-in/Sum', [csys '/Subtract'],'IconShape','round',...
                'Inputs',sum_inputs,...
                'Position',subtract_pos,...
                'NamePlacement','alternate');
      add_line(csys, 'In 1/1', 'Subtract/2','autorouting','on');
      add_line(csys, [morph_blk '/1'], 'Subtract/1','autorouting','on');
      add_line(csys, 'Subtract/1', 'Frame Conversion/1','autorouting','on');
    end
  else
    if ~isblk_present('And') % already must be in intensity mode
      % remove setup for intensity input
      delete_line(csys, 'In 1/1', 'Subtract/2');
      delete_line(csys, [morph_blk '/1'], 'Subtract/1');
      delete_line(csys, 'Subtract/1', 'Frame Conversion/1');
      delete_block([csys '/Subtract']);
      
      % add blocks and lines for binary input
      add_block('built-in/Logic', [csys '/Not'],...
                'Position',not_pos,...
                'Operator','NOT');
      and_pos = [440 42 470 73];
      add_block('built-in/Logic', [csys '/And'],...
                'Position',and_pos,...       
                'Operator','AND');
      
      if istophat % approprietly connect AND and NOT block depending on
                  % the filter type
        add_line(csys, [morph_blk '/1'], 'Not/1','autorouting','on');
        add_line(csys, 'Not/1', 'And/1','autorouting','on');
        add_line(csys, 'In 1/1', 'And/2','autorouting','on');    
      else
        add_line(csys, [morph_blk '/1'], 'And/1','autorouting','on');
        add_line(csys, 'Not/1', 'And/2','autorouting','on');
        add_line(csys, 'In 1/1', 'Not/1','autorouting','on');    
      end      
      add_line(csys, 'And/1', 'Frame Conversion/1','autorouting','on');        
    end
  end
else
  error(message('vision:vipblkhatfilter:invalidInput'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% checks if the block is present in the model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function res = isblk_present(blk)

res = ~isempty(find_system(gcb,'FollowLinks','on',...
                           'LookUnderMasks','all','Name',blk));
