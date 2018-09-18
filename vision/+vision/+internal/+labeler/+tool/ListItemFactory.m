% This class defines a factory interface to create instances of ListItem
% objects.
classdef ListItemFactory 

    methods(Static, Abstract)
        %------------------------------------------------------------------
        % Return an instance of an item. This static method is called
        % repeatedly to create a list of items.
        %------------------------------------------------------------------
        item = create(varargin)        
    end    
    
    methods(Sealed)
      
        %------------------------------------------------------------------
        % This method builds and configures a list item object. It attaches
        % the item selection method to the list item's selection event.
        %------------------------------------------------------------------
        function item = buildAndConfigure(factory, list, positionInList, data)
            item = factory.create(getParentForItem(list), positionInList, data);
            addlistener(item, 'ListItemSelected', @list.listItemSelected);
            addlistener(item, 'ListItemExpanded', @list.listItemExpanded);
            addlistener(item, 'ListItemShrinked', @list.listItemShrinked);
            addlistener(item, 'ListItemModified', @list.listItemModified);
            addlistener(item, 'ListItemDeleted', @list.listItemDeleted);
        end
        
    end       
end