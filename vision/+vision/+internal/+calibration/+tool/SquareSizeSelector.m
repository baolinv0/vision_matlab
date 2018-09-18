% SquareSizeSelector A compound UI control for selecting square size and
% units.

% Copyright 2014 The MathWorks, Inc.

classdef SquareSizeSelector < handle
    properties
        Parent;
        Location;
        SquareSizeEditBox;
        UnitsPopup;
        AvailableUnits = {'millimeters','centimeters','inches'};
    end
    
    methods
        function this = SquareSizeSelector(parent, location, ...
                initSquareSize, initUnits)
            this.Parent = parent;
            this.Location = location;
            
            addLabel(this);
            addEditBox(this, initSquareSize);
            addUnitsPopup(this, initUnits);
        end
        
        %------------------------------------------------------------------
        function [squareSize, units] = getSizeAndUnits(this)
            squareSize = str2double(get(this.SquareSizeEditBox,'String'));
            idx = get(this.UnitsPopup,'value');
            units = this.AvailableUnits{idx}; 
        end
        
        %------------------------------------------------------------------
        function disable(this)
            set(this.SquareSizeEditBox, 'Enable', 'off');
            set(this.UnitsPopup, 'Enable', 'off');
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function addLabel(this)
            position = [this.Location, 200, 20];
            uicontrol('Parent',this.Parent,'Style','text',...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Position', position,'String',...
                vision.getMessage('vision:caltool:SquareSize'));
        end
        
        %------------------------------------------------------------------
        function addEditBox(this, initSquareSize)
            position = [this.Location(1) + 210, this.Location(2) - 3, 50, 25];
            this.SquareSizeEditBox = uicontrol('Parent', this.Parent,...
                'Style','edit',...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'String',initSquareSize,'Position', position,...
                'BackgroundColor',[1 1 1],...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:SquareSizeToolTip'));
        end
        
        %------------------------------------------------------------------
        function addUnitsPopup(this, initUnits)
            position = [this.Location(1) + 280, this.Location(2) + 2, 90, 20];
            unitIdx = find(strcmp(initUnits, this.AvailableUnits));
            this.UnitsPopup = uicontrol('Parent', this.Parent,...
                'Style', 'popup', 'String', this.AvailableUnits,...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Position', position, 'Value', unitIdx, ...
                'ToolTipString', ...
                getString(message('vision:caltool:SquareSizeUnitsToolTip')));
            
        end
    end
            
end
