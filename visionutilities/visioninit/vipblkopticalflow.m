function [disp_str, si, so] = vipblkopticalflow(which2img, numInportsOrg)%numInports=>sigmaTorg
% VIPBLKOPTICALFLOW Video Processing Blockset Optical Flow mask helper function.
% Copyright 1995-2006 The MathWorks, Inc.
%  
numInports = numInportsOrg;
blkh = gcbh;
blk = gcb;
puMETHODstr      = get_param(blkh,'method');

isMethodHS = strncmpi(puMETHODstr, 'Horn ...',2) ;
isMethodLK = ~isMethodHS;
isGradMethodGaussDer = strncmpi(get_param(blk, 'gradMethod'), 'Derivative of Gaussian', 3);
isGradMethodTwoImageDiff = ~isGradMethodGaussDer;
useNthFrame = (which2img==2);

useSingleDelayBlkWithN   = (isMethodHS && useNthFrame) || ...
                      (isMethodLK && isGradMethodTwoImageDiff && useNthFrame);
useCascadedDelayBlk = (isMethodLK && isGradMethodGaussDer); 
outputCurrentImg=0;
if useCascadedDelayBlk
   outputCurrentImg = strcmp(get_param(blkh,'outputCurrentImage'), 'on');
end
% string
isBlkInLibrary = strcmp(get_param(bdroot(blkh),'BlockDiagramType'),'library');

if isBlkInLibrary
disp_str = 'Optical Flow';
else
if (isMethodHS)
   disp_str = 'Optical Flow\n(Horn-Schunck)'; 
else
   disp_str = 'Optical Flow\n(Lucas-Kanade)'; 
end
end 
puOUTVELFORM      = get_param(blkh,'outVelForm');
if strncmp(puOUTVELFORM,'Hori ..',2)
  so(1).port = 1;
  so(1).txt = 'V';
else
  so(1).port = 1;
  so(1).txt = '|V|^2';
end

if useSingleDelayBlkWithN || useCascadedDelayBlk % only one input port
    if (useCascadedDelayBlk && outputCurrentImg)
        txt = 'I(t)';
    else
        txt = 'I';
    end
 si(1).port = 1;
 si(1).txt = txt; 
 si(2).port = 1;
 si(2).txt = txt;
else % two input port
 si(1).port = 1;
 si(1).txt = 'I1'; 
 si(2).port = 2;
 si(2).txt = 'I2';
end
%% add/delete DELAY block if necessary
 
if (useCascadedDelayBlk)%isMethodLK && isGradMethodGaussDer
    if invalidNumInports(numInports)
        % don't set the invalid 'numInports' in lower_blk to get proper error message from S-fcn
        % locally set numInports=3, so that sub-system is created properly
        % Note that S-fcn will get the invalid numInports (not 3) and throw proper
        % error message
        numInports = 3;
    end
end
        
OFE_blk = [blk,'/Optical Flow Estimation'];

w = warning;
warning('off');

needToOrganizeCascadedDelayBlocks=0;
if useSingleDelayBlkWithN || useCascadedDelayBlk
    % delete in2 blocks and other lines
     if exist_block(blk, 'In2')%% second inpt port blk exists

         delete_line(blk,'In2/1','Optical Flow Estimation/2');
         delete_block([blk,'/In2']);
         if useCascadedDelayBlk
            needToOrganizeCascadedDelayBlocks=1;
         end         
         % if in2 exists, there must not be any delay blocks
     else
         if (useSingleDelayBlkWithN)
             if ~exist_block(blk, 'Delay')
                  % remove all delay blocks before rewiring
                  deleteAllDelayBlocksAndConnectedLines(blk);
             end
         else
             lower_blk = [blk,'/Optical Flow Estimation'];
             allPorts = get_param(lower_blk,'ports');
             numOldInPorts = allPorts(1);
             newNumInPorts = numInports;%getNumberOfInputPorts(sigmaT);
             if (numOldInPorts ~= newNumInPorts) || exist_block(blk, 'Delay') 
                 needToOrganizeCascadedDelayBlocks=1;
                 deleteAllDelayBlocksAndConnectedLines(blk);
             end
         end
     end
     
else %% uses two images from two inports
    if ~exist_block(blk, 'In2')
        % remove all delay blocks before rewiring
        deleteAllDelayBlocksAndConnectedLines(blk);
    end    
end

setParamInLowerOFEblock(blk, isMethodLK, numInports);

if useSingleDelayBlkWithN || useCascadedDelayBlk
    load_system('simulink');
    
    if (useSingleDelayBlkWithN)
        if ~exist_block(blk, 'Delay')
             add_block('simulink/Discrete/Delay',[blk,'/Delay'],'position',[125    72   165    98]);
             set_param([blk,'/Delay'], 'DelayLength', 'N');
             add_line(blk,'In1/1','Delay/1');
             add_line(blk,'Delay/1','Optical Flow Estimation/2');
             % reposition the lowerOFE and outport blocks
             set_param([blk,'/Optical Flow Estimation'], 'position', [195    31   365   104]);
             set_param([blk, '/Out'], 'position', [430    63   460    77]); 

        end
    else
        if needToOrganizeCascadedDelayBlocks
            %add the delay blocks (Delay1, Delay2, ...)
            
            numInPorts = numInports;%getNumberOfInputPorts(sigmaT);
            numDelayBlocksNeeded = numInPorts-1;
            prevBlk = 'In1';
            for i=1:numDelayBlocksNeeded
                 thisDelayBlk = ['Delay' num2str(i)];
                 offsetY = (i-1)*30;
                 offsetX = (i-1)*60;
                 add_block('simulink/Discrete/Delay',[blk,'/',thisDelayBlk],'position',[125+offsetX    72+offsetY   160+offsetX    92+offsetY]);
                 set_param([blk,'/',thisDelayBlk], 'DelayLength', '1');
                 add_line(blk,[prevBlk '/1'],[thisDelayBlk '/1']);
                 add_line(blk, [thisDelayBlk '/1'],['Optical Flow Estimation/' num2str(i+1)]);
                 prevBlk = thisDelayBlk;
            end
            lower_blk = [blk,'/Optical Flow Estimation'];
            set_param(lower_blk, 'position', [225+offsetX    34   360+offsetX    100+offsetY]);
            set_param([blk, '/Out'], 'position', [400+offsetX 64+offsetY/2 440+offsetX 90+offsetY/2]); 
        end
    end
else %% uses two images from two inports
    if ~exist_block(blk, 'In2')
        add_second_inport(blk);
        add_line(blk,'In2/1','Optical Flow Estimation/2');
        % reposition the lowerOFE and outport blocks
        set_param([blk,'/Optical Flow Estimation'], 'position', [195    31   365   104]);
        set_param([blk, '/Out'], 'position', [430    63   460    77]); 
    end  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output image corresponding to motion vectors (accounts for block delay)
if (useCascadedDelayBlk)
    outputCurrentImg = strcmp(get_param(blkh,'outputCurrentImage'), 'on');
    %if (needToOrganizeCascadedDelayBlocks) 
    if outputCurrentImg
        if ~exist_block(blk, 'OutImg') % last setup was LK_GaussDeriv method and outputCurrentImage was checked
             middleDlyBlkName = getMidDlyBlkNameFromInport(blk);
             pos = getOutImageBlkPosition(blk);
             add_block('built-in/Outport',[blk,'/OutImg'],'position', pos); 
             add_line(blk, [middleDlyBlkName '/1'],'OutImg/1','autorouting','on');
        end 
    else
         if exist_block(blk, 'OutImg') % last setup was LK_GaussDeriv method and outputCurrentImage was checked
             middleDlyBlkName = getMidDlyBlkNameFromInport(blk);
             delete_line(blk, [middleDlyBlkName '/1'], 'OutImg/1');
             delete_block([blk,'/' 'OutImg']);
         end        
    end
end

so(2).port = 1;
so(2).txt = so(1).txt;
if (useCascadedDelayBlk && outputCurrentImg)
     lower_blk = [blk,'/Optical Flow Estimation'];
     allPorts  = get_param(lower_blk,'ports');
     numInPorts = allPorts(1);

     
    so(2).port = 2;
    so(2).txt = ['I(t-' num2str((numInPorts-1)/2) ')'];
end

warning(w);
end

%%====================================================================
function pos = getOutImageBlkPosition(blk)

     lower_blk = [blk,'/Optical Flow Estimation'];
     pos  = get_param(lower_blk,'position');
     pos(1) = pos(3)+50;
     pos(2) = 72;
     pos(3) = pos(1)+ 40;
     pos(4) = pos(2)+20;
end

%%====================================================================
function middleDlyBlkName = getMidDlyBlkNameFromInport(blk)

     lower_blk = [blk,'/Optical Flow Estimation'];
     allPorts  = get_param(lower_blk,'ports');
     numInPorts = allPorts(1);
     middleDlyBlkName = ['Delay' num2str((numInPorts-1)/2)];
end

%%====================================================================
function setParamInLowerOFEblock(blk, isMethodLK, numInports)
    lower_blk = [blk,'/Optical Flow Estimation'];
    puORcbParams = {'method','gradMethod','which2img','outVelForm','stop_criteria', ...
                    'discardNormalFlow','outputCurrentImage', ...
                    'outputMode','accumMode','prodOutputMode','firstCoeffMode','memoryMode','roundingMode','overflowMode'};
    alreadyCalledSetParam = 0;
    for i=1:length(puORcbParams)
        BLKpuORcb = get_param(blk, puORcbParams{i});
        LBLKpuORcb = get_param(lower_blk, puORcbParams{i});
        if ~strcmp(BLKpuORcb,LBLKpuORcb)
            set_param(lower_blk, puORcbParams{i}, BLKpuORcb);
            alreadyCalledSetParam = 1;% here it computes numInports in S-function 
                                      % and recomputes number of input ports
        end
    end
    
    % explicitly set numInports in lower_blk ;
    
    isGradMethodGaussDer = strncmpi(get_param(blk, 'gradMethod'), 'Derivative of Gaussian', 3);
    if (~alreadyCalledSetParam && isMethodLK && isGradMethodGaussDer)
        %numInports = get_param(blk, 'numInports');
        if ~isempty(numInports)
           allPorts = get_param(lower_blk,'ports');
           numInPorts = allPorts(1);
           newNumInPorts = numInports;%getNumberOfInputPorts(sigmaT);
           if (numInPorts ~= newNumInPorts)
               set_param(lower_blk, 'numInports', 'numInports');
           end
        end  
    end    
end

%====================================================================
function deleteAllDelayBlocksAndConnectedLines(blk)
     % delete old delay blocks and other lines
     w = warning;
     warning('off');
     
     if exist_block(blk, 'Delay')
        delete_line(blk,'In1/1', 'Delay/1');
        delete_line(blk, 'Delay/1', 'Optical Flow Estimation/2');
        delete_block([blk,'/Delay']);
     else
         %delete lines to/from Delay1, Delay2,...; don't delete the Delay blocks
         %last set-up must be for LK_GaussDeriv method
         allDelayBlks = getAllDelayBlocks(blk);
         numDelayBlks = length(allDelayBlks);
         %step-1:
         %before deleting delay blocks delete OutImg block and connected line
         if exist_block(blk, 'OutImg') % last setup was LK_GaussDeriv method and outputCurrentImage was checked
             middleDlyBlkName = ['Delay' num2str(numDelayBlks/2)];
             delete_line(blk, [middleDlyBlkName '/1'], 'OutImg/1');
             delete_block([blk,'/' 'OutImg']);
         end
         %step-2:
         prevBlk = 'In1';
         for i=1:numDelayBlks
             thisDelayBlk = ['Delay' num2str(i)];
             delete_line(blk, [prevBlk '/1'], [thisDelayBlk '/1']);
             delete_line(blk, [thisDelayBlk '/1'], ['Optical Flow Estimation/' num2str(i+1)]);
             prevBlk = thisDelayBlk;             
         end
         
         % delte all delay blocks
         for i=1:numDelayBlks
           delete_block([blk,'/Delay', num2str(i)]);
         end
     end
     warning(w);
end

%====================================================================
function add_second_inport(blk) 
  add_block('built-in/Inport',[blk,'/In2'],'position',[25    78    55    92]);  
end

function allDelayBlks = getAllDelayBlocks(sys) 
    allDelayBlks = find_system(sys,'searchdepth',1,...
        'followlinks','on','lookundermasks','on', 'BlockType', 'Delay');  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function present = exist_block(sys, name)
    present = ~isempty(find_system(sys,'searchdepth',1,...
        'followlinks','on','lookundermasks','on','name',name));
end

%%==================================================================
function flag = invalidNumInports(numInports)
    % if numInports is invalid (length>1, or complex, or even numbered or fraction or <3 or >31) validateChange
    % function will throw error, and it will not call vipblkopticalflow.m
    % vipblkopticalflow doesn't throw error if numInports is an undefined
    % variable; we need to catch that case here;
    % numInports is passed as double
%    flag = isempty(numInports);% numInports is an undefined variable
    flag=0;
    if isempty(numInports)   || ...
       length(numInports) >1 || ...
       (~isreal(numInports)) || ... 
       (numInports ~= floor(numInports)) || ... 
       (mod(numInports,2) ~= 1) || ...
       (numInports < 3 || numInports >31) || ...
       (isnan(numInports))
          
         flag=1;
    end
end

% [EOF] vipblkopticalflow.m
