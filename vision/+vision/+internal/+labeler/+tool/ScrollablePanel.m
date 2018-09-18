% This class defines a scrollable panel interface designed to display a
% vertical stack of HG objects.
classdef ScrollablePanel < handle
    
    properties(Abstract)
        % Items an array of list item objects. These will be stacked
        % vertically in the scrollable panel. Use the createItems method to
        % populate the items array.
        Items
        
        % ItemFactory A concrete implementation of the ListItemFactory
        %             class. The factory should produce a list item.
        %
        ItemFactory
    end
    
    methods(Abstract)
        % createItems Implement method to create items to add to list.
        % These should be cached to the Items property. This speeds up
        % rendering of the list.
        createItems(this)
    end
    
    %=======================================================================
    properties(Access = protected)
        % Figure Parent of the scrollable panel
        Figure
        
        % FixedPanel This panel holds the slider and moving panel. Position
        % this panel within the Figure
        FixedPanel
        
        % MovingPanel This panel's position is updated during scrolling.
        MovingPanel
        
        % VerticalSlider The vertical slider
        VerticalSlider
        
        % HorizontalSlider The horizontal slider
        HorizontalSlider
        
        % CornerFiller A small panel to cover corner of the MovingPanel when
        % both horizontal and vertical slider are visible.
        CornerFiller
        
        % Slider width in pixels.
        SliderHeightInPixels = 18;
        SliderWidthInPixels  = 18;
        
        % Flags to remember if panel has a slider or not.
        HasVerticalSlider
        HasHorizontalSlider
    end
    
    properties(Dependent)
        Position
        NumItems
        SliderHeightInChar
        SliderWidthInChar
    end
    
    properties(Constant)
        KeyboardUpDownScrollAmount     = 1;
        KeyboardPageUpDownScrollAmount = 5;
        KeyboardHomeEndScrollAmount    = Inf;
    end
    
    %======================================================================
    methods(Access = public)
        
        %-------------------------------------------------------------------
        % Returns parent object to add items into.
        %-------------------------------------------------------------------
        function p = getParentForItem(this)
            p = this.MovingPanel;
        end
    end
    
    %======================================================================
    methods
        function set.Position(this, value)
            this.FixedPanel.Position = max(0, value);
            this.update();
        end
        
        function value = get.Position(this)
            value = this.FixedPanel.Position;
        end
        
        function val = get.NumItems(this)
            val = numel(this.Items);
        end
        function val = get.SliderHeightInChar(this)
            val = pix2char(this, this.SliderHeightInPixels);
        end
        
        function val = get.SliderWidthInChar(this)
            val = pix2char(this, this.SliderWidthInPixels);
        end
    end
    
    %======================================================================
    methods
        
        function this = ScrollablePanel(parent, position)
            this.Figure = parent;
            
            this.Figure.WindowScrollWheelFcn = @this.mouseScroll;
            this.Figure.WindowKeyPressFcn    = @this.keyboardScroll;
            
            this.FixedPanel = uipanel('Parent', this.Figure,...
                'BorderType','none',...
                'Title','',...
                'Units','Normalized',...
                'Position', position,...
                'Visible', 'off',...
                'Tag','FixedPanel');
            
            this.MovingPanel = uipanel('Parent', this.FixedPanel,...
                'BorderType','none',...
                'Title','',...
                'Units','Normalized',...
                'Position',[0 0 0 0],...
                'Visible', 'off',...
                'Tag','MovingPanel');
            
            this.HasVerticalSlider   = false;
            this.HasHorizontalSlider = false;
        end
        
        %------------------------------------------------------------------
        function show(this)
            set(this.MovingPanel,'Visible','on');
            set(this.FixedPanel,'Visible','on');
        end
        
        %------------------------------------------------------------------
        function c = pix2char(this, val)
            c = hgconvertunits(this.Figure,[val 0 0 0], 'pixels', 'char', this.Figure);
            c = c(1);
        end
        
        %-------------------------------------------------------------------
        function update(this)
            
            if this.NumItems < 1
                return; % nonthing to update
            end
            
            this.MovingPanel.Units = 'char';
            
            parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'char', this.Figure);
            
            sliderWidth  = this.SliderWidthInChar;
            
            movingPanelHeight = zeros(this.NumItems, 1);
            
            % Get all the pixel position of the items.
            pos = this.getItemPixelPositions();
            
            % pre-compute the panel height so that we can determine if a
            % scroll bar is needed.
            for i = this.NumItems:-1:1
                itemPosition = hgconvertunits(this.Figure, pos(i,:), this.Items{i}.Units, this.MovingPanel.Units, this.Figure);
                movingPanelHeight(i) = itemPosition(4);
            end
            
            % cumsum to compute each panels height, reverse order to
            % faciliate looping over these in reverse order.
            movingPanelHeight = cumsum(movingPanelHeight, 'reverse');
            
            needsVerticalScroll = movingPanelHeight(1) > parentPos(4);
            
            if needsVerticalScroll
                % Assume all items share the same units!
                % account for the slider width before computing the parent
                % width.
                parentPosInItemUnits = hgconvertunits(this.Figure, [0 0 parentPos(3) - sliderWidth 0], 'char', this.Items{1}.Units, this.Figure);
                parentWidth = parentPosInItemUnits(3);                
            else
                parentPosInItemUnits = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, this.Items{1}.Units, this.Figure);
                parentWidth = parentPosInItemUnits(3);
            end
            
            layoutTop = 0;
            % Stack graphics objects starting from the bottom.
            for i = this.NumItems:-1:1
                
                % Left justified stacking
                listPos = hgconvertunits(this.Figure, [0 layoutTop 1 1], this.MovingPanel.Units, this.Items{i}.Units, this.Figure);
                
                this.Items{i}.Position(1) = 0;
                this.Items{i}.Position(2) = listPos(2);
                
                % Allow the item to adjust it's width to match the parent.
                adjustWidth( this.Items{i}, parentWidth );
                
                layoutTop = movingPanelHeight(i);
            end
            
            % Reposition panel to be flush to top of parent
            this.MovingPanel.Position(4) = movingPanelHeight(1);
            this.MovingPanel.Position(2) = -(this.MovingPanel.Position(4)-parentPos(4));
            
            pos = this.getItemPixelPositions();
            [~, idx] = max(pos(:,3));
            pos = hgconvertunits(this.Figure, pos(idx,:), 'pixels', this.MovingPanel.Units, this.Figure);
            maxItemWidth = pos(3);
            this.MovingPanel.Position(3) = maxItemWidth;
            
            % The parentWidth input to adjustWidth method is only the
            % visible text width. It must be the full text width. Allow the
            % item to adjust it's height based on parent's width.
            for i = this.NumItems:-1:1
                adjustHeight(this.Items{i}, parentWidth);
            end
            
            % Get all the pixel position of the items.
            pos = this.getItemPixelPositions();
            
            % Recompute the panel height so that we can determine if a
            % scroll bar is needed.
            for i = this.NumItems:-1:1
                itemPosition = hgconvertunits(this.Figure, pos(i,:), this.Items{i}.Units, this.MovingPanel.Units, this.Figure);
                movingPanelHeight(i) = itemPosition(4);
            end
            
            % cumsum to compute each panels height, reverse order to
            % faciliate looping over these in reverse order.
            movingPanelHeight = cumsum(movingPanelHeight, 'reverse');
                    
            layoutTop = 0;
            % Restack graphics objects starting from the bottom based on
            % adjusted height.
            for i = this.NumItems:-1:1
                
                % Left justified stacking
                listPos = hgconvertunits(this.Figure, [0 layoutTop 1 1], this.MovingPanel.Units, this.Items{i}.Units, this.Figure);
                
                this.Items{i}.Position(1) = 0;
                this.Items{i}.Position(2) = listPos(2);
                
                layoutTop = movingPanelHeight(i);
            end
                            
            % Reposition panel to be flush to top of parent
            this.MovingPanel.Position(4) = movingPanelHeight(1);
            this.MovingPanel.Position(2) = -(this.MovingPanel.Position(4)-parentPos(4));
                   
            needsVerticalScroll = movingPanelHeight(1) > parentPos(4);
            
            % Sometimes the Moving Panel windth is lightly larger than the
            % parent + slider width, in the order of 1e-15. This is
            % not visible. Hence giving it a buffer width of 1e-10
            if needsVerticalScroll
                needsHorizontalScroll = this.MovingPanel.Position(3) > parentPos(3) - sliderWidth + 1e-10;
            else
                needsHorizontalScroll = this.MovingPanel.Position(3) > parentPos(3) + 1e-10;
            end
            
            addScrollBarsIfNeeded(this, needsVerticalScroll, needsHorizontalScroll);
            
            % make sure MovingPanel has correct width
            this.MovingPanel.Position(3) = maxItemWidth;
            % Alwas set the moving Panel x position to 0 so that it is
            % aligned correctly in the parent figure when an update is
            % called.
            this.MovingPanel.Position(1) = 0; 
            cellfun(@(x)set(x.Panel, 'Visible','on'), this.Items);
        end
        
        %------------------------------------------------------------------
        % Scroll to this.Items(idx)
        %------------------------------------------------------------------
        function scrollTo(this, idx)
            if idx == 1
                scrollToTop(this);
                
            elseif idx == this.NumItems
                scrollToBottom(this);
                
            else
                itemStepInSlider = (this.VerticalSlider.Max - this.VerticalSlider.Min)/this.NumItems;
                
                amount = (this.NumItems - idx) * itemStepInSlider;
                
                if this.HasHorizontalSlider
                    amount = amount + this.HorizontalSlider.Position(4);
                end
                
                this.VerticalSlider.Value = amount;
                
            end
            drawnow;
        end
        
        %------------------------------------------------------------------
        function horizontalScroll(this, varargin)
            curPos = this.MovingPanel.Position;
            curPos(1) = -this.HorizontalSlider.Value;
            % The following code limits the panel to be moved all the way 
            % till the slider moves just showing a blank area.
            parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'char', this.Figure);
            if abs(curPos(1)) < this.MovingPanel.Position(3) - parentPos(3)
                this.MovingPanel.Position = curPos;
            end
        end
        
        %------------------------------------------------------------------
        function verticalScroll(this, varargin)
            curPos = this.MovingPanel.Position;
            curPos(2) = -this.VerticalSlider.Value;
            this.MovingPanel.Position = curPos;
        end
        
        %------------------------------------------------------------------
        function mouseScroll(this, ~, event)
            if ~isempty(this.VerticalSlider) && isvalid(this.VerticalSlider)
                amount = this.VerticalSlider.Value - event.VerticalScrollCount;
                amount = max(amount, this.VerticalSlider.Min);
                amount = min(amount, this.VerticalSlider.Max);
                this.VerticalSlider.Value = amount;
                this.verticalScroll();
            end
        end
        
        %------------------------------------------------------------------
        function scrollToTop(this)
            if this.HasVerticalSlider
                this.VerticalSlider.Value = this.VerticalSlider.Max;
            end
        end
        
        %------------------------------------------------------------------
        function scrollToBottom(this)
            if this.HasVerticalSlider
                this.VerticalSlider.Value = this.VerticalSlider.Min;
                drawnow;
            end
        end
        
        %------------------------------------------------------------------
        % Return true if this.Item(idx) is in the viewable area defined by
        % by the extent of this.FixedPanel.
        %------------------------------------------------------------------
        function tf = isItemVisible(this, idx)
            itemPos  = getpixelposition(this.Items{idx}, true);
            panelPos = getpixelposition(this.FixedPanel, true);
            
            itemTop = itemPos(2) + itemPos(4) - 1;
            itemBot = itemPos(2);
            
            panelTop = panelPos(2) + panelPos(4) - 1;
            panelBot = panelPos(2);
            
            if this.HasHorizontalSlider
                % account for horizontal slider height. item needs to be
                % above this to be visible.
                panelBot = panelBot + this.SliderHeightInPixels;
            end
            
            if itemBot < panelBot || itemTop > panelTop
                tf = false;
            else
                tf = true;
            end
        end
        
        %------------------------------------------------------------------
        function keyboardScroll(this, ~, event)
            if ~isempty(this.VerticalSlider) && isvalid(this.VerticalSlider)
                
                % Set the scroll amount to be proportional to the height of
                % the items.
                itemHeight = this.MovingPanel.Position(4)/this.NumItems;
                
                switch event.Key
                    case 'downarrow'
                        scrollAmount =  this.KeyboardUpDownScrollAmount * itemHeight;
                    case 'uparrow'
                        scrollAmount = -this.KeyboardUpDownScrollAmount * itemHeight;
                    case 'pageup'
                        scrollAmount = -this.KeyboardPageUpDownScrollAmount * itemHeight;
                    case 'pagedown'
                        scrollAmount =  this.KeyboardPageUpDownScrollAmount * itemHeight;
                    case 'home'
                        scrollAmount = -this.KeyboardHomeEndScrollAmount;
                    case 'end'
                        scrollAmount =  this.KeyboardHomeEndScrollAmount;
                    otherwise
                        % No action
                        return;
                end
                amount = this.VerticalSlider.Value - scrollAmount;
                amount = max(amount, this.VerticalSlider.Min);
                amount = min(amount, this.VerticalSlider.Max);
                this.VerticalSlider.Value = amount;
                this.verticalScroll();
            end
        end
        
        %------------------------------------------------------------------
        function addScrollBarsIfNeeded(this, needsVerticalScroll, needsHorizontalScroll)
            
            if this.HasVerticalSlider && this.HasHorizontalSlider
                delete(this.CornerFiller);
            end
            
            if needsHorizontalScroll && needsVerticalScroll
                % add small panel to cover corner area of
                parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'pixels', this.Figure);
                pos = [];
                pos(1) = parentPos(3) - this.SliderWidthInPixels + 1;
                pos(2) = 0;
                pos(3) = this.SliderWidthInPixels;
                pos(4) = this.SliderHeightInPixels;
                hgconvertunits(this.Figure, pos, 'char', 'pixels', this.Figure);
                this.CornerFiller = uipanel('Parent', this.FixedPanel, ...
                    'Units', 'pixels', ...
                    'Position', pos, ...
                    'BackgroundColor', [0.94 0.94 0.94],...
                    'Tag','CornerFillerPanel'); % match color slider color
            end
            
            if needsHorizontalScroll
                
                % Compute position of slider and create a new one if
                % needed. Otherwise re-use existing one, but just update
                % it's position.
                parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'pixels', this.Figure);
                
                sliderPos = parentPos;
                
                if needsVerticalScroll
                    sliderPos(3) = parentPos(3) - this.SliderWidthInPixels;
                end
                
                sliderPos(2) = 0;
                sliderPos(4) = this.SliderHeightInPixels;
                sliderStep = [.1 1];
                
                parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.Figure.Units, this.MovingPanel.Units, this.Figure);

                if needsVerticalScroll
                    numExtraCharLines  = this.MovingPanel.Position(3) - (parentPos(3) - this.SliderWidthInChar);
                else
                    numExtraCharLines  = this.MovingPanel.Position(3)-parentPos(3);
                end
                
                if this.HasHorizontalSlider
                    % Preserve position of slider while resizing
                    this.HorizontalSlider.Units = 'pixels';
                    this.HorizontalSlider.Position = max(0, sliderPos);
                    this.HorizontalSlider.Units    = 'char';
                    this.HorizontalSlider.Value    = min(numExtraCharLines, this.HorizontalSlider.Value);
                    this.HorizontalSlider.Max      = numExtraCharLines;
                else
                    this.HorizontalSlider = uicontrol('Style', 'Slider', ...
                        'Parent', this.FixedPanel, ...
                        'Units', 'pixels', ...
                        'Min', 0, ...
                        'Value', 0, ...
                        'Callback', @this.horizontalScroll, ...
                        'Position', sliderPos, ...
                        'SliderStep', sliderStep);
                    
                    this.HasHorizontalSlider = true;
                    
                    this.HorizontalSlider.Units = 'char';
                    
                    this.HorizontalSlider.Max = numExtraCharLines;
                end
                
                this.horizontalScroll();
            else
                if this.HasHorizontalSlider
                    delete(this.HorizontalSlider);
                    this.HasHorizontalSlider = false;
                end
            end
            
            if needsVerticalScroll
                % Compute position of slider and create a new one if
                % needed. Otherwise re-use existing one, but just update
                % it's position.
                parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'pixels', this.Figure);
                
                sliderPos = parentPos;
                
                sliderPos(1) = sliderPos(3)-this.SliderWidthInPixels + 1;
                
                if needsHorizontalScroll
                    sliderPos(2) = this.SliderHeightInPixels;
                    sliderPos(4) = max(0, sliderPos(4) - this.SliderHeightInPixels);
                else
                    sliderPos(2) = 0;
                end
                
                sliderPos(3) = this.SliderWidthInPixels;
                
                sliderStep = [.1 1];
                parentPos = hgconvertunits(this.Figure, this.FixedPanel.Position, this.FixedPanel.Units, 'char', this.Figure);
                numExtraCharLines  = (this.MovingPanel.Position(4)-parentPos(4));
                if this.HasHorizontalSlider
                    minValue = -this.HorizontalSlider.Position(4);
                else
                    minValue = 0;
                end
                
                if this.HasVerticalSlider
                    % Preserve position of slider while resizing
                    this.VerticalSlider.Units    = 'pixels';
                    this.VerticalSlider.Position = sliderPos;
                    this.VerticalSlider.Units    = 'char';
                    
                    if this.VerticalSlider.Value == this.VerticalSlider.Max
                        % force value to remain at max after resizing.
                        % Otherwise it may "drift away" will look odd.
                        this.VerticalSlider.Value = numExtraCharLines;
                    else
                        this.VerticalSlider.Value = min(numExtraCharLines, this.VerticalSlider.Value);
                    end
                    
                    this.VerticalSlider.Min   = minValue;
                    this.VerticalSlider.Max   = numExtraCharLines;
                else
                    this.VerticalSlider = uicontrol('Style', 'Slider', ...
                        'Parent', this.FixedPanel, ...
                        'Units', 'pixels', ...
                        'Min', minValue, ...
                        'Callback', @this.verticalScroll,...
                        'Position', sliderPos,...
                        'SliderStep', sliderStep);
                    
                    this.VerticalSlider.Units = 'char';
                    this.VerticalSlider.Max   = numExtraCharLines;
                    this.VerticalSlider.Value = numExtraCharLines;
                    
                    this.HasVerticalSlider = true;
                end
                this.verticalScroll();
            else
                if this.HasVerticalSlider
                    delete(this.VerticalSlider);
                    this.HasVerticalSlider = false;
                end
            end
        end
        
        %------------------------------------------------------------------
        function pos = getItemPixelPositions(this)
            tmp = [this.Items{:}];
            panels = [tmp(:).Panel];
            pos = getpixelposition(panels);
            if iscell(pos)
                pos = vertcat(pos{:});
            end
        end
    end
end
