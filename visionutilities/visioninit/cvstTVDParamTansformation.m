function [outData] = cvstTVDParamTansformation(inData)
% Transformation Function for 'To Video Display' block.

%%
outData.NewBlockPath = '';
outData.NewInstanceData = [];

instanceData = inData.InstanceData;
% Get the field type 'Name' and 'Value' from instanceData
[ParameterNames{1:length(instanceData)}] = instanceData.Name;
[ParameterValues{1:length(instanceData)}] = instanceData.Value;

if (~ismember('windowSizeMode',ParameterNames))
    
    instanceData(end+1).Name = 'windowSizeMode';

    % What size should the window be? 
    % Options are: (1) Normal (2) Full-screen (Esc to exit), (3) True size (1:1)
    
    % Source of logic
    %{ 
        % see setMenuState_Callback in vipToVideoDisplayPanel
        itemToCheck = 1; % Normal
        if strcmp(get_param(handles.id, 'fullScreen'), 'on')
            itemToCheck = 2; % Full-screen (Esc to exit)
        elseif ~strcmp(get_param(handles.id, 'saveWindowSize'), 'on')
            itemToCheck = 3; % True size (1:1)
        end
    %}
    
    idx = findParamIdx(ParameterNames,'fullScreen');
    val = ParameterValues(idx);
    if strcmpi(val,'on')
       instanceData(end).Value = 'Full-screen (Esc to exit)';
    else        
        idx = findParamIdx(ParameterNames,'saveWindowSize');
        val = ParameterValues(idx);
        if ~strcmpi(val,'on')
           instanceData(end).Value = 'True size (1:1)';
        else
           instanceData(end).Value = 'Normal';
        end
    end
end

outData.NewInstanceData = instanceData;

function idx = findParamIdx(ParameterNames, str)

for i=1:length(ParameterNames)
    if strcmp(ParameterNames{i}, str)
        idx = i;
        return;
    end
    idx = [];
end