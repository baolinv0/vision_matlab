function output(this)
% Function called by core block output function
% using the draw scheduler
%   Copyright 2015 The MathWorks, Inc.

if ~isvalid(this.UnifiedScope) 
    return
end

source = this.UnifiedScope.DataSource;

if source.SnapShotMode
    return
end

%Update time used for the text display
updateSimulationTime(source);

source.NeedsUpdate = true;
updateDisplay(source);

% This does not need to be updated every time display is updated
% Change every 5 times
if (this.UpdateCount == 0)
    updateText(source);
end
this.UpdateCount = mod(this.UpdateCount + 1,5);

end
% [EOF]
