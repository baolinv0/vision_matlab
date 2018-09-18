% EnhancedROI is a rectangle with a close button and a text label

% Copyright 2016 The MathWorks, Inc.
classdef EnhancedROI < handle    
    properties(Access=private)
        Roi;
        ImageHandle;
        AxesHandle;
        FigHandle;
        
        ContextMenuDeleteFlag;
        ShouldFireEventOnSelection;
    end
    
    properties(Dependent)
        IsValid;
        IsSelected;
        BBox;
        Position;
        CategoryID;
        CopiedData;
    end
    
    events
        Delete
        Move
        Copy
        Cut
        Selected
    end
    
    methods
        %------------------------------------------------------------------
        function this = EnhancedROI(bbox, hAxes, hImage, hFig, catID, color, label, ...
                showLabel, contextMenuDeleteFlag, fireEventOnSelection)
            this.ImageHandle  = hImage;
            this.AxesHandle   = hAxes;
            if isempty(hFig)
               this.FigHandle = ancestor(this.AxesHandle,'Figure');
            else
               this.FigHandle = hFig;
            end
            if isa(bbox, 'imrect') 
                this.Roi = bbox;
            else
                this.Roi = iptui.imcropRect(hAxes, bbox - [0.5 0.5 0 0], this.ImageHandle);
            end
            this.Roi.setColor(color);
            this.IsSelected = false;
            userData.catID = catID;
            
            % Set flag for Delete affordance placement.
            % If true, Delete is part of context menu
            % If false, Delete is possible through icon
            if nargin>=9
                this.ContextMenuDeleteFlag = contextMenuDeleteFlag;
            else
                this.ContextMenuDeleteFlag = false;
            end
            
            %Set flag for event based handling of selection/un-selection 
            if nargin >=10
                handleSelectionWithEvent = fireEventOnSelection;
            else
                handleSelectionWithEvent = false;
            end
            this.ShouldFireEventOnSelection = handleSelectionWithEvent;
            set(this.Roi, 'UserData', userData);
            enhanceROIAppearance(this, color, label, showLabel)
        end
        
        function copiedData = get.CopiedData(this)
            copiedData.bbox = this.BBox + [0.5 0.5 0 0];
            copiedData.Position = copiedData.bbox; %Alias for bbox
            copiedData.categoryID = this.CategoryID;
            userData = get(this.Roi, 'UserData');
            copiedData.categoryName = userData.category.String;
            copiedData.color = this.Roi.getColor();
            copiedData.shape = 'rect';
        end
        %------------------------------------------------------------------
        function bbox = get.BBox(this)
            bbox = this.Roi.getPosition();
        end
        
        %------------------------------------------------------------------
        function pos = get.Position(this)
            %Alias for Bbox
            pos = this.BBox;
        end
        
        %------------------------------------------------------------------
        function catID = get.CategoryID(this)
           userData = get(this.Roi, 'UserData');
           catID = userData.catID;
        end
        
        %------------------------------------------------------------------
        function isValid = get.IsValid(this)
            isValid = this.Roi.isvalid();
        end
        
        %------------------------------------------------------------------
        function tf = get.IsSelected(this)
            if this.Roi.isvalid()
                tf = strcmpi(get(this.Roi, 'Selected'), 'on');
            else
                tf = false;
            end
        end
        
        %------------------------------------------------------------------
        function set.IsSelected(this, val)
            if ~this.Roi.isvalid()
                return;
            end
            
            roiPatch = findobj(this.Roi, 'type', 'patch');
            if val
                set(this.Roi, 'Selected', 'on');
                set(roiPatch, 'FaceColor', 'y');
            else
                set(this.Roi, 'Selected', 'off');
                set(roiPatch, 'FaceColor', 'none');
            end
        end
        
        %------------------------------------------------------------------
        function delete(this)
            if this.IsValid
                userData = get(this.Roi, 'userData');
                delete(userData.delIcon)
                delete(userData.category)
                delete(this.Roi);
            end
        end
        
        %------------------------------------------------------------------
        function setTextLabelVisible(this, showLabel)
            if this.IsValid
                userData = get(this.Roi, 'userData');
                if showLabel
                    userData.category.Visible = 'on';
                else
                    userData.category.Visible = 'off';
                end
            end
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function enhanceROIAppearance(this, catColor, catName, showLabel)
            if ~this.IsValid
                return;
            end
            
            roi = this.Roi;
                        
            % Specify the order in which objects are drawn to avoid Z
            % buffer fighting (which messes up the patch color when we
            % select an ROI and zoom into the image)
            set(this.AxesHandle, 'SortMethod', 'childorder');
                        
            userData = get(roi,'UserData');
            
            if ~this.ContextMenuDeleteFlag
            userData.delIcon = this.createDeleteIcon();
            else
                userData.delIcon = [];
            end
            userData.category = this.createCategoryLabel(catColor, catName,...
                showLabel);
            
            set(roi,'UserData',userData);
            
            % Set SelectionHighlight property to OFF
            % This is required to ensure that the IMRECT corner marker does
            % not block the delete text box
            set(roi, 'SelectionHighlight','off');
            roiChildren = get(roi, 'Children');
            set(roiChildren, 'SelectionHighlight','off');            
            
            % Set patch properties
            roiPatch = findall(roi, 'Type', 'Patch');
            set(roiPatch, 'FaceAlpha', 0.5);
            
            % Set patch callback to select/ unselect ROIs
            iptaddcallback(roiPatch, 'ButtonDownFcn', @clickOnROI);
            iptaddcallback(userData.category, 'ButtonDownFcn', @clickOnROI);
            
            this.setupContextMenu(roiPatch,userData.category);
                        
            % Constrain drawing of ROIs
            this.constrainROI();
            
            % Add callback to reposition delete button if moved
            roi.addNewPositionCallback(@this.doReposition);
                        
            % Nested Subfunctions of enhanceROIAppearence
            %----------------------------------------------------------
            function clickOnROI(~,~)
                
                fig         = ancestor(this.ImageHandle,'Figure');
                clickType   = get(fig, 'SelectionType');
                leftClick   = strcmp(clickType, 'normal');
                ctrlPressed = strcmp(get(fig, 'CurrentModifier'), 'control');
                rightClick  = strcmp(clickType,'alt')& isempty(ctrlPressed);
                ctrlClick   = strcmp(clickType,'alt')& ~isempty(ctrlPressed);
                
                if leftClick || rightClick
                    if ~this.IsSelected
                        if this.ShouldFireEventOnSelection
                            %Used by videoLabeler to uniformly handle
                            %selection of multiple types of widgets
                            notify(this,'Selected');
                        else
                            %Use HG techniques to handle changes
                            roiHandles = findall(this.AxesHandle, 'tag',...
                                'imrect','Selected','on');
                            if ~isempty(roiHandles)
                                roiPatches = findall(roiHandles,'Type',...
                                    'Patch');
                                unSelectROI(roiHandles, roiPatches);
                            end
                        end
                        selectROI(roi, roiPatch);
                    end
                elseif ctrlClick
                    if this.IsSelected
                        unSelectROI(roi, roiPatch);                        
                    else
                        selectROI(roi, roiPatch);
                    end
                end                
                drawnow;          
            end
        end 
        
        %----------------------------------------------------------
        function constrainROI(this)
            roiPosition = this.BBox;
            [y_extent, x_extent, ~] = size(get(this.ImageHandle,'CData'));
            % Get image boundaries
            xLimit = [0.5 x_extent+0.5];
            yLimit = [0.5 y_extent+0.5];
            
            if roiPosition(1) < xLimit(1) % Drawn beyond left axis
                this.Roi.setPosition([xLimit(1) roiPosition(2) ...
                    roiPosition(3)-(xLimit(1)-roiPosition(1)) roiPosition(4)]);
            elseif roiPosition(1)+roiPosition(3) > xLimit(2) % Drawn beyond right axis
                this.Roi.setPosition([roiPosition(1) roiPosition(2) ...
                    xLimit(2)-roiPosition(1) roiPosition(4)]);
            elseif roiPosition(2) < yLimit(1) % Drawn above top axis
                this.Roi.setPosition([roiPosition(1) yLimit(1) ...
                    roiPosition(3)  roiPosition(4)-(yLimit(1)-roiPosition(2))]);
            elseif roiPosition(2)+roiPosition(4) > yLimit(2) % Drawn above bottom axis
                this.Roi.setPosition([roiPosition(1) roiPosition(2) ...
                    roiPosition(3) yLimit(2)-roiPosition(2)]);
            end
        end
        
        %----------------------------------------------------------
        function doReposition(this, newPosition)
            userData = get(this.Roi,'UserData');
            category = userData.category;
           
           [y_extent, x_extent, ~] = size(get(this.ImageHandle,'CData'));
            
            % Get image boundaries
            xLimit = [0.5 x_extent+0.5];
            yLimit = [0.5 y_extent+0.5];
            
            if ~this.ContextMenuDeleteFlag
                delIcon = userData.delIcon;
                set(delIcon,'pos',...
                    [newPosition(1)+newPosition(3) newPosition(2)]);
                
            % check if upper left border is outside axes
            if newPosition(1) < min(xLimit) || ...
                    newPosition(1) > max(xLimit)|| ...
                    newPosition(2) < min(yLimit)|| ...
                    newPosition(2) > max(yLimit)
                set(delIcon,'Visible','off');
            else
                set(delIcon,'Visible','on');
            end
            end
            
            labelPos = [newPosition(1), ...
                newPosition(2)+newPosition(4)+category.Extent(4)*0];
            set(category, 'pos', labelPos);
            notify(this, 'Move');
       end
        
        %----------------------------------------------------------
        function delIcon = createDeleteIcon(this)
            
            roiPosition = this.BBox;
            delIcon = text('parent',this.AxesHandle,...
                'pos',[roiPosition(1)+roiPosition(3) roiPosition(2)],...
                'string','\fontsize{4} \bf\fontsize{6}X\rm\fontsize{4} ',...
                'tag','delIcon',...
                'edgecolor','w',...
                'color','w',...
                'backgroundcolor',[0.7 0 0],...
                'horizontalalignment','center',...
                'buttondownfcn',@this.doDeleteROI,...
                'Clipping','on');
            
            
            % Anonymous function for setting mouse pointer to arrow while
            % hovering over delete button.
            
            enterFcn = @(figHandle, currentPoint)...
                set(figHandle, 'Pointer', 'arrow');
            
            iptSetPointerBehavior(delIcon, enterFcn);
            iptPointerManager(this.FigHandle);
        end
        
        %----------------------------------------------------------
        function category = createCategoryLabel(this, catColor, catName, ...
                showLabel)
            roiPosition = this.BBox;
            category = text('parent', this.AxesHandle, ...
                'backgroundcolor', catColor, 'string', catName, ...
                'tag', 'category', 'Interpreter', 'none',...
                'Clipping','on');
            labelPos = [roiPosition(1), ...
                roiPosition(2)+roiPosition(4)];
            category.Position = labelPos;
            
            if showLabel
                category.Visible = 'on';
            else
                category.Visible = 'off';
            end
        end
        
        %----------------------------------------------------------
        function doDeleteROI(this, ~, ~)
            userData = get(this.Roi, 'UserData');
            selectionState = vision.internal.cascadeTrainer.tool.WasSelectedEventData(this.IsSelected);
            delete(userData.delIcon)
            delete(userData.category)
            delete(this.Roi);
            notify(this, 'Delete', selectionState);
        end
        
        %----------------------------------------------------------
        function setupContextMenu(this, roiPatch, textLabel)
            
             % Set patch & text label context menu
            patchRightClick = uicontextmenu('Parent', this.FigHandle);
            set(roiPatch, 'UIContextMenu', patchRightClick);
            set(textLabel, 'UIContextMenu', patchRightClick);
            
            % Copy
            uimenu(patchRightClick,'Label','Copy', ...
                'Callback', @(~,~)notify(this, 'Copy'), ...
                'Accelerator', 'C');
            
            % Cut
            uimenu(patchRightClick,'Label','Cut', ...
                'Callback', @(~,~)notify(this, 'Cut'), ...
                'Accelerator', 'X');        
            
            % Delete
            uimenu(patchRightClick,'Label','Delete', ...
                'Callback', @this.doDeleteROI);
            
            l = findobj(this.Roi, 'type', 'line');
            contextMenuHandle = get(l(1), 'UIContextMenu');
            delete(contextMenuHandle);
        end
    end
end

%------------------------------------------------------------------
% Change patch and bounding box colors to indicate selection
function selectROI(roi, roiPatch)
% Change patch color to yellow
set(roiPatch, 'FaceColor', 'y');
set(roi, 'Selected','on');
end
%------------------------------------------------------------------

% Change patch and bounding box colors to indicate de-selection
function unSelectROI(roi, roiPatch)
% Change patch color to none
set(roiPatch, 'FaceColor', 'none');
set(roi, 'Selected','off');
end

