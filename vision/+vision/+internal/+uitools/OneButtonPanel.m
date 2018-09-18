% OneButtonPanel A tool strip panel containing a single push button.
%
%  This class creates a panel with a single button. The button has an
%  ActionPerformed listener that executes a give callback function.
%
%  panel = OneButtonPanel() creates an empty panel.
%
%  panel = OneButtonPanel(icon, nameId, tag, toolTipId, fun) creates a panel
%  with one push button. icon is the button's icon. nameId is the message
%  catalog id of the button caption. tag is a string used to identify the
%  button for testing. toolTipId is the message catalog id of the tool tip
%  message. fun is the handle to the buttons callback function.
%
%  OneButtonPanel properties:
%
%    Panel           - Tool strip panel object
%    IsButtonEnabled - Enable/disable the button
%
%  OneButtonPanel methods:
%
%    createTheButton   - Create and add the button to the panel
%    addButtonCallback - Add a callback function to the button
%    setToolTip        - Set the button tool tip


% Copyright 2014 The MathWorks, Inc.

classdef OneButtonPanel < vision.internal.uitools.ToolStripPanel
    properties(Access=protected)
        Button;
    end
    
    properties(Dependent)
        % IsButtonEnabled Enable/disable the button.
        IsButtonEnabled;
    end
    
    methods
        function this = OneButtonPanel(icon, nameId, tag, toolTipId, fun)
            this.createPanel();
            if nargin > 0
                this.createTheButton(icon, nameId, tag);
                this.setToolTip(toolTipId);
                this.addButtonCallback(fun);
            end
        end
        
        %------------------------------------------------------------------
        function set.IsButtonEnabled(this, isEnabled)
            this.Button.Enabled = isEnabled;
        end
        
        %------------------------------------------------------------------
        function isEnabled = get.IsButtonEnabled(this)
            isEnabled = this.Button.Enabled;
        end        
        
        %------------------------------------------------------------------
        function setToolTip(this, toolTipId)
        % setToolTip Set the button tool tip
        %   setToolTip(obj, toolTipId) sets the button tool tip. obj is a
        %   OneButtonPanel object. toolTipId is the message catalog id of
        %   the tool tip string.
        
            this.setToolTipText(this.Button, toolTipId);
        end
        
        %------------------------------------------------------------------
        function createTheButton(this, icon, nameId, tag)
        % createTheButton Create and add the button
        %   createTheButton(obj, icon, nameId, tag) creates the button and
        %   adds it to the panel. obj is a OneButtonPanel object. icon is
        %   the button's icon. nameId is the message catalog id of the
        %   button's caption. tag is a string used to identify the button
        %   for testing.
            this.Button = this.createButton(icon, nameId, tag, 'vertical');            
            addTheButton(this);
        end
        
        %------------------------------------------------------------------
        function addButtonCallback(this, fun)
        % addButtonCallback Add a callback function to the button
        %   addButtonCallback(obj, fun) adds a callback function to the
        %   button. obj is a OneButtonPanel object. fun is a function
        %   handle.
            addlistener(this.Button, 'ActionPerformed', fun);
        end
        
        %------------------------------------------------------------------
        function enableButton(this)
        % enableButton Enable the button        
            this.Button.Enabled = true;
        end
        
        %------------------------------------------------------------------
        function disableButton(this)
        % disableButton Disable the button
            this.Button.Enabled = false;
        end
        
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function createPanel(this)
            this.Panel = toolpack.component.TSPanel('c:p:g', 'f:p');
        end
        
        %------------------------------------------------------------------
        function addTheButton(this)
            add(this.Panel, this.Button, 'xy(1,1)');
        end
        
    end
end