% This class coordinates the display of the image browser and of the
% labeled image.
%
% Test Code for this display:
% 
% folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
% exts = {'.jpg','.png','.tif'};
% imds = imageDatastore(folders,'FileExtensions',exts);
% 
% h = vision.internal.imageLabeler.tool.LabeledImageBrowserDisplay();
% h.makeFigureVisible
% 
% data.ImageFilename = imds.Files;
% configure(h, @(varargin)selectImage(h, data, varargin{:}), @(varargin)disp('edit image'),@(varargin)disp('key image'));
% 
% for i = 1:numel(imds.Files)
%     data.Filename = imds.Files{i};
%     h.appendImage(data);
% end
% 
% h.selectImageByIndex(1);
% disp('done')
% 
% function selectImage(h, data, varargin)
% % data provided by app
% d.ImageFilename = data.ImageFilename{varargin{2}.Index};
% d.Image = imread(d.ImageFilename);
% d.LabelMatrix = zeros(size(d.Image));
% d.LabelMatrixFilename = d.ImageFilename;
% d.ImageIndex = varargin{2}.Index;
% [d.Positions, d.Names, d.Colors, d.Shapes] = deal([]);
% h.draw(d);
% end

classdef LabeledImageBrowserDisplay < ...
        vision.internal.uitools.AppFigure & ...
        vision.internal.labeler.tool.UndoRedoQuickAccessBarMixin
    
    properties
        %ImagePanel Manages the image display panel and the drawing of
        %           images and labels.
        ImagePanel
        
        %
        BrowserPanel
        
    end
    
    properties(Access = private)
        KeyPressFcn
    end
    
    properties(Dependent)
        %SelectedImageIndex Indices of the selected images (may be a vector
        %                   when multiple images are selected).
        SelectedImageIndex
        
        %VisibleImageIndices Indices of visible images in the browser
        VisibleImageIndices
    end
    
    events
        % ImageSelectedInBrowser Event when image is selected in browser.
        ImageSelectedInBrowser

        % ImageRemovedInBrowser Event when images are removed in browser.
        ImageRemovedInBrowser
        
        % ImageRotateInBrowser Event when images are rotated.
        ImageRotateInBrowser        
        
        % DrawOrEdit Event when mouse button down on the actual image is detected.
        DrawOrEdit
    end
    
    methods
        function this = LabeledImageBrowserDisplay()
            nameDisplayedInTab = vision.getMessage(...
                'vision:imageLabeler:LabeledImageBrowserDisplayName');
            this = this@vision.internal.uitools.AppFigure(nameDisplayedInTab);
            
            % Set handle visibility to 'callback' to prevent users from
            % deleting figure. During automation algorithm callback we must
            % turn this 'off' to prevent user code from messing with
            % figure.
            this.Fig.HandleVisibility = 'callback';
            
            this.Fig.Resize = 'on'; 
            
            createPanels(this);
            
            this.Fig.SizeChangedFcn = @(varargin)this.doPanelPositionUpdate;
            
            this.Fig.WindowButtonDownFcn =  @(varargin)this.doDispatchToCorrectPanel(varargin{:});
            
            configureListeners(this);
            
            showHelperText(this, ...
                vision.getMessage('vision:imageLabeler:ImageDisplayHelperText'));
        end
        
        %------------------------------------------------------------------
        % Configure display callbacks and listeners. These callbacks are
        % defined in the main app.
        %------------------------------------------------------------------
        function configure(this, ...
                browserButtonDownCallback, ...
                browserRemoveImageCallback, ...
                browserRotateImageCallback, ...
                labelChangedCallback, ...
                keyPressCallback, ...
                modeChangeCallback, ...
                polygonStartedCallback, ...
                polygonFinishedCallback)
            
            addlistener(this, 'ImageSelectedInBrowser', browserButtonDownCallback);
            addlistener(this, 'ImageRemovedInBrowser', browserRemoveImageCallback);
            addlistener(this, 'ImageRotateInBrowser', browserRotateImageCallback);
            
            % tell the client something about the labels changed: new label
            % or edited.
            addlistener(this, 'DrawOrEdit', labelChangedCallback);
            
            this.KeyPressFcn = keyPressCallback;
            
            this.Fig.KeyPressFcn  = @this.doFigureKeyPress;
            
            configure(this.ImagePanel, modeChangeCallback, polygonStartedCallback, polygonFinishedCallback);
        end
        
        %------------------------------------------------------------------
        function finalize(this)
            this.ImagePanel.finalize();
        end
        
        %------------------------------------------------------------------
        function resetPixelLabeler(this,data)
            
            this.ImagePanel.PixelLabeler.reset(data);
            data.ForceRedraw = true;
            this.ImagePanel.drawImage(data);
        end
        
        %------------------------------------------------------------------
        function loadImages(this, imageFilenames)
            hideHelperText(this);
            this.BrowserPanel.loadImages(imageFilenames);
        end
        
        %------------------------------------------------------------------
        function algorithmRunSetup(this)
            % set browser timer to zero.
            this.BrowserPanel.setTimerToZero;
        end
        
        %------------------------------------------------------------------
        function algorithmRunTearDown(this)
            this.BrowserPanel.resetTimer();
        end
        
        %------------------------------------------------------------------
        function appendImage(this, imageData)
            
            hideHelperText(this);
            
            this.BrowserPanel.appendImage(imageData);
        end
        
        %------------------------------------------------------------------
        function selectImageByIndex(this, idx)
            this.ImagePanel.CurrentImageIndex = idx;
            this.BrowserPanel.selectImageByIndex(idx);
        end
        
        %------------------------------------------------------------------
        function idx = getCurrentImageIndex(this)
            idx = this.ImagePanel.CurrentImageIndex;
        end
        
        %------------------------------------------------------------------
        function updateLabelSelection(this, label)
            % label isa vision.internal.labeler.ROILabel or 
            %  'vision.internal.labeler.FrameLabel
             updateLabel(this.ImagePanel, label);
        end
        
        %------------------------------------------------------------------
        function deleteSelectedROIs(this)
            this.ImagePanel.deleteSelectedROIs();
        end
        
        %------------------------------------------------------------------
        function idx = get.SelectedImageIndex(this)
            idx = this.BrowserPanel.SelectedItemIndex;
        end
        
        %------------------------------------------------------------------
        function idx = get.VisibleImageIndices(this)
            idx = this.BrowserPanel.VisibleItemIndex;
        end
        
        %------------------------------------------------------------------
        function draw(this, data)
            % Required fields:
            % data.ImageFilename The image filename. char vec.
            % data.Image         The image data to display.
            % Optional:
            % data.ForceRedraw Redraws the image again, even if it is
            % already displayed.
            
            assert( ischar(data.ImageFilename) );
            
            this.ImagePanel.PixelLabeler.reset(data);
            this.ImagePanel.wipeROIs();
            this.ImagePanel.drawImage(data);
            this.ImagePanel.drawLabels(data);
            
            % Set figure name to match image name so it shows up in the
            % figure tab.
            idx = this.getCurrentImageIndex();
            [~, name] = fileparts(this.BrowserPanel.imageNameByIndex(idx));
            setFigureTitle(this, name);
        end
        
        %------------------------------------------------------------------
        function clearImage(this)
            clearImage(this.ImagePanel);
        end
        %------------------------------------------------------------------
        function drawLabels(this, data)
            % called by client to draw existing labels in labelData.
            drawLabels(this.ImagePanel, data);
        end
        
        %------------------------------------------------------------------
        function enableDrawing(this)
            this.ImagePanel.enableDrawing();
        end
        
        %------------------------------------------------------------------
        function disableDrawing(this)
            this.ImagePanel.disableDrawing();
        end
        %------------------------------------------------------------------
        function grabFocus(this)
            if ~isempty(this.Fig) && isvalid(this.Fig) && strcmpi(this.Fig.Visible, 'on')
                figure(this.Fig);
            end
        end
        
        %------------------------------------------------------------------
        function syncImageAxes(this, displayHandle)
            % Since a new image is drawn everytime an image is selected,
            % the axes of legend display needs to be synced. 
            syncImageAxes( this.ImagePanel, displayHandle);
        end

        %------------------------------------------------------------------
        function selectAllROIs(this)
            this.ImagePanel.selectAll();
        end
        
        %------------------------------------------------------------------
        function copySelectedROIs(this)
            this.ImagePanel.copySelectedROIs();
        end
        
        %------------------------------------------------------------------
        function pasteSelectedROIs(this)
            this.ImagePanel.pasteSelectedROIs();
        end
        
        %------------------------------------------------------------------
        function cutSelectedROIs(this)
            this.ImagePanel.cutSelectedROIs();
        end
        
        %------------------------------------------------------------------
        function redo(this, ~, ~)
           this.ImagePanel.redo(); 
        end
        
        %------------------------------------------------------------------
        function undo(this, ~, ~)
           this.ImagePanel.undo()
        end
        
        %------------------------------------------------------------------
        function addROILabelsToUndoStack(this, index, labelNames, ...
                labelPositions, labelColors, labelShapes)
            
            this.ImagePanel.addROILabelsToUndoStack(this, index, labelNames, ...
                labelPositions, labelColors, labelShapes);
            
           
        end
        
        %------------------------------------------------------------------
        function cleanupForROIRemoved(this, type)
            % perform cleanup required when ROI label is removed.
            if type == labelType.Rectangle
                this.ImagePanel.cleanupRectangleLabeler();
            end
        end
        
        %------------------------------------------------------------------
        function doBrowserKeyPress(this, src)
           
            if canRespondToKeyPress(this)
                this.BrowserPanel.doKeyPress(src);
            end
        end
        
		%------------------------------------------------------------------
        function filterSelectedImages(this)
            
            if isempty(this.SelectedImageIndex)
                return;
            end
            
            % Filter selected images
            this.BrowserPanel.filterSelectedImages();
            
            % Select first image
            index = this.SelectedImageIndex(1);
            this.selectImageByIndex(index);
        end
        
        %------------------------------------------------------------------
        function restoreAllImages(this)
            
            this.BrowserPanel.restoreAllImages();
            
            % Select current image so that browser internals correctly hold
            % state for shift-click/multi-select operations.
            this.selectImageByIndex(this.getCurrentImageIndex);
        end
        
        %------------------------------------------------------------------
        function freezeBrowserInteractions(this)
            this.BrowserPanel.freeze();
            
            % Set handle visibility to 'off'. AutomationAlgorithms 
            % are callbacks that could destroy the app's video display.
            % Prevent this by seting visiblity to callback so that image
            % browser selection still keeps working and imshow calls don't
            % write into figure.
            this.Fig.HandleVisibility = 'off';
        end
        
        %------------------------------------------------------------------
        function unfreezeBrowserInteractions(this)
            % reset back to 'callback'.
            this.Fig.HandleVisibility = 'callback';
            this.BrowserPanel.unfreeze();
        end
        
        %------------------------------------------------------------------
        function freezeDrawingTools(this)
            this.ImagePanel.disableDrawing();
        end
        
        %------------------------------------------------------------------
        function unfreezeDrawingTools(this)
            this.ImagePanel.enableDrawing();
        end
        
        %------------------------------------------------------------------
        function reset(this)
            % Reset ImageBrowser Display
            wipeFigure(this);
            
            createPanels(this);
            
            configureListeners(this);
            
            nameDisplayedInTab = vision.getMessage(...
                'vision:imageLabeler:LabeledImageBrowserDisplayName');
            
            setFigureTitle(this, nameDisplayedInTab);
            
            showHelperText(this, ...
                vision.getMessage('vision:imageLabeler:ImageDisplayHelperText'));
        end
        
        %------------------------------------------------------------------
        function setMode(this, mode)
           this.ImagePanel.setMode(mode, @(hObj, data)this.doInterceptButtonDown(hObj, data));
        end
        
        %------------------------------------------------------------------
        function showROILabelNames(this, showROILabelFlag)
            showROILabelNames(this.ImagePanel, showROILabelFlag);
        end
    end
    
    %----------------------------------------------------------------------
    % Callbacks
    %----------------------------------------------------------------------
    methods(Access = private)
        
        %------------------------------------------------------------------
        function createPanels(this)
            this.ImagePanel = vision.internal.imageLabeler.tool.ImagePanel(...
                this.Fig);
            
            this.BrowserPanel = vision.internal.imageLabeler.tool.BrowserPanel(...
                this.Fig);
            
            % Initialize panel position.
            this.doPanelPositionUpdate();               
        end
        
        %------------------------------------------------------------------
        function configureListeners(this)
            % Browser notifies the display when an thumbnail is selected. 
            addlistener(this.BrowserPanel, 'ImageSelectedInBrowser', @this.doImageSelected);
            
            % Browser notifies the display when an thumbnail is removed.
            addlistener(this.BrowserPanel, 'ImageRemovedInBrowser', @this.doImageRemoved);
            
            % Browser notifies the display when a image rotation is requested.
            addlistener(this.BrowserPanel, 'ImageRotateInBrowser', @this.doImageRotate);            
            
            % Listeners for the LabelIsChanged event. This should write out
            % label changes to the session.
            addlistenerForLabelIsChanged(this.ImagePanel, @this.doLabelIsChanged);         
            
            % Listeners for updating undo/redo button state in QAB.
            addlistenerForUpdateUndoRedoQAB(this.ImagePanel, @this.doUndoRedoUpdate);
        end
        
        %------------------------------------------------------------------
        function doUndoRedoUpdate(this, ~, data)
            this.enableQABUndo(data.UndoState);
            this.enableQABRedo(data.RedoState);
        end
        
        %------------------------------------------------------------------
        function TF = canRespondToKeyPress(this)
            TF = ~(this.BrowserPanel.hasImages() && this.ImagePanel.UserIsDrawing);
        end
        
        %------------------------------------------------------------------
        function doFigureKeyPress(this, varargin)
            
            % Don't listen to key presses if user is drawing.
            if canRespondToKeyPress(this)
                this.KeyPressFcn(varargin{:});
            end
            
        end
        
        %------------------------------------------------------------------
        function doDispatchToCorrectPanel(this, varargin)
            % Figure out which object was clicked on because there is
            % only a single WindowButtonDownFcn for the entire figure.
            
            % Get the active object.
            selectedObject = gco;
            
            if isa(selectedObject, 'matlab.graphics.GraphicsPlaceholder')
            	return
            else
                parentPanel = selectedObject.Parent;
            end
            
            if isa(parentPanel, 'matlab.graphics.GraphicsPlaceholder')
                % place holders don't have parents.
                haveSomethingToDispatch = false;
                
            else
                
                haveSomethingToDispatch = true;
                
                % Determine which panel the selected object belongs to.
                while ~(strcmp(getTag(parentPanel), 'Browser') || ...
                        strcmp(getTag(parentPanel), 'Image'))
                    
                    if isa(parentPanel, 'matlab.graphics.GraphicsPlaceholder')
                        % place holders don't have parents.
                        haveSomethingToDispatch = false;
                        break
                    end
                    
                    parentPanel = parentPanel.Parent;
                    
                    if isa(parentPanel,'matlab.ui.Figure')
                        % Made it to the display figure. Something else was
                        % selected.
                        haveSomethingToDispatch = false;
                        break
                    end
                end
            end
            
            if haveSomethingToDispatch          

                % Query the tag to see which panel should handle the callback.
                if strcmp(parentPanel.Tag, 'Browser')
                    doMouseButtonDownFcn(this.BrowserPanel, varargin{:});
                elseif strcmp(parentPanel.Tag, 'Image')
                   % do nothing. image object button down takes care of this.            
                else
                    assert(0, 'Unknown Tag');
                end
            end
            
            %--------------------------------------------------------------
            function t = getTag(x)
                if isa(x, 'matlab.graphics.GraphicsPlaceholder')
                    t = '';
                else
                    t = x.Tag;
                end
            end
        end
        
        %------------------------------------------------------------------
        function doImageSelected(this, ~, data)
            % with multi-select first index is currently shown in display
            if ~isempty(data.Index)
                this.ImagePanel.CurrentImageIndex = data.Index(1);
            end
            notify(this, 'ImageSelectedInBrowser', data);
        end
        
        %------------------------------------------------------------------
        function doImageRemoved(this, ~, data)
            notify(this, 'ImageRemovedInBrowser', data);
        end
        
        %------------------------------------------------------------------
        function doImageRotate(this, ~, data)
            notify(this, 'ImageRotateInBrowser', data);
        end        
        
        %------------------------------------------------------------------
        function doLabelIsChanged(this, ~, data)
            notify(this, 'DrawOrEdit', data);
        end    
        
        %------------------------------------------------------------------
        function doPanelPositionUpdate(this)
            % set position in pixels.
            
            figPos = getpixelposition(this.Fig);
            
            w = figPos(3);
            
            % The thumnail+selection border is 96x96. Select the browser
            % panel height so it fits in nicely - including space for
            % slider.
            browserHeight = 132;
            imageHeight = max(1, figPos(4) - browserHeight);
            
            this.BrowserPanel.Position = [1 1 w browserHeight];
            this.ImagePanel.Position = [1 browserHeight w imageHeight];
        end
        
        function TF = doInterceptButtonDown(this, hObj, ~)
            if strcmpi(hObj.Tag, 'griddedAxes')
                hEvent.Source = ancestor(hObj, 'Figure');
                hEvent.Source.SelectionType = 'normal';
                args = {hEvent.Source, hEvent};
                doMouseButtonDownFcn(this.BrowserPanel, args{:});
                TF = true;
            else
                TF = false;
            end
        end        
    end
    
    %----------------------------------------------------------------------
    % Pixel Label Mode Change Callbacks
    %----------------------------------------------------------------------
    methods
        %------------------------------------------------------------------
        % When one of the pixel label buttons on the toolstrip is pressed,
        % this method updates the PixelLabeler to change mode.
        %------------------------------------------------------------------
        function setPixelLabelMode(this, mode)
            setPixelLabelMode(this.ImagePanel, mode);
        end
        
        %------------------------------------------------------------------
        % When marker size slider on the toolstrip is changed, this method 
        % updates the PixelLabeler to change the MarkerSize property.
        %------------------------------------------------------------------
        function setPixelLabelMarkerSize(this, sz)
            setPixelLabelMarkerSize(this.ImagePanel, sz);
        end
        
        %------------------------------------------------------------------
        % When the label opacity slider is changes, this method updates the
        % PixelLabeler to change the label opacity.
        %------------------------------------------------------------------
        function setPixelLabelAlpha(this, alpha)
            setPixelLabelAlpha(this.ImagePanel, alpha);
        end
        
        function deletePixelLabelData(this,pixelID)
            deletePixelLabelData(this.ImagePanel,pixelID);
        end
        
        function setLabelingMode(this, mode)
            setLabelingMode(this.ImagePanel,mode);
        end
        
        function setLabelMatrixFilename(this,fullfilename)
            setLabelMatrixFilename(this.ImagePanel,fullfilename);
        end
        
    end
end