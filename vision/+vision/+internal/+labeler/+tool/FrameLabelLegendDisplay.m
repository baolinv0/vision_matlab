classdef FrameLabelLegendDisplay < handle
    %FrameLabelLegendDisplay class to handle display of frame labels as a
    %legend.
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties (Dependent = true, Access = private)
        %NumLabels
        %   Number of frame labels
        NumLabels
    end
    
    properties (GetAccess = public, SetAccess = private)
        %ShowLabel
        %   Show or hide frame label state
        ShowLabel logical = true;
    end
    
    properties (Access = private)
        %Names
        %   M-by-1 Cell array of label names
        Names
        
        %Colors
        %   M-by-3 array of colors for each label
        Colors
        
        %States
        %   M-by-1 logical array of current states
        States
        
        %Figure
        %   Parent figure handle
        Figure
        
        %Axes
        %  Axes to draw legend
        Axes
        
        %Patches
        %   Invisible patches on which legend is drawn
        Patches
        
        %Legend
        %   Legend handle
        Legend
    end
    
    methods
        %------------------------------------------------------------------
        function this = FrameLabelLegendDisplay(hFig)
            this.Figure = hFig;
            reset(this);
        end
        
        %------------------------------------------------------------------
        function show(this)
            this.ShowLabel = true;
            if this.hasValidAxes() && this.NumLabels>0
                updateView(this);
            end
            
        end
        
        %------------------------------------------------------------------
        function hide(this)
            this.removeLegend();
            this.ShowLabel = false;
        end
        
        %------------------------------------------------------------------
        function reset(this)
            this.Names  = {};
            this.Colors = zeros(0,3);
            this.States = [];
            
            this.Patches = repmat(gobjects,0,0);
            updateView(this);
        end
        
        %------------------------------------------------------------------
        function reparent(this)
            names   = this.Names;
            colors  = this.Colors;
            states  = this.States;
            showLabel = this.ShowLabel;
            
            reset(this);
            for n = 1 : numel(names)
                onLabelAdded(this, names{n}, colors(n,:));
            end
            
            if showLabel
                show(this);
            else
                hide(this);
            end
            
            update(this, find(states));
        end
        
        %------------------------------------------------------------------
        function update(this, trueIDs)
            states = false(size(this.States));
            states(trueIDs) = true;
            this.States = states;
            updateStates(this);
        end
        
    end
    
    methods
        %------------------------------------------------------------------
        function onLabelAdded(this, name, color)
            assert(nargin==3 && ischar(name));
            
            this.Names{end+1}       = name;
            this.Colors(end+1,:)    = color;
            this.States(end+1)      = false;
            updateView(this);
        end
        
        %------------------------------------------------------------------
        function onLabelRemoved(this, labelID)
            assert(labelID >0 && labelID <= this.NumLabels);
            
            this.Names(labelID)     = [];
            this.Colors(labelID,:)  = [];
            this.States(labelID)    = [];
            updateView(this);
        end
        
        %------------------------------------------------------------------
        function onLabelModified(this, labelID, newName)
            assert(labelID >0 && labelID <= this.NumLabels);
            
            this.Names{labelID} = newName;
            updateView(this);
        end
    end
    
    methods
        
        %------------------------------------------------------------------        
        function  setAxes(this, axes)
            this.Axes = axes;
        end
        
        %------------------------------------------------------------------
        function num = get.NumLabels(this)
            num = numel(this.Names);
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function updateView(this)
            
            if ~isvalid(this.Figure)
                return;
            else
                if ~this.hasValidAxes()
                    this.Axes = this.Figure.CurrentAxes;
                    if ~this.hasValidAxes()
                        return;
                    end
                end
            end
         
            % Draw patches
            hAx = this.Axes;
            
            % Recreate the patches
            removePatches(this);
            
            for n = 1 : this.NumLabels
                this.Patches(n) = patch(nan, nan, this.Colors(n,:), 'Parent', hAx);
                this.Patches(n).Tag = 'InvisiblePatch';
            end
            

            if this.ShowLabel                
                if this.NumLabels > 0
                    % Only create legend when there are labels
                    % Disable auto update to avoid showing other ROI's 
                    this.Legend = legend(hAx, this.Patches, this.Names, ...
                        'Location', 'northeastoutside', 'Autoupdate','off');
                    % Place legend                    
                    this.Legend.Title.String        = vision.getMessage('vision:labeler:FrameLabel');
                    this.Legend.PickableParts       = 'none';
                    this.Legend.HitTest             = 'off';
                    this.Legend.HandleVisibility    = 'off';
                    this.Legend.Interpreter         = 'none';
                    this.Legend.Box                 = 'off';
                    this.Legend.Visible = 'on';
                else
                    this.removeLegend();
                end
            end
            updateStates(this);
        end
        
        %------------------------------------------------------------------
        function updateStates(this)
            
            % Update states only if there are valid patches to act on.
            if isempty(this.Patches) || any(~isvalid(this.Patches))
                return;
            end
            
            for n = 1 : this.NumLabels
                if this.States(n)
                    this.Patches(n).FaceColor = this.Colors(n,:);
                else
                    this.Patches(n).FaceColor = [1 1 1];
                end
            end
        end
        
        %------------------------------------------------------------------
        function tf = hasValidAxes(this)
            hAx = this.Axes;
            tf = ~isempty(hAx) && isvalid(hAx);
        end
         
        %------------------------------------------------------------------       
        function removeLegend(this)
            if isa(this.Legend, 'matlab.graphics.illustration.Legend')
                legend(this.Axes,'off');
            end
        end
        
        %------------------------------------------------------------------        
        function removePatches(this)
            % Remove patches from axes, populate it with empty gobjects
            % to reset the index.
            delete(this.Patches);
            this.Patches = repmat(gobjects,0,0);
        end
    end
end