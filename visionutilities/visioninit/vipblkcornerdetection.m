function [outport] = vipblkcornerdetection(varargin)
% vipblkcornerdetection Mask dynamic dialog function for the Corner
% Detection block

% Copyright 2007 The MathWorks, Inc.

% Input arguments:
% blkh, output, outputInUse, isOutVarDim

blkh = varargin{1};
sys = [get(blkh, 'path'), '/', get(blkh, 'name')];
metric_blk = [sys, '/', 'Corner Metric'];
find_blk = [sys, '/', 'Find Local Maxima'];

% New configuration
if varargin{2} == 4  % 'Obsolete9b'
    outputNew = varargin{3};
    isR2009bOrLater = true;
else
    outputNew = varargin{2};
    isR2009bOrLater = false;
end

% Blocks and lines related to output "Location" option.
if isR2009bOrLater
    isOutVarDimNew = varargin{4};
else
    isOutVarDimNew = false;
end
    
if isOutVarDimNew
    isOutVarDimVal = 'on';
else
    isOutVarDimVal = 'off';
end

% Old configuration
locationOld = exist_block(sys, 'Find Local Maxima');
metricOld   = exist_block(sys, 'Metric');
countOld    = exist_block(sys, 'Count');

libname = strtok(get_param(blkh,'ReferenceBlock'), '/');

if strncmp('vip',libname,3)
    statslib = 'vipstatistics';
else
    statslib = 'visionstatistics'; % use new lib /w new coordinate system
end

% Blocks and lines to add
locationBlock{1} = {statslib, 'Find Local Maxima', ...
    'Find Local Maxima',  '[280 39 395 121]', ...
    'num_peaks', 'maxNum', ...
    'nhood_size', 'neighborSize', ...
    'src_thresh','Obsolete9b', ...
    'src_thresh_inuse', 'Specify via dialog', ...
    'threshold', 'thrMetric', ...
    'inputIsHough', 'off', ...
    'dt_peak', 'uint32', ...
    'dt_count', 'uint32', ...
    'isOutVarDim', isOutVarDimVal};
locationLine{1}  = {'Corner Metric/1', 'Find Local Maxima/1'};

locationBlock{2} = {'built-in', 'Outport', 'Location', '[440 53 470 67]'};
locationLine{2}  = {'Find Local Maxima/1', 'Location/1'};

% Block and line related to "Count" output
countBlock{1}   = {'built-in', 'Outport', 'Count', '[440 93 470 107]'};
countLine{1}    = {'Find Local Maxima/2', 'Count/1'};

% Block and line related to output "Metric" option.
metricBlock{1}   = {'built-in', 'Outport', 'Metric', '[440 138 470 152]'};
metricLine{1}    = {'Corner Metric/1', 'Metric/1'};

% Copy the value for non-edit-box parameters from the main block to the sub
% block, so as to activate fixed-point auto scaling.
params = {'method', 'thrAngle', 'output', 'outputInUse', 'outputMode', ...
    'accumMode', 'prodOutputMode', 'memoryMode', 'firstCoeffMode', ...
    'roundingMode', 'overflowMode', 'LockScale'};

for idx = 1: length(params)
    main_value = get_param(sys, params{idx});
    sub_value  = get_param(metric_blk,  params{idx});
    if ~strcmp(main_value, sub_value)
        set_param(metric_blk, params{idx}, main_value);
    end
end 

% Determine the port labels according to the new parameters.
idx = 1;
portNum = 1;
if outputNew == 1
    outport(idx).port = portNum;
    outport(idx).txt = 'Loc';
    idx = idx + 1;
    if isOutVarDimNew
        outport(idx).port = portNum;
        outport(idx).txt = '';
    else
        portNum = portNum + 1;
        outport(idx).port = portNum;
        outport(idx).txt = 'Count';
    end
    idx = idx + 1;
    outport(idx).port = portNum;
    outport(idx).txt = '';
elseif outputNew == 2
    outport(idx).port = portNum;
    outport(idx).txt = 'Loc';
    idx = idx + 1;
    if isOutVarDimNew
        outport(idx).port = portNum;
        outport(idx).txt = '';
    else
        portNum = portNum + 1;
        outport(idx).port = portNum;
        outport(idx).txt = 'Count';
    end
    idx = idx + 1;
    portNum = portNum + 1;
    outport(idx).port = portNum;
    outport(idx).txt = 'Metric';
else % outputNew == 3
    outport(1).port = 1;
    outport(1).txt = '';
    outport(2).port = 1;
    outport(2).txt = '';
    outport(3).port = 1;
    outport(3).txt = 'Metric';
end

% New configuration
switch outputNew
    case 1
        locationNew = true;
        metricNew   = false;
    case 2
        locationNew = true;
        metricNew   = true;
    case 3
        locationNew = false;
        metricNew   = true;
end

if (isOutVarDimNew || ~locationNew)
    countNew = false;    
else
    countNew = true;
end

% Edit the block if the new and old configurations are different.
if locationNew ~= locationOld || metricNew ~= metricOld || countNew ~= countOld
    w = warning;
    warning('off', 'Simulink:Masking:DispInvalidExpr');
    if locationNew ~= locationOld
        if locationNew
            editSubSystem(sys, locationBlock, locationLine, 'add');
            if countNew
                editSubSystem(sys, countBlock, countLine, 'add');
            end
        else   
            if ~countNew
                editSubSystem(sys, countBlock, countLine, 'delete');
            end
            editSubSystem(sys, locationBlock, locationLine, 'delete');
        end
    elseif countNew ~= countOld
        if locationNew
            if countNew
                set_param(find_blk, 'isOutVarDim', isOutVarDimVal);
                editSubSystem(sys, countBlock, countLine, 'add');
            else
                editSubSystem(sys, countBlock, countLine, 'delete');
                set_param(find_blk, 'isOutVarDim', isOutVarDimVal);                
            end
        end
    end
    
    if metricNew ~= metricOld
        if metricNew
            editSubSystem(sys, metricBlock, metricLine, 'add');
        else
            editSubSystem(sys, metricBlock, metricLine, 'delete');
        end
        
    end

	% Reset port numbers
    portNum = 1;
    if locationNew
        set_param([sys, '/Location'], 'Port', num2str(portNum));
        if countNew
            portNum = portNum + 1;
            set_param([sys, '/Count'], 'Port', num2str(portNum));
        end
        if metricNew
            portNum = portNum + 1;
            set_param([sys, '/Metric'], 'Port', num2str(portNum));
        end
    else
        set_param([sys, '/Metric'], 'Port', num2str(portNum));
    end

    warning(w);
end

end

%===============================================================================
% Edit a blocks and lines
function errmsg = editSubSystem(sys, blocks, lines, action)
    errmsg = ''; %#ok<NASGU>
    try
        if strcmpi(action, 'add')
            % Add blocks before add lines
            errmsg = editBlock(action, sys, blocks);
            if ~isempty(errmsg) 
                rethrow(errmsg); 
            end
            errmsg = editLine(action, sys, lines);
        else
            % Delete lines before delete block
            errmsg = editLine(action, sys, lines);
            if ~isempty(errmsg) 
                rethrow(errmsg); 
            end
            errmsg = editBlock(action, sys, blocks);
        end
    catch editSubSystemException
        errmsg = editSubSystemException.message;
    end
end

%=============================================================================== 
% Add or delete lines
function errmsg = editLine(action, sys, lines)
    errmsg = '';
    try
        for ind = 1: length(lines)
            if strcmpi(action, 'add')
                add_line(sys, lines{ind}{1}, lines{ind}{2}, 'autorouting', 'on');
            else
                delete_line(sys, lines{ind}{1}, lines{ind}{2});
            end
        end
    catch editLineException
        errmsg = editLineException.message;
    end
end

%=============================================================================== 
% Add or delete blocks
% library, src_blk, dst_name, position, param_name1, param_value1, ...
function errmsg = editBlock(action, sys, blks)
    errmsg = '';
    try
        for ind = 1: length(blks)
            param = blks{ind};
            len_param = length(param);

            [lib, src_name, dst_name, position]...
                = deal(param{1}, param{2}, param{3}, param{4});

            dst_blk = [sys, '/', dst_name];
            if strcmpi(action, 'add')    % add the block
                src_blk = [lib, '/', src_name];
                add_block(src_blk, dst_blk, 'Position', position);

                for inp = 5:2:len_param
                    set_param(dst_blk, param{inp}, param{inp+1});
                end
            else      % delete the block
                delete_block(dst_blk);
            end
        end
    catch editBlockException
        errmsg = editBlockException.message;
    end
end

%===============================================================================
% Check to see if a block exists in a system
function present = exist_block(sys, name)
    present = ...
        ~isempty(find_system(sys, 'searchdepth', 1, 'followlinks', 'on',...
            'lookundermasks', 'on', 'name', name));
end

