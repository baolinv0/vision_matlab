classdef ToggleButton < handle
    properties
        Button;       
        Parent;
        Position;
        Tag = '';
        GroupName = '';
        
        PushedName = 'Pushed';
        PushedToolTip = 'If you push this button, it will pop back up.';
        PushedFcn = @()[];
        
        UnpushedName = 'Unpushed';
        UnpushedToolTip = 'If you push this button, it will stay pushed.';
        UnpushedFcn = @()[];
    end
    
    methods
        %------------------------------------------------------------------
        function this = ToggleButton(groupName)
            if nargin < 1
                groupName = '';
            end
            this.GroupName = groupName;
        end
        
        %------------------------------------------------------------------
        function create(this)
            this.Button = uicontrol('Parent',this.Parent,'Style',...
                'togglebutton',  ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Position', this.Position, 'String', this.UnpushedName,...
                'ToolTipString', this.UnpushedToolTip, ...                
                'Tag', this.Tag, 'Callback', @this.onPush);
        end
        
        %------------------------------------------------------------------
        function reset(this)
            set(this.Button, 'String', this.UnpushedName);
            set(this.Button, 'Value', get(this.Button, 'Min'));
            set(this.Button, 'Visible', 'on');
        end        
        
        %------------------------------------------------------------------
        function hide(this)
            set(this.Button, 'Visible', 'off');
        end
        
        %------------------------------------------------------------------
        function tf = isPushed(this)
            tf = (get(this.Button, 'Value') == get(this.Button,'Max'));
        end
        
        %------------------------------------------------------------------
        function onPush(this, ~, ~)
            newState = get(this.Button, 'Value');
            try
                if isPushed(this)
                    this.PushedFcn();
                    set(this.Button, 'String', this.PushedName);
                    set(this.Button, 'ToolTipString', this.PushedToolTip);
                else
                    this.UnpushedFcn();
                    set(this.Button, 'String', this.UnpushedName);
                    set(this.Button, 'ToolTipString', this.UnpushedToolTip);
                end
            catch e
                set(this.Button, 'Value', ~newState);                
                errordlg(e.message);
            end                
        end
    end
end