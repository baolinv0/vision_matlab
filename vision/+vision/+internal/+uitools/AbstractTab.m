% ABSTRACTTAB  Ancestor of all tabs available in Camera Calibrator
%
%    This class is simply a part of the tool-strip infrastructure.

% Copyright 2011 The MathWorks, Inc.

classdef AbstractTab < handle
    
    properties(Access = private)
        Parent
        ToolTab
    end
    
    %----------------------------------------------------------------------
    methods
        % Constructor
        function this = AbstractTab(tool,tabname,title)
            this.Parent = tool;
            
            % tab name is combination of tool name (which is unique for
            % each app instance) and the user specified name. A unique tab
            % name is required for each tab added to a tool group.
            tabname = [tool.getGroupName() '_' tabname];
            
            this.ToolTab = toolpack.desktop.ToolTab(tabname,title);
        end
        
        %------------------------------------------------------------------
        function tooltab = getToolTab(this)
            tooltab = this.ToolTab;
        end     
        
        %------------------------------------------------------------------
        function name = getName(this)
            name = this.ToolTab.Name;
        end
                 
    end
    
    %----------------------------------------------------------------------
    % Abstract methods that each subclass should implement
    methods (Abstract = true)
        testers = getTesters(this) % Get the testers for the tab
    end
    
    %----------------------------------------------------------------------
    methods (Access = protected)
        % getParent
        function parent = getParent(this)
            parent = this.Parent;
        end
    end
    
    methods(Static)
        %--------------------------------------------------------------------------
        function section = createSection(nameId, tag)
            section = toolpack.desktop.ToolSection(tag, getString(message(nameId)));
        end
        
        %--------------------------------------------------------------------------
        % Sets tool tip text for labels, buttons, and other components
        %--------------------------------------------------------------------------
        function setToolTipText(component, toolTipID)
            component.Peer.setToolTipText(...
                vision.getMessage(toolTipID));
        end
            
        %--------------------------------------------------------------------------
        function toggleButton = createToggleButton( icon, titleID, name, orientation)
            toggleButton = toolpack.component.TSToggleButton(...
                vision.getMessage(titleID), icon);
            toggleButton.Name = name;
            switch orientation
                case 'horizontal'
                    toggleButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
                case 'vertical'
                    toggleButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            end
        end
    end
    
end
