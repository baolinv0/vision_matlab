% This class implements an frame label item that is shown in the
% FrameLabelPanel list. 
classdef FrameLabelItem < vision.internal.labeler.tool.ListItem
    
    % Define constant values for selected/unselected 
    properties(Constant)
        MinWidth = 185; 
        Shift = 80;
        SelectedBGColor = [0.9882    0.9882    0.8627];
        UnselectedBGColor = [0.94 0.94 0.94];        
        ArrowIconStartX = 9;
        ArrowIconW = 10;
        ArrowAndTextSpaceX = 10;
        MaxTextWidth = 200;% in pixel
        TextNColorSpaceX = 20;
        FrameLabelRowRightClearance = 10;
        FrameColorAndStatusXSpacing = 10;
        FrameTextAndColorXSpacing = 10;
        
        FrameColorPanelW = 8;
        FrameColorPanelH = 16;
        
        FrameStatusIconW = 16;
        RightClearance = 10;
        IconHighlightedIntensity = 0.4;
    end             
 
    properties
        Index;
        TextStartX;
        MinFrameColorPanelStartX;
        MaxWidthReqForFrameLabelRow;  
        MaxFrameColorPanelStartX;
        Panel;
        
        RightDownArrowPanel;
        %%
        RightDownArrowImgHnd;
                
        DownArrowSelectCData;
        DownArrowUnselectCData;
        
        RightArrowSelectCData;        
        RightArrowUnselectCData;
        
        %%
        FrameStatusImgHnd;
                
        FrameStatusSelectCData;
        FrameStatusUnselectCData;
        
        %%
        FrameColorPanel;

        FrameLabelText;
        FrameStatusPanel;

        DescriptionEditBox;
        
        ItemContextMenu;

        IsExpanded;
        IsDisabled;
        IsSelected;
        Description;        
    end
    
    methods
        function this = FrameLabelItem(parent, idx, data)
            setConsDependentProps(this);
            
            computeDownRightArrowIconsCData(this);
            computeFrameStatusIconsCData(this);
            
            this.Index = idx;
            this.IsDisabled = false;   
            this.IsExpanded = false;            
            
            containerW = getContainerWidth(this, parent);
            
            % Main panel --------------------------------------------------
            panelW = max(this.MinWidth, containerW);
            this.Panel = uipanel('Parent', parent,...
                'Visible', 'off',...
                'Units', 'pixels', ...
                'BackgroundColor', this.UnselectedBGColor, ...
                'Position', [0 0 panelW 28], ...
                'ButtonDownFcn', @this.doButtonDownFcn);

            % Right arrow -------------------------------------------------
            ArrowIconH = this.ArrowIconW;
            this.RightDownArrowPanel = uipanel('Parent', this.Panel,...
                'Visible', 'on',...
                'Units', 'pixels', ...
                'BackgroundColor', parent.BackgroundColor, ...
                'BorderType','none', ...
                'Position', [this.ArrowIconStartX 9 this.ArrowIconW ArrowIconH]);

            showArrowIconAndSaveHandle(this);
            % 'ButtonDownFcn' must be on image ('ButtonDownFcn' on uipanel, 
            % callback on panel will not work,
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', @this.doExpandButtonDownFcn);
            
            % Text label --------------------------------------------------
            textPos = [this.TextStartX 0 this.MaxTextWidth 20];
            [frameColorPanelStartX, frameStatusPanelStartX] = getFrameColorNStatusPanelStartX(this, containerW);
            maxTextLenInPixel = frameColorPanelStartX - this.FrameTextAndColorXSpacing - this.TextStartX;
            fullLabel = data.Label;
            shortLabel = vision.internal.labeler.tool.shortenLabel(fullLabel, maxTextLenInPixel);
            this.FrameLabelText = uicontrol('Style', 'text', ...
                'Parent', this.Panel,...
                'TooltipString', fullLabel,...
                'String', shortLabel,...
                'Position', textPos, ...
                'FontName', 'Arial', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'inactive', ...
                'ButtonDownFcn', @this.doButtonDownFcn);
            
            % Frame color -------------------------------------------------             
            this.FrameColorPanel = uipanel('Parent', this.Panel,...
                'Units', 'pixels', ...
                'BorderType','none', ...
                'BackgroundColor', data.Color, ...
                'Position', [frameColorPanelStartX 6 this.FrameColorPanelW this.FrameColorPanelH], ...
                'ButtonDownFcn', @this.doButtonDownFcn);
            
            % Frame status ------------------------------------------------ 
            FrameStatusIconH = this.FrameStatusIconW;            
            this.FrameStatusPanel = uipanel('Parent', this.Panel,...
                'Units', 'pixels', ...
                'BorderType','none', ...
                'BackgroundColor', this.UnselectedBGColor, ...
                'Position', [frameStatusPanelStartX 6 this.FrameStatusIconW FrameStatusIconH],...
                'Tag',sprintf('%s_StatusIcon',data.Label),...
                'Visible', 'off');
            
            showFrameStatusIconAndSaveHandle(this);
            set(this.FrameStatusImgHnd, 'ButtonDownFcn', @this.doButtonDownFcn);
            
            % ROI description --------------------------------------------- 
            this.Description = data.Description;            
            this.DescriptionEditBox = uicontrol('Parent', this.Panel, ...
                'Style','edit',...
                'Max', 5,...
                'String', this.Description,...
                'Position', [16, 30, this.MinWidth-16, 50],...
                'HorizontalAlignment', 'left',...
                'Enable', 'inactive', ...
                'Visible', 'off');
            
            % Context menu ------------------------------------------------
            panelFigure = ancestor(this.Panel, 'Figure');
            % Cache context menu in order to allow restoring it after the
            % item is disabled.
            this.ItemContextMenu = uicontextmenu(panelFigure);
            uimenu(this.ItemContextMenu,'Label',...
                vision.getMessage('vision:labeler:ContextMenuEdit'),...
                'Callback', @this.OnCallbackEditItem);
            uimenu(this.ItemContextMenu,'Label',...
                vision.getMessage('vision:labeler:ContextMenuDelete'),...
                'Callback', @this.OnCallbackDeleteItem);
            this.Panel.UIContextMenu = this.ItemContextMenu;
            this.FrameLabelText.UIContextMenu = this.ItemContextMenu;
            this.DescriptionEditBox.UIContextMenu = this.ItemContextMenu;
        end

        function setConsDependentProps(this)
            this.TextStartX = this.ArrowIconStartX + this.ArrowIconW + ...
                this.ArrowAndTextSpaceX;
            this.MaxFrameColorPanelStartX = this.TextStartX + this.MaxTextWidth + ...
                this.TextNColorSpaceX;
            this.MaxWidthReqForFrameLabelRow = this.MaxFrameColorPanelStartX + ...
                this.FrameColorPanelW + ...
                this.FrameColorAndStatusXSpacing + this.FrameStatusIconW + ...
                this.RightClearance;
            this.MinFrameColorPanelStartX = this.MinWidth ...
                - this.FrameLabelRowRightClearance ....
                - this.FrameStatusIconW ...
                - this.FrameColorAndStatusXSpacing ...
                - this.FrameColorPanelW;
        end
        %------------------------------------------------------------------
        function containerW = getContainerWidth(~, parent)
              fig = ancestor(parent, 'Figure');
              containerW = fig.Position(3);
        end
        
        function imOut = blendImageWithBG(this, imIn, bgColor)
            if ismatrix(imIn)
                assert(isa(imIn, 'logical'));
                % True means highlighted pixel.
                % False means show background.
                imIn = double(imIn);
                imOut = zeros([size(imIn) 3],'like', imIn);
                tmp = imIn(:,:);
                idx = (tmp==0);
                for i=1:3
                    tmp(idx) = bgColor(i);
                    imOut(:,:,i) = tmp;
                end
                imOut(imOut==1) = this.IconHighlightedIntensity;
            else
                imIn = im2double(imIn);
                imOut = imIn;
                tmp = sum(imIn, 3);
                idx1 = (tmp<0.2);
                idx2 = (tmp>=0.2&tmp<0.35);
                for i=1:3
                    tmp = imIn(:,:,i);
                    tmp(idx1) = bgColor(i);
                    tmp(idx2) = tmp(idx2)*0.3+bgColor(i)*0.7;
                    imOut(:,:,i) = tmp;
                end
            end
        end
        
        function  computeDownRightArrowIconsCData(this)
            downArrowIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','arrow_down.png');
            downArrowIconData = imread(downArrowIconPath);
            this.DownArrowSelectCData = blendImageWithBG(this, downArrowIconData, this.SelectedBGColor);
            this.DownArrowUnselectCData = blendImageWithBG(this, downArrowIconData, this.UnselectedBGColor);
            
            rightArrowIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','arrow_right.png');
            rightArrowIconData = imread(rightArrowIconPath);            
            this.RightArrowSelectCData = blendImageWithBG(this, rightArrowIconData, this.SelectedBGColor);
            this.RightArrowUnselectCData = blendImageWithBG(this, rightArrowIconData, this.UnselectedBGColor);
        end
        
        function  computeFrameStatusIconsCData(this)
            frameStatusIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','GreenCheck_16px.png');
            frameStatusIconData = imread(frameStatusIconPath);
            this.FrameStatusSelectCData = blendImageWithBG(this, frameStatusIconData, this.SelectedBGColor);
            this.FrameStatusUnselectCData = blendImageWithBG(this, frameStatusIconData, this.UnselectedBGColor);            
        end
        
        function showArrowIconAndSaveHandle(this)
            hax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', this.RightDownArrowPanel);
            this.RightDownArrowImgHnd = imshow(this.RightArrowSelectCData,[],'InitialMagnification','fit','Parent',hax);
        end
        
        function showFrameStatusIconAndSaveHandle(this)
            hax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', this.FrameStatusPanel);
            this.FrameStatusImgHnd = imshow(this.FrameStatusSelectCData,[],'InitialMagnification','fit','Parent',hax);
        end
        
        %------------------------------------------------------------------
        function [frameColorPanelStartX, frameStatusPanelStartX] = getFrameColorNStatusPanelStartX(this, containerW)
            w = containerW;
            
            if w > this.MinWidth
                if w > this.MaxWidthReqForFrameLabelRow
                    frameColorPanelStartX = this.MaxFrameColorPanelStartX;
                else
                    %startX = w - 10-16-20-35;
                    % in the following equation, 
                    % the RHS parameters (except w) do not change
                    frameColorPanelStartX = w - this.FrameLabelRowRightClearance ....
                               - this.FrameStatusIconW ...
                               - this.FrameColorAndStatusXSpacing ...
                               - this.FrameColorPanelW;
                end
            else
                frameColorPanelStartX = this.MinFrameColorPanelStartX;
            end
            
            frameStatusPanelStartX = frameColorPanelStartX + ...
                this.FrameColorPanelW + ...
                this.FrameColorAndStatusXSpacing;            
        end
        %------------------------------------------------------------------
        % Route the button down function to issue the ListItemSelected
        % event. Any other uicontrol button down function can issue this
        % event to trigger the a selection event. 
        %------------------------------------------------------------------
        function doButtonDownFcn(this, varargin)
            
            if this.IsDisabled
                return;
            end
            
            data = vision.internal.labeler.tool.ItemSelectedEvent(this.Index);                
            notify(this, 'ListItemSelected', data);
        end
        
        function doExpandButtonDownFcn(this, varargin)
            
            if this.IsDisabled
                return;
            end
            
            doButtonDownFcn(this, varargin{:});
            
            data = vision.internal.labeler.tool.ItemSelectedEvent(this.Index);  
            
            if this.IsExpanded
                notify(this, 'ListItemShrinked', data);
            else
                notify(this, 'ListItemExpanded', data);
            end
        end
        
        function select(this)
            this.Panel.BackgroundColor = this.SelectedBGColor;
            if this.IsExpanded
              this.RightDownArrowImgHnd.CData = this.DownArrowSelectCData;              
            else
              this.RightDownArrowImgHnd.CData = this.RightArrowSelectCData;  
            end
            
            this.FrameStatusPanel.BackgroundColor = this.SelectedBGColor;
            this.FrameStatusImgHnd.CData = this.FrameStatusSelectCData;
                
            this.FrameLabelText.BackgroundColor = this.SelectedBGColor;
            this.FrameLabelText.FontWeight = 'bold';
            this.FrameLabelText.Enable = 'on'; % needed so that tootip is visible
            this.IsSelected = true;
            this.DescriptionEditBox.BackgroundColor = this.SelectedBGColor;
        end
        
        function unselect(this)
            this.Panel.BackgroundColor = this.UnselectedBGColor;
            if this.IsExpanded
              this.RightDownArrowImgHnd.CData = this.DownArrowUnselectCData;
            else
              this.RightDownArrowImgHnd.CData = this.RightArrowUnselectCData;  
            end
            
            this.FrameStatusPanel.BackgroundColor = this.UnselectedBGColor;
            this.FrameStatusImgHnd.CData = this.FrameStatusUnselectCData;
            
            this.FrameLabelText.BackgroundColor = this.UnselectedBGColor;
            this.FrameLabelText.FontWeight = 'normal';
            this.FrameLabelText.Enable='inactive'; % tootip no longer visible
            this.IsSelected = false;
            this.DescriptionEditBox.BackgroundColor = this.UnselectedBGColor;
        end
        
        function disable(this)
            this.IsDisabled = true;
            
            this.FrameLabelText.Enable = 'off'; % does not show tooltip
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', '');
            
            freeze(this);
        end
        
        function enable(this)
            this.IsDisabled = false;
            
            if this.IsSelected
               this.FrameLabelText.Enable = 'on'; % needed so that tootip is visible (doesn't show tooltip in 'inactive' state)
            else
               this.FrameLabelText.Enable = 'inactive';
            end            
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', @this.doExpandButtonDownFcn);
            
            unfreeze(this);
        end
        
        function freeze(this)
            this.Panel.UIContextMenu                = gobjects(0);
            this.FrameLabelText.UIContextMenu       = gobjects(0);
            this.DescriptionEditBox.UIContextMenu   = gobjects(0);
        end
        
        function unfreeze(this)
            this.Panel.UIContextMenu                = this.ItemContextMenu;
            this.FrameLabelText.UIContextMenu       = this.ItemContextMenu;
            this.DescriptionEditBox.UIContextMenu   = this.ItemContextMenu;
        end
        
        function expand(this)
            if this.IsExpanded
                return;
            end

            this.RightDownArrowImgHnd.CData = this.DownArrowSelectCData;
            
            this.Panel.Position(4) = this.Panel.Position(4) + this.Shift;
            this.RightDownArrowPanel.Position(2) = this.RightDownArrowPanel.Position(2) + this.Shift;
            this.FrameLabelText.Position(2)      = this.FrameLabelText.Position(2) + this.Shift;
            this.FrameColorPanel.Position(2)     = this.FrameColorPanel.Position(2) + this.Shift;
            this.FrameStatusPanel.Position(2)    = this.FrameStatusPanel.Position(2) + this.Shift;  
            
            this.DescriptionEditBox.Visible = 'on';
            this.IsExpanded = ~this.IsExpanded;
        end
        
        function shrink(this)
            if ~this.IsExpanded
                return;
            end
            
            this.RightDownArrowImgHnd.CData = this.RightArrowSelectCData;

            this.Panel.Position(4) = this.Panel.Position(4) - this.Shift;
            this.RightDownArrowPanel.Position(2) = this.RightDownArrowPanel.Position(2) - this.Shift;
            this.FrameLabelText.Position(2)      = this.FrameLabelText.Position(2) - this.Shift;
            this.FrameColorPanel.Position(2)     = this.FrameColorPanel.Position(2) - this.Shift;
            this.FrameStatusPanel.Position(2)    = this.FrameStatusPanel.Position(2) - this.Shift;   

            set(this.DescriptionEditBox, 'Visible', 'off'); 
            this.IsExpanded = ~this.IsExpanded;
        end
        
        function modify(this, frameLabel)
            this.Description = frameLabel.Description;
            this.DescriptionEditBox.String = this.Description;
        end
        
        function checkStatus(this)
            set(this.FrameStatusPanel,'Visible','On');
        end
        
        function UncheckStatus(this)
            set(this.FrameStatusPanel,'Visible','Off');
        end
        
        %------------------------------------------------------------------
        function OnCallbackEditItem(this, varargin)
            
            data = vision.internal.labeler.tool.ItemModifiedEvent(this.Index, this.Description);
            notify(this, 'ListItemModified', data);
        end
        
        %------------------------------------------------------------------
        function OnCallbackDeleteItem(this, varargin)
            data = vision.internal.labeler.tool.ItemSelectedEvent(this.Index);
            notify(this, 'ListItemDeleted', data);
        end
        
        %------------------------------------------------------------------
        function adjustWidth(this, parentWidth)    
            this.Panel.Position(3) = max(this.MinWidth, parentWidth);            
            this.DescriptionEditBox.Position(3) = this.Panel.Position(3)-16;
        end
        
        %------------------------------------------------------------------
        function delete(this)
            delete(this.Panel);
            delete(this.ItemContextMenu);
        end
    end           
end