classdef ImageStrip < handle
    properties
        
        JImageStrip
        JImageList
        
        MaxNumIcons = 13;
        
        % Cache for java objects
        Misc
        
        % variables needed to control HG/Java synchronization
        IsInteractionDisabledByScrollCallback = false;
        IsBrowserInteractionEnabled = true;
                
        ToolGroup
        Session  % image strip helps manage this, is there a way to abstract this better?
    end
    
    %----------------------------------------------------------------------
    % Properties to store callback function handles for image strip events.
    %----------------------------------------------------------------------
    properties
        % SelectionCallback Callback for selecting an image with the mouse.
        % Typically, apps will use this callback to draw the image in the
        % app's main display.
        SelectionCallback = []
        
        % MousePressedCallback Callback for dealing with other events such
        % as right-click context menus.
        MousePressedCallback   = []
        
        % KeyPressedCallback Callback for dealing with keyboard events in
        % the image strip, e.g. delete, up/down arrow, etc.
        KeyPressedCallback     = []
        
        % MouseMovedCallback Callback for dealing with mouse motion over
        % the image list, e.g. updating status text when mouse hovers over
        % an image.
        MouseMovedCallback     = []
    end
    
    %======================================================================
    % Public methods
    %======================================================================
    methods
        
        %------------------------------------------------------------------
        function this = ImageStrip(tool, session)
            this.ToolGroup = tool;
            this.Session = session;
        end
        
        %------------------------------------------------------------------
        % Set up image strip and attach callbacks.
        %------------------------------------------------------------------
        function update(this)
            
            this.JImageStrip = javaObject('com.mathworks.toolbox.vision.ImageStrip');
            this.JImageList = javaMethod('getImageList', this.JImageStrip);
            
            jfirstVisibleIndex = this.JImageList.getFirstVisibleIndex();
            jlastVisibleIndex  = this.JImageList.getLastVisibleIndex();
            
            if jfirstVisibleIndex == -1
                jfirstVisibleIndex = 0;
            end
            
            if jlastVisibleIndex == -1
                % By default, a full sized viewport can hold approx 13
                % icons, if the number of images selected is lesser than
                % that set it as the last visible index.
                jlastVisibleIndex = min(getNumel(this.Session.ImageSet)-1,...
                    this.MaxNumIcons);
            end
            
            for ind = jfirstVisibleIndex:jlastVisibleIndex
                this.Session.ImageSet.updateImageListEntry(ind); 
                javaMethodEDT('setListData', this.JImageList, ...
                    getIcons(this.Session.ImageSet))
            end
                          
            dataPanel = this.JImageStrip.getImagePanel();
            this.ToolGroup.setDataBrowser(dataPanel); % moved to parent
            
            % Add a listener for handling file selections
            this.addSelectionListener();
            
            if isempty(this.MousePressedCallback)
                popupListener = [];
            else
                popupListener = addlistener(this.JImageList, 'MousePressed', ...
                    this.MousePressedCallback);
            end
            
            if isempty(this.KeyPressedCallback)
                keyListener = [];
            else
                keyListener = addlistener(this.JImageList, 'KeyPressed', ...
                    this.KeyPressedCallback);
            end
            
            % Use the handle command to convert the Java object to a
            % handle object.
            scrollCallback = handle(this.JImageStrip.getScrollCallback);
            
            % Connect the callback to a nested function. The callback
            % class requires 'delayed' as the listener type.
            scrollListener = handle.listener(scrollCallback, 'delayed', @doScroll);
            
            if isempty(this.MouseMovedCallback)
                mouseMotionListener = [];
            else
                mouseMotionListener = addlistener(this.JImageList, 'MouseMoved', ...
                    this.MouseMovedCallback);
            end
            
            % Store handles to prevent going out of scope
            this.Misc.PopupListener       = popupListener;
            this.Misc.KeyListener         = keyListener;
            this.Misc.DataPanel           = dataPanel;
            this.Misc.ScrollListener      = scrollListener;
            this.Misc.MouseMotionListener = mouseMotionListener;
            
            %--------------------------------------------------------------
            function doScroll(~, ~)
                if this.Session.ImageSet.areAllIconsGenerated()
                    return;
                end
                
                drawnow(); % update Java UI components before proceeding
                this.setBrowserInteractionEnabled(false);
                this.IsInteractionDisabledByScrollCallback = true;
                
                jfirstVisibleIndex = this.JImageList.getFirstVisibleIndex();
                jlastVisibleIndex = this.JImageList.getLastVisibleIndex();
                
                for index = jfirstVisibleIndex:jlastVisibleIndex
                    doUpdate = this.Session.ImageSet.updateImageListEntry(index);
                    
                    if doUpdate
                        
                        % Do not move the "setWaiting" outside of the for loop!
                        % It will cause the down/up arrows on the scrollbar
                        % to misbehave
                        setWaiting(this.ToolGroup, true); % turn on waiting pointer
                        
                        selectedIndex = this.getSelectedImageIndex();
                        
                        javaMethodEDT('setListData', this.JImageList, ...
                            getIcons(this.Session.ImageSet));
                        
                        this.setSelectedImageIndex(selectedIndex);
                        drawnow();
                    end
                end
                
                this.setBrowserInteractionEnabled(true);
                this.IsInteractionDisabledByScrollCallback = false;
                setWaiting(this.ToolGroup, false); % turn off waiting pointer
                drawnow();
            end
            
        end % updateImageStrip               
        
        %------------------------------------------------------------------
        function updateListItems(this, idx)                                  
            
            this.Session.IsChanged = true;                                     
             
            if this.Session.hasAnyItems()
                javaMethodEDT('setListData', ...
                    this.JImageList, getIcons(this.Session.ImageSet));
                
                
                % conditionally update selected image. Setting the selected  to allow for
                % dynamic insertion into the list without forcing the
                % selection callback to be trigg
                %jLowestIdx = this.getSelectedImageIndex();
                
                if idx ~= 0
                    newIdx = idx;
                else
                    newIdx = 1;
                end
                
                this.setSelectedImageIndex(newIdx);
                
                drawnow();
            end
            
            % Update the UI before proceeding further
            drawnow;
            
        end
        
        %------------------------------------------------------------------
        % Removes selected images from the strip. A pop-up dialog is
        % displayed for user confirmation.
        %------------------------------------------------------------------
        function wasCanceled = removeSelectedItems(this, showConfirmationDialog)
            
            if nargin == 1
                showConfirmationDialog = true;
            end
            
            idxMultiselect = this.getSelectedImageIndices();
             
            if showConfirmationDialog
                                               
                % Display different warnings based on whether multiple images
                % are selected or just a single image is selected.
               
                cancelString = getString(message('MATLAB:uistring:popupdialogs:Cancel')); 
                if numel(idxMultiselect) > 1
                    
                    choice = questdlg(vision.getMessage('vision:trainingtool:RemoveImagesPrompt'),...
                        vision.getMessage('vision:trainingtool:RemoveImagesTitle'),...
                        vision.getMessage('vision:uitools:Remove'), cancelString, cancelString);
                    
                elseif (numel(idxMultiselect) == 1)
                    
                    choice = questdlg(vision.getMessage('vision:trainingtool:RemoveImagePrompt'),...
                        vision.getMessage('vision:trainingtool:RemoveImageTitle'),...
                        vision.getMessage('vision:uitools:Remove'), cancelString, cancelString);
                    
                end
                
                % Handle of the dialog is destroyed by the user
                % closing the dialog or the user pressed cancel
                wasCanceled = isempty(choice) || strcmp(choice, cancelString);
                
                if wasCanceled
                    return;
                end
            end
            
            this.Session.ImageSet.removeItem(idxMultiselect);
            
            this.Session.IsChanged = true;
            
            jLowestIdx = idxMultiselect(1)-1;
            
            if this.Session.hasAnyItems()
                javaMethodEDT('setListData', ...
                    this.JImageList, getIcons(this.Session.ImageSet));
                
                if jLowestIdx ~= 0
                    newIdx = jLowestIdx;
                else
                    newIdx = 1;
                end
                
                this.setSelectedImageIndex(newIdx);
                drawnow();
            end
            
            % Update the UI before proceeding further
            drawnow;
            
        end
        
        %------------------------------------------------------------------
        % Puts the image strip in focus
        %------------------------------------------------------------------
        function setFocus(this)
             %drawnow;
             if ishandle(this.JImageList)
                javaMethodEDT('requestFocus', this.JImageList);
             end
        end
        
        %------------------------------------------------------------------
        % Key pressed callback wrapper provides synchronisation and invokes
        % user defined key press callback functions.
        %------------------------------------------------------------------
        function processKeyPressedCallback(this, es, ed)
            if this.IsBrowserInteractionEnabled
                this.KeyPressedCallback(es,ed);
            end
        end               
        
        %------------------------------------------------------------------
        % Moves up and down the image strip.
        %------------------------------------------------------------------
        function changeImage(this, direction)
            
            currentIndex = this.getSelectedImageIndex();
            this.setSelectedImageIndex(currentIndex+direction);
            this.makeSelectionVisible(currentIndex+direction);
            
        end
        %------------------------------------------------------------------
        % returns index of the selected Image
        %------------------------------------------------------------------
        function idx = getSelectedImageIndex(this)
            idx = double(javaMethodEDT('getSelectedIndex', this.JImageList));
            idx = idx+1; % make it one based
        end
        
        %------------------------------------------------------------------
        function setSelectedImageIndex(this, index) % assumes 1-based index
            javaMethodEDT('setSelectedIndex', this.JImageList, index-1);
        end
        
        %------------------------------------------------------------------
        function makeSelectionVisible(this, index)
            javaMethodEDT('ensureIndexIsVisible', this.JImageList, index-1);
        end
        
        %------------------------------------------------------------------
        function [idx, jIdx] = getSelectedImageIndices(this)
            idx = double(this.JImageList.getSelectedIndices);
            jIdx = idx; % 0-based java index
            idx = idx+1; % make it one based
        end
        
        %------------------------------------------------------------------
        function wipeFigure(this, fig)
            if ishandle(fig)
                set(fig,'HandleVisibility','on');
                
                clf(fig); % clean out figure content
                
                zoom(fig, 'off');
                pan(fig, 'off');
                resetCallbacks();
                
                % turn off the visibility
                set(fig,'HandleVisibility','off');
            end
            
            %----------------------------------------
            function resetCallbacks
                % remove any hanging callbacks
                set(fig,'WindowButtonMotionFcn',[])
                set(fig,'WindowButtonUpFcn',[])
                set(fig,'WindowButtonDownFcn',[])
                set(fig,'WindowKeyPressFcn',[])
                set(fig,'WindowKeyReleaseFcn',[])
                
                % install listeners that temporarily block use of the
                % image browser
                iptaddcallback(fig,'WindowButtonDownFcn',@mouseClick);
                iptaddcallback(fig,'WindowButtonUpFcn',@mouseRelease);
                
                %----------------------------------------
                function mouseClick(~,~)
                    if ~this.IsInteractionDisabledByScrollCallback
                        this.setBrowserInteractionEnabled(false);
                    end
                end
                
                %----------------------------------------
                function mouseRelease(~,~)
                    if ~this.IsInteractionDisabledByScrollCallback
                        this.setBrowserInteractionEnabled(true);
                        drawnow();
                    end
                end
                
            end % end of resetCallbacks
            
        end % end of wipeFigure
        
        %------------------------------------------------------------------
        % This function can suspend and resume interaction with the
        % image browser.  This is particularly useful for synchronizing
        % Java UI with MATLAB's functions.
        %------------------------------------------------------------------
        function setBrowserInteractionEnabled(this, isEnabled)
            
            scrollPane = this.JImageStrip.getImageScrollPane();
            this.IsBrowserInteractionEnabled = isEnabled;
            
            if isEnabled
                javaMethod('enableImageScrolling', this.JImageStrip);
            else
                javaMethod('disableImageScrolling', this.JImageStrip);
            end
            
            javaMethodEDT('setEnabled', scrollPane, isEnabled);
            javaMethodEDT('setWheelScrollingEnabled', scrollPane, isEnabled);
        end                               
        
    end
    
    %======================================================================
    % Methods for processing selection callback.
    %======================================================================
    methods(Access = protected)
        
        %------------------------------------------------------------------
        % Add image selection callback to the image browser to handle the
        % update of the image display when a user selects an image from the
        % list.
        %------------------------------------------------------------------
        function addSelectionListener(this)
            if isempty(this.SelectionCallback)
                selectionListener = [];
            else
                selectionCallback = handle(this.JImageStrip.getSelectionCallback);
                
                % Connect the callback to a class function. The callback
                % class requires 'delayed' as the listener type.
                selectionListener = handle.listener(selectionCallback, ...
                    'delayed', @this.processImageSelectionCallBack);
            end
            
            % Cache the java object to prevent it from going out of scope.
            this.Misc.SelectionListener = selectionListener;
        end
        
        %------------------------------------------------------------------
        % Processes user defined image selection callback. Uses
        % synchronization guards to prevent issues between JAVA and MATLAB
        % UI elements.
        %------------------------------------------------------------------
        function processImageSelectionCallBack(this, es, ed)
            if this.Session.hasAnyItems
                this.preSelectionSyncGuard();
                
                this.SelectionCallback(es,ed); % execute user defined callback
                
                this.postSelectionSyncGuard();
            end
        end
        
        %------------------------------------------------------------------
        % Sync guard for executing selection callback.
        %------------------------------------------------------------------
        function preSelectionSyncGuard(this)
            if ~this.IsInteractionDisabledByScrollCallback
                drawnow();
                setWaiting(this.ToolGroup, true);
                this.setBrowserInteractionEnabled(false);
            end
        end
                
        %------------------------------------------------------------------
        % Sync guard for executing selection callback.
        %------------------------------------------------------------------
        function postSelectionSyncGuard(this)
            if ~this.IsInteractionDisabledByScrollCallback
                drawnow();
                this.setBrowserInteractionEnabled(true);
                setWaiting(this.ToolGroup, false);
            end
        end
                
    end
end
