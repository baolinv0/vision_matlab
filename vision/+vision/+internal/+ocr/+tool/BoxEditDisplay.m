classdef BoxEditDisplay < vision.internal.uitools.AppFigure
    properties
        KeyPressFcn
        MouseButtonDownFcn
        BoundingBoxButtonDownFcn
        NewPositionCallbackFcn
        Tag = 'BoxEditDisplay'                          
    end
    
    %----------------------------------------------------------------------
    % UI components
    %----------------------------------------------------------------------
    properties
        Axes       
        ScrollPanel
        ScrollAPI
        ROI        
    end
    
    %----------------------------------------------------------------------
    % State managed by BoxEditDisplay
    %----------------------------------------------------------------------
    properties
        % Boxes - Current set of boxes show in image
        Boxes
        
        % BoxIDs - unique ID for each box. 
        BoxIDs
        
        % Text - Cell array of characters associated with each box. This is
        % updated as boxes are modified.
        Text
        
        % LastBoxID - The last box ID used. New box ID is LastBoxID + 1.
        LastBoxID
        
        % IsChanged - set to true if any boxes are modified.
        IsChanged
        
        % Box color and line width settings
        BoxColor = uint8([66 161 230])      
        BoxLineWidth = 3;
    end
    
    %----------------------------------------------------------------------
    methods
        % Construct main image display. Requires key press and button down
        % callbacks to be provided.
        function this = BoxEditDisplay() 
            this = this@vision.internal.uitools.AppFigure('Box Edit');                   
        end             
        
        %------------------------------------------------------------------
        % Draws image and boxes that make up the image display.
        %------------------------------------------------------------------
        function draw(this, I, bboxes, selectedBox)
            
            bbox = bboxes(selectedBox,:);
            
            drawImage(this, I, bbox);
            
            drawBoxes(this, bboxes, selectedBox);
        end
        
        %------------------------------------------------------------------
        function drawImage(this, I, bbox)
                        
            makeHandleVisible(this);
            
            this.Axes = findobj(this.Fig, 'Type','axes');                                   
            
            if isempty(this.Axes) || ~ishandle(this.Axes) % add an axes if needed
                this.Axes = axes('Parent', this.Fig,...
                    'Tag', this.Tag,...
                    'Units','normalized','Position',[0 0 1 0.88],'Visible','off');
                
                 hImage = imshow(I,'InitialMagnification', 'fit',...
                'Parent', this.Axes, 'Border', 'tight');    
            
                  this.ScrollPanel = imscrollpanel(this.Fig, hImage);
                  
                  this.Axes = hImage.Parent;
                  
                  this.ScrollAPI = iptgetapi(this.ScrollPanel);
                
            else
               
                this.ScrollAPI.replaceImage(I);
                
                %hImage = imshow(I,'InitialMagnification', 'fit',...
                %'Parent', this.Axes, 'Border', 'tight');
            end
                        
            mag = this.ScrollAPI.findMagnification(4*bbox(3),4*bbox(4));
            
            cx = bbox(1) + bbox(3)/2;
            
            cy = bbox(2) + bbox(4)/2;
            
            this.ScrollAPI.setMagnificationAndCenter(mag, cx, cy);          
            
            % attach key board accelerator callbacks          
            iptaddcallback(this.Fig, 'KeyPressFcn', this.KeyPressFcn);
            
            % attach callback for drawing ROIs
            set(hImage, 'buttondownfcn', this.MouseButtonDownFcn);
            
            % Install context menu again. Have to do it twice because the
            % pointer behavior code prevents the context menus from
            % showing up immediately after images are loaded.
            %this.installContextMenu('ROI', hImage);
                     
            % Disable overwriting to put on the ROIs
            set(this.Axes, 'NextPlot', 'add');
             
            % resets all axes properties to default values
            set(this.Axes, 'NextPlot', 'replace');
            set(this.Axes, 'Tag', this.Tag); % add tag after reset              
            
            lockFigure(this);            
        end
        
        %------------------------------------------------------------------
        function setPointerToCross(this)
                                      
            hImage = this.getImage();
            
            enterFcn = @(figHandle, currentPoint)...
                set(figHandle, 'Pointer', 'cross');
            iptSetPointerBehavior(hImage, enterFcn);
            iptPointerManager(this.Fig);
        end
        
        %------------------------------------------------------------------
        function resetPointerBehavior(this)
            
            hImage = this.getImage();
              
            iptSetPointerBehavior(hImage, []);
            iptPointerManager(this.Fig);
        end
        
        % 
        function attachDrawROICallback(this)
             hImage = findobj(this.ScrollPanel,'type','image');
             set(hImage, 'buttondownfcn', this.MouseButtonDownFcn);
        end
        
        %------------------------------------------------------------------
        function drawBoxes(this, bboxes, selectedBox)
            
            isValid = cellfun(@(x)ischar(x), this.Text);
                        
            points = bbox2points(bboxes);
            
            points = reshape(points,4,[]);
            X = points(:,1:2:end);
            Y = points(:,2:2:end);
            
            % set patch alpha values to zero to not display patch at that
            % box. Instead a imrect will be placed there instead.
            
            N = size(X,2); % num patches           
            patchAlphas = zeros(N,1);
            patchAlphas(selectedBox) = 0;
                        
            edgeAlphas = ones(N,1);
            edgeAlphas(selectedBox) = 0;
            
            patchOptions = {'EdgeColor',this.BoxColor, ...
                'EdgeAlpha',1,...
                'FaceColor',this.BoxColor,...
                'FaceAlpha','flat',...
                'AlphaDataMapping','none',... % don't use figure's alphamap
                'FaceVertexAlphaData', patchAlphas, ...
                'LineWidth',this.BoxLineWidth};
            
            % Create patch object for each box and attach callback.
            p(N) = matlab.graphics.GraphicsPlaceholder;
            for i = 1:N
                if isValid(i)
                    
                    tag = sprintf('bboxPatch%d',i); % add tag so we can findobj easily.
                    
                    p(i) = patch(X(:,i), Y(:,i), this.BoxColor,...
                        'Parent', this.Axes,  patchOptions{:},...
                        'FaceVertexAlphaData', patchAlphas(i),...
                        'EdgeAlpha', edgeAlphas(i), ...
                        'Tag',tag);
                    
                    iptaddcallback(p(i), 'ButtonDownFcn',...
                        {this.BoundingBoxButtonDownFcn, i});
                end
                
            end
            
            this.LastBoxID = N;

            bbox = bboxes(selectedBox, :);
            this.addROI(bbox)
            % add ROI 
            
           
        end
        
        %------------------------------------------------------------------
        function removeBox(this, whichBox)
            % delete patch
            
            for i = 1:numel(whichBox)
                p = getBoxPatch(this, whichBox(i));
                delete(p)                                
            end          
            
            idxToRemove = this.getBoxIDs(whichBox);
            
            this.Boxes(idxToRemove,:)  = [];
            this.BoxIDs(idxToRemove) = [];
            this.Text(idxToRemove) = [];
            
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        function idx = getBoxIDs(this, whichBox)
            if isscalar(whichBox)
                idx = this.BoxIDs == whichBox;
            else
                idx = max(bsxfun(@eq, this.BoxIDs, whichBox(:)));
            end
        end
        
        %------------------------------------------------------------------
        function txt = getText(this, whichBox)
            assert(isscalar(whichBox));            
            idx = this.BoxIDs == whichBox;
            txt = this.Text{idx};            
        end
        
        %------------------------------------------------------------------
        function boxes = getBoxes(this, whichBox)            
            idx = this.getBoxIDs(whichBox);
            boxes = this.Boxes(idx,:);
        end
        
        %------------------------------------------------------------------
        function resizeBox(this, whichBox, newBox)  
            
            % update boxes
            idx = this.getBoxIDs(whichBox);
            this.Boxes(idx,:) = newBox;
            
            % update patch
            p = getBoxPatch(this, whichBox);
            
            p.Vertices = bbox2points(newBox);
            
            this.IsChanged = true;
        end
        
        %------------------------------------------------------------------
        % Appends box and returns position in Boxes.
        %------------------------------------------------------------------
        function idx = appendBox(this, bbox, showBoxBorder)
            
            if nargin == 2
                showBoxBorder = true;           
            end
            
            if showBoxBorder
                edgeAlpha = 1;
            else
                edgeAlpha = 0;
            end                            
            
            patchOptions = {'EdgeColor',this.BoxColor, ...
                'EdgeAlpha',edgeAlpha,...
                'FaceColor',this.BoxColor,...
                'FaceAlpha','flat',...
                'AlphaDataMapping','none',... % don't use figure's alphamap
                'FaceVertexAlphaData', 0,...
                'LineWidth',this.BoxLineWidth};
            
            points = bbox2points(bbox);
            
            points = reshape(points,4,[]);
            X = points(:,1:2:end);
            Y = points(:,2:2:end);
            
            this.LastBoxID = this.LastBoxID + 1; 
                       
            tag = sprintf('bboxPatch%d',this.LastBoxID); % add tag so we can findobj easily.
             
            p = patch(X, Y, this.BoxColor,...
                'Parent', this.Axes,  patchOptions{:},...
                'FaceVertexAlphaData', 0,...
                'EdgeAlpha', edgeAlpha,...
                'Tag', tag);
            
            iptaddcallback(p, 'ButtonDownFcn',...
                {this.BoundingBoxButtonDownFcn, this.LastBoxID});
            
            % return position at which added
            idx = this.LastBoxID;
            
            this.Boxes(end+1,:)  = bbox;
            this.BoxIDs(end+1)   = idx; 
            this.Text{end+1}     = char(0); % for now
            
            this.IsChanged = true;              
                  
        end
                
        %------------------------------------------------------------------
        % Adds an ROI programmatically given a bounding box.
        %------------------------------------------------------------------
        function addROI(this, bbox)
             
            hIm = findobj(this.Axes, 'type','Image');                       
           
            % bbox is in spatial coordinates for drawing           
            this.ROI = iptui.imcropRect(this.Axes, bbox, hIm);
            this.ROI.addNewPositionCallback(this.NewPositionCallbackFcn);
            
            p = findobj(this.ROI, 'type','patch');
            p.FaceColor = this.BoxColor;
            p.FaceAlpha = 0.5;
            
            this.removeROIContextMenu(this.ROI);
            
        end                
        
        %------------------------------------------------------------------
        function removeROIContextMenu(~, roi)
            % remove context menus
            p = findobj(roi, 'Type','patch');     
            
            if ishandle(p)
                delete(p.UIContextMenu.Children);
            end
        end
        
        %------------------------------------------------------------------
        % Draw an ROI interactively.
        %------------------------------------------------------------------
        function roi = drawROI(this)
            
            hImage = findobj(this.ScrollPanel,'type','image');
            
            roi = vision.internal.uitools.imrectButtonDown.drawROI(hImage);    
            
            if vision.internal.uitools.imrectButtonDown.isValidROI(roi)
                
                this.ROI = roi;
                this.ROI.addNewPositionCallback(this.NewPositionCallbackFcn);
                this.removeROIContextMenu(this.ROI);  
            end
            
            drawnow(); % Finish all the drawing before moving on           
            
        end
        
        %------------------------------------------------------------------
        % Highlight a box by setting it face alpha to 0.5.
        %------------------------------------------------------------------
        function highLightBox(this, whichBox)
            for i = 1:numel(whichBox)
                       
                p = getBoxPatch(this, whichBox(i));
                
                p.EdgeAlpha = 1;
                p.FaceVertexAlphaData = 0.5;                               
                
            end
        end
        
        %------------------------------------------------------------------
        % Un-highlight a box by making its face alpha 0
        %------------------------------------------------------------------
        function unhighlightBox(this, whichBox)
            for i = 1:numel(whichBox)
                boxIdx = whichBox(i);
                
                p = getBoxPatch(this, boxIdx);
                p.EdgeAlpha = 1;
                p.FaceVertexAlphaData = 0;                               
            end
        end
        
        %------------------------------------------------------------------
        % Select a single box by removing the batch border and adding and
        % ROI on top. This box can now be resized.
        %------------------------------------------------------------------
        function selectBox(this, whichBox)            
            if numel(whichBox) == 1
                p = getBoxPatch(this, whichBox);
                
                p.EdgeAlpha = 0;
                p.FaceVertexAlphaData = 0;
                
                % convert vertex points to box
                xy = p.Vertices;
                xymax = max(xy);
                xymin = min(xy);
                
                bbox = [xymin(1) xymin(2) xymax(1)-xymin(1) xymax(2)-xymin(2)];
                
                this.addROI(bbox);
            end
            
        end
        
        %------------------------------------------------------------------
        % Unselect a single box by removing the ROI and adding the patch
        % border.
        %------------------------------------------------------------------
        function unselectBox(this, whichBox)                       
            if numel(whichBox) == 1
                p = getBoxPatch(this, whichBox);
                p.EdgeAlpha = 1;
                p.FaceVertexAlphaData = 0;
                
                delete(this.ROI);
            end
        end  
        
        %------------------------------------------------------------------
        function p = getBoxPatch(this, whichBox)
            
             tag = sprintf('bboxPatch%d',whichBox);
             p = findobj(this.Axes, 'Type','patch','Tag', tag);
        end

    end
    
    %----------------------------------------------------------------------
    % Zoom/Pan methods specialized for imscrollbar.
    %----------------------------------------------------------------------
    methods
        
        %------------------------------------------------------------------        
        function setZoomInState(this, shouldZoomIn)
            
            hIm = getImage(this);
            
            if shouldZoomIn
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomInFcn = imuitoolsgate('FunctionHandle', 'imzoomin');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomInFcn);
                glassPlus = setptr('glassplus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassPlus{:}));
            else                
                set(hIm,'ButtonDownFcn','');
                iptSetPointerBehavior(hIm,[]);
            end            
        end
        
        %------------------------------------------------------------------
        function setZoomOutState(this, shouldZoomOut)
            
            hIm = getImage(this);
            
            if shouldZoomOut
               
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomOutFcn = imuitoolsgate('FunctionHandle', 'imzoomout');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomOutFcn);
                glassMinus = setptr('glassminus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassMinus{:}));
            else                
                set(hIm,'ButtonDownFcn','');
                iptSetPointerBehavior(hIm,[]);
                
            end
        end
        
        %------------------------------------------------------------------
        function setPanState(this, shouldPan)
            
            hIm = getImage(this);
            
            if shouldPan       
                
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                panFcn = imuitoolsgate('FunctionHandle', 'impan');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',panFcn);
                handCursor = setptr('hand');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,handCursor{:}));
            else                
                set(hIm,'ButtonDownFcn','');
                iptSetPointerBehavior(hIm,[]);
            end           
        end
        
        %------------------------------------------------------------------
        function h = getImage(this)
            h = findobj(this.ScrollPanel,'type','image');
        end
   
    end
        
    %----------------------------------------------------------------------
    methods        
         
        %------------------------------------------------------------------
        function tf = isLeftClick(this)
            tf = strcmpi(this.Fig.SelectionType,'normal');
        end
        
        %------------------------------------------------------------------
        function tf = isDoubleClick(this)
            tf = strcmpi(this.Fig.SelectionType,'open');
        end
        
        %------------------------------------------------------------------
        function tf = isCtrlClick(this)
            % selection type is 'alt' for both right click and ctrl-left
            % click. check current modifier to check for ctrl press.
            modifier    = get(this.Fig, 'CurrentModifier');
            ctrlPressed = ~isempty(modifier) && strcmpi(modifier, 'control');
           
            tf = ctrlPressed && strcmpi(this.Fig.SelectionType,'alt');
        end
        
        %------------------------------------------------------------------
        function tf = isShiftClick(this)
             tf = strcmpi(this.Fig.SelectionType, 'extend');
        end
               
    end
end
