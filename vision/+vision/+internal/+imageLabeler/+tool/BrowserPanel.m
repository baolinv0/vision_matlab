% Class defines panel that holds image browser component.

% Copyright 2017 The MathWorks, Inc.
classdef BrowserPanel < handle
    
    properties
        % Figure Parent figure for browser panel.
        Figure
        
        %OuterPanel Contains the Panel holding the browser.
        OuterPanel
        
        % Panel The panel containing browser widget.
        Panel
        
        % Browser Image browser component.
        Browser
    end
    
    properties(Dependent)
        Position
        
        SelectedItemIndex
        
        % Indices to items currently visible in the browser.
        VisibleItemIndex
    end
    
    properties(Access = private)
        % Flag indicating whether interactions (mouse-clicks and
        % key-presses) are frozen. In this mode, the browser ignores
        % responses to key-presses and clicks.
        IsFrozen = false;
    end
    
    events
        ImageSelectedInBrowser
        ImageRemovedInBrowser
        ImageRotateInBrowser
    end
    
    methods
        function this = BrowserPanel(fig)
            this.Figure = fig;
            
            this.OuterPanel = uipanel('Parent', this.Figure,...
                'Units', 'pixels',...
                'BorderType', 'none');          
            
            this.Panel = uipanel('Parent', this.OuterPanel,...
                'Units', 'pixels',...
                'BorderType', 'none', ...
                'Tag', 'Browser', ...
                'DeleteFcn', @(varargin)delete(this.Browser)); % to delete browser object and avoid timer drool.
            
            this.Browser = vision.internal.imageLabeler.tool.HorizontalImageStrip(this.Panel);
            
            installContextMenu(this);
            
            addlistener(this.Browser, 'SelectionChange', @this.doImageSelected);
            addlistener(this.Browser, 'ImageRemovedInBrowser', @this.doImageRemoval);
            addlistener(this.Browser, 'ImageRotateInBrowser', @this.doImageRotate);
        end
        
        %------------------------------------------------------------------
        function doKeyPress(this, src)
            if ~this.IsFrozen
                this.Browser.keyPressFcn([], src);
            end
        end
        
        %------------------------------------------------------------------
        function TF = hasImages(this)
            TF = this.Browser.numberOfVisibleImages() > 0;
        end
        
        %------------------------------------------------------------------
        function loadImages(this, imageFilenames)
            this.Browser.loadImages(imageFilenames)
        end
        
        %------------------------------------------------------------------
        function appendImage(this, imageData)
            this.Browser.appendImage(imageData)
        end
        
        %------------------------------------------------------------------
        function selectImageByIndex(this, idx)
            this.Browser.selectImageByIndex(idx);
        end
        
        %------------------------------------------------------------------
        function filterSelectedImages(this)
            %filterSelectedImages filters the browser panel so that only
            %currently selected images are visible.
            
            this.Browser.filterSelectedImages();
        end
        
        %------------------------------------------------------------------
        function restoreAllImages(this)
            %restoreAllImages restores all images in the browser panel
            %clearing any previous filter.
            
            this.Browser.restoreAllImages();
        end
        
        %------------------------------------------------------------------
        function freeze(this)
            this.IsFrozen = true;
        end
        
        %------------------------------------------------------------------
        function unfreeze(this)
            this.IsFrozen = false;
        end
        
        %------------------------------------------------------------------
        function name = imageNameByIndex(this, idx)
            % return the name of the select image.
            name = this.Browser.imageFilenameByIndex(idx);
        end
        
        %------------------------------------------------------------------
        function set.Position(this, pos)
            this.OuterPanel.Position = pos;
            margin = 20; %pixels
            this.Panel.Position = [0 0 pos(3) pos(4)-margin];
        end
        
        %------------------------------------------------------------------
        function pos = get.Position(this)
            pos = this.OuterPanel.Position;
        end
        
        %------------------------------------------------------------------
        function idx = get.SelectedItemIndex(this)
            idx = this.Browser.CurrentSelection;
        end
        
        %------------------------------------------------------------------
        function idx = get.VisibleItemIndex(this)
            idx = this.Browser.BlockNumToImageNum;
        end
        
        %------------------------------------------------------------------
        function doMouseButtonDownFcn(this, varargin)
            % Forward to browser component.
            if ~this.IsFrozen
                this.Browser.mouseButtonDownFcn(varargin{:});
            end
        end
        
        %------------------------------------------------------------------`
        function doImageSelected(this, ~, ~)
            data = vision.internal.labeler.tool.ItemSelectedEvent(...
                this.Browser.CurrentSelection);
            notify(this, 'ImageSelectedInBrowser', data);
        end
        
        %------------------------------------------------------------------
        function setTimerToZero(this)
            % set timer to zero to enable programmatic image selection
            % in browser during algorithm runs
            this.Browser.CoalescePeriod = 0;
        end
        
        %------------------------------------------------------------------
        function resetTimer(this)
            this.Browser.CoalescePeriod = 1;
        end
        
        %------------------------------------------------------------------
		function doImageRemoval(this, ~, data)
            notify(this, 'ImageRemovedInBrowser', data);
        end  
        
        %------------------------------------------------------------------
        function doImageRotate(this, ~, data)
            notify(this, 'ImageRotateInBrowser', data);
        end         
    end
    
    
    methods
        
        function installContextMenu(this)
            % Remove Image
            removeImageMenu = uimenu(this.Browser.hContextMenu, 'Label',...
                getString(message('vision:imageLabeler:RemoveImage')),...
                'Callback', @(~,~)removeSelectedImages(this.Browser),...
                'Tag', 'ContextMenuRemove'); %#ok<NASGU>
            
            % Rotate Image
            rotateImageMenu = uimenu(this.Browser.hContextMenu, 'Label',...
                getString(message('vision:imageLabeler:RotateImage')),...
                'Tag', 'ContextMenuRotate'); %#ok<NASGU> 
            
            % Rotate Image Clockwise
            rotateImageClockwiseMenu = uimenu(rotateImageMenu, 'Label',...
                getString(message('vision:imageLabeler:RotateImageClockwise')),...
                'Callback', @(~,~)rotateSelectedImages(this.Browser, 'Clockwise'),...
                'Tag', 'ContextMenuRotateClockwise'); %#ok<NASGU> 
            
            % Rotate Image Anti-Clockwise
            rotateImageCounterClockWiseMenu = uimenu(rotateImageMenu, 'Label',...
                getString(message('vision:imageLabeler:RotateImageCounterClockwise')),...
                'Callback', @(~,~)rotateSelectedImages(this.Browser, 'Counterclockwise'),...
                'Tag', 'ContextMenuRotateCounterclockwise'); %#ok<NASGU>             
        end

    end
end