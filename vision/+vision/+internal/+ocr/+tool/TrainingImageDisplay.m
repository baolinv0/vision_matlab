classdef TrainingImageDisplay < vision.internal.uitools.AppFigure
    properties
        KeyPressFcn
        MouseButtonDownFcn
        BoundingBoxButtonDownFcn
        ROINewPositionFcn
        RemoveROIFcn
        MouseOverFcn
        Tag = 'TrainingImageDisplay'                          
    end
    
    %----------------------------------------------------------------------
    % UI components
    %----------------------------------------------------------------------
    properties
        SideBySideDisplay
        RightImageHandle
        LeftImageHandle
        MessagePane
        ROI
    end
      
    methods
        % Construct main image display. Requires key press and button down
        % callbacks to be provided.
        function this = TrainingImageDisplay() 
            this = this@vision.internal.uitools.AppFigure('Image');         
            this.Fig.Tag = 'TrainingImageDisplay';
        end        
        
        %------------------------------------------------------------------
        % Draws image and boxes that make up the image display.
        %------------------------------------------------------------------
        function draw(this, I, BW, roi)
            
            drawImage(this, I, BW, roi);            
            
        end            
        
        %------------------------------------------------------------------
        function drawImage(this, I, BW, roi)
                        
            makeHandleVisible(this);                                                 
            
            if isempty(this.SideBySideDisplay) || ~ishandle(this.SideBySideDisplay)                                 
                                             
                this.SideBySideDisplay = ...
                    vision.internal.ocr.tool.ImageSideBySideDisplay(this.Fig);    
                
                set(this.Fig, 'KeyPressFcn', this.KeyPressFcn);
                                                                           
            end            
       
            this.SideBySideDisplay.showImages(...
                I, vision.getMessage('vision:ocrTrainer:BinarizationOriginal'),...
                BW, vision.getMessage('vision:ocrTrainer:BinarizationSegmented'));
            
            rpanel = this.SideBySideDisplay.rPanel.Children;
            hAxes = findobj(rpanel, 'type', 'axes');
            this.RightImageHandle = findobj(hAxes,'type','image');
            
            lpanel = this.SideBySideDisplay.lPanel.Children;
            hAxes = findobj(lpanel, 'type', 'axes');
            this.LeftImageHandle = findobj(hAxes,'type','image');
            
            set(this.LeftImageHandle, 'buttondownfcn', this.MouseButtonDownFcn);
                        
           
            % setup pointer for drawing ROI            
            this.setPointerToCross();
                     
            % Disable overwriting to put on the ROIs
            set(hAxes, 'NextPlot', 'add');
             
            % resets all axes properties to default values
            set(hAxes, 'NextPlot', 'replace');
            set(hAxes, 'Tag', this.Tag); % add tag after reset                                     
            
            if ~isempty(roi)
                addROI(this, roi);
            end           
            
            this.MessagePane = addMessagePane(this.Fig, ...
                vision.getMessage('vision:ocrTrainer:TrainingPanelMsg'));
            
            lockFigure(this);            
        end        
        
        %------------------------------------------------------------------
        function addROI(this, bbox)
                        
            lpanel = this.SideBySideDisplay.lPanel.Children;
            hAxes = findobj(lpanel, 'type', 'axes');            
            
            this.ROI = iptui.imcropRect(hAxes, bbox, this.LeftImageHandle);
            this.removeROIContextMenu(this.ROI);  
            this.ROI.addNewPositionCallback(this.ROINewPositionFcn);            
           
        end                
        
        %------------------------------------------------------------------
        function setPointerToCross(this)                                                
            
            % setup pointer behavior to call MouseOverFcn.
            pointerBehavior.enterFcn = @enterFcn;
            pointerBehavior.traverseFcn = [];
            pointerBehavior.exitFcn = @exitFcn;
            
            iptSetPointerBehavior(this.LeftImageHandle, pointerBehavior );
            
            iptPointerManager(this.Fig);
            
            %--------------------------------------------------------------
            function enterFcn(figHandle, ~)
                this.MouseOverFcn('showMessage');
                set(figHandle, 'Pointer', 'cross');                
            end
            
            %--------------------------------------------------------------
            function exitFcn(~, ~)
                this.MouseOverFcn('reset');                                
            end
        end        
        
        %------------------------------------------------------------------
        function resetPointerBehavior(this)
            this.MouseOverFcn('reset');
            iptSetPointerBehavior(this.LeftImageHandle, []);
            iptPointerManager(this.Fig);
        end
        %------------------------------------------------------------------
        % Draw an ROI interactively.
        %------------------------------------------------------------------
        function roi = drawROI(this)                        
            
            roi = vision.internal.uitools.imrectButtonDown.drawROI(...
                this.LeftImageHandle);    
            
            if vision.internal.uitools.imrectButtonDown.isValidROI(roi)
                
                this.ROI = roi;
                this.ROI.addNewPositionCallback(this.ROINewPositionFcn);
                this.removeROIContextMenu(this.ROI);  
            end
            
            drawnow(); % Finish all the drawing before moving on           
            
        end
        
        %------------------------------------------------------------------
        function removeROIContextMenu(this, roi)
            % Add "remove" to the context menu
            
            % First remove default imrect context menu
            p = findobj(roi, 'Type','patch');     
            
            if ishandle(p)
                delete(p.UIContextMenu.Children);
            end
            
            % add the "remove"
            p.UIContextMenu = uicontextmenu('Parent',this.Fig);
            uimenu(p.UIContextMenu,'Label','Remove','Callback',this.RemoveROIFcn);
            
        end
        
        %------------------------------------------------------------------
        function updateDisplay(this, BW)
            
            this.RightImageHandle.CData = BW;
                              
        end
                
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
            ctrlPressed = strcmp(get(this.Fig,...
                'CurrentModifier'), 'control');
             tf = strcmpi(this.Fig.SelectionType,'alt') & ~isempty(ctrlPressed);
        end
       
    end
    
    %----------------------------------------------------------------------
    % Zoom/Pan functionality
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        function resetZoomState(this)
            
            zoom(this.Fig, 'inmode');
            zoom(this.Fig, 'off');
            pan(this.Fig, 'off');
        end
        
        %------------------------------------------------------------------        
        function setZoomInState(this, shouldZoomIn)
            resetZoomState(this);
            
            if shouldZoomIn
                zoom(this.Fig, 'on');
            else
                zoom(this.Fig, 'off');
            end
        end
        
        %------------------------------------------------------------------
        function setZoomOutState(this, shouldZoomOut)
            resetZoomState(this);
           
            if shouldZoomOut
                zoom(this.Fig, 'outmode');
            else
                zoom(this.Fig, 'inmode');
                zoom(this.Fig, 'off');
            end
        end
        
        %------------------------------------------------------------------
        function setPanState(this, shouldPan)
            resetZoomState(this);
            
            if shouldPan
                pan(this.Fig, 'on');
            else
                pan(this.Fig, 'off');
            end
        end
    end
end

function msgPane = addMessagePane(hFig,message)
%addMessagePane(hFig,message) adds a minimizable message notification pane
%to the top of the figure. This function assumes the message to be 1 line
%long.

% Copyright 2015 The MathWorks, Inc.

msgPane = ctrluis.PopupPanel(hFig);

fontName = get(0,'DefaultTextFontName');
fontSize = 16;
txtPane = ctrluis.PopupPanel.createMessageTextPane(message,fontName,fontSize);
msgPane.setPanel(txtPane);

%Position message pane at the top of the figure. Assume message to be
%one line only.
positionMessagePane();

msgPane.showPanel()

hFig.SizeChangedFcn = @(~,~)positionMessagePane();

function positionMessagePane()

msgLen = numel(message);
pos = hgconvertunits(hFig, [0 0 msgLen, 2.5], 'characters', 'normalized', hFig);

pos(2) = 1 - pos(4);
pos(3) = .5;

msgPane.setPosition(pos);
end

end
