% This class handles the display of the set of frame labels.
classdef FrameLabelSetDisplay < vision.internal.uitools.AppFigure       
    properties(Constant)
        % Define heights of panels in char. char is used to scale across
        % different types of monitors (e.g. High DPI).
        AddLabelPanelHeight  = 3; % in char      
        AddLabelButtonHeight = 0.8 * 3;
        AddButtonTextColor = repelem(160/255,1,3); % a light gray
        FrameLabelOptionsPanelHeight = 6 ; % in char
        RadioButtonWidth = 18; % in char
        ActionButtonWidth = 18; % in char
    end
    
    properties
        AddLabelPanel
        AddLabelButton
        AddLabelText
        LabelSetPanel
        HelperText

        FrameLabelOptionsBGPanel
        FrameLabelOptionsPanel
        FrameLabelOptionGroup
        FrameRadioButton
        FrameIntervalRadioButton
        AddFrameLabelButton
        RemoveFrameLabelButton
        
        % The width depends on height and system settings and is
        % initialized during construction.
        AddLabelButtonWidth 
        AddLabelButtonSizeInPixels
        
    end
    
    properties(Access=private)
        % This holds the type of the parent tool
        ToolName
    end
    
    properties(Dependent)
        % CurrentSelection The current selected item.
        CurrentSelection
        
        % NumItems The number of Scene Labels in the set.
        NumItems
    end
    
    events
        % FrameLabelAdded Event that is issued when a single or multiple
        %                 frames are labeled.
        FrameLabeled
        
        FrameUnlabeled
        
        % FrameLabelSelected Event that is issued when an item is selected.
        FrameLabelSelected
        
        % FrameLabelModified Event that is issued when an item is modified.
        FrameLabelModified

        % FrameLabelRemoved Event that is issued when an item is removed.
        FrameLabelRemoved
    end
    methods     
        %------------------------------------------------------------------
        function this = FrameLabelSetDisplay(toolName)            
            nameDisplayedInTab = vision.getMessage(...
                'vision:labeler:FrameLabelSetDisplayName');
            
            this = this@vision.internal.uitools.AppFigure(nameDisplayedInTab);
            
            this.Fig.Resize = 'on'; 
            
            this.ToolName = toolName;
            
            initializeButtonWidth(this);
                        
            [addLabelPanelPos, labelSetPanelPos, buttonPos, ...
                frameOptionsPanelPos, frameOptionsBGPanelPos, helperPos] = uicontrolPositions(this);
            
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
            this.AddLabelButton = uicontrol('Style','pushbutton', ...
                'Parent', this.AddLabelPanel, ...
                'Units', 'char', ...
                'FontUnits', 'normalized',...
                'FontWeight', 'bold', ...
                'FontSize', .80,...
                'ForegroundColor', this.AddButtonTextColor, ...
                'CData', addIcon,...
                'Position', buttonPos,...
                'Tag','AddFrameLabelDefinitionButton');
            
            txt = vision.getMessage('vision:labeler:AddNewFrameLabel');
            this.AddLabelButton.TooltipString = txt;
            
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
            this.LabelSetPanel = vision.internal.labeler.tool.FrameLabelSetPanel(this.Fig, labelSetPanelPos);

            addlistener(this.LabelSetPanel, 'ItemSelected', @this.doFrameLabelSelected);
            addlistener(this.LabelSetPanel, 'ItemModified', @this.doFrameLabelModified);
            addlistener(this.LabelSetPanel, 'ItemRemoved', @this.doFrameLabelDeleted);
            
            % add panel for labeling options
            this.FrameLabelOptionsBGPanel = uipanel(this.Fig, ...
                'Units', 'char', ...
                'BorderType', 'line',...
                'HighlightColor', [0.65 0.65 0.65], ...
                'Position', frameOptionsBGPanelPos,...
                'Tag','FrameLabelOptionsBGPanel');
            
            this.FrameLabelOptionsPanel = uipanel(...
                this.FrameLabelOptionsBGPanel,...
                'Units', 'normalized', ...
                'BorderType', 'none',...
                'HighlightColor', [0.65 0.65 0.65], ...
                'Position', frameOptionsPanelPos,...
                'Tag','FrameLabelOptionsPanel');

            % the option panel does not expand to the whole figure. set the
            % figure color and remove the border of the panel. 
            % Note: revisit this for alternative way of centering
            % components. 
            % this.Fig.Color = this.FrameLabelOptionsPanel.BackgroundColor;

            if ~strcmpi(this.ToolName, 'imageLabeler')
                % add radio buttons for labeling options
                this.FrameLabelOptionGroup = uibuttongroup(...
                    this.FrameLabelOptionsPanel, ...
                    'Units', 'char', ...
                    'Visible','off',...
                    'BorderType','none',...
                    'Position',[1 0 this.RadioButtonWidth frameOptionsBGPanelPos(4)]);

                % Create two radio buttons in the button group.
                this.FrameRadioButton = uicontrol(...
                    this.FrameLabelOptionGroup, ...
                    'Style', 'radiobutton',...
                    'String',vision.getMessage('vision:labeler:FrameOption'),...
                    'HorizontalAlignment', 'left',...
                    'Units', 'char', ...                
                    'Position',[0 3 this.RadioButtonWidth 2],...
                    'Tag','SingleFrameRadioButton',...
                    'HandleVisibility','off', ...
                    'TooltipString', vision.getMessage('vision:labeler:FrameOptionToolTip'));

                this.FrameIntervalRadioButton = uicontrol(...
                    this.FrameLabelOptionGroup, ...
                    'Style', 'radiobutton',...
                    'String',vision.getMessage('vision:labeler:IntervalOption'),...
                    'HorizontalAlignment', 'left',...
                    'Units', 'char', ...                
                    'Position',[0 1 this.RadioButtonWidth 2],...
                    'Tag','TimeIntervalRadioButton',...
                    'HandleVisibility','off', ...
                    'TooltipString', vision.getMessage('vision:labeler:IntervalOptionToolTip'));

                % Make the uibuttongroup visible after creating child objects. 
                this.FrameLabelOptionGroup.Visible = 'on';
                
                % Starting position of the buttons
                frameButtonXPos = this.RadioButtonWidth+2;
            else
                frameButtonXPos = 5;
            end
            
            if strcmpi(this.ToolName, 'imageLabeler')
                addFrameLabelText = vision.getMessage('vision:imageLabeler:ApplySceneLabelToImage');
                removeFrameLabelText = vision.getMessage('vision:imageLabeler:RemoveSceneLabelFromImage');                
                addFrameLabelToolTip = vision.getMessage('vision:imageLabeler:AddFrameLabelToolTip');
                removeFrameLabelToolTip =  vision.getMessage('vision:imageLabeler:RemoveFrameLabelToolTip');
                % Giving a buffer space of 4 more characters, since the
                % text is longer compared to GTL
                buttonWidth = this.ActionButtonWidth + 4;
            else
                addFrameLabelText = vision.getMessage('vision:labeler:AddFrameLabel');
                removeFrameLabelText = vision.getMessage('vision:labeler:RemoveFrameLabel');                
                addFrameLabelToolTip = vision.getMessage('vision:labeler:AddFrameLabelToolTip');
                removeFrameLabelToolTip =  vision.getMessage('vision:labeler:RemoveFrameLabelToolTip');
                buttonWidth = this.ActionButtonWidth;
            end
            
            % create 'add' and 'remove' buttons
            this.AddFrameLabelButton = uicontrol(...
                'style','pushbutton', ...
                'Parent', this.FrameLabelOptionsPanel, ...
                'Units', 'char', ...                
                'String', addFrameLabelText,...
                'HorizontalAlignment', 'left',...
                'Position', [frameButtonXPos 3 buttonWidth 2],...
                'Callback', @this.doLabelFrame, ...
                'Tag','AddFrameLabelButton', ...
                'TooltipString', addFrameLabelToolTip);
            
            this.RemoveFrameLabelButton = uicontrol(...
                'style','pushbutton', ...
                'Parent', this.FrameLabelOptionsPanel, ...
                'Units', 'char', ...                
                'String', removeFrameLabelText,...
                'HorizontalAlignment', 'left',...
                'Position', [frameButtonXPos 1 buttonWidth 2],...
                'Callback', @this.doUnlabelFrame, ...
                'Tag','RemoveFrameLabelButton', ...
                'TooltipString', removeFrameLabelToolTip);
    
            this.Fig.SizeChangedFcn = @(varargin)this.doPanelPositionUpdate;
            
            this.HelperText = showHelperText(this, vision.getMessage('vision:labeler:FrameHelperText'), helperPos);
        end
                    
        %------------------------------------------------------------------
        % Configure display callbacks and listeners. These callbacks are
        % defined in the main app.
        %------------------------------------------------------------------
        function configure(this, ...
                labelFrameCallback, ...
                unlabelFrameCallback, ...
                selectionCallback, additionCallBack, ...
                modificationCallback, deletionCallback, varargin)
            
            addlistener(this, 'FrameLabeled', labelFrameCallback);
            
            addlistener(this, 'FrameUnlabeled', unlabelFrameCallback);
            
            % add listener to handle changes to selected item.
            addlistener(this, 'FrameLabelSelected', selectionCallback);
            % add listener to handle changes to modified item.
            addlistener(this, 'FrameLabelModified', modificationCallback);
            % add listener to handle deleted item.
            addlistener(this, 'FrameLabelRemoved', deletionCallback);

            % attach callback to handle "new frame label" button
            this.AddLabelButton.Callback = additionCallBack;
            
            if nargin > 7
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
            this.LabelSetPanel.disableItem(idx);
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
        
        %------------------------------------------------------------------
        function freezeOptionPanel(this)
            if ~strcmpi(this.ToolName, 'imageLabeler')
                this.FrameRadioButton.Enable  = 'off';
                this.FrameIntervalRadioButton.Enable  = 'off';
            end
            this.AddFrameLabelButton.Enable  = 'off';
            this.RemoveFrameLabelButton.Enable  = 'off';
        end
        
        %------------------------------------------------------------------
        function unfreezeOptionPanel(this)
            if ~strcmpi(this.ToolName, 'imageLabeler')            
                this.FrameRadioButton.Enable  = 'on';
                this.FrameIntervalRadioButton.Enable  = 'on';
            end
            this.AddFrameLabelButton.Enable  = 'on';
            this.RemoveFrameLabelButton.Enable  = 'on';
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
        function [addLabelPanel, labelSetPanel, buttonPos, ...
                optionsPanelPos, optionsBGPanelPos, helperText] = uicontrolPositions(this)
            
            % uipanels are stacked as follows
            % [ AddLabelPanel]
            % [ FrameLabelOptionsBGPanel]
            % [ LabelSetPanel]
        
            figPos = hgconvertunits(this.Fig, this.Fig.Position, this.Fig.Units, 'char', this.Fig);

            addLabelPanel = [0 figPos(4)-this.AddLabelPanelHeight figPos(3) this.AddLabelPanelHeight];

            % set option background panel
            optionsBGPanelPos = [0 addLabelPanel(2)-this.FrameLabelOptionsPanelHeight ...
                figPos(3) this.FrameLabelOptionsPanelHeight];
            
            optionsBGPanelNormalized = hgconvertunits(this.Fig, optionsBGPanelPos, 'char', 'normalized', this.Fig);
            helperText = [0.05 optionsBGPanelNormalized(2)-0.25 0.9 0.2];

            % set option panel, which is centered at the option background
            % panel. The location is normalized w.r.t background panel
            w = (this.RadioButtonWidth+this.ActionButtonWidth+5)/figPos(3);
            x = max(0,(1-w)/2);
            optionsPanelPos = [x 0 w 1];
            
            % scrollable panel units are normalized. This is just for
            % simplicity, and can be changed in the future.
            h = max(0, figPos(4)-addLabelPanel(4)-optionsBGPanelPos(4));
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
        
        function updateFrameLabelStatus(this, labelIDs)
            for i = 1:this.NumItems
                if ismember(i, labelIDs)
                    this.LabelSetPanel.listItemChecked(i);
                else
                    this.LabelSetPanel.listItemUnchecked(i);
                end
            end
        end

    end
    
    %======================================================================
    % Callbacks
    %======================================================================
    methods
        function repositionFrameLabelInRow(this)
            if this.NumItems > 0
                [frameColorPanelStartX, frameStatusPanelStartX] = getFrameColorNStatusPanelStartX(this);
                for i=1: this.NumItems
                   thisItem = this.LabelSetPanel.Items{i};
                   thisItem.FrameColorPanel.Position(1) = frameColorPanelStartX;
                   thisItem.FrameStatusPanel.Position(1) = frameStatusPanelStartX;     
                   %
                   maxTextLenInPixel = frameColorPanelStartX - thisItem.FrameTextAndColorXSpacing - thisItem.TextStartX;
                   shortLabel = vision.internal.labeler.tool.shortenLabel(thisItem.FrameLabelText.TooltipString, maxTextLenInPixel);
                   thisItem.FrameLabelText.String = shortLabel;                   
                end                
            end
        end
        function doPanelPositionUpdate(this)
            [pos1, pos2, buttonPos, pos3, pos4, pos5] = uicontrolPositions(this);
            this.AddLabelPanel.Position  = pos1;            
            this.AddLabelButton.Position = buttonPos;
            this.LabelSetPanel.Position  = pos2;  
            this.FrameLabelOptionsPanel.Position = pos3;
            this.FrameLabelOptionsBGPanel.Position = pos4;
            this.HelperText.Position = pos5;
            repositionFrameLabelInRow(this);
        end
        %------------------------------------------------------------------
        function [frameColorPanelStartX, frameStatusPanelStartX] = getFrameColorNStatusPanelStartX(this)
            assert(this.NumItems > 0);
            w = this.Fig.Position(3);
            itemObj = this.LabelSetPanel.Items{1};
            
            if w > itemObj.MinWidth
                if w > itemObj.MaxWidthReqForFrameLabelRow
                    frameColorPanelStartX = itemObj.MaxFrameColorPanelStartX;
                else
                    %startX = w - 10-16-20-35;
                    % in the following equation, 
                    % the RHS parameters (except w) do not change
                    frameColorPanelStartX = w - itemObj.FrameLabelRowRightClearance ....
                               - itemObj.FrameStatusPanel.Position(3) ...
                               - itemObj.FrameColorAndStatusXSpacing ...
                               - itemObj.FrameColorPanel.Position(3);
                end
            else
                frameColorPanelStartX = itemObj.MinFrameColorPanelStartX;
            end
            
            frameStatusPanelStartX = frameColorPanelStartX + ...
                itemObj.FrameColorPanel.Position(3) + ...
                itemObj.FrameColorAndStatusXSpacing;            
        end
        %------------------------------------------------------------------
        function doLabelFrame(this, varargin)
            
            if this.CurrentSelection == 0
                return;
            end
            data = vision.internal.labeler.tool.FrameLabelData;
            % Label ID happens to be the linear index
            data.LabelID = this.CurrentSelection;
            
            isGTL = strcmpi(this.ToolName, 'groundTruthLabeler');
            
            if isGTL && (this.FrameIntervalRadioButton.Value == this.FrameIntervalRadioButton.Max)
                data.ApplyToInterval = true;
            else
                data.ApplyToInterval = false;
            end
            notify(this, 'FrameLabeled', data);            
        end
        
        function checkFrameLabel(this, labelID)
            this.LabelSetPanel.listItemChecked(labelID);
        end
            
        %------------------------------------------------------------------
        function doUnlabelFrame(this, varargin)
            if this.CurrentSelection == 0
                return;
            end
            data = vision.internal.labeler.tool.FrameLabelData;
            data.LabelID = this.CurrentSelection;
            
            isGTL = strcmpi(this.ToolName, 'groundTruthLabeler');
            
            if isGTL && (this.FrameIntervalRadioButton.Value == this.FrameIntervalRadioButton.Max)
                data.ApplyToInterval = true;
            else
                data.ApplyToInterval = false;
            end
            notify(this, 'FrameUnlabeled', data);            
        end
        
        function uncheckFrameLabel(this, labelID)
            this.LabelSetPanel.listItemUnchecked(labelID);
        end
        
        %------------------------------------------------------------------
        function doFrameLabelSelected(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'FrameLabelSelected', data);
        end
        
        %------------------------------------------------------------------
        function doFrameLabelModified(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'FrameLabelModified', data);
        end
        
        %------------------------------------------------------------------
        function doFrameLabelDeleted(this, ~, data)
            % Pass the event on to the main app.
            notify(this, 'FrameLabelRemoved', data);
        end
        
    end
end