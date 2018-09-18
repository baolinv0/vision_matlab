% NEWABSTRACTTAB  Ancestor of all tabs 
%
%    This class is simply a part of the tool-strip infrastructure.

% Copyright 2016 The MathWorks, Inc.

classdef NewAbstractTab < handle
    
    properties(Access = private)
        Parent
        TabGroup
        Tab
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor. Use in derived class to instantiate base portion of
        % object.
        %------------------------------------------------------------------
        function this = NewAbstractTab(tool,tabname)
            this.Parent = tool;
            this.TabGroup = tool.getTabGroup();
            
            % tab name is combination of tool name (which is unique for
            % each app instance) and the user specified name. A unique tab
            % name is required for each tab added to a tool group.
            tag = [tool.getGroupName() '_' tabname];
            
            this.Tab = this.TabGroup.addTab(tabname);
            this.Tab.Tag = tag;
        end
        
        %------------------------------------------------------------------
        % Show the tab if hidden.
        %------------------------------------------------------------------
        function show(this)
            this.TabGroup.add(this.Tab);
        end
        
        %------------------------------------------------------------------
        % Hide the tab if visible.
        %------------------------------------------------------------------
        function hide(this)
            this.TabGroup.remove(this.Tab);
        end
        
        %------------------------------------------------------------------
        % Returns the matlab.ui.internal.toolstrip.Tab object encapsulated
        % by this tab.
        %------------------------------------------------------------------
        function tooltab = getTab(this)
            
            tooltab = this.Tab;
        end     
        
        %------------------------------------------------------------------
        % Returns the name of the tab.
        %------------------------------------------------------------------
        function name = getName(this)
            
            name = this.Tab.Title;
        end
        
        %------------------------------------------------------------------
        % Set the name of the tab.
        %------------------------------------------------------------------
        function setName(this, name)
            
            this.Tab.Title = name;
        end
        
        %------------------------------------------------------------------
        % Creates and adds a section to the current tab.
        %------------------------------------------------------------------
        function section = addSectionToTab(this, section)
            
            this.Tab.add(section.Section);
        end
    end
    
    %----------------------------------------------------------------------
    % Abstract methods that each subclass should implement
    %----------------------------------------------------------------------
    methods (Abstract = true)
        testers = getTesters(this) % Get the testers for the tab
    end
    
    %----------------------------------------------------------------------
    methods (Access = protected)
        %------------------------------------------------------------------
        % Returns the parent matlab.ui.internal.desktop.ToolGroup object.
        %------------------------------------------------------------------
        function parent = getParent(this)
            parent = this.Parent;
        end
    end
    
    methods(Static)
        %------------------------------------------------------------------
        % Sets tool tip text for labels, buttons, and other components
        %------------------------------------------------------------------
        function setToolTipText(component, toolTipID)
            component.Description = vision.getMessage(toolTipID);
        end
            
        %------------------------------------------------------------------
        % Creates and returns a toggle button
        %------------------------------------------------------------------
        function toggleButton = createToggleButton( icon, titleID, name, varargin)
            
            if ~isempty(varargin)
                group = varargin{1};
                toggleButton = matlab.ui.internal.toolstrip.ToggleButton( vision.getMessage(titleID), icon, group );
            else
                toggleButton = matlab.ui.internal.toolstrip.ToggleButton( vision.getMessage(titleID), icon );
            end
            
            toggleButton.Tag = name;
        end
    end
    
end
