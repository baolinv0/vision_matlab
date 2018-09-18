% This class defines the interface for a list item. The list item must be
% contained within a panel. 
classdef ListItem < handle
    
    properties(Abstract, Constant)
        % MinWidth The minimum width of the list item in Item Units.
        MinWidth
    end
    
    properties(Abstract)  
        % Panel The list item content must be contained within a uipanel.
        Panel                             
    end
            
    properties(Dependent)
        % Units/Position are the units an position of the Panel.
        Units
        Position
    end
    
    events
        % ListItemSelected This event should be issued whenever the list
        % item should be selected.
        ListItemSelected   
        
        ListItemExpanded;
        ListItemShrinked;
        
        ListItemModified;
        ListItemDeleted;
    end        
    
    methods(Abstract)
        %------------------------------------------------------------------
        % Make an item look selected.
        %------------------------------------------------------------------
        select(~)
        
        %------------------------------------------------------------------
        % Make an item look unselected.
        %------------------------------------------------------------------
        unselect(~)
                
    end 
    
    %----------------------------------------------------------------------
    % Dependent property methods. Gets the units and position of the
    % underlying Panel. This is used to position the list item with a
    % scrollable list.
    %----------------------------------------------------------------------
    methods
        function val = get.Units(this)
            val = this.Panel.Units;
        end
        
        function val = get.Position(this)
            val = this.Panel.Position;
        end
        
        function set.Position(this, val)
            this.Panel.Position = val;
        end
        
        function set.Units(this, val)
            this.Panel.Units = val;
        end
        
        %------------------------------------------------------------------
        % Adjust the item width to match the parent width. Overload this
        % method in concrete implementations if you want to disable this or
        % if you need to adjust other ui element positions within your
        % panel based on the change in width.               
        %------------------------------------------------------------------
        function adjustWidth(this, parentWidth)    
            this.Position(3) = max(this.MinWidth, parentWidth);            
        end
        
        %------------------------------------------------------------------
        % Adjust the item height to match the parent height. Overload this
        % method in concrete implementations if you want to disable this or
        % if you need to adjust other ui element positions within your
        % panel based on the change in height. For text boxes, the height
        % is determined based on the width. In that case, pass the width as
        % input and calculate the height in the adjustHeight method's
        % concrete implementation.
        %------------------------------------------------------------------
        function adjustHeight(this, parentHeight)     %#ok<INUSD>
                        
        end
    end
    
    methods(Sealed)
        %------------------------------------------------------------------
        % Get the underlying Panel's pixel position.
        %------------------------------------------------------------------
        function pos = getpixelposition(this, varargin)
            pos = getpixelposition(this.Panel, varargin{:});
        end                          
    end        
end