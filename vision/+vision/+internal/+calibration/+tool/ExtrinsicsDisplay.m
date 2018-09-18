classdef ExtrinsicsDisplay < vision.internal.uitools.AppFigure
    % ExtrinsicsDisplay enapsulates the extrinsics figure for the Camera
    % Calibrator and the Stereo Camera Calibrator.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties
        View = 'CameraCentric';
        Axes = [];
        Tag = 'ExtrinsicsAxes';
        ViewSwitchBtn;
        Azimuth = 322;
        Elevation = 30;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExtrinsicsDisplay()
            title = vision.getMessage('vision:caltool:ExtrinsicsFigure');
            this = this@vision.internal.uitools.AppFigure(title);
        end
        
        %------------------------------------------------------------------
        function tf = isAxesValid(this)
            tf = ~(isempty(this.Axes) || ~ishandle(this.Axes));
        end
        
        %------------------------------------------------------------------
        function createAxes(this, cameraCentricFcn, patternCentricFcn)
            this.Axes = axes('Parent', this.Fig,...
                'tag', this.Tag);
            
            % Create space between the axes and the switch button
            set(this.Axes, 'Position', [0.15, 0.2, 0.75, 0.72] );
            
            hRotate = rotate3d(this.Fig);
            set(hRotate, 'Enable', 'on');
            
            % set ButtonDownFilter Callback
            set(hRotate,'ButtonDownFilter',@rotateDecisionCallback);
            
            view(this.Axes, this.Azimuth, this.Elevation);
            
            this.addViewSwitchButton(cameraCentricFcn, patternCentricFcn);
            
            %--------------------------------------------------------------
            % ButtonDownFilter Callback to decide whether to rotate or
            % enable click
            function flag = rotateDecisionCallback(hObject,~)
                
                objTag = get(hObject,'Tag');
                
                if isempty(regexp(objTag,'\w*ExtrinsicsObj\w*','once'))
                    flag = false;
                else
                    flag = true;
                end
            end
            
        end
        
        function updateSelection(this,highlightIndices)
            if ~ishandle(this.Axes)
                % Axes not showing.
                return;
            end
            
            % only updates index without reploting the entire axes.
            % remove all highlightings
            hObjHilited = findobj(this.Fig,...
                '-regexp','tag','HighlightedExtrinsicsObj');
            for i = 1:numel(hObjHilited)
                hObjHilited(i).Tag = strrep(hObjHilited(i).Tag,...
                    'Highlighted','');
                if strcmpi(this.View,'CameraCentric')
                    hObjHilited(i).FaceAlpha = 0.2;
                else
                    % pattern centric, path objects
                    hObjPatches = findobj(hObjHilited(i),'Type','Patch');
                    set(hObjPatches,'FaceAlpha',0.2);
                end
            end
            
            highlightTag = arrayfun(@(x)sprintf('ExtrinsicsObj%d',x),...
                highlightIndices,'UniformOutput',false);
            hObjToChange = cellfun(@(x)findobj(this.Fig,'tag',x),...
                highlightTag,'UniformOutput',false);
            
            if strcmpi(this.View,'CameraCentric')
                cellfun(@(x)changeAlphaCameraCentric(x),hObjToChange);
            else
                hObjPatches = cellfun(@(x)findobj(x,'Type','Patch'),...
                    hObjToChange,'UniformOutput',false);
                cellfun(@(x)changeAlphaPatternCentric(x),hObjPatches);
            end
            
            % Update object's tag
            cellfun(@(x)changeHighlightTag(x),hObjToChange);
            
            function changeHighlightTag(x)
                arrayfun(@(y)set(y,'Tag',['Highlighted' y.Tag]),x);
            end
            function changeAlphaCameraCentric(x)
                x.FaceAlpha = 0.8;
            end
            
            function changeAlphaPatternCentric(x)
                arrayfun(@(y)set(y,'FaceAlpha',0.8),x);
            end
            
        end
        %------------------------------------------------------------------
        function plot(this, cameraParams, highlightIndex, ...
                clickFcn, clickSelectedFcn)
            if ~ishandle(this.Axes)
                createAxes(this);
            else
                [this.Azimuth, this.Elevation] = view(this.Axes);
            end
            
            showExtrinsics(cameraParams, this.View, ...
                'Parent', this.Axes, 'HighlightIndex', highlightIndex);
            
            % The title of the figure is set by showExtrinsics().
            % Setting it to empty, because it is redundant in the
            % context of the app.
            title(this.Axes, '');
            
            view(this.Axes, this.Azimuth, this.Elevation);
            
            % reset the view originally stored by rotate3d so that 
            % double-clicking in the plot does not distort the plot's
            % limits; the reset is accomplished by re-saving the current
            % view
            resetplotview(this.Axes,'SaveCurrentView');
            
            set(this.Axes, 'Tag', this.Tag); % plotting resets the tag
            this.lockFigure();
            
            setBoardClickCallbacks(this, clickFcn, clickSelectedFcn);
            drawnow();
        end
        
        %------------------------------------------------------------------
        function addViewSwitchButton(this, cameraCentricFcn, patternCentricFcn)
            this.ViewSwitchBtn = vision.internal.calibration.tool.ToggleButton;
            this.ViewSwitchBtn.Parent = this.Fig;
            this.ViewSwitchBtn.UnpushedName = ...
                vision.getMessage('vision:caltool:ShowPatternCentricViewButton');
            this.ViewSwitchBtn.UnpushedToolTip = ...
                vision.getMessage('vision:caltool:ShowPatternCentricViewToolTip');
            this.ViewSwitchBtn.PushedName = ...
                vision.getMessage('vision:caltool:ShowCameraCentricViewButton');
            this.ViewSwitchBtn.PushedToolTip = ...
                vision.getMessage('vision:caltool:ShowCameraCentricViewToolTip');
            this.ViewSwitchBtn.Tag = 'ExtrinsicButton';
            this.ViewSwitchBtn.Position = [5 5 180 20];
            this.ViewSwitchBtn.UnpushedFcn = cameraCentricFcn;
            this.ViewSwitchBtn.PushedFcn = patternCentricFcn;
            create(this.ViewSwitchBtn);
        end
        
        %------------------------------------------------------------------
        function switchView(this, newView)
            this.View = newView;
        end
        
        %------------------------------------------------------------------
        function setBoardClickCallbacks(this, clickFcn, clickSelectedFcn)
            % Find all non-highlighted cameras and set click callback
            hExtrinsicsObj = findobj(this.Fig, ...
                '-regexp','Tag','ExtrinsicsObj*');
            for i = 1:numel(hExtrinsicsObj)
                set (hExtrinsicsObj(i),'ButtonDownFcn', clickFcn);
            end
            
            % Find all highlighted cameras and set click callback
            hSelectedExtrinsicsObj = findobj(this.Fig,...
                '-regexp','tag', 'HighlightedExtrinsicsObj*');
            for i = 1:numel(hSelectedExtrinsicsObj)
                set(hSelectedExtrinsicsObj(i), 'ButtonDownFcn', clickSelectedFcn);
            end
        end
        
        %------------------------------------------------------------------
        function [clickedIdx, selectionType] = getSelection(this, h)
            extrinsicsTag = get(h,'Tag');
            clickedIdx = str2double(extrinsicsTag(numel('HighlightedExtrinsicsObj')+1:end));
            if isnan(clickedIdx)
                clickedIdx = str2double(extrinsicsTag(numel('ExtrinsicsObj')+1:end));
            end
            selectionType = get(this.Fig, 'SelectionType');
        end
    end
end