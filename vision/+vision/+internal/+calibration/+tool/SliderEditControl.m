classdef SliderEditControl < handle
% SliderEditControl Handle class that excapsulates Slider and Edit field
% capability.

% Copyright 2014 The MathWorks, Inc.

    properties(Access=public)
        SliderControl
        LabelControl
        EditControl
    end

    properties (Access=private)
        PropertyName
        CurrentValue
        MinValue
        MaxValue 
    end

    events
        PropValueChanged
    end
    
    methods
        function this = SliderEditControl(labelName, minValue, maxValue, defaultValue)
            %% Perform Initializations
            this.PropertyName = labelName;
            this.MinValue = minValue;
            this.MaxValue = maxValue;
            this.CurrentValue = defaultValue;

            % Create the label.
            this.LabelControl = toolpack.component.TSLabel(this.PropertyName);

            % Set slider tick spacing and create label table.
            this.SliderControl = toolpack.component.TSSlider(this.MinValue, this.MaxValue, this.CurrentValue);
            this.SliderControl.MajorTickSpacing = ceil((this.MaxValue-this.MinValue)/20);
            this.SliderControl.MinorTickSpacing = 1;
            this.SliderControl.Name = strcat(this.PropertyName, 'Slider');

            addlistener(this.SliderControl,'StateChanged',@(hobj,~)this.sliderEditControlCallback(hobj));

            % Create text field to enter slider.
            this.EditControl = toolpack.component.TSTextField(num2str(this.CurrentValue), 5);
            this.EditControl.Name = strcat(this.PropertyName, 'Edit');
            addlistener(this.EditControl,'TextEdited',@(hobj,~)this.sliderEditControlCallback(hobj));
        end
    end

    methods(Access=private)
        function sliderEditControlCallback(this, obj)
            if isa(obj,'toolpack.component.TSSlider')
                this.CurrentValue = obj.Value;
                this.EditControl.Text = num2str(this.CurrentValue);
            elseif isa(obj,'toolpack.component.TSTextField')
                value = str2double(obj.Text);
                if isnan(value)
                    % TODO: Do we need an unnecessary error message?
                    this.EditControl.Text = num2str(this.CurrentValue);
                    return;
                end
                
                % Valid value - continue.
                if value < this.MinValue
                    value = this.MinValue;
                elseif value > this.MaxValue
                    value = this.MaxValue;
                end      
                this.CurrentValue = value;
                this.EditControl.Text = num2str(value);
                this.SliderControl.Value = this.CurrentValue;
            end
            
            % Notify to listener to update camera object.
            notify(this, 'PropValueChanged');
        end
    end
end