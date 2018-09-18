function requiresStatisticsToolbox(myFunction)
% Verify that the Statistics and Machine Learning Toolbox is available.

% check if stats is installed first.
if isdeployed
    isInstalled = isdir(fullfile(ctfroot, 'toolbox', 'stats'));
else    
    isInstalled = isdir(fullfile(matlabroot, 'toolbox', 'stats'));
end

if ~isInstalled
    exception = MException(message('vision:validation:statsNotInstalled',myFunction));
    throwAsCaller(exception);
end

% check out a license. Request 2nd output to prevent message printing.
[isLicensePresent, ~] = license('checkout','statistics_toolbox');

if ~isLicensePresent
    exception = MException(message('vision:validation:statsLicenseUnavailable',myFunction));
    throwAsCaller(exception);    
end