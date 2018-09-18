% Class defines panel that hold image.

% Copyright 2017 The MathWorks, Inc.
classdef ImagePanel < handle
    properties(Access = private)
        % Figure Parent figure for image panel.
        Figure
        
        % Panel The panel containing the widgets related to showing the
        % full image selected in the browser (along with all the
        % annotations).
        Panel
        
        % ImageAxes A handle to the axes that contains the image.
        ImageAxes
        
        % Image A handle to the curent displayed image object.
        Image
        
        % CurrentImageFilename A char vec holding the current image on
        %                      display. Used to avoid reading re-displaying
        %                      image.
        CurrentImageFilename
        
        %LabelingMode Rectangle, PixelLabel, ...
        LabelingMode
        
        %Clipboard
        Clipboard
        
        %ContextMenuCache
        ContextMenuCache
        
        % Patch for Brush Marker Size
        BrushMarker
        
    end
    
    properties
        PixelLabeler
        RectangleLabeler
        
        %Labler Active labeler.
        Labeler
        
        %CurrentImageIndex Index of the displayed image.
        CurrentImageIndex
        
        % Mode Either ROI, none, Pan, ZoomIn, ZoomOut
        Mode
    end
    
    properties(Access = private)
        RectangleUndoRedoManager
    end
    
    
    properties(Dependent)
        Position
        UserIsDrawing
    end
    
    events
        RequestForModeChange
       
    end
    
    methods
        function this = ImagePanel(fig)
            this.Figure = fig;
            this.Figure.WindowScrollWheelFcn = @this.zoomCallback;
            
            this.Panel = uipanel('Parent', this.Figure,...
                'Units', 'pixels',...
                'BorderType', 'none', ...
                'Tag', 'Image');
            
            this.ImageAxes = axes(this.Panel, 'Visible', 'off', ...
                'Units', 'Normalized','Position', [0 0 1 1], ...
                'Tag', 'ImageLabelerImageAxes');
            
            this.CurrentImageFilename = '';
            
            this.Clipboard = vision.internal.labeler.tool.ROILabelerClipBoard();
            
            % Create managers for undo/redo. Labelers can share an
            % undo/redo stack or use separate ones. Here pixel labeler and
            % rectangle labeler use different stacks.
            this.RectangleUndoRedoManager = vision.internal.labeler.tool.UndoRedoManager();
            
            this.PixelLabeler = vision.internal.labeler.tool.PixelLabeler();
            setHandles(this.PixelLabeler,this.Figure,this.ImageAxes,this.Image);
            setBrushMarker(this);
            this.RectangleLabeler = vision.internal.labeler.tool.RectangleLabeler(...
                @this.copySelectedROIs, @this.cutSelectedROIs, this.RectangleUndoRedoManager);
            
            % Pixel labeler needs to send updated image for display.
            addlistener(this.PixelLabeler, 'ImageIsChanged', @(~,evt) this.drawImage(evt.Data));
        end
        
        %------------------------------------------------------------------
        function enableDrawing(this)
            % enable drawing by activating labeler. 
            if ~isempty(this.Labeler) && ~isempty(this.Image) && ~isempty(this.Figure) && ~isempty(this.ImageAxes)
                activate(this.Labeler,this.Figure, this.ImageAxes, this.Image);
            end
        end
        
        %------------------------------------------------------------------
        function disableDrawing(this)
            if ~isempty(this.Labeler) && ~isempty(this.Image) && ~isempty(this.Figure) && ~isempty(this.ImageAxes)
                % disable drawing by deactivating labeler. Used during mode
                % changes.
                this.Labeler.deactivate();
            end
        end
        
        %------------------------------------------------------------------
        function cleanupRectangleLabeler(this)
            this.Clipboard.purge();
            this.RectangleLabeler.UndoRedoManager.resetUndoRedoBuffer();
        end
        
        %------------------------------------------------------------------
        function configure(this, modeChangeCallback, polygonStartedCallback, polygonFinishedCallback)
            addlistener(this, 'RequestForModeChange', modeChangeCallback);
            addlistener(this.PixelLabeler, 'PolygonStarted', polygonStartedCallback);
            addlistener(this.PixelLabeler, 'PolygonFinished', polygonFinishedCallback);
        end
        
        %------------------------------------------------------------------
        function setMode(this, mode, interceptFunctionHandle)
            
            if isempty(this.Figure)
                return;
            end

            this.Mode = mode;
            
            switch mode
                case 'ROI'
                     this.enableDrawing()

                    % Turn off zoom and pan
                    zoom(this.Figure, 'off');
                    pan(this.Figure, 'off');
                    
                    setPointer(this);
                    
                case 'ZoomIn'
                    set(this.Image,'ButtonDownFcn',[]);
                    
                    hZoom = zoom(this.Figure);
                    hZoom.ButtonDownFilter = interceptFunctionHandle;
                    
                    % Set context menu
                    attachContextMenu(this, hZoom);
                    
                    % Turn on zoom
                    set(hZoom,'Enable','on');
                    
                    % Set zoom direction in
                    set(hZoom,'Direction','in');
                    
                case 'ZoomOut'
                    set(this.Image,'ButtonDownFcn',[]);
                    
                    hZoom = zoom(this.Figure);
                    hZoom.ButtonDownFilter = interceptFunctionHandle;
                    
                    % Set context menu
                    attachContextMenu(this, hZoom);
                    
                    % Turn on zoom
                    set(hZoom,'Enable','on');
                    
                    % Set zoom direction out
                    set(hZoom,'Direction','out');
                    
                case 'Pan'
                    set(this.Image,'ButtonDownFcn',[]);
                    
                    hPan = pan(this.Figure);
                    hPan.ButtonDownFilter = interceptFunctionHandle;
                    
                    % Set context menu
                    attachContextMenu(this, hPan);
                    
                    % Turn on pan
                    set(hPan,'Enable','on');
                     
                case 'none'
                    this.disableDrawing();
                    
                    %Turn off zoom and pan
                    zoom(this.Figure, 'off');
                    pan(this.Figure, 'off');
                    
                    setPointer(this);
            end
            
            updateUIContextMenuCheckMarks(this);
            
            
        end
        
        %------------------------------------------------------------------
        function setLabelingMode(this, mode)
            
            if ~isempty(this.LabelingMode) && this.LabelingMode == mode
                return
            else
                % Switch labelers. Deactivate current one and activate the
                % new one. An active labeler is the one that will be used
                % to draw or edit labels.
                this.LabelingMode = mode;
                
                if ~isempty(this.Labeler)
                    deactivate(this.Labeler);
                    % empty clipboard of copied data.
                    purge(this.Clipboard);
                end
                
                switch mode
                    case labelType.Rectangle
                        
                        this.Labeler = this.RectangleLabeler;
                        
                    case labelType.PixelLabel
                        
                        this.Labeler = this.PixelLabeler;
                end
                
                if ~isempty(this.Image) && ~isempty(this.Figure) && ~isempty(this.ImageAxes)
                    activate(this.Labeler,this.Figure, this.ImageAxes, this.Image);  
                    
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function finalize(this)
            % Tell pixel labeler to perform final updates.
            this.PixelLabeler.finalize();
        end
        
        %------------------------------------------------------------------
        function updateLabel(this, roiLabel)
            % make sure correct labeler is activated.
            this.setLabelingMode(roiLabel.ROI);
            
            % update labeler with details about selected label.
            this.Labeler.SelectedLabel = roiLabel;
        end
        
        %------------------------------------------------------------------
        function addlistenerForLabelIsChanged(this, callback)
            % attach listerner for all labeler's "label is changed" event.
            addlistener(this.PixelLabeler, 'LabelIsChanged', callback);
            addlistener(this.RectangleLabeler, 'LabelIsChanged', callback);
        end
        
         %------------------------------------------------------------------
        function addlistenerForUpdateUndoRedoQAB(this, callback)
            % attach listerner updating QAB undo/redo
            addlistener(this.PixelLabeler, 'UpdateUndoRedoQAB', callback);
            addlistener(this.RectangleLabeler, 'UpdateUndoRedoQAB', callback);
        end
        
        %------------------------------------------------------------------
        function drawLabels(this, data)
            drawLabels(this.RectangleLabeler, data);
        end
        
        %------------------------------------------------------------------
        function wipeROIs(this)
            % Remove ROIs using rectangle labeler. PixelLabeler has no ROIs
            % to remove.
            wipeROIs(this.RectangleLabeler);
        end
        
        %------------------------------------------------------------------
        function drawImage(this, data)
            % data.ImageFilename The image filename.
            % data.Image         The image data.
            % data.ForceRedraw A logical. Whether or not the image should
            %                  be forced to be re-drawn. Force redraw
            %                  needed for pixel labeling when image file is
            %                  the same but pixel label data is different.
            
            % Pixel labeler should create label overlay if data has pixel
            % labels.
            I = preprocessImageData(this.PixelLabeler, data);
            
            forceRedraw = isfield(data,'ForceRedraw') && data.ForceRedraw;
            
            isSameImage = strcmp(this.CurrentImageFilename, data.ImageFilename);
            
            if ~forceRedraw && isSameImage
                % no need to re-draw.
            else
                % Restore the tag once imshow is done
                originalTag = this.ImageAxes.Tag;
                
                if isempty(this.Image)
                    this.Image = imshow(I,'InitialMagnification', 'fit',...
                        'Parent', this.ImageAxes, 'Border', 'tight', 'DisplayRange', []);
                    set(this.ImageAxes,'CLim',[0 1]);
                else
                    this.Image.CData = I;
                    % Update axes limits to reset zoom level when moving to
                    % a different image
                    if ~isSameImage
                        xLim = get(this.Image,'XData') + [-0.5 0.5];
                        yLim = get(this.Image,'YData') + [-0.5 0.5];
                        set(this.ImageAxes,'XLim',xLim,'YLim',yLim);
                    end
                end
                
                this.ImageAxes.Tag = originalTag;
                
                % Cache current image file name.
                if ismissing(data.ImageFilename)
                    this.CurrentImageFilename = '';
                else
                    this.CurrentImageFilename = data.ImageFilename;
                end
                
                % Setup the Labeler to handle image button down on this new
                % image.
                if ~isempty(this.Labeler) && strcmp(this.Mode, 'ROI')
                    activate(this.Labeler, this.Figure, this.ImageAxes, this.Image);                   
                end
                
                % make sure all labelers are attached to current
                % figure handles.
                attachToImage(this.RectangleLabeler, this.Figure, this.ImageAxes, this.Image);
                attachToImage(this.PixelLabeler, this.Figure, this.ImageAxes, this.Image);
            end
            
            installContextMenu(this);
            
            if isfield(data,'ImageIndex')
                this.CurrentImageIndex = data.ImageIndex;
            end
            % labeler needs current image index for undo/redo.
            this.RectangleLabeler.CurrentImageIndex = this.CurrentImageIndex;
        end
        
        %------------------------------------------------------------------
        function clearImage(this)
            this.Image = [];
        end
        %------------------------------------------------------------------
        function installContextMenu(this)
            hCMenu = uicontextmenu('Parent', this.Figure, ...
                'Tag', 'ImageDisplayContextMenu');
            
            % Paste
            pasteUIMenu = uimenu(hCMenu, 'Label', ...
                getString(message('vision:trainingtool:PastePopup')),...
                'Callback', @this.pasteSelectedROIs, 'Accelerator', 'V',...
                'Tag','PasteContextMenu');
            
            if isempty(this.Clipboard)
                set(pasteUIMenu, 'Enable', 'off');
            end
            
            
            % ROI
            roiUIMenu = uimenu(hCMenu, 'Label',...
                getString(message('vision:labeler:ROIButtonTitle')),...
                'Callback', @(~,~)requestModeChange(this,'ROI'),...
                'Separator', 'on', 'Tag', 'ROIContextMenu'); %#ok<NASGU>

            % Zoom in
            zoomInUIMenu = uimenu(hCMenu, 'Label',...
                getString(message('vision:uitools:ZoomInButton')),...
                'Callback', @(~,~)requestModeChange(this,'ZoomIn'), ...
                'Tag', 'ZoomInContextMenu'); %#ok<NASGU>

            % Zoom out
            zoomOutUIMenu = uimenu(hCMenu, 'Label',...
                getString(message('vision:uitools:ZoomOutButton')),...
                'Callback', @(~,~)requestModeChange(this,'ZoomOut'),...
                'Tag', 'ZoomOutContextMenu'); %#ok<NASGU>

            % Pan
            panUIMenu = uimenu(hCMenu, 'Label', ...
                getString(message('vision:uitools:PanButton')),...
                'Callback', @(~,~)requestModeChange(this,'Pan'),...
                'Tag', 'PanContextMenu'); %#ok<NASGU>
            
            
            set(this.Image, 'UIContextMenu', hCMenu);
            
            this.ContextMenuCache = hCMenu;
        end
        
        %------------------------------------------------------------------
        function set.Position(this, pos)
            this.Panel.Position = pos;
        end
        
        %------------------------------------------------------------------
        function pos = get.Position(this)
            pos = this.Panel.Position;
        end
        
        %------------------------------------------------------------------
        function syncImageAxes(this, displayHandle)
            % Since a new image is drawn everytime an image is selected,
            % the axes of legend display needs to be synced.
            setAxes(displayHandle, this.ImageAxes);
        end
        
        %------------------------------------------------------------------
        function TF =  get.UserIsDrawing(this)
            if isempty(this.Labeler)
                TF = false;
            else
                TF = this.Labeler.UserIsDrawing;
            end
        end
        
        %------------------------------------------------------------------
        function copySelectedROIs(this, varargin)
            % gather roi copy data for selected rois. add to clipboard and
            % enable paste.
            
            rois = this.RectangleLabeler.getSelectedROIsForCopy();
            
            this.Clipboard.add(rois);
            
            if ~isempty(this.Clipboard)
                enablePaste(this)
            end
            
        end
        
        %------------------------------------------------------------------
        function cutSelectedROIs(this, varargin)
            % gather roi copy data for selected rois. add to clipboard and
            % enable paste.
            
            this.copySelectedROIs();
            
            this.RectangleLabeler.deleteSelectedROIs;
            
        end
        
        %------------------------------------------------------------------
        function deleteSelectedROIs(this)
            this.RectangleLabeler.deleteSelectedROIs;
        end
        
        %------------------------------------------------------------------
        function enablePaste(this, varargin)
            
            foundPaste = findall(get(this.Image,'UIContextMenu'),...
                'Label',getString(message('vision:trainingtool:PastePopup')));
            set(foundPaste, 'Enable','on');
        end
        
        %------------------------------------------------------------------
        function pasteSelectedROIs(this, varargin)
            
            if isempty(this.Clipboard)
                return;
            end
            
            rois = contents(this.Clipboard);
            
            %Distinguish between paste logic specific to roi type
            CopiedRectROIs = {};
            
            for inx=1:numel(rois)
                shape = rois{inx}.shape;
                switch shape
                    case 'rect'
                    CopiedRectROIs{end+1} = rois{inx}; %#ok<AGROW>
                    otherwise
                    error('Undefined action for shape %s', shape);
                end
            end
            
            % call paste methods on each labeler.
            pasteSelectedROIs(this.RectangleLabeler, CopiedRectROIs);
            
            % Flush the event queue before new paste callback
            % This is required to ensure ROIs are pasted only as long as
            % CTRL+V is held down
            drawnow;
        end
        
        %------------------------------------------------------------------
        function selectAll(this)
            % delegate select-all to each labeler.
            this.RectangleLabeler.selectAll();
        end
    
        %------------------------------------------------------------------
        function showROILabelNames(this, showROILabelFlag)
            showROILabelNames(this.RectangleLabeler, showROILabelFlag);
        end
    end
    
    %----------------------------------------------------------------------
    % Undo/Redo - Forward undo/redo to active labeler
    %----------------------------------------------------------------------
    methods
        function undo(this)
            if ~isempty(this.Labeler)
                this.Labeler.undo();
            end
        end
        
        function redo(this)
            if ~isempty(this.Labeler)
                this.Labeler.redo();
            end
        end
        
    end
    
    % Pixel Label Mode Change Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % When one of the pixel label buttons on the toolstrip is pressed,
        % this method updates the PixelLabeler to change mode.
        %------------------------------------------------------------------
        function setPixelLabelMode(this, mode)
            this.PixelLabeler.Mode =  mode;
        end
        
        %------------------------------------------------------------------
        % When marker size slider on the toolstrip is changed, this method
        % updates the PixelLabeler to change the MarkerSize property.
        %------------------------------------------------------------------
        function setPixelLabelMarkerSize(this, sz)
            this.PixelLabeler.MarkerSize =  sz;
        end
        
        %------------------------------------------------------------------
        % When the label opacity slider is changes, this method updates the
        % PixelLabeler to change the label opacity.
        %------------------------------------------------------------------
        function setPixelLabelAlpha(this, alpha)
            this.PixelLabeler.Alpha =  alpha;
        end
        
        function deletePixelLabelData(this,pixelID)
            deletePixelLabelData(this.PixelLabeler,pixelID);
        end
        
        function setLabelMatrixFilename(this,fullfilename)
            setLabelMatrixFilename(this.PixelLabeler,fullfilename);
        end
        
    end
    
    % Marker size patch for brush tool
    %----------------------------------------------------------------------
    methods (Access = private)
        
        %------------------------------------------------------------------
        function setBrushMarker(this)
            delete(this.BrushMarker);
            patchVerts = [NaN,NaN;NaN,NaN;NaN,NaN;NaN,NaN];
            patchFaces = [1 2 3 4];
            
            this.BrushMarker = patch('Parent',this.ImageAxes,'HitTest','off','HandleVisibility','off',...
                                    'FaceColor','none','EdgeColor',[1 1 1],'Faces',patchFaces,...
                                    'Vertices',patchVerts,'Visible','off','PickableParts','none');
                                
            this.Figure.WindowButtonMotionFcn = @(src,evt) this.brushMarkerCallback(src,evt);
        end
        
        %------------------------------------------------------------------
        function showBrushMarker(this)
            try
                set(this.BrushMarker,'Visible','on');
            catch
                setBrushMarker(this);
            end
        end
        
        %------------------------------------------------------------------
        function hideBrushMarker(this)
            try
                set(this.BrushMarker,'Visible','off');
            catch
                setBrushMarker(this);
            end
        end
        
        %------------------------------------------------------------------
        function brushMarkerCallback(this,~,evt)
            
            isValidMarkerState = isa(evt.HitObject,'matlab.graphics.primitive.Image') && ...
                strcmp(this.Mode,'ROI') && ...
                this.LabelingMode == labelType.PixelLabel && ...
                any(strcmp(this.PixelLabeler.Mode,{'draw','erase'}));

            if ~isValidMarkerState
                hideBrushMarker(this);
                return;
            end
            
            % Get Marker dimensions
            val = round(this.PixelLabeler.MarkerSize);
            if mod(val,2) == 0
                val = round(val + 1);
            end

            try
                clickPos = round(getCurrentAxesPoint(this));
                if ~isInBounds(this, clickPos(1), clickPos(2))
                    hideBrushMarker(this);
                    return;
                end

                offset = round((val - 1) / 2)+0.5;
                patchVerts = [(clickPos(1)-offset),(clickPos(2)-offset);...
                    (clickPos(1)+offset),(clickPos(2)-offset); ...
                    (clickPos(1)+offset),(clickPos(2)+offset); ...
                    (clickPos(1)-offset),(clickPos(2)+offset)];
                
                if strcmp(this.PixelLabeler.Mode,'draw')
                    rgbColor = this.Labeler.SelectedLabel.Color;
                else
                    rgbColor = [1 1 1];
                end

                set(this.BrushMarker,'Vertices',patchVerts,'EdgeColor',rgbColor);
                showBrushMarker(this);
            catch
                setBrushMarker(this);
            end
            
        end
        
        %------------------------------------------------------------------
        function clickPos = getCurrentAxesPoint(this)
            cP = this.ImageAxes.CurrentPoint;
            clickPos = [cP(1,1) cP(1,2)];
        end
        
        %------------------------------------------------------------------
        function tf = isInBounds(this, X, Y)
            XLim = this.ImageAxes.XLim;
            YLim = this.ImageAxes.YLim;
            tf = X >= XLim(1) && X <= XLim(2) && Y >= YLim(1) && Y <= YLim(2);
        end
        
    end
    
    methods (Access = private)
        function setPointer(this)
            
            if strcmpi(this.Mode,'ROI')
                if this.LabelingMode == labelType.PixelLabel
                    setPointer(this.PixelLabeler)
                else
                    set(this.Figure, 'Pointer', 'arrow');
                    % Set pointer to cross
                    enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'cross');
                    iptSetPointerBehavior(this.Image, enterFcn);
                    iptPointerManager(this.Figure);
                end
            elseif strcmpi(this.Mode,'none')
                % Reset pointer
                iptSetPointerBehavior(this.Image, []);
                iptPointerManager(this.Figure);
            else
                % Reset pointer
                iptSetPointerBehavior(this.Image, []);
                iptPointerManager(this.Figure);
            end
        end  
        
        function requestModeChange(this,mode)
            modeData = vision.internal.labeler.tool.ModeChangeEventData(mode);
            notify(this, 'RequestForModeChange', modeData);
        end
        
        function attachContextMenu(this, hObj)
            
            hCMenu = this.ContextMenuCache;
            
            if ~isempty(hCMenu)
                
                % Make sure hObj is not enabled before setting the
                % UIContextMenu.
                origEnableState = strcmpi(hObj.Enable, 'on');
                if origEnableState
                    set(hObj, 'Enable', 'off');
                end
                
                set(hObj, 'UIContextMenu', hCMenu);
                
                % Restore the original state if needed
                if origEnableState
                    set(hObj, 'Enable', 'on');
                end
            end
        end 
        
        function updateUIContextMenuCheckMarks(this)
            
            mode = this.Mode;
            
            if isempty(this.ContextMenuCache)
                return;
            end
            
            hCMenu = this.ContextMenuCache;
            zInMenu     = findobj(hCMenu, 'Tag', 'ZoomInContextMenu');
            zOutMenu    = findobj(hCMenu, 'Tag', 'ZoomOutContextMenu');
            panMenu     = findobj(hCMenu, 'Tag', 'PanContextMenu');
            roiMenu     = findobj(hCMenu, 'Tag', 'ROIContextMenu');
            
            switch mode
                case 'ZoomIn'
                    set(zInMenu, 'Checked', 'on');
                    set(zOutMenu, 'Checked', 'off');
                    set(panMenu, 'Checked', 'off');
                    set(roiMenu, 'Checked', 'off');
                case 'ZoomOut'
                    set(zInMenu, 'Checked', 'off');
                    set(zOutMenu, 'Checked', 'on');
                    set(panMenu, 'Checked', 'off');
                    set(roiMenu, 'Checked', 'off');
                case 'Pan'
                    set(zInMenu, 'Checked', 'off');
                    set(zOutMenu, 'Checked', 'off');
                    set(panMenu, 'Checked', 'on');
                    set(roiMenu, 'Checked', 'off');
                case 'ROI'
                    set(zInMenu, 'Checked', 'off');
                    set(zOutMenu, 'Checked', 'off');
                    set(panMenu, 'Checked', 'off');
                    set(roiMenu, 'Checked', 'on');
                case 'none'
                    set(zInMenu, 'Checked', 'off');
                    set(zOutMenu, 'Checked', 'off');
                    set(panMenu, 'Checked', 'off');
                    set(roiMenu, 'Checked', 'off');
            end
        end
        
    
        function zoomCallback(this,~,data)

            hZoom = zoom(this.Figure);
            % Turn on zoom
            set(hZoom,'Enable','on');    
            
            if data.VerticalScrollCount > 0
                % Set zoom direction in
                set(hZoom,'Direction','in');
           else
                % Set zoom direction out
                set(hZoom,'Direction','out');
            end
            drawnow
            zoom(this.Figure, 'off');
        end
    end
    
end
