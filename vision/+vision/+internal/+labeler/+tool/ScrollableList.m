% This class implements a scrollable list using a scrollable panel. It uses
% a ListItemFactory to populate items in the list. 
classdef ScrollableList < vision.internal.labeler.tool.ScrollablePanel
   
    properties
        % Items Items displayed in the scrollable list.
        Items
        
        % CurrentSelection The current selection in the list. Only one item
        % can be selected at a time.
        CurrentSelection
        
        % DisabledItems The disabled items in the list.
        DisabledItems
        
        ItemFactory
        
        % MultiSelectSupport Is true if the list should support multiple
        % item selection. By default, this is false. Set this to true in
        % your specific list implementations to buy into multi-select.
        MultiSelectSupport = false;
    end
    
    properties(Constant)
        % Define the number of items to scroll through when using keyboard
        % shortcuts.
        KeyboardUpDownScrollIncrement     = 1;
        KeyboardPageUpDownScrollIncrement = 5;
    end
    
    events
        % ItemSelected Event that is issued when an item is selected.
        ItemSelected;
        
        % ItemModified Event that is issued when an item is modified.
        ItemModified;

        % ItemRemoved Event that is issued when an item is deleted.
        ItemRemoved;
    end
    
    methods
        
        function this = ScrollableList(parent, position, itemFactory)
            
            this = this@vision.internal.labeler.tool.ScrollablePanel(parent, position);

            this.ItemFactory = itemFactory;
                       
            show(this);
            update(this); 
            
            % initialize current selection 
            if this.NumItems > 0
                this.CurrentSelection = 1;
            else
                this.CurrentSelection = 0;
            end
            
            this.DisabledItems = 0;
        end
        
        %------------------------------------------------------------------
        function appendItem(this, data)
            
            idx = this.NumItems + 1;
            
            this.Items{end+1} = this.ItemFactory.buildAndConfigure(this, idx, data);
            
            update(this);                                                
        end
        
        %------------------------------------------------------------------
        function modifyItem(this, idx, data)
            modify( this.Items{idx}, data );
        end
        
        %------------------------------------------------------------------
        function deleteItem(this, data)
            
            idx = data.Index;
            
            this.Items{idx}.Panel.Visible = 'off';
            delete(this.Items{idx});
            this.Items(idx) = [];
            
            % Reset index of each item
            for i = 1:this.NumItems
                this.Items{i}.Index = i;
            end
                        
            update(this);

            this.CurrentSelection = 0;
            if this.NumItems > 0
                idx = min(idx, this.NumItems);
                selectItem(this, idx);
            end

        end
        
        %------------------------------------------------------------------
        function unselectToBeDisabledItems(this, toBeDisabledItemsIdx)
            
            validItemIdx = setdiff(1 : this.NumItems, toBeDisabledItemsIdx);
            
            validSelectedItemIdx = intersect(this.CurrentSelection, validItemIdx);
            hasValidSelection = ~isempty(validSelectedItemIdx);
            
            % step-1: Make sure atleast one item is selected
            if ~hasValidSelection && ~isempty(validItemIdx)
                
                % select the first valid item in the list
                this.selectItem(validItemIdx(1));
                
                this.CurrentSelection = validItemIdx(1);
            end
               
            % step-2: now safely unselct all invalid items
            invalidSelectedItemIdx = intersect(this.CurrentSelection, toBeDisabledItemsIdx);
            
            for i = 1 : numel(invalidSelectedItemIdx)
                
                itemIdx = invalidSelectedItemIdx(i);
                
                unselect( this.Items{itemIdx} );
                
                % Remove this item from 'current selection' list
                this.CurrentSelection(this.CurrentSelection==itemIdx)=[];          
            end
        end
            
        %------------------------------------------------------------------
        function disableItem(this, idx)
            
            disable( this.Items{idx} );
            
            if ~isequal(this.DisabledItems,0)
                this.DisabledItems = [this.DisabledItems idx];
            else
                this.DisabledItems = idx;
            end
            
            update(this);

        end
        
        %------------------------------------------------------------------
        function disableAllItems(this)
            
            if this.NumItems > 0
                for n = 1 : this.NumItems
                    disableItem(this, n);
                end
            end
        end
        
        %------------------------------------------------------------------
        function enableItem(this, idx)
            
            enable( this.Items{idx} );
            
            if ~isequal(this.DisabledItems,0)
                this.DisabledItems = this.DisabledItems(this.DisabledItems~=idx);
            end
            
            update(this);
        end
        
        %------------------------------------------------------------------
        function enableAllItems(this)
            
            if this.NumItems > 0
                for n = 1 : this.NumItems
                    enableItem(this, n);
                end
            end
        end
        
        %------------------------------------------------------------------
        function deleteAllItems(this)
            
            if this.NumItems > 0
                for n = this.NumItems : -1 : 1
                    data.Index = n;
                    deleteItem(this, data);
                end
            end
        end
        
        %------------------------------------------------------------------
        function freezeAllItems(this)
            if this.NumItems > 0
                for n = 1 : this.NumItems
                    freeze(this.Items{n});
                end
            end
        end
        
        %------------------------------------------------------------------
        function unfreezeAllItems(this)
            if this.NumItems > 0
                for n = 1 : this.NumItems
                    unfreeze(this.Items{n});
                end
                
                % At least one item should be selected. If no current
                % selection exists, select the first item.
                if isempty(this.CurrentSelection) || any(this.CurrentSelection==0)
                    this.CurrentSelection = 1;
                    select( this.Items{1} );
                    
                    eventData = vision.internal.labeler.tool.ItemSelectedEvent(1);
                    notify(this, 'ItemSelected', eventData);
                end
            end
        end
        
        %------------------------------------------------------------------
        function createItems(this, data)
            numItems = numel(data);
            this.Items = cell(numItems, 1);
            for i = 1:numItems
                this.Items{i} = this.ItemFactory.buildAndConfigure(this, i, data(i));                                
            end
            
            if this.NumItems > 0
                % Select first item
                this.CurrentSelection = 1;
                select( this.Items{1} );
            end
        end
        
        %------------------------------------------------------------------
        function selectNextItem(this)
            
            enabledItems = setdiff( 1:this.NumItems, this.DisabledItems );
            
            % If there's only 1 enabled item, no need to scroll.
            if numel(enabledItems) < 2
                return;
            end
            
            currentIdx = find(enabledItems == this.CurrentSelection, 1);
            nextIdx = currentIdx+1;
            
            % If the next item is after the last item, loop back to the
            % first item.
            if nextIdx>numel(enabledItems)
                nextIdx = 1;
            end
            
            selectItem(this, enabledItems(nextIdx));
        end
        
        %------------------------------------------------------------------
        function selectPrevItem(this)
            
            enabledItems = setdiff( 1:this.NumItems, this.DisabledItems );
            
            % If there's only 1 enabled item, no need to scroll.
            if numel(enabledItems) < 2
                return;
            end
            
            currentIdx = find(enabledItems == this.CurrentSelection, 1);
            prevIdx = currentIdx-1;
            
            % If the previous item is before the first item, loop back to
            % the last item.
            if prevIdx<1
                prevIdx = numel(enabledItems);
            end
            
            selectItem(this, enabledItems(prevIdx));
        end
        
        %------------------------------------------------------------------
        function selectAllItems(this)
            if this.NumItems > 0
                for i = 1:this.NumItems
                    select( this.Items{i} );
                end
                
                this.CurrentSelection = 1:this.NumItems;
                
                eventData = vision.internal.labeler.tool.ItemSelectedEvent(this.CurrentSelection);
                
                notify(this, 'ItemSelected', eventData);
            end
        end
        
        %------------------------------------------------------------------
        function selectItem(this, idx)
            
            
            if this.MultiSelectSupport && isCtrlClick(this)
                
                if not(any(this.CurrentSelection == idx))
                    select( this.Items{idx} );
                    
                    % Add selected item to CurrentSelection.
                    boolarray([this.CurrentSelection idx]) = true;
                    this.CurrentSelection = find(boolarray);

                    eventData = vision.internal.labeler.tool.ItemSelectedEvent( this.CurrentSelection );
                    
                    notify(this, 'ItemSelected', eventData);
                end
            else
                
                % Maked item look selected. Let this work when the current
                % selection and idx are the same to handle first time selection
                % cases.
                
                if this.CurrentSelection > 0
                    for i = this.CurrentSelection
                        unselect( this.Items{i} );
                    end
                end
                
                select( this.Items{idx} );
                
                drawnow;
                
                if numel(this.CurrentSelection) > 1 || this.CurrentSelection ~= idx
                    % only notify of a real selection change if the idx is
                    % different than that current selection.
                    this.CurrentSelection = idx;
                    
                    % scroll to item
                    if ~isItemVisible(this, this.CurrentSelection)
                        this.scrollTo(this.CurrentSelection);
                    end
                    
                    eventData = vision.internal.labeler.tool.ItemSelectedEvent(idx);
                    
                    notify(this, 'ItemSelected', eventData);
                end
            end
        end
        
        %------------------------------------------------------------------
        function listItemSelected(this, ~, data)
            selectItem(this, data.Index);
        end   
        
        %------------------------------------------------------------------
        function listItemChecked(this, index)
            checkStatus( this.Items{index} );
        end
        
        %------------------------------------------------------------------
        function listItemUnchecked(this, index)
            UncheckStatus( this.Items{index} );
        end
        
        %------------------------------------------------------------------
        function listItemExpanded(this, ~, data)
            expand( this.Items{data.Index} );
            
            % shrink all others
            for i = 1 : this.NumItems
                if data.Index ~= i
                    shrink( this.Items{i} );
                end
            end
            
            update(this);
        end
        
        %------------------------------------------------------------------
        function listItemShrinked(this, ~, data)
            shrink( this.Items{data.Index} );
            
            update(this);
        end     
        
        %------------------------------------------------------------------
        function listItemModified(this, ~, data)
            notify(this, 'ItemModified', data);
        end
        
        %------------------------------------------------------------------
        function listItemDeleted(this, ~, data)
            notify(this, 'ItemRemoved', data);
        end
        
        %------------------------------------------------------------------
        function keyboardScroll(this, src, event)
                
            if this.NumItems<1
                return;
            end
            
            isCtrlPressed = any(strcmp(event.Modifier,'control'))|| ...
                any(strcmp(event.Modifier, 'command'));
            
            ctrl_a_pressed = this.MultiSelectSupport && ...
                isCtrlPressed && strcmp(event.Key,'a');
            
            if ctrl_a_pressed
                
                selectAllItems(this);
                
            else
            
                switch event.Key
                    case 'downarrow'
                        increment =  this.KeyboardUpDownScrollIncrement;
                    case 'uparrow'
                        increment = -this.KeyboardUpDownScrollIncrement;
                    case 'pageup'
                        increment = -this.KeyboardPageUpDownScrollIncrement;
                    case 'pagedown'
                        increment =  this.KeyboardPageUpDownScrollIncrement;
                    case 'home'
                        increment = -Inf;
                    case 'end'
                        increment =  Inf;
                    otherwise
                        % No action
                        return;
                end
                
                % When multiple items are selected, pushing the up/down keys
                % will unselect the items and increment from the last item in
                % the CurrentSelection array.
                if numel(this.CurrentSelection) > 1
                    for i = this.CurrentSelection
                        unselect( this.Items{i} );
                    end
                    this.CurrentSelection = this.CurrentSelection(end);
                end
                
                % Clamp selection between 1:this.NumItems
                selection = max( 1, ...
                    min( this.CurrentSelection + increment, this.NumItems));
                
                selectItem(this, selection);
                
                % Only scroll if item is not visible.
                if ~isItemVisible(this, selection)
                    keyboardScroll@vision.internal.labeler.tool.ScrollablePanel(this,src,event);
                end
            end
        end
        
        %------------------------------------------------------------------
        function tf = isCtrlClick(this)
            % selection type is 'alt' for both right click and ctrl-left
            % click. check current modifier to check for ctrl press.
            modifier    = get(this.Figure, 'CurrentModifier');
            ctrlPressed = ~isempty(modifier) && strcmpi(modifier, 'control');
            
            tf = ctrlPressed && strcmpi(this.Figure.SelectionType,'alt');
        end
        
    end
    
end