classdef ReprojectionErrorsDisplay < vision.internal.uitools.AppFigure
    % ReprojectionErrorsDisplay encapsulates the reprojection errors figure for the
    % Camera Calibrator and the Stereo Camera Calibrator
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties
        Axes = [];
        Tag = 'ReprojectionErrorsAxes';
        ViewSwitchBtn;
        LegendPositionBar = [];        
        IsViewChanged = false;
        Slider = [];
    end
    
    events
        ErrorPlotChanged
    end
    
    methods
        %------------------------------------------------------------------
        function this = ReprojectionErrorsDisplay()
            title = getString(message('vision:caltool:ErrorsFigure'));
            this = this@vision.internal.uitools.AppFigure(title);
        end
        
        %------------------------------------------------------------------
        function createAxes(this)
            this.Axes = axes('Parent', this.Fig,...
                'tag', this.Tag);
        end
        
        %------------------------------------------------------------------
        function tf = isAxesValid(this)
            tf = ~(isempty(this.Axes) || ~ishandle(this.Axes));
        end
        
        %------------------------------------------------------------------
        function plot(this, cameraParams, highlightIndex, clickBarFcn, ...
                clickSelectedBarFcn)
            if ~ishandle(this.Axes)
                createAxes(this);
            end
            
            if ~this.IsViewChanged
                % If the view has changed, then legend position is already
                % saved. If we save it again it will be saved under the
                % wrong view.
                this.saveLegendPosition();
            end
            this.IsViewChanged = false;
            
            showReprojectionErrors(cameraParams, 'BarGraph', 'Parent', ...
                this.Axes, 'HighlightIndex', highlightIndex);
            set(this.Axes, 'Tag', this.Tag);
            
            this.restoreLegendPosition();
            
            % The title of the figure is set by showReprojectionErrors().
            % Setting it to empty, because it is redundant in the
            % context of the app.
            title(this.Axes, '');
            set(this.Fig, 'HandleVisibility', 'callback');
            
            createSlider(this);
            
            setBarClickCallbacks(this, clickBarFcn, clickSelectedBarFcn)
        end
        
        %------------------------------------------------------------------
        function saveLegendPosition(this)
            hLegend = findobj(this.Fig, 'Type', 'Legend');
            if ishandle(hLegend)                
                this.LegendPositionBar = get(hLegend, 'Position');
            end
        end
        
        %------------------------------------------------------------------
        function restoreLegendPosition(this)
            hLegend = findobj(this.Fig, 'Type', 'Legend');
            if ~isempty(this.LegendPositionBar)
                set(hLegend, 'Position', this.LegendPositionBar);
            end
        end
        
        %------------------------------------------------------------------
        function indx = getSelected(this)
            hiliteBarPlot = findobj(this.Axes.Children,'Tag','highlightedBars');
            indx = find(hiliteBarPlot(1).YData~=0);
            
        end
        
        %------------------------------------------------------------------
        function updateSelection(this,highlightIndices)
            % only updates index without reploting the entire axes.
            % remove all highlightings
            hObjHilited = findobj(this.Fig,...
                '-regexp','tag','highlightedBars');
            for i = 1:numel(hObjHilited)
                hObjHilited(i).YData =  0*hObjHilited(i).YData;
            end
            
            hObjNormal = findobj(this.Fig,...
                '-regexp','tag','errorBars');
            for i = 1:numel(hObjHilited)
                hObjHilited(i).YData(highlightIndices) = hObjNormal(i).YData(highlightIndices);
            end
            
        end
        %------------------------------------------------------------------        
        function [loc,isLine] = getSliderState(this)
            if ~isempty(this.Slider)
                [loc,isLine] = getState(this.Slider);
            else
                loc = 0;
                isLine = false;
            end
        end
        
        %------------------------------------------------------------------
        function setBarClickCallbacks(this, clickBarFcn, clickSelectedBarFcn)            
            % enable click-ability for the bar graph
            fig = this.Fig;
            hBar = findobj(fig, 'tag', 'errorBars');
            set (hBar,'buttondownfcn', clickBarFcn);
            hSelectedBar = findobj(fig, 'tag', 'highlightedBars');
            set(hSelectedBar, 'buttondownfcn', clickSelectedBarFcn);

        end
        
        %------------------------------------------------------------------
        function [clickedIdx, selectionType] = getSelection(this, h)
            % return the index of the bar that was clicked
            pt = get(get(h, 'Parent'), 'CurrentPoint');
            pt = pt(1, 1);
            
            % find the bar whose center is nearest to the click point
            barCenters = get(h, 'XData');
            [~, clickedIdx] = min(abs(barCenters - pt));
            
            selectionType = get(this.Fig, 'SelectionType');
        end
        
        %------------------------------------------------------------------
        function createSlider(this)
            % Create the sliding line at maximum error level.            
            
            % Find the maximum error
            hBar = findobj(this.Axes, 'tag', 'errorBars');
            maxBar = max([hBar.YData]);
            
            % Create the threshold line
            this.Slider = vision.internal.calibration.tool.SelectionLine(this.Axes,maxBar,...
                0,maxBar);
            
            % Enable customized cursor icon.
            iptPointerManager(this.Fig);            
            enterFcn = @(lineobj, currentPoint)...
                set(lineobj, 'Pointer', 'fleur');
            iptSetPointerBehavior(this.Slider.Group,enterFcn);
            
            % Setup the drag callbacks
            registerCallback(this);
        end
        
        %------------------------------------------------------------------
        function restoreSliderState(this,loc,dirty)
            %restore the slider state when necessary.
            restoreState(this.Slider,loc,dirty);
        end
        
        %------------------------------------------------------------------
        function registerCallback(this)
            % Register Button down callback only.
            set(this.Slider.Group,...
                'ButtonDownFcn',@(es,ev)doLineBtnDown(es,ev),...
                'BusyAction','cancel');            
            
            function doLineBtnDown(es,~)
                % Register dragging callback and done dragging callback
                set(es.Parent.Parent,...
                    'windowbuttonmotionfcn',@(es,ev)this.doDragLine(es,ev),...
                    'BusyAction','cancel');                
                set(es.Parent.Parent,...
                    'windowbuttonupfcn',@(es,ev)this.doDragDone(es,ev),...
                    'BusyAction','cancel');
            end
        end
        
        %------------------------------------------------------------------
        function doDragLine(this,~,~)
            % Lock the customized cursor while we are moving.
            iptPointerManager(this.Fig,'disable');

            % Switch to line style when starts dragging.
            this.Slider.switchToLine();            
            
            % update location
            clicked=get(this.Axes,'currentpoint');
            
            % Update Line's location
            ycoord=clicked(1,2,1);
            
            this.Slider.setSliderLocation(ycoord);
            
        end
        
        %------------------------------------------------------------------
        function doDragDone(this,es,~)
            % Reset motion and ButtonUp callbacks
            set(es,'windowbuttonmotionfcn','')
            set(es,'windowbuttonupfcn','')
            
            %re-enable customized pointer.
            iptPointerManager(this.Fig,'enable');
            
            % highlight the selections if user has moved the line
            [~,wasLine] = getState(this.Slider);
            if wasLine
                hline = findobj(es,'Tag','ThresholdLine');
                updateReprojectionThreshold(this,hline.YData(1)-eps,es);
            end
        end
        
        %------------------------------------------------------------------
        function resetSlider(this)
            % Routine to reset slider to the maximum error level.
            if ~isempty(this.Slider)
                reset(this.Slider);
            end
        end
        
        %------------------------------------------------------------------
        function updateReprojectionThreshold(this,val,es)            
            % Update threshold on reprojection barplot            
            barPlot = findobj(es.CurrentAxes.Children,'Tag','errorBars');
            
            % Highlight all outliers to be removed
            outlierIdx = mod(find([barPlot.YData] >= val),numel(barPlot.YData));
            outlierIdx = unique(outlierIdx);
            outlierIdx(outlierIdx==0) = numel(barPlot.YData);
            if numel(outlierIdx) <= 0
                % nothing will be selected
                return;
            end
            this.updateSelection(outlierIdx);
            % Notify the App that error plot has changed.
            this.notify('ErrorPlotChanged');
            
            drawnow('limitrate');
        end
        
    end
end