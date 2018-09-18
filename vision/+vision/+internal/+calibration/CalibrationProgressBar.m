% CalibrationProgressBar Progress bar dialog for camera calibration

%   Copyright 2014 MathWorks, Inc.
classdef CalibrationProgressBar < handle
    properties(Access=private)
        isEnabled = true;
        hWaitBar = [];
        Messages = {};
        Percentages = [];
        CurrentState = 1;        
    end
        
    methods
        %------------------------------------------------------------------
        function this = CalibrationProgressBar(isEnabled, messages, percentages)
            this.isEnabled = isEnabled;
            if this.isEnabled
                this.Messages = messages;
                this.Percentages = percentages;
                this.hWaitBar = waitbar(0, getString(message(this.Messages{1})), ...
                    'Tag', 'SingleCalibrationProgressBar',...
                    'WindowStyle', 'modal',...
                    'Name', 'Calibration Progress');
            end            
        end
                
        %------------------------------------------------------------------
        function update(this)
            if this.isEnabled && this.CurrentState <= numel(this.Messages)
                this.CurrentState = this.CurrentState + 1;
                waitbar(this.Percentages(this.CurrentState), this.hWaitBar,...
                    getString(message(this.Messages{this.CurrentState})));           
            end
        end
        
        %------------------------------------------------------------------
        function delete(this)
            % close the progress bar window
            if this.isEnabled && ishandle(this.hWaitBar)
                delete(this.hWaitBar);
            end
        end                
    end
end