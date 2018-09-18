function report = getTrimmedReport(exception, internalCodeSearchPattern)
% getTrimmedReport trimmed exception error report
%   
%   report = vision.internal.getTrimmedReport(ex, searchPattern) returns a
%   trimmed version of the error report for MException object ex, trimmed
%   to hide code specified in cellstr searchPattern. searchPattern will be
%   fed to regexp. If searchPattern is empty, the default searchPattern
%   hides internal MathWorks code for the groundTruthLabeler.
%   
%   This function is intended for internal use only and is subjected to
%   change in the future.
%
%   See also vision.internal.labeler.tool.ExceptionDisplay.

% Copyright 2016-2017 The MathWorks, Inc.

if nargin<2 || isempty(internalCodeSearchPattern)
    % This is a copy from the property
    % this.InternalCodeSearchPattern, used as a default for the
    % labeling apps.
    internalCodeSearchPattern = ...
        {
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','vision','vision','+vision','+internal','+labeler'))]               % common app internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','vision','vision','+vision','+internal','+imageLabeler'))]          % il app internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','vision','vision','+vision','+labeler','@AutomationAlgorithm'))]    % automation algorithm internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','driving','driving','+driving','+internal','+videoLabeler'))]       % gtl app internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','driving','driving','+vision','+labeler','+mixin'))]                % mixin internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','driving','driving','+driving','+connector'))]                      % connector internals
        ['\n[^\n]*',regexptranslate('escape', fullfile(matlabroot,'toolbox','driving','driving','+driving','+automation'))]                     % old automation algorithm internals
        };
    
end

report = getReport(exception);

% Find the top-most occurence of internal code in the error
% stack.
internalStart = [];
for p = 1 : numel(internalCodeSearchPattern)
    internalStartP = regexp(report, internalCodeSearchPattern{p});
    
    internalStart = min([internalStartP,internalStart]);
end

% Filter the error report to start right above this.
if ~isempty(internalStart)
    report = report(1:(internalStart-1));
end
end