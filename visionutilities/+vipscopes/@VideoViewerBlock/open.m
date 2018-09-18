function open(this, preShowCallbackExists)
%OPEN Open method for Unified Scope coreblock.

%   Copyright 2015 The MathWorks, Inc.
if nargin < 2
    preShowCallbackExists = false;
end

block = this.Handle;

model = bdroot(block);
% Pop up an error dialog if a test harness belonging to the model is open.
if strcmp(get_param(model,'Lock'), 'on') && ...
    Simulink.harness.internal.hasActiveHarness(model)
    h = Simulink.harness.find(model, 'OpenOnly', 'on');
    errordlg(DAStudio.message('Simulink:Harness:CannotOpenMainMdlScopeAsTestHarnessIsActive', ...
        get_param(model, 'Name'), h.name));
    return;
end

% Pop up an error dialog if we are in a locked library.  
if strcmp(get_param(model,'Lock'), 'on') || ...
        strcmp(get_param(block,'LinkStatus'),'implicit')
    errordlg(DAStudio.message('Spcuilib:scopes:ScopeInLockedSystem', ...
        regexprep(get_param(block, 'Name'), '\n', ' ')));
    return;
end
set_param(block, 'inputType', 'Obsolete7b');

createScopeSpecificationObject(this);
hScopeSpec = get_param(block,'ScopeSpecificationObject');

% Set flag on the block that the pre show callback can be cleared later
% on, if applicable
this.PreShowCallbackExists = preShowCallbackExists;

setVisible(hScopeSpec,'on');


% [EOF]
