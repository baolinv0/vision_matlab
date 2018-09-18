classdef AppFigure < handle
    % AppFigure Base class for figures used in a tool strip-based app.
    %
    %   fig = AppFigure(title) returns an AppFigure object representing a
    %   figure that can be dropped into a tool strip app. title is a string
    %   containing the figure title.
    %
    %   AppFigure properties:
    %     Fig       - The figure handle
    %     Title     - The figure title
    %     GroupName - the name of the toolgroup
    %
    %   AppFigure methods:
    %     createFigure        - Create the figure
    %     wipeFigure          - Clear the figure
    %     makeFigureVisible   - Turn figure visibility on
    %     makeHandleVisible   - Turn figure handle visibility on
    %     makeHandleInvisible - Turn figure handle visibility off
    %     lockFigure          - Make the figure modifiable by callbacks only
    %     showHelperText      - Show helper text
    %     hideHelperText      - Hide helper text
    %     close               - Close the figure
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties
        %Fig The figure handle
        Fig = []
        
        %Title The figure title
        Title
        
        %GroupName The name of the toolgroup. Useful for creating dialogs
        %          from within an AppFigure.
        GroupName
        
        %TextLabel UICONTROL containing static text displayed at top of the
        %          figure
        TextLabel 
    end
    
    properties(Dependent)
        % Add alias for Title property to keep it in-sync with "Name"
        % property usage in HG.
        Name
    end
    
    methods
        %------------------------------------------------------------------
        function this = AppFigure(title)
            this.Title = title;
            createFigure(this);
        end
        
        %------------------------------------------------------------------
        function addFigureToApp(this, app)
            this.GroupName = app.getGroupName();
            addFigure(app, this.Fig); 
        end
        %------------------------------------------------------------------
        function createFigure(this)
            % suppress docked-window warning
            warning('off', 'MATLAB:figure:SetResize');
            c = onCleanup(@()warning('on', 'MATLAB:figure:SetResize'));
            
            this.Fig = figure('Resize', 'off', 'Visible','off', ...
                'NumberTitle', 'off', 'Name', this.Title, 'HandleVisibility',...
                'callback', 'Color','white','IntegerHandle','off');
        end
        
        %------------------------------------------------------------------
        function wipeFigure(this)
            %wipeFigure Clear the figure
            if ishandle(this.Fig)
                set(this.Fig,'HandleVisibility','on');
                clf(this.Fig);
                set(this.Fig,'HandleVisibility','callback');
            end
        end
        
        %------------------------------------------------------------------
        function makeFigureVisible(this)
            %makeFigureVisible Turn figure handle visibility on
            set(this.Fig, 'Visible', 'on');
        end
        
        %------------------------------------------------------------------
        function makeFigureInvisible(this)
            %makeFigureVisible Turn figure handle visibility off
            set(this.Fig, 'Visible', 'off');
        end
        
        %------------------------------------------------------------------
        function makeHandleVisible(this)
            %makeHandleVisible Turn figure handle visibility on
            set(this.Fig,'HandleVisibility','on');
        end
        
        %------------------------------------------------------------------
        function makeHandleInvisible(this)
            %makeHandleInvisible Turn figure handle visibility off
            set(this.Fig,'HandleVisibility','off');
        end
        
        %------------------------------------------------------------------
        function lockFigure(this)
            %lockFigure Make the figure modifiable by callbacks only
            if ishandle(this.Fig)
                set(this.Fig,'HandleVisibility', 'callback');
            end
        end
        
        %------------------------------------------------------------------
        function textLabel = showHelperText(this, textString, pos)
            % Expect pos to be normalized
            
            if isempty(this.TextLabel) || ~isvalid(this.TextLabel)
                this.TextLabel = uicontrol('Parent', this.Fig,...
                    'Style', 'text', 'HorizontalAlignment', 'Left',...
                    'Units', 'normalized', 'Position', [0.05 0.75 0.9 0.2],...
                    'ForegroundColor', [0.45 0.45 0.45]);
            end
            
            if nargin>1
                set(this.TextLabel, 'String', textString, 'Visible', 'on');
            end
            
            if nargin>2
                set(this.TextLabel, 'Position', pos);
            end
            
            textLabel = this.TextLabel;
        end
        
        %------------------------------------------------------------------
        function hideHelperText(this)
            
            if ~isempty(this.TextLabel) && isvalid(this.TextLabel)
                set(this.TextLabel, 'Visible', 'off');
            end
        end
        
        %------------------------------------------------------------------
        function close(this)
            %CLOSE Close the figure
            if ishandle(this.Fig)
                this.makeHandleVisible();
                delete(this.Fig);
            end
        end
        
        %------------------------------------------------------------------
        function name = get.Name(this)
            name = this.Title;
        end
        
        %------------------------------------------------------------------
        function setFigureTitle(this, title)
            % The Title property and Figure 'Name' property must be in sync
            set(this.Fig,'Name',title);
            this.Title = title;
        end
    end
    
end