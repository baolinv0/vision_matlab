% This class deals with marking an image with pixel label types.
classdef PixelLabeler < vision.internal.labeler.tool.ROILabeler
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties(Dependent)
        LabelMatrix
        Colormap
        MarkerSize
        Mode
        Alpha
    end
    
    properties (Access = protected)
        
        Polygon
        LabelMatrixInternal
        ColormapInternal
        MarkerSizeInternal = 0.5;
        ModeInternal = 'polygon';
        AlphaInternal = 0.5;

        Image
        ImageSize
        ImageFilename
        LabelMatrixFilename
        ImageIndex
        IncludeList = 1:255;
                
        UndoPlaceholder = [];
        UndoLabelMatrix = [];
        RedoPlaceholder = [];
        RedoLabelMatrix = [];
        UndoAvailable = false;
        RedoAvailable = false;
                
    end
    
    events
        % These events are used to disable/enable toolstrip during polygon
        % placement
        PolygonStarted
        PolygonFinished
        
    end
    
    methods
        
        %------------------------------------------------------------------
        % Create overlay image to display
        %------------------------------------------------------------------
        function I = preprocessImageData(this, data)
            
            I = data.Image;
            if ~isempty(this.LabelMatrix) && max(this.LabelMatrix(:)) > 0
                I = images.internal.labeloverlayalgo(im2single(data.Image),double(this.LabelMatrix),this.ColormapInternal,this.Alpha,this.IncludeList);
            end
            
        end
        
        %------------------------------------------------------------------
        % Finalize label matrix
        %------------------------------------------------------------------
        function finalize(this)
            % do final actions. Pixel labeler uses this to send data to the
            % session only on image change.
            
            commitPolygon(this);
            
            if ~isempty(this.LabelMatrix)
                % Only send data back if LabelMatrix has been modified at
                % some point (e.g. not empty)
                labelData.Label = this.LabelMatrix;
                labelData.Color = [];
                labelData.Position = this.LabelMatrixFilename;
                labelData.Shape = labelType.PixelLabel;
                labelData.Index = this.ImageIndex;

                evtData = vision.internal.labeler.tool.PixelLabelEventData(labelData);

                notify(this,'LabelIsChanged',evtData);
            end
            
        end
        
        %------------------------------------------------------------------
        % Reset image and label matrix
        %------------------------------------------------------------------
        function reset(this,data)
            % Clear any visible polygon
            this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            
            % Set data
            this.Image = data.Image;
            this.ImageSize = size(data.Image);
            this.LabelMatrix = data.LabelMatrix;
            this.Colormap = single(squeeze(vision.internal.labeler.getColorMap('pixel')));
            this.ImageFilename = data.ImageFilename;
            this.LabelMatrixFilename = data.LabelMatrixFilename;
            this.ImageIndex = data.ImageIndex;

        end
        
        function setLabelMatrixFilename(this,fullfilename)
            this.LabelMatrixFilename = fullfilename;
        end
        
        function setHandles(this,hFig,hAx,hIm)
            this.ImageHandle = hIm;
            this.AxesHandle = hAx;
            this.Figure = hFig;
            this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
        end
        
        %------------------------------------------------------------------
        % Add polygon to image
        %------------------------------------------------------------------
        function addPolygon(this,labelVal,color)
                        
            % Extend pointer behavior to entire figure
            enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'crosshair');
            iptSetPointerBehavior(this.Figure, enterFcn);
            iptPointerManager(this.Figure);
            
            % Hide previous Polygon
            this.Polygon.Visible = false;
            
            if ~this.Polygon.Valid
                this.UndoLabelMatrix = this.LabelMatrixInternal;
            end
            
            selectedROI = images.internal.drawingTools.Polygon(this.AxesHandle);
            selectedROI.MinimumNumberOfPoints = 3;
            selectedROI.Color = color;
            selectedROI.Label = this.SelectedLabel.Label;
            selectedROI.SemanticValue = labelVal;
            notify(this,'PolygonStarted');
            selectedROI.beginDrawing()
            
            if ~isvalid(this) || ~isvalid(this.Figure)
                return; % Case when app is closed during draw
            end
            notify(this,'PolygonFinished'); 
                        
            % If polygon is not valid or if it has less than 2 vertices,
            % delete the polygon
            if selectedROI.Valid
                wirePolygonListeners(this,selectedROI);
                
                if this.Polygon.Valid
                    this.UndoPlaceholder = this.Polygon.CopiedData;
                    oldROI = this.Polygon;
                    this.commitPolygonToLabelMatrix(oldROI);
                    delete(oldROI)
                else
                    this.UndoPlaceholder = [];
                end
                
                this.UndoAvailable = true;
                this.RedoAvailable = false;
                this.Polygon = selectedROI;
                this.updateSemanticView()

            else
                % Polygons can be invalid when drawn interactively.
                delete(selectedROI);
                this.Polygon.Visible = true;
            end
            
            % Revert pointer behavior
            iptSetPointerBehavior(this.Figure, []);
            iptPointerManager(this.Figure);
            setPointer(this);
           
        end
        
        %------------------------------------------------------------------
        % Add smart polygon to image
        %------------------------------------------------------------------
        function addSmartPolygon(this,labelVal,color)
                        
            % Extend pointer behavior to entire figure
            enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'crosshair');
            iptSetPointerBehavior(this.Figure, enterFcn);
            iptPointerManager(this.Figure);
            
            % Hide previous Polygon
            this.Polygon.Visible = false;
            
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
            else
                this.UndoPlaceholder = [];
            end
            
            selectedROI = images.internal.drawingTools.Polygon(this.AxesHandle);
            selectedROI.MinimumNumberOfPoints = 3;
            selectedROI.Color = color;
            selectedROI.Label = this.SelectedLabel.Label;
            selectedROI.SemanticValue = labelVal;
            notify(this,'PolygonStarted');
            selectedROI.beginDrawing()
            
            if ~isvalid(this)
                return; % Case when app is closed during draw
            end
            notify(this,'PolygonFinished');  
            
            % If polygon is not valid or if it has less than 2 vertices,
            % delete the polygon
            if selectedROI.Valid
                
                mask = selectedROI.createMask(this.ImageSize(1),this.ImageSize(2));
                
                % Use active contour with Chan-Vese at n iterations
                smoothMask = activecontour(this.Image,mask,20);
                
                if this.Polygon.Valid
                    commitPolygon(this);
                else
                    this.UndoLabelMatrix = this.LabelMatrixInternal;
                end

                L = this.LabelMatrixInternal;
            
                L(smoothMask) = selectedROI.SemanticValue;
                this.LabelMatrixInternal = L;
                
                this.UndoAvailable = true;
                this.RedoAvailable = false;

                delete(selectedROI);
                this.updateSemanticView()

            else
                % Polygons can be invalid when drawn interactively.
                delete(selectedROI);
                this.Polygon.Visible = true;
            end
            
            % Revert pointer behavior
            iptSetPointerBehavior(this.Figure, []);
            iptPointerManager(this.Figure);
            setPointer(this);
            
        end
        
        %------------------------------------------------------------------
        % Add pixel-level marks to label matrix
        %------------------------------------------------------------------
        function addPaintBrush(this,labelVal,color)
            
            % Hide previous Polygon
            this.Polygon.Visible = false;
            
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
            else
                this.UndoPlaceholder = [];
            end
            
            selectedROI = images.internal.drawingTools.PaintBrush(this.AxesHandle,this.ImageSize);
            selectedROI.Color = color;
            selectedROI.Label = this.SelectedLabel.Label;
            selectedROI.SemanticValue = labelVal;
            selectedROI.MarkerSize = this.MarkerSize;

            selectedROI.beginDrawing();
            wirePaintBrushListeners(this,selectedROI);
            this.UndoAvailable = true;
            this.RedoAvailable = false;
            this.commitMaskToLabelMatrix(selectedROI);
                        
            this.updateSemanticView()
            
            % Revert pointer behavior
            iptSetPointerBehavior(this.Figure, []);
            iptPointerManager(this.Figure);
            setPointer(this);

        end
        
        %------------------------------------------------------------------
        % Add floodfill to label matrix
        %------------------------------------------------------------------
        function addFloodFill(this,labelVal,color)
            
            % Hide previous Polygon
            this.Polygon.Visible = false;
            
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
            else
                this.UndoPlaceholder = [];
            end
            
            selectedROI = images.internal.drawingTools.PaintBrush(this.AxesHandle,this.ImageSize);
            selectedROI.Color = color;
            selectedROI.Label = this.SelectedLabel.Label;
            selectedROI.SemanticValue = labelVal;

            point = round(this.AxesHandle.CurrentPoint);
            row = max(min(point(1,2),size(this.Image,1)),1);
            col = max(min(point(1,1),size(this.Image,2)),1);
            
            im = sum((this.Image - this.Image(row,col,:)).^2,3);
            im = mat2gray(im);
            
            tol = 0.05;
            
            selectedROI.Mask = grayconnected(im, row, col, tol);
            this.UndoAvailable = true;
            this.RedoAvailable = false;
            this.commitMaskToLabelMatrix(selectedROI);
                        
            this.updateSemanticView()

        end
        
        %------------------------------------------------------------------
        % Undo previous action
        %------------------------------------------------------------------
        function undo(this)
            
            if ~this.canUndo()
                % Exit if no undo is available
                return;
            end
            
            this.RedoLabelMatrix = [];
            this.RedoPlaceholder = [];
            
            if this.Polygon.Valid
                this.RedoPlaceholder = this.Polygon.CopiedData;
                oldROI = this.Polygon;
                delete(oldROI)
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            end
            
            if ~isempty(this.UndoPlaceholder)
                % Case when Polygon was the last tool used
                % Paste Copied data
                copiedROI = this.UndoPlaceholder;
                this.pasteSelectedROIs(copiedROI);
            else
                % Case when Paint Brush was the last tool used
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            end
            
            if ~isempty(this.UndoLabelMatrix)
                this.RedoLabelMatrix = this.LabelMatrixInternal;
                this.LabelMatrixInternal = this.UndoLabelMatrix;
            end
            
            this.UndoAvailable = ~this.UndoAvailable;
            this.RedoAvailable = true;
            this.UndoPlaceholder = [];
            this.UndoLabelMatrix = [];
            this.updateSemanticView()
            this.updateUndoRedoQAB();
        end
        
        %------------------------------------------------------------------
        % Redo previous action
        %------------------------------------------------------------------
        function redo(this)
            
            if ~this.canRedo()
                % Exit if undo is available
                return;
            end
            
            this.UndoLabelMatrix = [];
            this.UndoPlaceholder = [];
            
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
                oldROI = this.Polygon;
                delete(oldROI)
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            end
            
            if ~isempty(this.RedoPlaceholder)
                % Case when Polygon was the last tool used
                % Paste Copied data
                copiedROI = this.RedoPlaceholder;
                this.pasteSelectedROIs(copiedROI);
            else
                % Case when Paint Brush was the last tool used
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            end
            
            if ~isempty(this.RedoLabelMatrix)
                this.UndoLabelMatrix = this.LabelMatrixInternal;
                this.LabelMatrixInternal = this.RedoLabelMatrix;
            end
            
            this.UndoAvailable = true;
            this.RedoAvailable = ~this.RedoAvailable;
            this.RedoPlaceholder = [];
            this.RedoLabelMatrix = [];
            this.updateSemanticView()
            this.updateUndoRedoQAB();
         
        end
                
        %------------------------------------------------------------------
        % Select Polygon
        %------------------------------------------------------------------
        function rois = getSelectedROIsForCopy(this)
            % returns the selected ROIs
            rois = [];
            if this.Polygon.Valid
                copiedData = this.Polygon.CopiedData;
                copiedData.shape = 'pixel';
                rois = copiedData;
            end
        end
        
        %------------------------------------------------------------------
        % Paste Polygon
        %------------------------------------------------------------------
        function pasteSelectedROIs(this, copiedData)
            
            if isempty(copiedData)
                return;
            end
            
            commitPolygon(this);
            
            this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            
            this.Polygon.SemanticValue = copiedData.SemanticValue;
            this.Polygon.Label = copiedData.Label;
            this.Polygon.Color = copiedData.Color;
            this.Polygon.Closed = copiedData.Closed;
            this.Polygon.MinimumNumberOfPoints = 3;
            this.Polygon.Position = copiedData.Position;
            
            wirePolygonListeners(this,this.Polygon);

            this.updateSemanticView();
            
            this.updateUndoRedoQAB();
        end
        
        %------------------------------------------------------------------
        % Commit currently editable polygon
        %------------------------------------------------------------------
        function commitPolygon(this)
            % Commits currently drawn polygon to label matrix then delete
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
                this.UndoAvailable = true;
                this.RedoAvailable = false;
                oldROI = this.Polygon;
                this.commitPolygonToLabelMatrix(oldROI);
                delete(oldROI)
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
            end
        end
        
        %------------------------------------------------------------------
        % Delete currently editable polygon
        %------------------------------------------------------------------
        function deletePolygon(this)
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
                oldROI = this.Polygon;
                delete(oldROI)
                this.Polygon = images.internal.drawingTools.Polygon(this.AxesHandle);
                this.updateSemanticView();
                this.updateUndoRedoQAB();
            end
        end
        
        %------------------------------------------------------------------
        function deletePixelLabelData(this,pixelID)
            L = this.LabelMatrixInternal;
            L(L == pixelID) = 0;
            this.LabelMatrix = L;
            this.updateSemanticView();
        end
        
        function setPointer(this)
            set(this.Figure, 'Pointer', 'arrow');
            switch this.ModeInternal
                case {'polygon','smartpolygon'}
                    % Set pointer to crosshair
                    enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'crosshair');
                case 'floodfill'
                    % Set pointer to pencil
                    myPointer = this.paintBucketPointer;
                    enterFcn = @(figHandle, currentPoint) set(figHandle,'Pointer','custom','PointerShapeCData',myPointer,'PointerShapeHotSpot',[16 16]);
                case 'draw'
                    % Set pointer to pencil
                    myPointer = this.pencilPointer;
                    enterFcn = @(figHandle, currentPoint) set(figHandle,'Pointer','custom','PointerShapeCData',myPointer,'PointerShapeHotSpot',[16 1]);
                case 'erase'
                    % Set pointer to erasing pencil
                    myPointer = transpose(this.pencilPointer);
                    enterFcn = @(figHandle, currentPoint) set(figHandle,'Pointer','custom','PointerShapeCData',myPointer,'PointerShapeHotSpot',[16 1]);
            end
            iptSetPointerBehavior(this.ImageHandle, enterFcn);
            iptPointerManager(this.Figure);
        end
        
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function TF = canUndo(this)
            TF = this.UndoAvailable;
        end
        
        %------------------------------------------------------------------
        function TF = canRedo(this)
            TF = this.RedoAvailable;
        end
        
        %------------------------------------------------------------------
        function onButtonDown(this,varargin)
            
            mouseClickType = get(this.Figure,'SelectionType');
            
            if ~strcmpi(mouseClickType,'normal')
                return;
            end
            
            labelVal = this.SelectedLabel.PixelLabelID;
            color = this.SelectedLabel.Color;
            
            switch this.ModeInternal
                case 'polygon'
                    addPolygon(this,labelVal,color);
                case 'smartpolygon'
                    addSmartPolygon(this,labelVal,color);
                case 'floodfill'
                    addFloodFill(this,labelVal,color);
                case 'draw'
                    addPaintBrush(this,labelVal,color);
                case 'erase'
                    addPaintBrush(this,0,[1 1 1]);
            end
            
            this.updateUndoRedoQAB();
        end
        
        %------------------------------------------------------------------
        function L = createLabelMatrix(this)
            % Returns current label matrix
            L = this.LabelMatrixInternal;        
            
            if this.Polygon.Valid && this.Polygon.Visible
                mask = this.Polygon.createMask(this.ImageSize(1),this.ImageSize(2));
                L(mask) = this.Polygon.SemanticValue;
            end
        end
        
        %------------------------------------------------------------------
        function commitPolygonToLabelMatrix(this,selectedROI)
            L = this.LabelMatrixInternal;
            this.UndoLabelMatrix = L;
            mask = selectedROI.createMask(this.ImageSize(1),this.ImageSize(2));
            L(mask) = selectedROI.SemanticValue;
            this.LabelMatrixInternal = L;
        end
        
        %------------------------------------------------------------------
        function commitMaskToLabelMatrix(this,selectedROI)
            % If prior action was a polygon, commit it to label matrix
            % first
            if this.Polygon.Valid
                commitPolygon(this);
            else
                this.UndoLabelMatrix = this.LabelMatrixInternal;
            end
            
            L = this.LabelMatrixInternal;
            
            mask = selectedROI.Mask;
            L(mask) = selectedROI.SemanticValue;
            this.LabelMatrixInternal = L;
        end
        
        %------------------------------------------------------------------
        function updateSemanticView(this)
            data.Image = this.Image;
            data.ImageFilename = this.ImageFilename;
            data.ForceRedraw = true;
            
            evtData = vision.internal.labeler.tool.PixelLabelEventData(data);
            
            notify(this,'ImageIsChanged',evtData);
            
        end
        
        %------------------------------------------------------------------
        function updateUndoRedoQAB(this)
            data = vision.internal.labeler.tool.UndoRedoStateEvent(...
                this.canUndo(), ...
                this.canRedo());
            
            notify(this, 'UpdateUndoRedoQAB', data);
        end
        
        %------------------------------------------------------------------
        function copyPolygon(this)
            this.UndoAvailable = true;
            this.RedoAvailable = false;
            if this.Polygon.Valid
                this.UndoPlaceholder = this.Polygon.CopiedData;
            else
                this.UndoPlaceholder = [];
            end
            this.UndoLabelMatrix = [];
        end
        
        %------------------------------------------------------------------
        function deleteROI(this)
            if ~isvalid(this)
                return;
            end
            this.updateSemanticView();
        end
        
        %------------------------------------------------------------------
        function wirePolygonListeners(this,selectedROI)
            addlistener(selectedROI, 'VertexBeingAdded', @(~,~) this.copyPolygon());
            addlistener(selectedROI, 'VertexBeingRemoved', @(~,~) this.copyPolygon());
            addlistener(selectedROI, 'VertexAdded', @(~,~) this.updateSemanticView());
            addlistener(selectedROI, 'VertexRemoved', @(~,~) this.updateSemanticView());
            addlistener(selectedROI, 'BeingDeleted', @(~,~) this.copyPolygon());
            addlistener(selectedROI, 'Deleted', @(~,~) this.deleteROI());
            addlistener(selectedROI, 'Moved', @(~,~) this.updateSemanticView());
        end
        
        %------------------------------------------------------------------
        function wirePaintBrushListeners(this,selectedROI)
            addlistener(selectedROI, 'MaskEdited', @(~,~) this.updateSemanticView());
        end
            
    end
    
    methods
        % Set/Get methods
        
        %------------------------------------------------------------------
        % Label Matrix
        function set.LabelMatrix(this,L)
            
            this.LabelMatrixInternal = L;
            this.UndoPlaceholder = [];
            this.UndoLabelMatrix = [];
            
        end
        
        function L = get.LabelMatrix(this)
            L = createLabelMatrix(this);
        end
        
        %------------------------------------------------------------------
        % Colormap
        function set.Colormap(this,cmap)
            assert(size(cmap,2) == 3,'Invalid Colormap');
            this.ColormapInternal = cmap;
        end
        
        function cmap = get.Colormap(this)
            cmap = this.ColormapInternal;
        end
        
        %------------------------------------------------------------------
        % Mode
        function set.Mode(this,str)
            if any(strcmp(str,{'polygon','smartpolygon','draw','erase','floodfill'}))
                this.ModeInternal = str;
                setPointer(this);
            end
        end
        
        function str = get.Mode(this)
            str = this.ModeInternal;
        end
        
        %------------------------------------------------------------------
        % Alpha
        function set.Alpha(this,val)
            assert(val >= 0 && val <= 100,'Invalid Alpha');
            this.AlphaInternal = val/100;
            updateSemanticView(this);
        end
        
        function val = get.Alpha(this)
            val = this.AlphaInternal;
        end
        
        %------------------------------------------------------------------
        % MarkerSize
        function set.MarkerSize(this,val)
            % Input slider value between 0 and 100 to compute marker size
            assert(val >= 0 && val <= 100,'Invalid MarkerSize');
            this.MarkerSizeInternal = val/100; % Store as fraction
        end
        
        function val = get.MarkerSize(this)
            minSize = min(this.ImageSize(1:2));
            % Biggest marker is 10% of smallest image dimension + one pixel
            % Smallest marker is one pixel
            % Requiring that marker size be an odd value is enforced in the
            % Paint Brush object
            val = round(this.MarkerSizeInternal*minSize*0.1) + 1;
        end
        
    end
    
    methods(Static,Access = private)
         
         function myPointer = pencilPointer
             myPointer = [NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,1,1,NaN,NaN,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,1,2,2,1,NaN,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,1,2,1,2,2,1,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,1,2,1,2,1,2,1,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,NaN,1,2,2,2,1,2,1,NaN,NaN;
                 NaN,NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,1,NaN,NaN,NaN;
                 NaN,NaN,NaN,NaN,NaN,1,2,2,2,2,2,1,NaN,NaN,NaN,NaN;
                 NaN,NaN,NaN,NaN,1,2,2,2,2,2,1,NaN,NaN,NaN,NaN,NaN;
                 NaN,NaN,NaN,1,2,2,2,2,2,1,NaN,NaN,NaN,NaN,NaN,NaN;
                 NaN,NaN,1,1,2,2,2,2,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 NaN,NaN,1,2,1,2,2,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 NaN,1,2,2,2,1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 NaN,1,2,2,1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 1,2,1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;
                 1,1,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN];
         end
         
         function myPointer = paintBucketPointer
             
             myPointer = [NaN   NaN   NaN   NaN   NaN     1     1     1   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
                 NaN   NaN   NaN   NaN     1   NaN   NaN   NaN     1   NaN   NaN   NaN   NaN   NaN   NaN   NaN
                 NaN   NaN   NaN   NaN     1   NaN   NaN     1     1   NaN   NaN   NaN   NaN   NaN   NaN   NaN
                 NaN   NaN   NaN   NaN     1   NaN     1     2     1     1   NaN   NaN   NaN   NaN   NaN   NaN
                 NaN   NaN   NaN   NaN     1     1     2     2     1     2     1     1   NaN   NaN   NaN   NaN
                 NaN   NaN   NaN   NaN     1     2     2     2     1     2     2     1     1     1   NaN   NaN
                 NaN   NaN   NaN     1     2     2     2     1     2     1     2     2     1     1     1   NaN
                 NaN   NaN     1     2     2     2     2     2     1     2     2     2     2     1     1     1
                 NaN     1     2     2     2     2     2     2     2     2     2     2     1     1     1     1
                 1     2     2     2     2     2     2     2     2     2     2     1   NaN     1     1     1
                 NaN     1     2     2     2     2     2     2     2     2     1   NaN   NaN     1     1     1
                 NaN   NaN     1     2     2     2     2     2     2     1   NaN   NaN   NaN     1     1     1
                 NaN   NaN   NaN     1     2     2     2     2     1   NaN   NaN   NaN   NaN     1     1     1
                 NaN   NaN   NaN   NaN     1     2     2     1   NaN   NaN   NaN   NaN   NaN     1     1   NaN
                 NaN   NaN   NaN   NaN   NaN     1     1   NaN   NaN   NaN   NaN   NaN   NaN     1   NaN   NaN
                 NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN];
             
         end
         
    end
    
end