% This class handles the display of the set of ROI labels.
classdef ROILabelSetDisplay < vision.internal.uitools.AppFigure
    
    properties(Constant)
        % Define heights of panels in char. char is used to scale across
        % different types of monitors (e.g. High DPI).
        AddLabelPanelHeight  = 3; % in char      
        AddLabelButtonHeight = 0.8 * 3;
        AddButtonTextColor = repelem(160/255,1,3); % a light gray
    end
    
    properties
        AddLabelPanel
        AddLabelButton
        AddLabelText
        LabelSetPanel   
        HelperText
        
        % The width depends on height and system settings and is
        % initialized during construction.
        AddLabelButtonWidth 
        AddLabelButtonSizeInPixels
    end
    
    properties(Dependent)
        % CurrentSelection The current selected item.
        CurrentSelection
        
        % NumItems The number of ROI Labels in the set.
        NumItems
    end
    
    properties(Access=private)
        % This holds the type of the parent tool
        ToolName
    end
    
    events
        % ROILabelSelected Event that is issued when an item is selected.
        ROILabelSelected
        
        % ROILabelModified Event that is issued when an item is modified.
        ROILabelModified

        % ROILabelRemoved Event that is issued when an item is removed.
        ROILabelRemoved
    end
    
    %======================================================================
    methods
        
        %------------------------------------------------------------------
        function this = ROILabelSetDisplay(toolName)
            nameDisplayedInTab = vision.getMessage(...
                'vision:labeler:ROILabelSetDisplayName');
            this = this@vision.internal.uitools.AppFigure(nameDisplayedInTab);
            
            this.ToolName = toolName;
            
            this.Fig.Resize = 'on'; 
                        
            initializeButtonWidth(this);
                        
            [addLabelPanelPos, labelSetPanelPos, buttonPos, helperPos] = uicontrolPositions(this);
            
            % Create panel to hold the "add label" button. Place it at the
            % top.
            this.AddLabelPanel = uipanel(this.Fig, ...
                'Units', 'char', ...
                'BorderType', 'line',...
                'HighlightColor', [0.65 0.65 0.65], ...
                'Position', addLabelPanelPos,...
                'Tag','AddLabelPanel');
            
            % Create the "add label" button. 
            addIcon = load(fullfile(toolboxdir('vision'),...
                'vision','+vision','+internal','+labeler','+tool','+icons',...
                'add_icon.mat'));
            addIcon = addIcon.addIcon;
            this.AddLabelButton = uicontrol('style','pushbutton', 'Parent', this.AddLabelPanel, ...
                'Units', 'char', ...                
                'CData',addIcon, ...
                'ForegroundColor', this.AddButtonTextColor, ...
                'Position', buttonPos,...
                'Tag','AddROILabelButton');
            
            if strcmpi(this.ToolName, 'imageLabeler')
                tip = vision.getMessage('vision:imageLabeler:AddNewROILabelToolTip');
            else
                tip = vision.getMessage('vision:labeler:AddNewROILabelToolTip');
            end
            
            txt = vision.getMessage('vision:labeler:AddNewROILabelButton');
            
            this.AddLabelButton.TooltipString = tip;
            
            width = numel(txt)+sum(isspace(txt))+10; % need to add extra space for spaces.
            textPos = [this.AddLabelButtonWidth+1 3/4 width 1.5];
            this.AddLabelText = uicontrol('style', 'text', ...
                'Parent', this.AddLabelPanel, ...
                'Units', 'char', ...
                'HorizontalAlignment', 'left', ...
                'String', txt, ...
                'Position', textPos);
           
            % add scrollable panel below the "add label" panel. Set it's
            % position using normalized units so it expands to fit as app
            % figure size is changed.
            this.LabelSetPanel = vision.internal.labeler.tool.ROILabelSetPanel(this.Fig, labelSetPanelPos);
            
            addlistener(this.LabelSetPanel, 'ItemSelected', @this.doROILabelSelected);
            addlistener(this.LabelSetPanel, 'ItemModified', @this.doROILabelModified);
            addlistener(this.LabelSetPanel, 'ItemRemoved', @this.doROILabelDeleted);
            
            this.Fig.SizeChangedFcn = @(varargin)this.doPanelPositionUpdate;
            if strcmpi(this.ToolName, 'imageLabeler')
                txt = vision.getMessage('vision:imageLabeler:ROIHelperText');
            else
                txt = vision.getMessage('vision:labeler:ROIHelperText');
            end
            this.HelperText = showHelperText(this, txt, helperPos);
            
        end
        
        %------------------------------------------------------------------
        % Configure display callbacks and listeners. These callbacks are
        % defined in the main app.
        %------------------------------------------------------------------
        function configure(this, selectionCallback, additionCallBack, ...
                modificationCallback, deletionCallback, varargin)
            
            % add listener to handle changes to selected item.
            addlistener(this, 'ROILabelSelected', selectionCallback);
            % add listener to handle changes to modified item.
            addlistener(this, 'ROILabelModified', modificationCallback);
            % add listener to handle deleted item.
            addlistener(this, 'ROILabelRemoved', deletionCallback);
            
            % attach callback to handle "new roi label" button
            this.AddLabelButton.Callback = additionCallBack;
            
            if nargin > 5
                % Override default window key press callback of scrollable
                % panel.
                keyPressCallback = varargin{1};
                this.Fig.WindowKeyPressFcn = keyPressCallback;
            end
        end
        
        %------------------------------------------------------------------
        function value = get.CurrentSelection(this)
            value = this.LabelSetPanel.CurrentSelection;
        end
        
        %------------------------------------------------------------------
        function value = get.NumItems(this)
            value = this.LabelSetPanel.NumItems;
        end
        
        %------------------------------------------------------------------
        function appendItem(this, data)
            this.LabelSetPanel.appendItem(data);
        end
        
        %------------------------------------------------------------------
        function modifyItem(this, idx, data)
            this.LabelSetPanel.modifyItem(idx, data);
        end
        
        %------------------------------------------------------------------
        function selectLastItem(this)
            this.LabelSetPanel.selectItem(this.NumItems);
        end
        
        %------------------------------------------------------------------
        function selectNextItem(this)
            this.LabelSetPanel.selectNextItem();
        end
        
        %------------------------------------------------------------------
        function selectPrevItem(this)
            this.LabelSetPanel.selectPrevItem();
        end
        
        %------------------------------------------------------------------
        function deleteItem(this, data)
            this.LabelSetPanel.deleteItem(data);
        end
        
        %------------------------------------------------------------------
        function deleteAllItems(this)
            this.LabelSetPanel.deleteAllItems();
        end
        
        %------------------------------------------------------------------
        function disableItem(this, idx)
            this.LabelSetPanel.disableItem(idx);
        end
        
        %------------------------------------------------------------------
        function disableAllItems(this)
            this.LabelSetPanel.disableAllItems();
        end
        
        %------------------------------------------------------------------
        function enableItem(this, idx)
            this.LabelSetPanel.enableItem(idx);
        end
        
        %------------------------------------------------------------------
        function enableAllItems(this)
            this.LabelSetPanel.enableAllItems();
        end
        
        %------------------------------------------------------------------
        function unselectToBeDisabledItems(this, idx)
            this.LabelSetPanel.unselectToBeDisabledItems(idx);
        end
        
        %------------------------------------------------------------------
        function freeze(this)
            this.AddLabelButton.Enable  = 'off';
            this.AddLabelText.Enable    = 'off';
            this.LabelSetPanel.freezeAllItems();
        end
        
        %------------------------------------------------------------------
        function unfreeze(this)
            this.AddLabelButton.Enable  = 'on';
            this.AddLabelText.Enable    = 'on';
            this.LabelSetPanel.unfreezeAllItems();
        end
    end
    
    %======================================================================
    % Utilities
    %======================================================================
    methods
        %------------------------------------------------------------------
        % Returns the uicontrol positions relative to the figure position.
        % This is used to keep all the panels and controls in the correct
        % spot as the figure is resized.
        %------------------------------------------------------------------
        function [addLabelPanel, labelSetPanel, buttonPos, helperText] = uicontrolPositions(this)
            figPos = hgconvertunits(this.Fig, this.Fig.Position, this.Fig.Units, 'char', this.Fig);
            addLabelPanel = [0 figPos(4)-this.AddLabelPanelHeight figPos(3) this.AddLabelPanelHeight];
            
            addLabelPanelNormalized = hgconvertunits(this.Fig, addLabelPanel, 'char', 'normalized', this.Fig);
            helperText = [0.05 addLabelPanelNormalized(2)-0.54 0.9 0.5];
            
            % scrollable panel units are normalized. This is just for
            % simplicity, and can be changed in the future.
            h = max(0, figPos(4)-addLabelPanel(4));
            labelSetPanel = hgconvertunits(this.Fig, [0 0 figPos(3) h], 'char', 'normalized', this.Fig);
           
            % button is left-justified in panel and centered vertically.                        
            panelPixPos = getpixelposition(this.AddLabelPanel);
            
            bottom = (panelPixPos(4) - this.AddLabelButtonSizeInPixels(2)) / 2 ;
            buttnPixPos = [1 bottom this.AddLabelButtonSizeInPixels];                
            buttonPos = hgconvertunits(this.Fig, buttnPixPos, 'pixels', 'char', this.Fig);
        end       
        
        %------------------------------------------------------------------
        % Initialize the button width based on the height, which is in
        % char. Equal values of char height and char width do not result in
        % a square, so button width is computed in pixels then converted to
        % char so we get a square button.
        %------------------------------------------------------------------
        function initializeButtonWidth(this)
            
            % Figure out the width in char given the height in char. This
            % is all to get a square button in char units.
            pos = hgconvertunits(...
                this.Fig, [0 0 0 this.AddLabelButtonHeight], 'char', 'pixels', this.Fig);                        
            pos = hgconvertunits(this.Fig, [0 0 pos(4) pos(4)], 'pixels', 'char', this.Fig);            
            
            this.AddLabelButtonWidth = pos(3);
            
            % Cache the size in pixels.
            pos = hgconvertunits(...
                this.Fig, [0 0 pos(3) pos(4)], 'char', 'pixels', this.Fig);    
            this.AddLabelButtonSizeInPixels = pos(3:4);
        end
    end
    
    %======================================================================
    % Callbacks
    %======================================================================
    methods
        function repositionROILabelInRow(this)
            if this.NumItems > 0
                [roiColorPanelStartX, roiTypePanelStartX] = getROIColorNTypePanelStartX(this);
                for i=1: this.NumItems
                   thisItem = this.LabelSetPanel.Items{i};
                   thisItem.ROIColorPanel.Position(1) = roiColorPanelStartX;
                   thisItem.ROITypePanel.Position(1) = roiTypePanelStartX;
                   %
                   maxTextLenInPixel = roiColorPanelStartX - thisItem.ROITextAndColorXSpacing - thisItem.TextStartX;
                   shortLabel = vision.internal.labeler.tool.shortenLabel(thisItem.ROILabelText.TooltipString, maxTextLenInPixel);
                   thisItem.ROILabelText.String = shortLabel;
                end                
            end
        end
        function doPanelPositionUpdate(this)
            [pos1, pos2, buttonPos, pos3] = uicontrolPositions(this);
            this.AddLabelPanel.Position  = pos1;            
            this.AddLabelButton.Position = buttonPos;
            this.LabelSetPanel.Position  = pos2;
            this.HelperText.Position     = pos3;
            repositionROILabelInRow(this);
        end
        
        %------------------------------------------------------------------
        function [roiColorPanelStartX, roiTypePanelStartX] = getROIColorNTypePanelStartX(this)
            assert(this.NumItems > 0);
            w = this.Fig.Position(3);
            itemObj = this.LabelSetPanel.Items{1};
            
            if w > itemObj.MinWidth
                if w > itemObj.MaxWidthReqForROILabelRow
                    roiColorPanelStartX = itemObj.MaxROIColorPanelStartX;
                else
                    %startX = w - 10-16-20-35;
                    % in the following equation, 
                    % the RHS parameters (except w) do not change
                    roiColorPanelStartX = w - itemObj.ROILabelRowRightClearance ....
                               - itemObj.ROITypePanel.Position(3) ...
                               - itemObj.ROIColorAndTypeXSpacing ...
                               - itemObj.ROIColorPanel.Position(3);
                end
            else
                roiColorPanelStartX = itemObj.MinROIColorPanelStartX;
            end
            
            roiTypePanelStartX = roiColorPanelStartX + ...
                itemObj.ROIColorPanel.Position(3) + ...
                itemObj.ROIColorAndTypeXSpacing;            
        end
        
        %------------------------------------------------------------------
        function doROILabelSelected(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'ROILabelSelected', data);
        end
        
        %------------------------------------------------------------------
        function doROILabelModified(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'ROILabelModified', data);
        end
        
        %------------------------------------------------------------------
        function doROILabelDeleted(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'ROILabelRemoved', data);
        end
    end
end