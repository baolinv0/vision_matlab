function varargout = vipblkblockmatch(action, which2img)
% VIPBLKOPTICALFLOW Video Processing Blockset Block Matching mask helper function.
% Copyright 1995-2006 The MathWorks, Inc.
%  
%if nargin==0, action = 'dynamic'; end

blkh = gcbh;
blk = gcb;
disp_str='';
si=[];
so=[];
dtInfo = [];
switch action
case 'icon'
  isBlkInLibrary = strcmp(get_param(bdroot(blkh),'BlockDiagramType'),'library');
  
  disp_str = sprintf('Block\nMatching');

  puOUTVELFORM      = get_param(blkh,'outVelForm');
  if strncmp(puOUTVELFORM,'Hori ..',2)
      so(1).port = 1;
      so(1).txt = 'V';
  else
      so(1).port = 1;
      so(1).txt = '|V|^2';
  end
  useDelayBlk = (which2img==2);
  if useDelayBlk % only one input port
     si(1).port = 1;
     si(1).txt = 'I'; 
     si(2).port = 1;
     si(2).txt = 'I';
  else % two input port
     si(1).port = 1;
     si(1).txt = 'I1'; 
     si(2).port = 2;
     si(2).txt = 'I2';
  end
  
  varargout(1) = {disp_str};  
  varargout(2) = {si};  
  varargout(3) = {so};  
  
  %% change the subsystem if necessary
  OFE_blk = [blk,'/block match'];
  if useDelayBlk 
     if exist_block(blk, 'In2')%% second inpt port blk exists
         w = warning;
         warning('off');
         
         delete_line_frmOFE_2ndinport_to2ndInPort(blk);
         delete_second_inport(blk);
         add_delay_block(blk);
         set_param([blk,'/Delay'], 'DelayLength', 'N');
         add_line_frm_1stInport_to_dlyInport(blk);
         add_line_frm_dlyOutport_to_OFE_2ndInport(blk); 
         warning(w);
     end
  else
     if exist_block(blk, 'Delay')% delay block exists
         w = warning;
         warning('off');

         delete_line_frm_1stInport_to_DlyInPort(blk);
         delete_line_frm_dlyOutport_to_OFE_2ndInport(blk);
         delete_delay_block(blk);
         add_second_inport(blk);
         add_line_frmOFE_2ndinport_to2ndInPort(blk);

         warning(w);
     end
  end
case 'init'
    % output = varargout = {dtInfo}
    % num = misc(1)
        % output H (2)
        % accum(4)
        % prodOutput(8)
    lower_blk = [blk,'/block match'];
    puORcbParams = {'searchMethod','matchCriteria','outVelForm','outputMode','accumMode','prodOutputMode','roundingMode','overflowMode'};
    for i=1:length(puORcbParams)
        BLKpuORcb = get_param(blk, puORcbParams{i});
        LBLKpuORcb = get_param(lower_blk, puORcbParams{i});
        if ~strcmp(BLKpuORcb,LBLKpuORcb)
            set_param(lower_blk, puORcbParams{i}, BLKpuORcb);
        end
    end 
    
    
end % end of switch statement

function delete_line_frmOFE_2ndinport_to2ndInPort(blk)
  delete_line(blk,'In2/1','block match/2');
 
function delete_second_inport(blk)  
  SecondPort_blk = [blk,'/In2'];
  delete_block(SecondPort_blk);
    
function add_delay_block(blk)
  load_system('simulink');
  add_block('simulink/Discrete/Delay',[blk,'/Delay'],'position',[125    72   165    98]);

function add_line_frm_1stInport_to_dlyInport(blk)
  add_line(blk,'In1/1','Delay/1');

function add_line_frm_dlyOutport_to_OFE_2ndInport(blk)
  add_line(blk,'Delay/1','block match/2');

function delete_line_frm_1stInport_to_DlyInPort(blk) 
  delete_line(blk,'In1/1','Delay/1');

function delete_line_frm_dlyOutport_to_OFE_2ndInport(blk) 
  delete_line(blk,'Delay/1','block match/2');

function delete_delay_block(blk) 
  delete_block([blk,'/Delay']);
  
function add_second_inport(blk) 
  add_block('built-in/Inport',[blk,'/In2'],'position',[25    78    55    92]);
  
function add_line_frmOFE_2ndinport_to2ndInPort(blk) 
  add_line(blk,'In2/1','block match/2');
         
         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function present = exist_block(sys, name)
    present = ~isempty(find_system(sys,'searchdepth',1,...
        'followlinks','on','lookundermasks','on','name',name));

