classdef ImageBrowser < handle
    
    events
        SelectionChange;
        OpenSelection;
        RemoveSelection;        
    end
    
    properties
        % Current selected image indices
        currentSelection = [];
        EnableContextMenu
    end
        
    properties (Access = private)    
        parent;
        hParentFigure;
        imageSource;
        
        haxes;
        hvsb;
        
        % index using the same index as the source
        hImages = matlab.graphics.primitive.Image.empty();
        hImageBackGroundColors = {};
        
        % Image indices that need to be redrawn
        hIndsOfDirtyImages = [];
        
        % In pixels
        thumbNailSize;
        thumbNailImagePadding = 4; % all around. This space is part of the thumbnail image.
        thumbNailCellPadding  = 2; % all around. This space is part of the canvas.
        
        % Border color for unselected images
        thumbNailImagePaddingColor   = uint8([ 255 255 255]);
        % Border color for selected images
        thumbNailImageSelectionColor = uint8([78 148 243]);
        
        % In char
        scrollBarWidth = 3;
        
        % Visible part
        viewPortWidth
        viewPortHeight
        % Virtual canvas
        canvasWidth      % same as viewPortWidth (no horizontal scrolling)
        canvasHeight
        
        % Visible number of thumbnails
        visibleColsOfThumbNails
        visibleRowsOfThumbNails
        
        % X and Y indices of visible thumbnails
        visibleThumbNailsXIndRange
        visibleThumbNailsYIndRange
        
        % Scale
        oneCharInPixels
        
        % Flag
        isDeleted = false;
        
        % Listeners
        sliderChangeListner
        
        % 
        shiftSelectionAnchor = [];
        
    end
    
    
    %% API
    methods
        function imbrowser = ImageBrowser(parent_, imageSource_, thumbnailSize_, enableContextMenu_)
            
            assert(isa(parent_,'matlab.ui.container.Panel'));
            
            imbrowser.parent        = parent_;
            imbrowser.hParentFigure = ancestor(parent_,'Figure');
            %TODO assert cell of images or image datastore
            imbrowser.imageSource   = imageSource_;
            % TODO assert int, MxN
            imbrowser.thumbNailSize = thumbnailSize_;
            
            % OCR App: enable context menu when required. This should be
            % removed when browser has support for custom context menus.
            imbrowser.EnableContextMenu = enableContextMenu_;
            
            imbrowser.haxes = axes('Parent',parent_,...
                'Units','normalized',...
                'Position', [ 0 0 1 1],...
                'Ydir', 'reverse',...
                'XLimMode','manual',...
                'YLimMode','manual',...
                'XTick', [],...
                'YTick', [],...
                'XColor', 'none',...
                'YColor', 'none',...
                'Tag', '_imageBrowserAxes',...
                'NextPlot','add');
            
            % NOTE - Value = 0 is bottom
            imbrowser.hvsb = uicontrol('Style','slider',...
                'Units','pixels',...
                'Parent',parent_,...
                'Min', 0,...
                'Max', 1,...
                'Value', 1,...
                'Tag', '_imageBrowserSlider',...
                'Visible','off');
            
            % TODO
            imbrowser.oneCharInPixels = 5;
            
            addlistener(parent_,'ObjectBeingDestroyed',@imbrowser.delete);
            
            parent_.SizeChangedFcn = @imbrowser.respondToSizeChange;
            imbrowser.sliderChangeListner = ...
                addlistener(imbrowser.hvsb,'Value','PostSet',@imbrowser.sliderChanged);
            
            % All images are initiall 'dirty'
            imbrowser.hIndsOfDirtyImages = 1:imbrowser.numberOfImages;
            imbrowser.hImageBackGroundColors{imbrowser.numberOfImages} = [];
            imbrowser.respondToSizeChange();
                        
        end
        
        
        function setSelection(imbrowser, selectedInds, scrollToSelection)
            if(nargin==2)
                scrollToSelection = true;
            end
                
            if(imbrowser.isDeleted)
                return
            end
            
            selectedInds(selectedInds<1) = 1;
            selectedInds(selectedInds>imbrowser.numberOfImages) = imbrowser.numberOfImages;
            
            
            % Mark previous selected as needing a redraw
            imbrowser.hIndsOfDirtyImages = ...
                [imbrowser.hIndsOfDirtyImages, imbrowser.currentSelection];
            
            % Set selection
            imbrowser.currentSelection = selectedInds;
            
            % Update viewport to bring the last selected image into view
            if ~isempty(selectedInds) && scrollToSelection
                imbrowser.scrollVerticallyToSelection();
            end
            
            % Redraw visible
            imbrowser.updateViewPortWithImages();
            
            % issue drawnow to flush context menu drawing.
            drawnow
            
            % update shift selection anchor to newly selected image
            imbrowser.shiftSelectionAnchor = imbrowser.currentSelection;
            
            % Broadcast
            notify(imbrowser,'SelectionChange');
        end
        
        function setImageBorderColor(imbrowser, iminds, rgbColor)
            if(imbrowser.isDeleted)
                return
            end
            
            for k =1:numel(iminds)
                imind = iminds(k);
                imbrowser.hImageBackGroundColors{imind} = uint8(rgbColor);
                imbrowser.hIndsOfDirtyImages(end+1) = imind;
            end
            
            imbrowser.updateViewPortWithImages();
        end
        
        function keyPressFcn(imbrowser, ~, hEvent)
            if(imbrowser.isDeleted)
                return
            end

            if(any(strcmp(hEvent.Modifier,'control'))...
                    ||any(strcmp(hEvent.Modifier,'command')))
                if(strcmpi(hEvent.Key,'a'))
                    % Only ctrl+a is supported
                    imbrowser.setSelection(1:imbrowser.numberOfImages);
                end
                return;
            end
            
            if(any(strcmp(hEvent.Modifier,'shift'))...
                    && ~(strcmp(hEvent.Key,'rightarrow')||strcmp(hEvent.Key,'leftarrow')))
                % Shift key is only supported with left and right arrows
                return;
            end
            
            if(isempty(imbrowser.currentSelection))
                lastClickedIndex = 1;
            else
                lastClickedIndex = imbrowser.currentSelection(end);
            end
            
            switch(hEvent.Key)
                case 'downarrow'
                    index = lastClickedIndex+imbrowser.visibleColsOfThumbNails;
                    if(index>imbrowser.numberOfImages)
                        index = lastClickedIndex;
                    end
                case 'pagedown'
                    index = lastClickedIndex+...
                        floor(imbrowser.visibleRowsOfThumbNails)*imbrowser.visibleColsOfThumbNails;
                    if(index>imbrowser.numberOfImages)
                        index = imbrowser.numberOfImages;
                    end
                case 'uparrow'
                    index = lastClickedIndex-imbrowser.visibleColsOfThumbNails;
                    if(index<1)
                        index = lastClickedIndex;
                    end
                case 'pageup'
                    index = lastClickedIndex-...
                        floor(imbrowser.visibleRowsOfThumbNails)*imbrowser.visibleColsOfThumbNails;
                    if(index<1)
                        index = 1;
                    end
                case 'leftarrow'
                    index = lastClickedIndex-1;
                case 'rightarrow'
                    index = lastClickedIndex+1;
                case 'home'
                    index = 1;
                case 'end'
                    index = imbrowser.numberOfImages;
                case 'delete'
                    imbrowser.removeCurrentlySelectedImages();
                    return;
                case 'backspace'
                    imbrowser.removeCurrentlySelectedImages();
                    return;
                case 'return'                    
                    notify(imbrowser,'OpenSelection');
                    return;
                otherwise
                    return;
            end
            
            % Limit
            index = max(1, index);
            index = min(index, imbrowser.numberOfImages);
            
            if(any(strcmp(hEvent.Modifier,'shift')))
                if(any(imbrowser.currentSelection==index))
                    % Remove
                    newSelection = imbrowser.currentSelection;
                    if(strcmp(hEvent.Key,'leftarrow'))
                        newSelection(newSelection>index) = [];
                    elseif(strcmp(hEvent.Key,'rightarrow'))
                        newSelection(newSelection<index) = [];
                    end
                else
                    % Extend
                    newSelection = [imbrowser.currentSelection, index];
                end
            else
                newSelection = index;
            end
            
            imbrowser.setSelection(newSelection);
        end
        
        function mouseWheelFcn(imbrowser, ~, hEvent)
            if(imbrowser.isDeleted)
                return
            end
            
            if(strcmp(imbrowser.hvsb.Visible,'off'))
                % Dont scroll.
                return;
            end

            curSliderLoc = imbrowser.hvsb.Value;
            scrollAmount = hEvent.VerticalScrollCount;
            % Slider top is Max bottom is 0;
            scrollAmount = -scrollAmount;
            curSliderLoc = curSliderLoc + scrollAmount;
            curSliderLoc = max(curSliderLoc,0);
            curSliderLoc = min(curSliderLoc, imbrowser.hvsb.Max);
            imbrowser.hvsb.Value = curSliderLoc;
        end
        
        function delete(imbrowser, varargin)
            imbrowser.isDeleted = true;
        end
        
    end
    
    %% Selection
    methods (Access = private)
        function thisImageWasClicked(imbrowser, hImage, hEvent)            
            %hFig = ancestor(hImage,'Figure');
            hFig = imbrowser.hParentFigure;
                       
            % Last normal selection is the shift anchor (unless shift is
            % pressed - see shift selection below)
            lastSelected = hImage.UserData.index;
            
            if(hEvent.Button == 1)
                % Left clicked                
                if(strcmp(hFig.SelectionType,'open'))
                    imbrowser.setSelection(hImage.UserData.index);
                    notify(imbrowser,'OpenSelection');
                elseif(strcmp(hFig.SelectionType,'normal'))
                    imbrowser.setSelection(hImage.UserData.index);
                elseif(strcmp(hFig.SelectionType,'alt'))                    
                    % ctrl+click
                    if(any(imbrowser.currentSelection==hImage.UserData.index))
                        % remove
                        cur = imbrowser.currentSelection;
                        cur(cur==hImage.UserData.index) = [];
                        imbrowser.setSelection(cur,false);
                    else
                        % add
                        imbrowser.setSelection(...
                            [imbrowser.currentSelection,  hImage.UserData.index]);
                    end
                elseif(strcmp(hFig.SelectionType,'extend'))
                    % shift+click
                    if imbrowser.shiftSelectionAnchor
                        % dont update anchor point
                        lastSelected = imbrowser.shiftSelectionAnchor;
                    end                                        
                    
                    if(lastSelected<hImage.UserData.index)
                        imbrowser.setSelection(lastSelected:hImage.UserData.index);
                    else
                        imbrowser.setSelection(hImage.UserData.index:lastSelected);
                    end
                end
            elseif(hEvent.Button == 3)
                % Right click, mark selection and let context menu handle
                % the rest if current image is not selected.
                
                if(~any(hImage.UserData.index==imbrowser.currentSelection))
                    imbrowser.setSelection(hImage.UserData.index);
                end
                
                % issue drawnow to flush context menu drawing.
                drawnow
            end  
            
            imbrowser.shiftSelectionAnchor = lastSelected;
        end
        
        function scrollVerticallyToSelection(imbrowser)
            
            % Scroll to view port which shows the last selected image.
            
            % If Selection is below current viewport, scroll to the top of
            % the new one, else scroll to the bottom.
            indexToScrollTo = imbrowser.currentSelection(end);
            rowToScrollTo   = ceil(indexToScrollTo/imbrowser.visibleColsOfThumbNails);
            
            fullRowsInView = [ceil(imbrowser.visibleThumbNailsYIndRange(1)),...
                floor(imbrowser.visibleThumbNailsYIndRange(2)-1)];
            
            % Note - important observation for the logic below to scroll to
            % a particular row (with that row being the top, fully visible
            % row in the current viewport)
            %
            % If slider.Value = 0, slider is at top and row 1 is at top of
            % viewport.
            % If slider.Value = max, slider is at bottom and the top row is
            % (totalrows - number of rows visible)            
            
            if(rowToScrollTo==1)
                imbrowser.hvsb.Value = imbrowser.hvsb.Max;
            elseif(rowToScrollTo<fullRowsInView(1))
                % Ensure rowToScrollTo is shown in full on the top
                viewTopRow = rowToScrollTo-1; % This bit is a bit shaky.
                imbrowser.hvsb.Value = imbrowser.hvsb.Max -(imbrowser.hvsb.Max/(imbrowser.hvsb.Max-imbrowser.visibleRowsOfThumbNails)) *viewTopRow;
            elseif(rowToScrollTo>fullRowsInView(2))
                % Ensure rowToScrollTo is shown in full on the bottom
                viewTopRow = rowToScrollTo-imbrowser.visibleRowsOfThumbNails;
                imbrowser.hvsb.Value = imbrowser.hvsb.Max -(imbrowser.hvsb.Max/(imbrowser.hvsb.Max-imbrowser.visibleRowsOfThumbNails)) *viewTopRow;
            else
                % already in view
            end
            
        end
    end
    
    %% Image source
    methods (Access = private)
        function n = numberOfImages(imbrowser)
            if(iscell(imbrowser.imageSource))
                n = numel(imbrowser.imageSource);
            else
                n = numel(imbrowser.imageSource.Files);
            end
        end
        
        function im = readimage(imbrowser, ind)
            if(iscell(imbrowser.imageSource))
                im = imbrowser.imageSource{ind};
            else
                im = imbrowser.imageSource.readimage(ind);
            end
        end
        
        function removeFromInternalState(imbrowser, inds)
            % From source
            if(iscell(imbrowser.imageSource))
                imbrowser.imageSource(inds) = [];
            else
                imbrowser.imageSource.Files(inds) = [];
            end
            % From view
            delete(imbrowser.hImages(inds));
            imbrowser.hImages(inds) = [];
            % From background colors
            imbrowser.hImageBackGroundColors(inds) = [];
        end
        
        function removeCurrentlySelectedImages(imbrowser, varargin)
            
            % Note - This bit is specific to the OCR App
            % -------------------------------------------------------------
            toRemoveInds = imbrowser.currentSelection();
                        
            if(isempty(toRemoveInds))
                % nothing to do
                return;
            end
            
            toRemoveInds = imbrowser.currentSelection();
            imbrowser.removeFromInternalState(toRemoveInds);
            
            % Reflow and re-index all
            imbrowser.hIndsOfDirtyImages = 1:imbrowser.numberOfImages;
            imbrowser.respondToSizeChange();
            
            notify(imbrowser, 'RemoveSelection');
            
            imbrowser.setSelection([]);
            drawnow;
        end
    end
    
    %% Redraw
    methods (Access = private)
        function respondToSizeChange(imbrowser, varargin)
            
            parentPosition =getpixelposition(imbrowser.haxes);
            imbrowser.viewPortWidth  = parentPosition(3);
            imbrowser.viewPortHeight = parentPosition(4);
            
            sbWidth = imbrowser.scrollBarWidth*imbrowser.oneCharInPixels;
            
            % Full canvas size (in units of thumbnails) given the current
            % width
            totalThumbnailWidth= imbrowser.thumbNailSize(1)...
                +2*(imbrowser.thumbNailImagePadding+imbrowser.thumbNailCellPadding);
            wPixels = imbrowser.viewPortWidth - sbWidth;
            numColsOfThumbnails = floor(wPixels/totalThumbnailWidth);
            % min width of 1 thumbnail
            numColsOfThumbnails = max(numColsOfThumbnails,1);
            numRowsOfThumbnails = ceil(imbrowser.numberOfImages()/numColsOfThumbnails);
            
            % Number of thumbnails rows that can fit in view port
            % Includes partially visible ones too.
            totalThumbnailHeight = imbrowser.thumbNailSize(2)...
                +2*(imbrowser.thumbNailImagePadding+imbrowser.thumbNailCellPadding);
            numPartialRowsInViewPort = imbrowser.viewPortHeight/totalThumbnailHeight;
            
            imbrowser.canvasHeight = numRowsOfThumbnails*totalThumbnailHeight;
            
            % no horizontal scrolling, at least one thumbnail wide
            imbrowser.canvasWidth  = imbrowser.viewPortWidth; 
            imbrowser.canvasWidth  = max(imbrowser.canvasWidth, totalThumbnailHeight);
            
            
            % Dont let the following manual slider value changes trigger
            % updates.
            imbrowser.sliderChangeListner.Enabled = false;
            
            if(numRowsOfThumbnails>numPartialRowsInViewPort)
                % Update slider limits
                if( (imbrowser.hvsb.Value>numRowsOfThumbnails) ...
                        ||strcmp(imbrowser.hvsb.Visible,'off'))
                    % Slider goes to top
                    imbrowser.hvsb.Value = numRowsOfThumbnails;
                end
                imbrowser.hvsb.Max = numRowsOfThumbnails;
                
                % (Re)position Scroll bar on right
                imbrowser.hvsb.Position = ...
                    [imbrowser.viewPortWidth-sbWidth 0 sbWidth imbrowser.viewPortHeight];
                imbrowser.hvsb.Visible = 'on';
            else
                imbrowser.hvsb.Visible = 'off';
                % Scrollbar to top
                imbrowser.hvsb.Value = numRowsOfThumbnails;
                imbrowser.hvsb.Max   = numRowsOfThumbnails;
            end
            
            imbrowser.visibleColsOfThumbNails = numColsOfThumbnails;
            imbrowser.visibleRowsOfThumbNails  = numPartialRowsInViewPort;
            
            if(imbrowser.canvasHeight==0)
                % No images. Nothing to do.
                return;
            end
            
            % Manually do all the slider changes once. (which updates all
            % visible images too)
            imbrowser.sliderChanged();
            
            % Restore
            imbrowser.sliderChangeListner.Enabled = true;
        end
        
        function sliderChanged(imbrowser, varargin)
            % No horizontal scrolling;
            imbrowser.haxes.XLim = [0 imbrowser.viewPortWidth];
            
            % Slider top implies Value=Max bottom implies Value=0
            sliderPercent = 1 - imbrowser.hvsb.Value/imbrowser.hvsb.Max;
            % Top Of Ylim can go from 0 to canvasHeight-imbrowser.viewPortHeight;
            topOfYLim = sliderPercent*(imbrowser.canvasHeight-imbrowser.viewPortHeight);
            imbrowser.haxes.YLim = [topOfYLim topOfYLim+imbrowser.viewPortHeight];
            
            % Update the indices of thumbnails in view
            % view port
            xViewPort = imbrowser.haxes.XLim;
            yViewPort = imbrowser.haxes.YLim;
            
            totalThumbnailSize = imbrowser.thumbNailSize...
                +2*(imbrowser.thumbNailImagePadding+imbrowser.thumbNailCellPadding);
            
            % Update view port in terms of visible thumbnail indices
            imbrowser.visibleThumbNailsXIndRange = xViewPort/totalThumbnailSize(1);
            imbrowser.visibleThumbNailsYIndRange = yViewPort/totalThumbnailSize(2)+1;
            
            % Redraw content
            imbrowser.updateViewPortWithImages();
        end
        
        function updateViewPortWithImages(imbrowser, varargin)
            xRange = [floor(imbrowser.visibleThumbNailsXIndRange(1)) ceil(imbrowser.visibleThumbNailsXIndRange(2))];
            yRange = [floor(imbrowser.visibleThumbNailsYIndRange(1)) ceil(imbrowser.visibleThumbNailsYIndRange(2))];
            xRange(1) = max(xRange(1), 1);
            xRange(2) = min(xRange(2), imbrowser.visibleColsOfThumbNails);
            yRange(1) = max(yRange(1), 1);
            yRange(2) = min(yRange(2), imbrowser.hvsb.Max);
            
            for xImageInd = xRange(1):xRange(2)
                for yImageInd = yRange(1):yRange(2)
                    imbrowser.showImage(xImageInd, yImageInd);
                end
            end
        end
        
        function showImage(imbrowser, x,y)
            imageInd = (y-1)*imbrowser.visibleColsOfThumbNails+x;
            if(imageInd>imbrowser.numberOfImages)
                return;
            end
            
            thumbNailCellSize = imbrowser.thumbNailSize...
                +2*(imbrowser.thumbNailImagePadding+imbrowser.thumbNailCellPadding);
            xLoc = (x-1)*thumbNailCellSize(2);
            yLoc = (y-1)*thumbNailCellSize(1);
            
            % Does this image need updating?
            isDirty = any(imbrowser.hIndsOfDirtyImages==imageInd);
            
            % Already created?
            if(numel(imbrowser.hImages) <imageInd || isDirty)
                % create
                fullImage = imbrowser.readimage(imageInd);
                paddedThumbNail = repmat(...
                    reshape(imbrowser.thumbNailImagePaddingColor,[ 1 1 3]),...
                    [imbrowser.thumbNailSize+imbrowser.thumbNailImagePadding*2 1]);
                if(size(fullImage,1)>size(fullImage,2))
                    thumbNail = imresize(fullImage,[imbrowser.thumbNailSize(1), NaN],'nearest');
                else
                    thumbNail = imresize(fullImage,[NaN, imbrowser.thumbNailSize(2)],'nearest');
                end
                
                if(size(thumbNail,3)==1)
                    thumbNail = cat(3, thumbNail, thumbNail,thumbNail);
                end
                
                % Position the resized thumbnail at the center of the
                % paddedthumbnail
                leftOffset = imbrowser.thumbNailImagePadding+1+...
                    ceil( (size(paddedThumbNail,1)-2*imbrowser.thumbNailImagePadding-size(thumbNail,1)) /2);
                topOffset  = imbrowser.thumbNailImagePadding+1+...
                    ceil( (size(paddedThumbNail,2)-2*imbrowser.thumbNailImagePadding-size(thumbNail,2)) /2);
                rightEnd   = leftOffset+size(thumbNail,1)-1;
                bottomEnd  = topOffset+size(thumbNail,2)-1;
                paddedThumbNail(leftOffset:rightEnd,topOffset:bottomEnd,:) = thumbNail;
                
                if(isDirty)
                    % No longer dirty
                    if(imageInd<= numel(imbrowser.hImages))
                        delete(imbrowser.hImages(imageInd));
                    end
                    imbrowser.hIndsOfDirtyImages(imbrowser.hIndsOfDirtyImages==imageInd) = [];
                end
                
                imbrowser.hImages(imageInd) = image(xLoc, yLoc, paddedThumbNail,...
                    'Parent',imbrowser.haxes);
                imbrowser.hImages(imageInd).UserData.index = imageInd;
                imbrowser.hImages(imageInd).ButtonDownFcn  = @imbrowser.thisImageWasClicked;
                               
                if imbrowser.EnableContextMenu            
                    imbrowser.hImages(imageInd).UIContextMenu  = uicontextmenu('Parent',imbrowser.hParentFigure);
                    uimenu(imbrowser.hImages(imageInd).UIContextMenu, ...
                        'Label',vision.getMessage('vision:ocrTrainer:MoveToUnknown'),...
                        'Callback',@imbrowser.removeCurrentlySelectedImages);
                end                               
               
            else
                
                % reposition
                imbrowser.hImages(imageInd).XData = xLoc;
                imbrowser.hImages(imageInd).YData = yLoc;
            end
            
            
            
            if(any(imageInd==imbrowser.currentSelection))
                % Show selection color on the border
                unSelectedPaddedThumbNail = imbrowser.hImages(imageInd).CData;
                paddedThumbNail = repmat(...
                    reshape(imbrowser.thumbNailImageSelectionColor,[ 1 1 3]),...
                    [imbrowser.thumbNailSize+imbrowser.thumbNailImagePadding*2 1]);
                
                % Position the resized thumbnail at the center of the
                % paddedthumbnail
                leftOffset = imbrowser.thumbNailImagePadding+1;
                topOffset  = imbrowser.thumbNailImagePadding+1;
                rightEnd   = size(paddedThumbNail,1)-imbrowser.thumbNailImagePadding;
                bottomEnd  = size(paddedThumbNail,2)-imbrowser.thumbNailImagePadding;
                paddedThumbNail(leftOffset:rightEnd,topOffset:bottomEnd,:) = ...
                    unSelectedPaddedThumbNail(leftOffset:rightEnd,topOffset:bottomEnd,:);
                
                imbrowser.hImages(imageInd).CData = paddedThumbNail;
            else
                % Check for custom color for the border
                customBackgroundColor = imbrowser.hImageBackGroundColors{imageInd};
                if(~isempty(customBackgroundColor))
                    unSelectedPaddedThumbNail = imbrowser.hImages(imageInd).CData;
                    paddedThumbNail = repmat(...
                        reshape(customBackgroundColor,[ 1 1 3]),...
                        [imbrowser.thumbNailSize+imbrowser.thumbNailImagePadding*2 1]);
                    
                    % Position the resized thumbnail at the center of the
                    % paddedthumbnail
                    leftOffset = imbrowser.thumbNailImagePadding+1;
                    topOffset  = imbrowser.thumbNailImagePadding+1;
                    rightEnd   = size(paddedThumbNail,1)-imbrowser.thumbNailImagePadding;
                    bottomEnd  = size(paddedThumbNail,2)-imbrowser.thumbNailImagePadding;
                    paddedThumbNail(leftOffset:rightEnd,topOffset:bottomEnd,:) = ...
                        unSelectedPaddedThumbNail(leftOffset:rightEnd,topOffset:bottomEnd,:);
                    
                    imbrowser.hImages(imageInd).CData = paddedThumbNail;
                end
            end
            
        end
    end
end