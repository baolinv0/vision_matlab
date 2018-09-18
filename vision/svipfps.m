function svipfps(varargin)
% Frame Rate display block Level-2 MATLAB S-function

% Copyright 1995-2004 The MathWorks, Inc.

mdlInitializeSizes(varargin{1});  % block
% if nargin==1,
%     mdlInitializeSizes(varargin{1});  % block
% else
%        varargin{4} => CopyFcn       = BlockCopy;
%                       DeleteFcn     = BlockDelete;
%                       NameChangeFcn = BlockNameChange; 
%                       MaskParameterChangeCallback =
%                       DialogApply(params,blkh);
%     feval(varargin{4:end});% GUI callback
% end 

% -----------------------------------------------------------
function mdlInitializeSizes(block)

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 0;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;

% Register the properties of the input port
block.InputPort(1).Complexity        = 'Inherited';
block.InputPort(1).DataTypeId        = -1;
block.InputPort(1).SamplingMode      = 'Inherited';
block.InputPort(1).DimensionsMode    = 'Inherited';

% Register parameters
block.NumDialogPrms = 1; % coming from mask

% sampling mode
block.SampleTimes = [-1 0]; %Port-based sample time

% Specify if Accelerator should use TLC or call back into MATLAB file
block.SetAccelRunOnTLC(false);
block.SetSimViewingDevice(true);% no TLC required

%Enable ND support
block.AllowSignalsWithMoreThan2D = true;

% Set the block simStateCompliance to DisallowSimState because this is a
% sink block
block.SimStateCompliance = 'DisallowSimState';

% Reg methods
block.RegBlockMethod('CheckParameters',         @mdlCheckParameters);

block.RegBlockMethod('SetInputPortSamplingMode',@mdlSetInputPortFrameData);
block.RegBlockMethod('SetInputPortDimensionsMode', @mdlSetInputDimsMode);
block.RegBlockMethod('SetInputPortDimensions',  @mdlSetInputPortDimensions);
block.RegBlockMethod('SetInputPortDataType',    @mdlSetInputPortDataType);

block.RegBlockMethod('PostPropagationSetup',    @mdlPostPropSetup); %C-Mex: mdlSetWorkWidths

block.RegBlockMethod('Start',                   @mdlStart);
block.RegBlockMethod('Update',                  @mdlUpdate);
block.RegBlockMethod('Terminate',               @mdlTerminate);

% see code in mdlStart

%% ---------------------------------------------------------------
function  mdlCheckParameters(block)
updateratePrm = block.DialogPrm(1);
if (updateratePrm.Data <= 0)
    errordlg('Display rate should be > 0','Frame Rate Calculator Dialog Error','modal');
    return;
end

%% ------------------------------------------------
function mdlSetInputPortFrameData(block, idx, fd)  %#ok

block.InputPort(idx).SamplingMode = fd;

%% ------------------------------------------------
function mdlSetInputPortDataType(block, idx, dtid) %#ok

block.InputPort(idx).DatatypeID = dtid;

%% ------------------------------------------------
function mdlSetInputDimsMode(block, port, dm)
% Set dimension mode
block.InputPort(port).DimensionsMode = dm;

%% ------------------------------------------------
function mdlSetInputPortDimensions(block,idx,di) %#ok

block.InputPort(idx).Dimensions = di;
if (numel(di) > 3)
    error(message('vision:dims:inputGreaterThan3D'));
end

%% ------------------------------------------------
function mdlPostPropSetup(block) %#ok
 
block.NumDworks             = 3;
block.Dwork(1).Name         = 'PrevTime';
block.Dwork(1).Dimensions   = 1;
block.Dwork(1).DatatypeID   = 0;
block.Dwork(1).Complexity   = 0;

block.Dwork(2).Name         = 'TotalTime';
block.Dwork(2).Dimensions   = 1;
block.Dwork(2).DatatypeID   = 0;
block.Dwork(2).Complexity   = 0;

block.Dwork(3).Name         = 'Count';
block.Dwork(3).Dimensions   = 1;
block.Dwork(3).DatatypeID   = 0;
block.Dwork(3).Complexity   = 0;

% There is no output from this block.
block.SignalSizesComputeType = 'FromInputSize';

%% -----------------------------------------------------------
function mdlStart(block)

prevtime  = block.Dwork(1); %#ok
totaltime = block.Dwork(2); %#ok
count     = block.Dwork(3); %#ok

prevtime.Data = now;
totaltime.Data = 0;
count.Data = 0;
%% ------------------------------------------------------------
function mdlUpdate(block)

curtime = now;
prevtime  = block.Dwork(1);
totaltime = block.Dwork(2);
count     = block.Dwork(3);

totaltime.Data = totaltime.Data + curtime - prevtime.Data;
prevtime.Data = curtime;
count.Data = count.Data + 1;
updateratePrm = block.DialogPrm(1);
updaterate = double(updateratePrm.Data);
if count.Data >= updaterate
    totaltime.Data = totaltime.Data * 86400 + eps; % convert to secs
    timediffstr = sprintf('%f', updaterate/totaltime.Data);
    dispstr = ['disp(' timediffstr ')'];
    modelname = strtok(get(block.BlockHandle,'Parent'),'/');
    notdirty = strcmp(get_param(modelname, 'Dirty'), 'off');
    set_param(block.BlockHandle, 'maskdisplay', dispstr);
    if (notdirty), set_param(modelname, 'Dirty','off'); end;
    count.Data = 0;
    totaltime.Data = 0;
end

% end mdlUpdate1
% ---------------------------------------------------------------
function mdlTerminate(block) %#ok

% TERMINATE Clean up any remaining items


% ------------------------------------------------------------
% [EOF] svipfps.m
