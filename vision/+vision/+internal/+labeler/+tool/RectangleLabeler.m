% This class deals with marking an image with rectangle label types.
classdef RectangleLabeler < vision.internal.labeler.tool.ROILabeler
    
    properties
        
        Rectangles
        
        %CurrentROIs Currently drawn ROIs
        CurrentROIs = {};
        
        %UndoRedoManager
        UndoRedoManager
        
        %CurrentImageIndex
        CurrentImageIndex
    end
    
    properties(Dependent)
        %SelectedROIs The selected ROIs
        SelectedROIs
    end
    
    methods
        
        function this = RectangleLabeler(copyCallback, cutCallback, undoMngr)
            this.CopyCallbackFcn = copyCallback;
            this.CutCallbackFcn  = cutCallback;
            this.UndoRedoManager = undoMngr;
        end
        
        %------------------------------------------------------------------
        function drawLabels(this, data)
            % Draw all the interactive rects.
            drawInteractiveROIs(this, data.Positions, data.Names, data.Colors, data.Shapes);
        end
        
        %------------------------------------------------------------------
        function wipeROIs(this)
            
            % Delete currentROIs
            for n = 1 : numel(this.CurrentROIs)
                delete(this.CurrentROIs{n});
            end
            this.CurrentROIs = {};
            
        end
        %------------------------------------------------------------------
        function rois = getSelectedROIsForCopy(this)
            % returns the selected ROIs
            rois = {};
            for i = 1:numel(this.CurrentROIs)
                if this.CurrentROIs{i}.IsValid && this.CurrentROIs{i}.IsSelected
                    rois{end+1} = this.CurrentROIs{i}.CopiedData; %#ok<AGROW>
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function deleteSelectedROIs(this, varargin)
            
            % Delete ROIs first.
            numROIs = numel(this.CurrentROIs);
            isDeleted = false(1, numROIs);
            for i = 1:numROIs
                if this.CurrentROIs{i}.IsSelected
                    delete(this.CurrentROIs{i});
                    isDeleted(i) = true;
                end
            end
            this.CurrentROIs = this.CurrentROIs(~isDeleted);
            
            % Then initialize the undo buffer.
            initializeUndoBuffer(this);
            
            evtData = this.makeRectangleROIEventData(this.CurrentROIs);
            notify(this, 'LabelIsChanged', evtData)
        end
        
        %------------------------------------------------------------------
        function pasteSelectedROIs(this, CopiedRectROIs)
            
            % initialize Undo buffer before the changes in ROI
            initializeUndoBuffer(this); 
            
            [y_extent, x_extent, ~] = size(get(this.ImageHandle,'CData'));
            constraint_fcn = makeConstrainToRectFcn('imrect',...
                [1 x_extent+1], [1 y_extent+1]);
            
            % Offsets needed for pasting in case of overlap
            Xoffset = round(x_extent/100 + 1);
            Yoffset = round(y_extent/100 + 1);
            offset(1,:) = [ Xoffset,  Yoffset, 0, 0];
            offset(2,:) = [-Xoffset, -Yoffset, 0, 0];
            offset(3,:) = [ Xoffset, -Yoffset, 0, 0];
            offset(4,:) = [-Xoffset,  Yoffset, 0, 0];
            
            numROIs = numel(CopiedRectROIs);
            
            currentRectROIs = zeros(0, 4);
            if numROIs > 0
                for i = 1:numel(this.CurrentROIs)
                    if this.CurrentROIs{i}.IsValid && size(this.CurrentROIs{i}.Position, 2) == 4
                        this.CurrentROIs{i}.IsSelected = false;
                        currentRectROIs(end+1, :) = this.CurrentROIs{i}.BBox + [0.5 0.5 0 0]; %#ok<AGROW>
                    end
                end
                
            else
                return;
            end
            
            
            numPastedROIs = 0;
            for i = 1:numROIs
                boxPoints = CopiedRectROIs{i}.bbox;
                
                % Pasting between images of different sizes. Move box to
                % inside of image if it is outside the right or bottom
                % boundary.
                if (boxPoints(1) > x_extent)
                    boxPoints(1) = x_extent - boxPoints(3) + 1;
                end
                
                if (boxPoints(2) > y_extent)
                    boxPoints(2) = y_extent - boxPoints(4) + 1;
                end
                
                % findPlaceToPaste will find a location in case when
                % boxPoints is much bigger than the destination image. Even
                % if boxPoints(1:2) are negative.
                
                boxPoints(3) = min(boxPoints(3), x_extent+1-boxPoints(1));
                boxPoints(4) = min(boxPoints(4), y_extent+1-boxPoints(2));
                
                % Offset code
                offsetIndex = 1;
                if ~isempty(currentRectROIs)
                    % Check if pasted ROI overlaps with existing ROIs
                    if ~isempty(intersect(currentRectROIs,boxPoints,'rows'))
                        lastToLastPoints = [NaN NaN NaN NaN];
                        lastPoints = boxPoints;
                        try
                            % Find a place to paste since there is overlap
                            findPlaceToPaste();
                        catch
                            % No place found, do not paste ROI
                            boxPoints = [];
                        end
                    end
                end
                
                if ~isempty(boxPoints)
                    eroi = this.drawEnhancedROI(CopiedRectROIs{i}, boxPoints, true);
                    this.CurrentROIs{end+1} = eroi;
                    numPastedROIs = numPastedROIs + 1;
                end
            end
            
            if numPastedROIs > 0
                % Update the session
                evtData = this.makeRectangleROIEventData(this.CurrentROIs);
                notify(this, 'LabelIsChanged', evtData);
            end
            
            %-------------------------------------------------------
            % Recursive function to look for a place to paste
            function findPlaceToPaste()
                
                % Add offset and check if within bounds
                newBoxPoints = boxPoints + offset(offsetIndex,:);
                if ~isequal(constraint_fcn(newBoxPoints), newBoxPoints)
                    
                    % Outside bounds, so change offset direction and keep
                    % looking for a place
                    offsetIndex = offsetIndex + 1;
                    if offsetIndex==5
                        offsetIndex = 1;
                    end
                    findPlaceToPaste();
                else
                    
                    % Check if we are have already been at the current
                    % location before (this check is needed to avoid
                    % getting stuck in an infinite loop)
                    if ~isequal(lastToLastPoints,newBoxPoints)
                        
                        % If there is no overlap, then we have found a
                        % place to paste. This is the only point of return
                        % from this recursive function
                        if ~isempty(intersect(currentRectROIs,boxPoints,'rows'))
                            
                            % We still have overlap, update previous
                            % locations, and keep looking for a place
                            boxPoints = newBoxPoints;
                            lastToLastPoints = lastPoints;
                            lastPoints = boxPoints;
                            findPlaceToPaste();
                        end
                    else
                        
                        % We have been here before, so change direction
                        % and keep looking for a place
                        offsetIndex = offsetIndex + 1;
                        if offsetIndex==5
                            offsetIndex = 1;
                        end
                        findPlaceToPaste();
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function selectAll(this)
            for i = 1:numel(this.CurrentROIs)
                this.CurrentROIs{i}.IsSelected = true;
            end
        end
    end
    
    %----------------------------------------------------------------------
    % Undo/Redo
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function flag = shouldResetUndoRedo(this)
            % Undo/Redo should be reset if time index has changed.
            currentIndex = this.CurrentImageIndex;
            if this.UndoRedoManager.isUndoStackEmpty()
                flag = true;
            else
                % Look at the the stack and see what index is there
                timeIndex = this.UndoRedoManager.undoStack{end}.TimeIndex;
                flag = (timeIndex ~= currentIndex);
            end
        end
        
        %------------------------------------------------------------------
        function updateInteractiveROIsForUndoRedo(this)

            if this.shouldResetUndoRedo()
                % you had some ROIs in a frame; you moved to a different
                % frame and did ctrl+z.
                this.UndoRedoManager.resetUndoRedoBuffer();
                addAllCurrentROILabelsToUndoStack(this);
            else
                rois = this.UndoRedoManager.undoStack{end};
                data.labelPositions = rois.LabelPositions;
                data.labelNames = rois.LabelNames;
                data.labelColors = rois.LabelColors;
                data.labelShapes = rois.LabelShapes;
                                
                % Redraw - wipe current labels, then re-draw.
                 wipeROIs(this);
                 drawInteractiveROIs(this, data.labelPositions, ...
                     data.labelNames, data.labelColors, data.labelShapes);
                 evtData = this.makeRectangleROIEventData(this.CurrentROIs);
                 
                 notify(this, 'LabelIsChanged', evtData)
                
                 % Push new state into undo/redo stack.
                 this.addROILabelsToUndoStack(this.CurrentImageIndex, evtData);
            end
        end
        
        %------------------------------------------------------------------
        function addAllCurrentROILabelsToUndoStack(this)

            roiAnnotations = this.reformatCurrentROIs(this.CurrentROIs);
            
            % Get current ROIs
            % For other labelers, we will have to combine data from each
            % labeler before pushing into undo stack.
            labelNames = {roiAnnotations.Label};
            labelPositions = {roiAnnotations.Position};
            labelColors = {roiAnnotations.Color};
            labelShapes = [roiAnnotations.Shape];
            
            % Get index of the current image.
            index = this.CurrentImageIndex;
            
            % save ALL the rois on the image (snapshot of current state of ROIs)
            this.UndoRedoManager.executeCommand(...
                vision.internal.labeler.tool.ROIUndoRedoParams(...
                index, labelNames, labelPositions, labelColors, labelShapes));
        end
        
        %------------------------------------------------------------------
        function initializeUndoBuffer(this)
            % NOTE:
            % We need to save the current status of imae before any changes
            % for ROI happens. Changes in ROI can happen in the following
            % ways:
            % (A)
            % ctrl+x (with ctrl+A) : to cut ROIS
            % ctrl+v (with ctrl+A) : to paste ROIS
            % - Above two events are triggered by KEYBOARD button down
            %   triggered from doFigKeyPress in VideoLabelingTool. This function calls
            %   this.VideoDisplay.cutSelectedROIs() and
            %   this.VideoDisplay.pasteSelectedROIs();
            % These two functions call initializeUndoBuffer function
            % (B)
            % By mouse click on image and add/modify/delete of ROI labels.
            % This event is captured in onButtonDown@VideoDisplay.m
            if this.shouldResetUndoRedo()
                this.UndoRedoManager.resetUndoRedoBuffer();
            end
            this.addAllCurrentROILabelsToUndoStack();
        end
        
        %------------------------------------------------------------------
        function addROILabelsToUndoStack(this, index, evtData)
            
            % Unpack event data.
            roiLabelData = evtData.Data;
            labelNames     = {roiLabelData.Label};
            labelPositions = {roiLabelData.Position};
            labelColors    = {roiLabelData.Color};
            labelShapes    = [roiLabelData.Shape];
            
            % this is triggered AFTER any change for the LabelIsChanged
            % callback.
            if this.shouldResetUndoRedo()
                this.UndoRedoManager.resetUndoRedoBuffer();
            end
            
            % save ALL the rois on the image (snapshot of current state of
            % ROIs)
            this.UndoRedoManager.executeCommand(...
                vision.internal.labeler.tool.ROIUndoRedoParams(...
                index, labelNames, labelPositions, labelColors, labelShapes));
            
            data = vision.internal.labeler.tool.UndoRedoStateEvent(...
                this.canUndo(), ...
                this.canRedo());
            
            notify(this, 'UpdateUndoRedoQAB', data);
            
        end
        
        %------------------------------------------------------------------
        function undo(this)
            if(this.canUndo())
                this.UndoRedoManager.undo();
                this.updateInteractiveROIsForUndoRedo();
            end
        end
        
        %------------------------------------------------------------------
        function redo(this)
            if(this.canRedo())
                this.UndoRedoManager.redo();
                this.updateInteractiveROIsForUndoRedo();
            end
        end
        
        %------------------------------------------------------------------
        function showROILabelNames(this, showROILabelFlag)
            this.ShowLabelName = showROILabelFlag;
            
            for i = 1:numel(this.CurrentROIs)
                this.CurrentROIs{i}.setTextLabelVisible(showROILabelFlag);
            end
        end
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function TF = canUndo(this)
            TF = this.UndoRedoManager.isUndoAvailable();
        end
        
        %------------------------------------------------------------------
        function TF = canRedo(this)
            TF = this.UndoRedoManager.isRedoAvailable();
        end
        
        %------------------------------------------------------------------
        function onButtonDown(this, varargin)
           
            mouseClickType = get(this.Figure,'SelectionType');
            
            this.deselectAllROIs();
            
            switch mouseClickType
                case 'normal'
                    % initialize Undo buffer before the changes in ROI
                    initializeUndoBuffer(this);
                    
                    roi = vision.internal.uitools.imrectButtonDown.drawROI(this.ImageHandle);
                    if vision.internal.uitools.imrectButtonDown.isValidROI(roi)
                        enhancedROI = this.drawEnhancedROI(roi);
                        this.CurrentROIs{end+1} = enhancedROI;
                        
                        evtData = this.makeRectangleROIEventData(this.CurrentROIs);
                        notify(this, 'LabelIsChanged', evtData);
                        
                        this.addROILabelsToUndoStack(this.CurrentImageIndex, evtData);
                        
                    end
                    
                case 'open'
                    % add full image ROI
                    imSize = size(this.ImageHandle.CData);
                    roiPos = [ 1 1 imSize(2) imSize(1) ];
                    roi = iptui.imcropRect(this.AxesHandle, roiPos, this.ImageHandle);
                    enhancedROI = this.drawEnhancedROI(roi);
                    this.CurrentROIs{end+1} = enhancedROI;

                    evtData = this.makeRectangleROIEventData(this.CurrentROIs);
                    notify(this, 'LabelIsChanged', evtData);

                    this.addROILabelsToUndoStack(this.CurrentImageIndex, evtData);                    
            end

          
        end
        
        %------------------------------------------------------------------
        function evtData = makeRectangleROIEventData(this, data)

            rois = this.reformatCurrentROIs(data);
            
            evtData = vision.internal.labeler.tool.ROILabelEventData(rois);
            
        end
        
        %------------------------------------------------------------------
        function drawInteractiveROIs(this, roiPositions, labelNames, colors, shapes)
            % Draw new ROIs
            for n = 1: numel(roiPositions)
                if shapes(n) == labelType.Rectangle
                    roiPos = roiPositions{n};
                    for rectRoiInx=1:size(roiPos, 1)
                        eroi = makeEnhancedROI(this, roiPos(rectRoiInx, :), labelNames{n}, colors{n});
                        this.CurrentROIs{end+1} = eroi;
                    end
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function deselectAllROIs(this)
            for i = 1:numel(this.CurrentROIs)
                this.CurrentROIs{i}.IsSelected = false;
            end
        end
        
        %------------------------------------------------------------------
        function eroi = makeEnhancedROI(this, rois, labelName, color)
            %Make enhanced ROI based on shape
            dummyIdx = 1;
            
            contextMenuDelete = true;
            fireEventOnSelection = true;
            eroi = vision.internal.cascadeTrainer.tool.EnhancedROI(...
                rois, this.AxesHandle, this.ImageHandle, this.Figure, dummyIdx, color, labelName, this.ShowLabelName, contextMenuDelete, fireEventOnSelection);
            addlistener(eroi, 'Delete', @(src,evtdata)onROIDeleted(this, src, evtdata));
            
            addlistener(eroi, 'Selected', @(src, ~) onROISelection(this, src));
            addlistener(eroi, 'Move', @this.onMove);
            addlistener(eroi, 'Copy', @this.CopyCallbackFcn);
            addlistener(eroi, 'Cut', @this.CutCallbackFcn);
        end
        
        %------------------------------------------------------------------
        function eroi = drawEnhancedROI(this, roi, boxPoints, isSelected)
            
            %EnhancedROI stores label ID's as well. We don't need this, so we pass a dummy ID.
            dummyIdx = 1;
            if nargin>2
                % The four input API is used by the paste logic to paste a
                % copied ROI onto a new position.
                eroi = vision.internal.cascadeTrainer.tool.EnhancedROI(boxPoints,...
                    this.AxesHandle, this.ImageHandle, this.Figure, dummyIdx, ...
                    roi.color, roi.categoryName, this.ShowLabelName, true, true);
            else
                eroi = vision.internal.cascadeTrainer.tool.EnhancedROI(roi, ...
                    this.AxesHandle, this.ImageHandle, this.Figure, dummyIdx, ...
                    this.SelectedLabel.Color, this.SelectedLabel.Label, this.ShowLabelName, true, true);
                isSelected = false;
            end
            
            addlistener(eroi, 'Selected', @(src, ~) onROISelection(this, src));
            addlistener(eroi, 'Delete', @(src,evtdata)onROIDeleted(this, src, evtdata));
            addlistener(eroi, 'Move', @this.onMove);
            addlistener(eroi, 'Copy', @this.CopyCallbackFcn);
            addlistener(eroi, 'Cut', @this.CutCallbackFcn);
            
            eroi.IsSelected = isSelected;
        end
        
        %------------------------------------------------------------------
        function onMove(this, varargin)
            evtData = this.makeRectangleROIEventData(this.CurrentROIs);
            notify(this, 'LabelIsChanged', evtData)
            
            % Push new state into undo/redo stack.
            this.addROILabelsToUndoStack(this.CurrentImageIndex, evtData);
        end
        
        %------------------------------------------------------------------
        function onROISelection(this, eroi)
            %For every other roi widget which happens to be selected,
            %unselect it
            numROIs = numel(this.CurrentROIs);
            for i = 1:numROIs
                roi = this.CurrentROIs{i};
                if ((eroi ~= roi) && roi.IsSelected)
                    roi.IsSelected = false;
                end
            end
        end
        
        %------------------------------------------------------------------
        function onROIDeleted(this, ~, evtData)
            
            if evtData.WasSelected
                deleteSelectedROIs(this);
            else
                evtData = this.makeRectangleROIEventData(this.CurrentROIs);
                notify(this, 'LabelIsChanged', evtData);
                
                % Push new state into undo/redo stack.
                this.addROILabelsToUndoStack(this.CurrentImageIndex, evtData);
            end
        end
        
        
        
        %------------------------------------------------------------------
        function rois = reformatCurrentROIs(~, data)
            isValid = cellfun(@(r)r.IsValid, data);
            
            rois = repmat(struct('Label',[],'Position',[],'Color',[],'Shape',labelType.empty),...
                nnz(isValid),1);
            idx = 1;
            for n = 1 : numel(data)
                if data{n}.IsValid
                    rois(idx).Label     = data{n}.CopiedData.categoryName;
                    rois(idx).Position  = data{n}.CopiedData.Position;
                    rois(idx).Color     = data{n}.CopiedData.color;
                    rois(idx).Shape     = labelType.Rectangle;
                    idx = idx+1;
                end
            end
        end
    end
    
end