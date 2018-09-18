function isUnsupported = hasUnsupportedTarget(mdl)
% ISUNSUPPORTEDTARGET Check if target hardware device is unsupported 
% If the model is configured either to generate code for target or to
% package generated code and artifacts, this function checks if target
% hardware device is compatible with the host platform 
%
% This function is used by the S-functions those support code-generation
% only on hosts and use shared-libraries in code-generation

isCodegenForTarget = strcmp(get_param(mdl,'RTWGenerateCodeOnly'), 'on') || ...
                     strcmp(get_param(mdl,'PackageGeneratedCodeAndArtifacts'), 'on');
if isCodegenForTarget
    isCompatibleDevType = isCompatibleDeviceType(mdl);
    isUnsupported = ~isCompatibleDevType;
else
    isUnsupported = false;
end

%--------------------------------------------------------------------------
function isCompatibleDevType = isCompatibleDeviceType(mdl)

mdlDevType = get_param(mdl,'TargetHWDeviceType');

if strcmp(mdlDevType, 'Generic->MATLAB Host Computer')
    % allow default setting
    isCompatibleDevType = true;
    return;
end

if ~contains(mdlDevType,'->x86-')
    isCompatibleDevType = true;
    return;
end

% example: For 'Intel->x86-32 (Windows64)', remain = '->x86-64 (Windows64)'
[~, remain] = strtok(mdlDevType,'->x86-');

% example: from '->x86-64 (Windows64)' to '64 (Windows64)'
remain = remain(7:end);

isCompatibleDevType = true; % allow by default
if ~isempty(remain)
    if ispc % must be win64
        isCompatibleDevType = strcmp(remain, '64 (Windows64)');
    elseif ismac % must be maci64
        isCompatibleDevType = strcmp(remain, '64 (Mac OS X)');
    else % must be glnxa64
        isCompatibleDevType = strcmp(remain, '64 (Linux 64)');
    end
end
