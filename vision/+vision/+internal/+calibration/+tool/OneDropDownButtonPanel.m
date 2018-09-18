% OneDropDownButtonPanel A tool strip panel containing a single split button.
%
%   This class creates a panel with a single split button. 
%
%   panel = OneSplitButtonPanel() creates an empty panel.
%
%   OneSplitButtonPanel properties:
%
%    Panel           - Tool strip panel object. 
%    IsButtonEnabled - Enable/disable the button.
%
%  OneSplitButtonPanel methods:
%
%    createTheButton   - Create and add the split button to the panel
%    addButtonCallback - Add a callback function to the button
%    setToolTip        - Set the button tool tip
%    createPopup       - Create the split button popup menu

classdef OneDropDownButtonPanel < vision.internal.uitools.OneButtonPanel
    methods        
        function panel = OneDropDownButtonPanel()
            panel = panel@vision.internal.uitools.OneButtonPanel();
        end
        
        %------------------------------------------------------------------
        function createTheButton(this, icon, nameId, tag, orientation)
        % createTheButton Create and add the button
        %   createTheButton(obj, icon, nameId, tag) creates the split button
        %   and adds it to the panel. obj is a OneSplitButtonPanel object. 
        %   icon is the button's icon. nameId is the message catalog id of 
        %   the button's caption. tag is a string used to identify the button
        %   for testing.
            this.Button = this.createDropDownButton(icon, nameId, tag, orientation);
            addTheButton(this);
        end
                
        %------------------------------------------------------------------
        function addPopup(this, popup)
            this.Button.Popup = popup;
        end        
    end            
end