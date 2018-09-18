classdef SelectionLine < handle
    %vision.internal.calibration.tool.SelectionLine creates a horizontal
    %line that can move vertically on an axes.
    properties
        Axes;   % The axes that we are drawing into.
        Group;  % The group that holds all hg objects, listens to mouse evt.
    end
    
    properties(Constant)
        BoxText = vision.getMessage('vision:caltool:OutlierThresholdLineTip');
    end
    
    properties(Dependent)
        TipText %String to show for the Tip.
    end
    
    properties(Access = private)
        % HG objects
        Line;   %The sliding line
        Box;    %The box with prompt
        Text;   %The prompt within the box
        Tip;    %The text tip indicating the current level
        
        % Top and bottom limit for the sliding line.
        Min;
        Max;
        Location; %Current location of the sliding line.
        
        % Tags and Misc.
        LineTag  = 'ThresholdLine'
        BoxTag   = 'ThresholdBox'
        TextTag  = 'ThresholdTip'
        FontSize = 11;
        
        % State of the sliding line.
        IsLine = false; % Flag to indicate the current state, line or box
    end
    
    methods
        function obj = SelectionLine(ax,loc,min,max)            
            obj.Min = min;
            obj.Max = max;
            obj.Axes = ax;
            obj.Location = loc;
            obj.Group = hggroup('Parent',obj.Axes,...
                'Visible','off');
            
            % create HG objects
            createLine(obj);
            createBox(obj);
            createText(obj);
            createTip(obj);
            
            % Turn on visibility
            MakeGroupVisible(obj);
        end
        
        %------------------------------------------------------------------
        function restoreState(this,loc,wasLine)
            % Restore line's state given location and line or box
            this.setSliderLocation(loc);
            if wasLine
                %Slider was moved, show the line.
                this.switchToLine();
            else
                %Slider didn't move, restore the box
                this.switchToBox();
            end
        end
        
        %------------------------------------------------------------------
        function [loc, isLine] = getState(this)
            % Returns the location and line state of current slider.
            loc = this.Location;
            isLine= this.IsLine;
        end
        
        %------------------------------------------------------------------
        function reset(this)
            % resets to slider's initial position
            if ~this.IsLine
                % for speed
                return;
            end
            % Reset the slider to max.
            this.setSliderLocation(this.Max);
            
            % display the box
            this.switchToBox();
        end
        
        %------------------------------------------------------------------
        function switchToLine(this)
            % Routine to show line with tip
            this.IsLine = true;
            this.Tip.Visible = 'on';
            this.Text.Visible = 'off';
            this.Box.Visible = 'off';
        end
        
        %------------------------------------------------------------------
        function switchToBox(this)
            % Routine to show box with prompt
            this.IsLine = false;
            this.Tip.Visible = 'off';
            this.Text.Visible = 'on';
            this.Box.Visible = 'on';
        end
        
        %------------------------------------------------------------------
        function setSliderLocation(this, loc)
            % Set the current slider to a given loc
            if loc < this.Min
                loc = this.Min;
            end
            
            if loc > this.Max
                loc = this.Max;
            end
            
            set(this.Line,'ydata',[loc,loc]);
            oldLoc = this.Location;
            this.Location = loc;
            if loc < oldLoc || loc == this.Min
                this.updateTip('down');
            else
                this.updateTip('up');
            end
        end
        
        %------------------------------------------------------------------
        function val = get.TipText(this)
            %Returns dependent datatip value.
            val = sprintf('%.2f ',this.Location);
        end
        
    end
    
    methods(Access = private)
        %------------------------------------------------------------------
        function createLine(this)
            %Creates the sliding line.
            y = this.Location;
            this.Line = line(...
                this.Axes.XLim,[y,y],...
                'LineWidth',2,...
                'Parent',this.Group,...
                'Color','red',...
                'Tag',this.LineTag,...
                'HitTest','off');
        end
        
        %------------------------------------------------------------------
        function createBox(this)
            %Creates the box that contains the prompt at initial state.
            val = this.Location;
            width = (this.Axes.XLim(2)-this.Axes.XLim(1))/1.2;
            height =(this.Axes.YLim(2)-val)/1.2;
            x = sum(this.Axes.XLim)/2 - width/2;
            y = val;
            this.Box = patch(...
                [x,x,x+width,x+width],...
                [y,y+height,y+height,y],...
                'red',...
                'Parent',this.Group,'Tag', this.BoxTag,...
                'FaceAlpha',0.2,'HitTest','off');
        end
        
        %------------------------------------------------------------------
        function createTip(this)
            % Create the data tip at the right end of line.
            val = this.Location;
            x = this.Axes.XLim(2);
            y = val;
            boxLocation = getBoxLocation(this);
            yoffset = boxLocation(4)/2;
            
            this.Tip = text(...
                x,y+yoffset,...
                this.TipText,...
                'Parent',this.Group,'Visible','off',...
                'HorizontalAlignment','right',...
                'Tag',this.TextTag,...
                'FontSize',this.FontSize,...
                'Color','Red',...
                'HitTest','off');
        end
        
        %------------------------------------------------------------------
        function createText(this)
            %Create the prompt within the box
            boxLocation = getBoxLocation(this);
            yoffset = boxLocation(4)/2;
            y = boxLocation(2);
            
            this.Text = text(...
                mean(this.Axes.XLim), y + yoffset,...
                this.BoxText,...
                'Parent',this.Group,...
                'FontSize',this.FontSize,...
                'HorizontalAlignment','center',...
                'HitTest','off');
        end
        
        %------------------------------------------------------------------
        function loc = getBoxLocation(this)
            hBox = findobj(this.Group,'Tag',this.BoxTag);
            vert = hBox.Vertices;
            loc = [vert(1,1),vert(1,2),vert(3,1)-vert(1,1),vert(3,2)-vert(1,2)];
        end
        
        %------------------------------------------------------------------
        function MakeGroupVisible(this)
            this.Group.Visible = 'on';
        end
        
        %------------------------------------------------------------------
        function updateTip(this,direction)
            % Update Tip's value and it's position
            this.Tip.String = this.TipText;
            textPos = this.Tip.Position;
            boxLocation = getBoxLocation(this);
            yoffset = boxLocation(4)/2;
            if strcmp(direction,'down')
                newLocation = this.Location + yoffset;
            else
                newLocation = this.Location - yoffset;
            end
            set(this.Tip,'Position',[textPos(1), newLocation, 0]);
        end
    end
end
