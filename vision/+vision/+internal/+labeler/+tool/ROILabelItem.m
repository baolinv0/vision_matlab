% This class implements an ROI Label item that is shown in the
% ROILabelPanel list. 
classdef ROILabelItem < vision.internal.labeler.tool.ListItem
    
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
        ROILabelRowRightClearance = 10;
        ROIColorAndTypeXSpacing = 10;
        ROITextAndColorXSpacing = 10;
        
        ROIColorPanelW = 8;
        ROIColorPanelH = 16;
        ROITypeIconW = 16;
        RightClearance = 10;
        IconHighlightedIntensity = 0.4;
    end             
 
    properties
        Index;
        TextStartX;
        MinROIColorPanelStartX;
        MaxWidthReqForROILabelRow;  
        MaxROIColorPanelStartX;
        Panel;
        
        RightDownArrowPanel;
        
        
        %%
        RightDownArrowImgHnd;
                
        DownArrowSelectCData;
        DownArrowUnselectCData;
        
        RightArrowSelectCData;        
        RightArrowUnselectCData;
        
        %%
        ROITypeImgHnd;
                
        RectSelectCData;
        RectUnselectCData;
        
        LineSelectCData;        
        LineUnselectCData;
        
        PixelLabelSelectCData;
        PixelLabelUnselectCData;
        
        %%
        ROIColorPanel;

        ROILabelText;
        ROITypePanel;

        DescriptionEditBox;
        
        ItemContextMenu;

        IsExpanded;
        IsDisabled;
        IsSelected;
        IsROIRect;
        Description;
        
        Data
    end
    
    methods
        function this = ROILabelItem(parent, idx, data)
            setConsDependentProps(this);
            
            computeDownRightArrowIconsCData(this);
            computeROITypeIconsCData(this);
            
            this.Index = idx;
            this.IsDisabled = false;   
            this.IsExpanded = false;
            this.Data = data;
            this.IsROIRect = (data.ROI == labelType.Rectangle);

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
            % callback on panel will not work
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', @this.doExpandButtonDownFcn);
            
            % Text label --------------------------------------------------
            textPos = [this.TextStartX 0 this.MaxTextWidth 20];
            [roiColorPanelStartX, roiTypePanelStartX] = getROIColorNTypePanelStartX(this, containerW);
            maxTextLenInPixel = roiColorPanelStartX - this.ROITextAndColorXSpacing - this.TextStartX;
            fullLabel = data.Label;
            shortLabel = vision.internal.labeler.tool.shortenLabel(fullLabel, maxTextLenInPixel);
            this.ROILabelText = uicontrol('Style', 'text', ...
                'Parent', this.Panel,...
                'TooltipString', fullLabel,...
                'String', shortLabel,...
                'Position', textPos, ...
                'FontName', 'Arial', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left', ...
                'Enable', 'inactive', ...
                'ButtonDownFcn', @this.doButtonDownFcn);
            
            % ROI color ---------------------------------------------------             
            this.ROIColorPanel = uipanel('Parent', this.Panel,...
                'Units', 'pixels', ...
                'BorderType','none', ...
                'BackgroundColor', data.Color, ...
                'Position', [roiColorPanelStartX 6 this.ROIColorPanelW this.ROIColorPanelH], ...
                'ButtonDownFcn', @this.doButtonDownFcn,...
                'Tag', 'LabelerROIColor');
            
            % ROI Type ---------------------------------------------------- 
            ROITypeIconH = this.ROITypeIconW;            
            this.ROITypePanel = uipanel('Parent', this.Panel,...
                'Units', 'pixels', ...
                'BorderType','none', ...
                'BackgroundColor', this.UnselectedBGColor, ...
                'Position', [roiTypePanelStartX 6 this.ROITypeIconW ROITypeIconH]);
            
            showROITypeIconAndSaveHandle(this);
            % 'ButtonDownFcn' must be on image ('ButtonDownFcn' on uipanel, 
            % callback on panel will not work
            set(this.ROITypeImgHnd, 'ButtonDownFcn', @this.doButtonDownFcn);
            
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
            this.ROILabelText.UIContextMenu = this.ItemContextMenu;
            this.DescriptionEditBox.UIContextMenu = this.ItemContextMenu;
        end
        
        function setConsDependentProps(this)
            this.TextStartX = this.ArrowIconStartX + this.ArrowIconW + ...
                this.ArrowAndTextSpaceX;
            this.MaxROIColorPanelStartX = this.TextStartX + this.MaxTextWidth + ...
                this.TextNColorSpaceX;
            this.MaxWidthReqForROILabelRow = this.MaxROIColorPanelStartX + ...
                this.ROIColorPanelW + ...
                this.ROIColorAndTypeXSpacing + this.ROITypeIconW + ...
                this.RightClearance;
            this.MinROIColorPanelStartX = this.MinWidth ...
                - this.ROILabelRowRightClearance ....
                - this.ROITypeIconW ...
                - this.ROIColorAndTypeXSpacing ...
                - this.ROIColorPanelW;
        end
        
        function showArrowIconAndSaveHandle(this)
            hax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', this.RightDownArrowPanel);
            this.RightDownArrowImgHnd = imshow(this.RightArrowSelectCData,[],'InitialMagnification','fit','Parent',hax);
        end
        
        function showROITypeIconAndSaveHandle(this)
            hax = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', this.ROITypePanel);
            roiTypeCdata = getROITypeSelectedCData(this);
            this.ROITypeImgHnd = imshow(roiTypeCdata,[],'InitialMagnification','fit','Parent',hax);
        end            
            
        %------------------------------------------------------------------
        function [roiColorPanelStartX, roiTypePanelStartX] = getROIColorNTypePanelStartX(this, containerW)
            w = containerW;
            
            if w > this.MinWidth
                if w > this.MaxWidthReqForROILabelRow
                    roiColorPanelStartX = this.MaxROIColorPanelStartX;
                else
                    %startX = w - 10-16-20-35;
                    % in the following equation, 
                    % the RHS parameters (except w) do not change
                    roiColorPanelStartX = w - this.ROILabelRowRightClearance ....
                               - this.ROITypeIconW ...
                               - this.ROIColorAndTypeXSpacing ...
                               - this.ROIColorPanelW;
                end
            else
                roiColorPanelStartX = this.MinROIColorPanelStartX;
            end
            
            roiTypePanelStartX = roiColorPanelStartX + ...
                this.ROIColorPanelW + ...
                this.ROIColorAndTypeXSpacing;   
        end
        
        %------------------------------------------------------------------
        function containerW = getContainerWidth(~, parent)
              fig = ancestor(parent, 'Figure');
              containerW = fig.Position(3);
        end
        
        function roiTypeCdata = getROITypeSelectedCData(this)
            
            switch this.Data.ROI
                case labelType.Rectangle
                    roiTypeCdata = this.RectSelectCData;
                case labelType.Line
                    roiTypeCdata = this.LineSelectCData;
                case labelType.PixelLabel
                    roiTypeCdata = this.PixelLabelSelectCData;
                otherwise
                    error('unsupported label type');
            end
                 
        end
        
        function roiTypeCdata = getROITypeUnselectedCData(this)
            
            switch this.Data.ROI
                case labelType.Rectangle
                    roiTypeCdata = this.RectUnselectCData;
                case labelType.Line
                    roiTypeCdata = this.LineUnselectCData;
                case labelType.PixelLabel
                    roiTypeCdata = this.PixelLabelUnselectCData;
                otherwise
                    error('unsupported label type');
            end
           
        end
        
        function imOut = blendImageWithBG(this, imIn, bgColor)
            assert(isa(imIn, 'logical'));
            assert(ismatrix(imIn));
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
        
        function  computeROITypeIconsCData(this)
            rectROIIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','ROI_rectBW.png');
            rectROIIconData = imread(rectROIIconPath);
            this.RectSelectCData = blendImageWithBG(this, rectROIIconData, this.SelectedBGColor);
            this.RectUnselectCData = blendImageWithBG(this, rectROIIconData, this.UnselectedBGColor);
            
            lineROIIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','ROI_lineBW.png');
            lineROIIconData = imread(lineROIIconPath);            
            this.LineSelectCData = blendImageWithBG(this, lineROIIconData, this.SelectedBGColor);
            this.LineUnselectCData = blendImageWithBG(this, lineROIIconData, this.UnselectedBGColor);
            
            pixelLabelROIIconPath = fullfile(toolboxdir('vision'),'vision','+vision','+internal','+labeler','+tool','+icons','ROI_pixelLabelBW.png');
            pixelLabelROIIconData = imread(pixelLabelROIIconPath);            
            this.PixelLabelSelectCData = blendImageWithBG(this, pixelLabelROIIconData, this.SelectedBGColor);
            this.PixelLabelUnselectCData = blendImageWithBG(this, pixelLabelROIIconData, this.UnselectedBGColor);
            
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
            
            this.ROITypeImgHnd.CData = this.getROITypeSelectedCData();
            
            this.ROILabelText.BackgroundColor = this.SelectedBGColor;
            this.ROILabelText.FontWeight = 'bold';
            this.ROILabelText.Enable = 'on'; % needed so that tootip is visible
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
            
            this.ROITypeImgHnd.CData = this.getROITypeUnselectedCData();           

            this.ROILabelText.BackgroundColor = this.UnselectedBGColor;
            this.ROILabelText.FontWeight = 'normal';
            this.ROILabelText.Enable='inactive'; % tootip no longer visible
            this.IsSelected = false;
            this.DescriptionEditBox.BackgroundColor = this.UnselectedBGColor;            
        end
        
        function disable(this)
            this.IsDisabled = true;
            
            this.ROILabelText.Enable = 'off'; % does not show tooltip
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', '');
            
            freeze(this);
        end
        
        function enable(this)
            this.IsDisabled = false;
            
            if this.IsSelected
               this.ROILabelText.Enable = 'on'; % needed so that tootip is visible (doesn't show tooltip in 'inactive' state)
            else
               this.ROILabelText.Enable = 'inactive';
            end
            set(this.RightDownArrowImgHnd, 'ButtonDownFcn', @this.doExpandButtonDownFcn);
            
            unfreeze(this);
        end
        
        function freeze(this)
            this.Panel.UIContextMenu                = gobjects(0);
            this.ROILabelText.UIContextMenu            = gobjects(0);
            this.DescriptionEditBox.UIContextMenu   = gobjects(0);
        end
        
        function unfreeze(this)
            this.Panel.UIContextMenu                = this.ItemContextMenu;
            this.ROILabelText.UIContextMenu            = this.ItemContextMenu;
            this.DescriptionEditBox.UIContextMenu   = this.ItemContextMenu;
        end
        
        function expand(this)
            if this.IsExpanded
                return;
            end
            
            this.RightDownArrowImgHnd.CData = this.DownArrowSelectCData;
            
            this.Panel.Position(4) = this.Panel.Position(4) + this.Shift;
            this.RightDownArrowPanel.Position(2) = this.RightDownArrowPanel.Position(2) + this.Shift;
            this.ROILabelText.Position(2)        = this.ROILabelText.Position(2) + this.Shift;
            this.ROIColorPanel.Position(2)       = this.ROIColorPanel.Position(2) + this.Shift;            
            this.ROITypePanel.Position(2)        = this.ROITypePanel.Position(2) + this.Shift;   
            
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
            this.ROILabelText.Position(2)        = this.ROILabelText.Position(2) - this.Shift;
            this.ROIColorPanel.Position(2)       = this.ROIColorPanel.Position(2) - this.Shift;
            this.ROITypePanel.Position(2)        = this.ROITypePanel.Position(2) - this.Shift;   
            
            set(this.DescriptionEditBox, 'Visible', 'off'); 
            this.IsExpanded = ~this.IsExpanded;
        end
        
        function modify(this, roiLabel)
            this.Description = roiLabel.Description;
            this.DescriptionEditBox.String = this.Description;
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
