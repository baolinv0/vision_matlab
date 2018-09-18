%DockableAppFigure Dockable app figure
%   A figure associated with a toolstrip app that can be docked/undocked.
%
%   This class creates a figure with a push button for undocking the figure
%   when it is docked. When undocked, the figure toolbar is wiped of
%   everything except the dock button.
%
%   This class is undocumented and is intended for internal use only.
%
%   Construction
%   ------------
%   hDockFig = DockableAppFigure(Name,Value,...) creates a dockable app
%   figure using the name-value pairs specified by Name, Value. Name, Value
%   pairs are all name-value pairs accepted by figure. In addition, the
%   following name-value pair is available:
%
%   'IsDocked'  When true, the DockableAppFigure is docked on construction.
%               Otherwise, it is undocked. 
%               
%               Default: true
%
%   
%   Methods
%   -------
%   addFigureToApp(hDockFig, app) adds the dockable figure hDockFig to the
%   toolstrip app. app is a ToolGroup object (new or old API).
%
%   TF = isDocked(hDockFig) returns true if the figure is currently docked
%   and false otherwise.
%
%   Example
%   -------
%   % Create the dockable figure using figure construction inputs
%   hDockFig = vision.internal.uitools.DockableAppFigure(...
%       'Name', 'Dockable App Figure');
%
%   % Display an image on it
%   imshow('peppers.png');
%
%   % Create and open a tool group
%   app = matlab.ui.internal.desktop.ToolGroup('App');
%   open(app)
%
%   % Add the dockable figure to the app
%   addFigureToApp(hDockFig, app);
%   
%   See also figure.

% Copyright 2016 The MathWorks, Inc.

classdef DockableAppFigure < handle
    
    
    properties (GetAccess = public, SetAccess = private)
        %Figure
        %   Figure used to create DockableAppFigure
        Figure
    end
    
    properties (Access = private)
        %UndockBtn
        %   Push button control for undock
        UndockBtn
        
        %WindowStyleListener
        %   Listeners for changes to WindowStyle
        WindowStyleListeners
    end
    
    events
        %FigureDocked
        %   Event notifying clients that the figure was docked. Use this to
        %   react to the figure being docked.
        FigureDocked
        
        %FigureUndocked
        %   Event notifying clients that the figure was undocked. Use this
        %   to react to the figure being undocked.
        FigureUndocked
        
        %FigureClosed
        %   Event notifying clients that the figure was closed. Use this to
        %   react to the figure being closed.
        FigureClosed
    end
    
    methods
        %------------------------------------------------------------------
        function this = DockableAppFigure(varargin)
            
            createFigure(this, varargin{:});
            addUndockControl(this);
        end
        
        %------------------------------------------------------------------
        function addFigureToApp(this, toolGroup)
            addFigure(toolGroup, this.Figure);
        end
        
        %------------------------------------------------------------------
        function TF = isDocked(this)
            TF = strcmp(this.Figure.WindowStyle,'docked');
        end
        
        %------------------------------------------------------------------
        function delete(this)
            if ~isempty(this.Figure) && isvalid(this.Figure)
                close(this.Figure);
            end
        end
    end
    
    methods(Access = private)
        %------------------------------------------------------------------
        function createFigure(this, varargin)
            
            % Parse out starting dock style
            idx = find(strcmpi(varargin, 'IsDocked'));
            
            if ~isempty(idx) && idx<numel(varargin)
                isDocked = logical(varargin{idx+1});
                
                varargin(idx:idx+1) = [];
            else
                % By default, the created figure is not docked.
                isDocked = false;
            end
            
            if isDocked
                windowStyle = 'docked';
            else
                windowStyle = 'normal';
            end
            
            % Create figure with user-specified parameters
            this.Figure = figure(varargin{:});
            
            % Overwrite window style
            this.Figure.WindowStyle = windowStyle;
            
            % Turn off the menubar
            this.Figure.MenuBar = 'none';
            
            % Create an empty toolbar. This allows the dock icon to be
            % visible when the figure is undocked.
            uitoolbar(this.Figure);
            
            addlistener(this.Figure, 'SizeChanged', ...
                @this.positionUndockBtn);
            addlistener(this.Figure, 'ObjectBeingDestroyed', ...
                @(~,~)notify(this, 'FigureClosed'));
        end
        
        %------------------------------------------------------------------
        function addUndockControl(this)
            
            undockIcon = this.getUndockIcon;
            
            figName = this.Figure.Name;
            if isempty(figName)
                figName = 'figure';
            end
            
            toolTipString = ['Undock ',figName];
            
            this.UndockBtn = uicontrol(this.Figure, 'Style', 'pushbutton', ...
                'CData', undockIcon, 'Tooltip', toolTipString, ...
                'HandleVisibility', 'off', 'Callback', @this.doUndock, ...
                'Tag', 'UndockBtn');
             
            positionUndockBtn(this);
            
            updateIconVisibility(this);
            
            addWindowStyleListener(this);
        end
        
        %------------------------------------------------------------------
        function doUndock(this,varargin)
            % Undock the figure
            this.Figure.WindowStyle = 'normal';
        end
        
        %------------------------------------------------------------------
        function addWindowStyleListener(this)
            
            hFig = this.Figure;
            this.WindowStyleListeners{1} = event.proplistener(hFig, ...
                findprop(hFig, 'WindowStyle'), ...
                'PostSet', @this.updateIconVisibility);
            this.WindowStyleListeners{2} = event.proplistener(hFig, ...
                findprop(hFig, 'WindowStyle'), ...
                'PostSet', @this.sendDockEvent);
        end
        
        %------------------------------------------------------------------
        function updateIconVisibility(this, varargin)
            if isDocked(this)
                this.UndockBtn.Visible = 'on';
            else
                this.UndockBtn.Visible = 'off';
            end
        end
        
        %------------------------------------------------------------------
        function sendDockEvent(this, varargin)
            if isDocked(this)
                notify(this, 'FigureDocked');
            else
                notify(this, 'FigureUndocked');
            end
        end
        
        %------------------------------------------------------------------
        function positionUndockBtn(this, varargin)
            
            oldUnits = this.Figure.Units;
            restoreUnits = onCleanup(@()set(this.Figure,'Units',oldUnits));
            
            % Flush graphics queue
            drawnow;
            
            btnSize = [20 20];
            
            btnSize = hgconvertunits(this.Figure, [0 0 btnSize], 'pixels', 'normalized', this.Figure);
            btnSize(1:2) = [];
            
            % Position button at top right
            btnPosition = [1-btnSize btnSize];
            
            set(this.UndockBtn, 'Units', 'normalized', 'Position', btnPosition);
        end
        
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function icon = getUndockIcon()
            icon = [...
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   0   0   0   0   0   1   1   1   1
                        1   1   1   1   1   0   0   0   1   1   1   1
                        1   1   1   1   0   0   0   0   1   1   1   1
                        1   1   1   0   0   0   1   0   1   1   1   1
                        1   1   1   0   0   1   1   0   1   1   1   1
                        1   1   1   0   1   1   1   1   1   1   1   1
                        1   1   1   1   0   1   1   1   1   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1];
            icon(icon==1) = nan;
            icon = repmat(icon,[1 1 3]);
        end
        
        %------------------------------------------------------------------
        function icon = getDockIcon()
            icon = [...
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   0   0   0   1   1   0   1   1   1
                        1   1   0   1   0   0   0   1   0   1   1   1
                        1   1   1   1   1   0   0   0   0   1   1   1
                        1   1   1   1   1   1   0   0   0   1   1   1
                        1   1   1   1   0   0   0   0   0   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1
                        1   1   1   1   1   1   1   1   1   1   1   1];
            icon(icon==1) = nan;
            icon = repmat(icon,[1 1 3]);
        end
    end
end