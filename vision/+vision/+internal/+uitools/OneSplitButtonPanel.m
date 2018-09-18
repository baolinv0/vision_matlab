% OneSplitButtonPanel A tool strip panel containing a single split button.
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

classdef OneSplitButtonPanel < vision.internal.uitools.OneButtonPanel
    methods        
        function panel = OneSplitButtonPanel()
            panel = panel@vision.internal.uitools.OneButtonPanel();
        end
        
        %------------------------------------------------------------------
        function createTheButton(this, icon, nameId, tag)
        % createTheButton Create and add the button
        %   createTheButton(obj, icon, nameId, tag) creates the split button
        %   and adds it to the panel. obj is a OneSplitButtonPanel object. 
        %   icon is the button's icon. nameId is the message catalog id of 
        %   the button's caption. tag is a string used to identify the button
        %   for testing.
            this.Button = this.createVerticalSplitButton(icon, nameId, tag);
            addTheButton(this);
        end
        
        %------------------------------------------------------------------
        function createPopup(this, options, popupName, popupFun)
        % createPopup Create the split button popup menu
        %   createPopup(this, options, popupName, popupFun) creates the
        %   split button popop menu. obj is a OnePlitButtonPanel object.
        %   options is an array of structs containing the menu items.
        %   popupName is a string used to identify the popup for testing.
            this.Button.Popup = this.createSplitButtonPopup(options, popupName);
            addlistener(this.Button.Popup, 'ListItemSelected', popupFun);
        end
    end            
end