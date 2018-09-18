function errmsg = vipblkblockproc(varargin)
%vipblkblockproc Does rewiring of block processing subsystem.

% blk is block handle. It is passed from outside since this function is called
% from dialog validateChanges also. See validateChanges for why.

% Copyright 1995-2006 The MathWorks, Inc.


blk = varargin{1};
NumI = varargin{2};
NumO = varargin{3};
Blocksize = varargin{4};
Overlapsize = varargin{5};
Traverse = varargin{6};
if (nargin < 7)
    ParamPort = 0;
else
    ParamPort = varargin{7};
end

errmsg = '';

if strcmp(get_param(bdroot,'SimulationStatus'), 'running')     || ...
   strcmp(get_param(bdroot,'SimulationStatus'), 'terminating') || ...
   strcmp(get_param(bdroot,'ExtModeConnected'), 'on')          || ...
   strcmp(get_param(bdroot(get(blk, 'Parent')), 'Lock'), 'on')
    return;
end

% check the parameters
%% NumI
if (iscell(NumI))
    errmsg = 'Number of inputs must not be a cell array.';
    return;
end
if ~builtInDtypes(NumI)
    errmsg = 'Number of inputs must be one of built in data types.';
    return;
end
if (length(NumI) > 1 || NumI <= 0)
    errmsg = 'Number of inputs must be a scalar >= 1.';
    return;
end
if (~isreal(NumI))
    errmsg = 'Number of inputs must be non-complex.';
    return;
end
if (isnan(NumI))
    errmsg = 'Number of inputs must not be NaN.';
    return;
end
if (~isfinite(NumI))
    errmsg = 'Number of inputs must be finite.';
    return;
end
if (~isnumeric(NumI))
    errmsg = 'Number of inputs must be numeric valued.';
    return;
end
if (~isIntegerValued(NumI))
    errmsg = 'Number of inputs must be integer valued.';
    return;
end
if (issparse(NumI))
    errmsg = 'Number of inputs must be non-sparse.';
    return;
end

%% NumO
if (iscell(NumO))
    errmsg = 'Number of outputs must not be a cell array.';
    return;
end
if ~builtInDtypes(NumO)
    errmsg = 'Number of outputs must be one of built in data types.';
    return;
end
if (length(NumO) > 1 || NumO <= 0)
    errmsg = 'Number of outputs must be a scalar >= 1.';
    return;
end
if (~isreal(NumO))
    errmsg = 'Number of outputs must be non-complex.';
    return;
end
if (isnan(NumO))
    errmsg = 'Number of outputs must not be NaN.';
    return;
end
if (~isfinite(NumO))
    errmsg = 'Number of outputs must be finite.';
    return;
end
if (~isnumeric(NumO))
    errmsg = 'Number of outputs must be numeric valued.';
    return;
end
if (~isIntegerValued(NumO))
    errmsg = 'Number of outputs must be integer valued.';
    return;
end
if (issparse(NumO))
    errmsg = 'Number of outputs must be non-sparse.';
    return;
end
% Blocksize
if ~iscell(Blocksize)
    errmsg = 'Block size must be a cell array.';
    return;
end

% Overlapsize
if ~iscell(Overlapsize)
    errmsg = 'Overlap size must be a cell array.';
    return;
end


blkroot = [get(blk,'Parent') '/' get(blk,'Name') '/Block iterator'];
blkproc = [get(blk,'Parent') '/' get(blk,'Name')];
subsys  = [blkroot '/sub-block process'];
itercount = [blkproc '/Iteration count'];

ports = get(blk, 'Ports');

if Traverse == 1
    Traversestr = 'Row-wise';
else
    Traversestr = 'Column-wise';
end

%input blocks
ParamPortOld = ~isempty(find_system(blkproc, 'LookUnderMasks', 'all', 'SearchDepth', 1, 'Name', 'P'));
numoldi = ports(1)-ParamPortOld;
numoldo = ports(2);

inputpos_start     = [105 185 145 245];
iportpos_start     = [ 20 208  50 222];
subinportpos_start = [ 40 153  70 167];
blkinportpos_start = [ 15 180  45 194];
blksize  = Blocksize;
ovlpsize = Overlapsize;
if (numel(blksize) ~= 1 && numel(blksize) ~= NumI)
    errmsg = 'Number of block size specifications should be 1 or equal to the number of inputs';
    return;
end
if (numel(blksize) == 1)
    oneblksize = 1;
else
    oneblksize = 0;
end
for i=1:numel(blksize)
    if (length(blksize{i}) ~= 2)
        errmsg = 'Each block size specification must have two elements.';
    end
end

if (numel(ovlpsize) ~= 1 && numel(ovlpsize) ~= NumI)
    errmsg = 'Number of overlap size specifications should be 1 or equal to the number of inputs';
    return;
end
if (numel(ovlpsize) == 1)
    oneovlpsize = 1;
else
    oneovlpsize = 0;
end
for i=1:numel(ovlpsize)
    if (length(ovlpsize{i}) ~= 2)
        errmsg = 'Each overlap size specification must have two elements.';
    end
end

for i=1:max(numel(blksize),numel(ovlpsize))
    if oneblksize
        blksizeI = blksize{1};
    else
        blksizeI = blksize{i};
    end

    if oneovlpsize
        ovlpsizeI = ovlpsize{1};
    else
        ovlpsizeI = ovlpsize{i};
    end
    
    if (blksizeI(1) < ovlpsizeI(1)) || (blksizeI(2) < ovlpsizeI(2))
        errmsg = 'Block size must be greater than the overlap size.';
    end
    
    if (blksizeI(1) < 1) || (blksizeI(2) < 1)
        errmsg = 'Block size must be at least 1 in each dimension.';
    end
    
    if (ovlpsizeI(1) < 0) || (ovlpsizeI(2) < 0)
        errmsg = 'Overlap size must be at least 0 in each dimension.';
    end
end

% Reposition ParamPort when an input is added
if (NumI>numoldi && ParamPortOld)
    inputpos     = inputpos_start;
    iportpos     = iportpos_start;
    subinportpos = subinportpos_start;
    blkinportpos = blkinportpos_start;

    pos = subinportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*50;
    set_param([subsys '/P'], 'Position', pos);
    set_param([subsys '/P'], 'Port', int2str(NumI+1));
    
    pos = iportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*100;
    set_param([blkroot '/P'], 'Position', pos);
    set_param([blkroot '/P'], 'Port', int2str(NumI+2));
        
    pos = blkinportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*50;
    set_param([blkproc '/P'], 'Position', pos);
    set_param([blkproc '/P'], 'Port', int2str(NumI+1));
end

set_param([blkroot '/Input'], 'Blocksize', 'Blocksize{1}',...
                             'Overlapsize', 'Overlapsize{1}',...
                             'tverse', Traversestr);
if strcmp(Traversestr, 'Row-wise')
    set_param([blkroot '/Input'], 'tverse', 'Column-wise');
else
    set_param([blkroot '/Input'], 'tverse', 'Row-wise');
end
set_param([blkroot '/Input'], 'tverse', Traversestr);

if ~exists([blkroot '/sub-block process/In1'])
    %try to repair the deleted inport 1
    add_block('built-in/Inport', [blkroot '/sub-block process/In1'],...
              'Position', [35 98 65 112],'Port', '1');
   %remove and add the partial unconnected line
   porth = get_param([blkroot '/Input'], 'PortHandles');
   delete_line(get(porth.Outport(1),'Line'));
   add_line(blkroot, 'Input/1', 'sub-block process/1', ...
       'autorouting','on');
end

inputpos     = inputpos_start;
iportpos     = iportpos_start;
subinportpos = subinportpos_start;
blkinportpos = blkinportpos_start;

for i=2:NumI
    istr = int2str(i);
    blkname = [blkroot '/Input' istr];
    if ~exists(blkname)
        add_block('vipmisc/Input', blkname, 'Position', inputpos);
        add_block('built-in/Inport', [blkroot '/In' istr],  'Position', iportpos);
        add_line(blkroot, ['In' istr '/1'], ['Input' istr '/1'], ...
            'autorouting','on');
        add_block('built-in/Inport', [blkproc '/In' istr], 'Position', blkinportpos);
        add_line(blkproc, ['In' istr '/1'], ['Block iterator/' int2str(i+1)], ...
            'autorouting','on');        
        if ~exists([subsys '/In' istr])
            add_block('built-in/Inport', [subsys '/In' istr],...
                      'Position', subinportpos);
            if exists([subsys '/Out' istr])
                inPortH = get_param([subsys '/In' istr],'porthandles');
                outPortH = get_param([subsys '/Out' istr],'porthandles');
                inL = get(inPortH.Outport(1), 'Line');
                outL = get(outPortH.Inport(1), 'Line');
                if ((inL == -1) && (outL == -1))

                    add_line(subsys, ['In' istr '/1'], ['Out' istr '/1'], ...
                        'autorouting','on');
                end
            end
        end
        add_line(blkroot, ['Input' istr '/1'], ['sub-block process/' istr], ...
            'autorouting','on');
    end
    
    inputpos([2,4])     = inputpos([2,4]) + 100;
    iportpos([2,4])     = iportpos([2,4]) + 100;
    subinportpos([2,4]) = subinportpos([2,4]) + 50;
    blkinportpos([2,4]) = blkinportpos([2,4]) + 50;
    if (oneblksize)
        set_param(blkname, 'Blocksize', 'Blocksize{1}',...
              'tverse', Traversestr);
    else
        set_param(blkname, 'Blocksize', ['Blocksize{' istr '}'],...
              'tverse', Traversestr);
    end
    %toggle traversetr to get things evaluated
    if strcmp(Traversestr, 'Row-wise')
        set_param(blkname, 'tverse', 'Column-wise');
    else
        set_param(blkname, 'tverse', 'Row-wise');
    end
    set_param(blkname, 'tverse', Traversestr);

    if (oneovlpsize)
        set_param(blkname, 'Overlapsize', 'Overlapsize{1}');
    else
        set_param(blkname, 'Overlapsize',['Overlapsize{' istr '}']);
    end
end


isNumIinIterCountWS = (NumI == slResolve('NumI',itercount));
ports = get_param(itercount, 'Ports');
OldNumIForIterCount = ports(1);

% Block Location - add
if (isNumIinIterCountWS && NumI>=OldNumIForIterCount)
    if exists([blkroot '/Matrix Concatenate'])
        set_param([blkroot '/Matrix Concatenate'], 'NumInputs', int2str(NumI));
    end
    for i=1:NumI
        istr = int2str(i);
        inputName = 'Input';
        if i~=1
            inputName = [inputName istr];
        end
        blkname = [blkroot '/' inputName];
        
        if exists(blkname)
            if exists([blkroot '/Matrix Concatenate'])
                allPorts = get_param([blkroot '/Matrix Concatenate'], 'PortHandles');
                if get(allPorts.Inport(i), 'Line')==-1 %if port not yet connected
                    add_line(blkroot, [inputName '/2'], ['Matrix Concatenate/' istr], ...
                        'autorouting','on');
                end
            else
                pos = get_param(blkname, 'Position');
                pos(1) = pos(1) + 60;
                pos(2) = pos(2) + 35;
                pos(3) = pos(1) + 15;
                pos(4) = pos(2) + 15;
                
                if ~exists([blkroot '/Terminator' istr])
                    add_block('built-in/Terminator', [blkroot '/Terminator' istr], 'Position', pos);
                end
                
                allPorts = get_param([blkroot '/Terminator' istr], 'PortHandles');
                if get(allPorts.Inport(1), 'Line')==-1 %if port not yet connected
                    add_line(blkroot, [inputName '/2'], ['Terminator' istr '/1'], ...
                        'autorouting','on');
                end
            end
        end
    end
end

% Iteration count - add
if (isNumIinIterCountWS && NumI>=OldNumIForIterCount)
    set_param(itercount, 'NumI', 'NumI'); %add input ports
end

if (isNumIinIterCountWS)
    allPorts = get_param(itercount, 'PortHandles');
    for i=2:NumI
        if get(allPorts.Inport(i), 'Line')==-1 %if port not yet connected
            istr = int2str(i);
            blkname = [blkroot '/Input' istr];
            if exists(blkname)
                add_line(blkproc, ['In' istr '/1'], ['Iteration count/' istr], ...
                    'autorouting','on');
            end
        end
    end
end

%delete extra inputs
for j=numoldi:-1:NumI+1
    istr = int2str(j);
    blkname = [blkroot '/Input' istr];

    if (isNumIinIterCountWS)
        delete_line(blkproc, ['In' istr '/1'], ['Iteration count/' istr]);
    end
    
    if exists(blkname)
        delete_line(blkproc, ['In' istr '/1'], ['Block iterator/' int2str(j+1)]);
        delete_block([blkproc '/In' istr]);
        porth = get_param(blkname, 'porthandles');
        delete_line(get(porth.Inport(1),'Line'));
        delete_line(get(porth.Outport(1),'Line'));
        delete_block(blkname);
        delete_block([blkroot '/In' istr]);
        if exists([subsys '/In' istr])
            if exists([subsys '/Out' istr])
                inPortH = get_param([subsys '/In' istr],'porthandles');
                outPortH = get_param([subsys '/Out' istr],'porthandles');
                inL = get(inPortH.Outport(1), 'Line');
                outL = get(outPortH.Inport(1), 'Line');
                if inL == outL
                    delete_line(subsys, ['In' istr '/1'], ['Out' istr '/1']);
                end
            end           
            delete_block([subsys '/In' istr]);
        end
    end
end

% Block Location - delete
if (isNumIinIterCountWS && NumI<OldNumIForIterCount)
    for i=OldNumIForIterCount:-1:NumI+1
        istr = int2str(i);
        
        if exists([blkroot '/Matrix Concatenate'])
            allPorts = get_param([blkroot '/Matrix Concatenate'], 'PortHandles');
            lineI = get(allPorts.Inport(i), 'Line');
            if (lineI ~= -1)
                delete_line(lineI);
            end
        else
            allPorts = get_param([blkroot '/Terminator' istr], 'PortHandles');
            lineI = get(allPorts.Inport(1), 'Line');
            if (lineI ~= -1)
                delete_line(lineI);
            end
            delete_block([blkroot '/Terminator' istr]);
        end
    end
    if exists([blkroot '/Matrix Concatenate'])
        set_param([blkroot '/Matrix Concatenate'], 'NumInputs', int2str(NumI));
    end
end

% Iteration count - add
if (isNumIinIterCountWS && NumI<OldNumIForIterCount)
    allPorts = get_param(itercount, 'PortHandles');
    for j=OldNumIForIterCount:-1:NumI+1
        lineJ = get(allPorts.Inport(j), 'Line');
        if (lineJ ~= -1)
            delete_line(lineJ);
        end
    end
    set_param(itercount, 'NumI', 'NumI'); %remove ports
end

%output blocks
outputpos_start     = [355 189 410 251];
portpos_start       = [465 213 495 227];
inportcopypos_start = [300 198 330 212];
suboutportpos_start = [285 153 315 167];
blkoutportpos_start = [530 138 560 152];
set_param([blkroot '/Output'], 'Blocksize', 'Blocksize{1}',...
                   'Overlapsize', 'Overlapsize{1}',...
                   'tverse', Traversestr);

if strcmp(Traversestr, 'Row-wise')
    set_param([blkroot '/Output'], 'tverse', 'Column-wise');
else
    set_param([blkroot '/Output'], 'tverse', 'Row-wise');
end
set_param([blkroot '/Output'], 'tverse', Traversestr);

%try to repair deleted outport 1
if ~exists([blkroot '/sub-block process/Out'])
    add_block('built-in/Outport', [blkroot '/sub-block process/Out'],...
              'Position', [280 98 310 112], 'Port', '1');
   porth = get_param([blkroot '/Output'], 'PortHandles');
   delete_line(get(porth.Inport(2),'Line'));
   add_line(blkroot, 'sub-block process/1', 'Output/2', ...
       'autorouting','on');
end

outputpos     = outputpos_start    ;
portpos       = portpos_start      ;
inportcopypos = inportcopypos_start;
suboutportpos = suboutportpos_start;
blkoutportpos = blkoutportpos_start;
for i=2:NumO
    istr = int2str(i);
    blkname = [blkroot '/Output' istr];
    if ~exists(blkname)
        add_block('vipmisc/Output', blkname, 'Position', outputpos);
        add_block('built-in/Outport', [blkroot '/Out' istr],  'Position', portpos);
        add_block([blkroot '/In1'], [blkroot '/Inc' istr],...
                  'CopyOption', 'duplicate',...
                  'Position', inportcopypos);
        add_line(blkroot, ['Inc' istr '/1'], ['Output' istr '/1'], ...
            'autorouting','on');
        add_line(blkroot, ['Output' istr '/1'], ['Out' istr '/1'], ...
            'autorouting','on');
        add_block('built-in/Outport', [blkproc '/Out' istr], 'Position', blkoutportpos);
        add_line(blkproc, ['Block iterator/' istr], ['Out' istr '/1'], ...
            'autorouting','on');
        if ~exists([subsys '/Out' istr])
            add_block('built-in/Outport', [subsys '/Out' istr],...
                'Position', suboutportpos);
            if exists([subsys '/In' istr])
                inPortH = get_param([subsys '/In' istr],'porthandles');
                outPortH = get_param([subsys '/Out' istr],'porthandles');
                inL = get(inPortH.Outport(1), 'Line');
                outL = get(outPortH.Inport(1), 'Line');
                if ((inL == -1) && (outL == -1))
                    add_line(subsys, ['In' istr '/1'], ['Out' istr '/1'], ...
                        'autorouting','on');
                end
            end
        end
        add_line(blkroot, ['sub-block process/' istr], ['Output' istr '/2'], ...
            'autorouting','on');
    end
    outputpos([2,4])     = outputpos([2,4]) + 100;
    portpos([2,4])       = portpos([2,4]) + 100;
    inportcopypos([2,4]) = inportcopypos([2,4]) + 100;
    suboutportpos([2,4]) = suboutportpos([2,4]) + 50;
    blkoutportpos([2,4]) = blkoutportpos([2,4]) + 50;
    set_param(blkname, 'Blocksize', 'Blocksize{1}',...
                       'Overlapsize', 'Overlapsize{1}',...
                       'tverse', Traversestr);

    %toggle traversetr to get things evaluated
    if strcmp(Traversestr, 'Row-wise')
        set_param(blkname, 'tverse', 'Column-wise');
    else
        set_param(blkname, 'tverse', 'Row-wise');
    end
    set_param(blkname, 'tverse', Traversestr);
end

%delete extra output blocks
for j=numoldo:-1:NumO+1
    istr = int2str(j);
    blkname = [blkroot '/Output' istr];
    if exists(blkname)
        delete_line(blkproc, ['Block iterator/' istr], ['Out' istr '/1']);
        delete_block([blkproc '/Out' istr]);
        delete_line(blkroot, ['Output' istr '/1'], ['Out' istr '/1']);
        porth = get_param(blkname, 'porthandles');
        delete_line(get(porth.Inport(1),'Line'));
        delete_block([blkroot '/Inc' istr]);
        delete_line(get(porth.Inport(2),'Line'));
        delete_block(blkname);
        delete_block([blkroot '/Out' istr]);
        if exists([subsys '/Out' istr])
            if exists([subsys '/In' istr])
                inPortH = get_param([subsys '/In' istr],'porthandles');
                outPortH = get_param([subsys '/Out' istr],'porthandles');
                inL = get(inPortH.Outport(1), 'Line');
                outL = get(outPortH.Inport(1), 'Line');
                if inL == outL
                    delete_line(subsys, ['In' istr '/1'], ['Out' istr '/1']);
                end
            end               
            delete_block([subsys '/Out' istr]);
        end
    end
end

% Reposition ParamPort when an input is removed
if (NumI<numoldi && ParamPortOld)

    inputpos     = inputpos_start;
    iportpos     = iportpos_start;
    subinportpos = subinportpos_start;
    blkinportpos = blkinportpos_start;

    pos = subinportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*50;
    set_param([subsys '/P'], 'Position', pos);
    set_param([subsys '/P'], 'Port', int2str(NumI+1));
    
    pos = iportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*100;
    set_param([blkroot '/P'], 'Position', pos);
    set_param([blkroot '/P'], 'Port', int2str(NumI+2));
        
    pos = blkinportpos;
    pos([2,4]) = pos([2,4]) + (NumI-1)*50;
    set_param([blkproc '/P'], 'Position', pos);
    set_param([blkproc '/P'], 'Port', int2str(NumI+1));
end

%add param port
if (~ParamPortOld && ParamPort)
    pos = get_param([subsys '/In' int2str(NumI)], 'Position');
    pos([2,4]) = pos([2,4]) + 50;
    add_block('built-in/Inport', [subsys '/P'], 'Position', pos);
    
    % terminate port in user subsystem
    pos([1,3]) = pos([1,3]) + 100; 
    add_block('built-in/Terminator', [subsys '/Terminator P'], 'Position', pos);
    add_line(subsys, 'P/1', 'Terminator P/1', 'autorouting', 'on');
    
    pos = get_param([blkroot '/In' int2str(NumI)], 'Position');
    pos([2,4]) = pos([2,4]) + 100;
    add_block('built-in/Inport', [blkroot '/P'],  'Position', pos);

    add_line(blkroot, 'P/1', ['sub-block process/' int2str(NumI+1)], ...
            'autorouting','on');

    if (NumI == 1)
        pos = get_param([blkproc '/In'], 'Position');
    else
        pos = get_param([blkproc '/In' int2str(NumI)], 'Position');
    end
    
    pos([2,4]) = pos([2,4]) + 50;
    add_block('built-in/Inport', [blkproc '/P'], 'Position', pos);    
    add_line(blkproc, 'P/1', ['Block iterator/' int2str(NumI+2)], ...
        'autorouting','on');
end

%delete param port
if (ParamPortOld && ~ParamPort)

    delete_line(blkproc, 'P/1', ['Block iterator/' int2str(NumI+2)]);
    delete_block([blkproc '/P']);

    delete_line(blkroot, 'P/1', ['sub-block process/' int2str(NumI+1)]);
    delete_block([blkroot '/P']);
    
    delete_line(subsys, 'P/1', 'Terminator P/1');
    delete_block([subsys '/Terminator P']);
    delete_block([subsys '/P']);
end

% For models made in R2010a and before
% make blksize and ovlpsize inputs to Iteration count a cell array
newblksize = regexprep(get_param(itercount, 'blksize'), '{\w*}', '');
set_param(itercount, 'blksize', newblksize);
newovlpsize = regexprep(get_param(itercount, 'ovlpsize'), '{\w*}', '');
set_param(itercount, 'ovlpsize', newovlpsize);

end %function
%==========================================================================
function e = exists(blk)
    try
        get_param(blk, 'BlockType');
        e = true;
    catch %#ok
        e = false;
    end
end %function

%==========================================================================
function flag = builtInDtypes(x)

    flag=0;
    c=class(x);
    if (strcmp(c,'double') || ...
        strcmp(c,'single') || ...
        strcmp(c,'int8') || ...
        strcmp(c,'uint8') || ...
        strcmp(c,'int16') || ...
        strcmp(c,'uint16') || ...
        strcmp(c,'int32') || ...
        strcmp(c,'uint32') || ...
        strcmp(c,'boolean'))
        flag=1;
    end
end%function
%==========================================================================
function flag = isIntegerValued(x)

    flag=0;
    y=double(x);
    if (y==floor(y)) 
        flag=1;
    end  
end%function
    

% [EOF]
