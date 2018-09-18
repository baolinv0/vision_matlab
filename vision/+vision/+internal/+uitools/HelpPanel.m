% HelpPanel Tool strip panel containing the help button
%
% panel = HelpPanel(helpFun, toolTipId) creates the help panel. helpFun is
% the callback function handle, and toolTipId is the message catalog id of
% the tool tip string.

classdef HelpPanel < vision.internal.uitools.OneButtonPanel
    methods
        function this = HelpPanel(helpFun, toolTipId)
            helpIcon = toolpack.component.Icon.HELP_24;
            nameId = 'vision:uitools:HelpButton';
            this = this@vision.internal.uitools.OneButtonPanel(...
                helpIcon, nameId, 'btnHelp', toolTipId, helpFun);
        end
    end
end