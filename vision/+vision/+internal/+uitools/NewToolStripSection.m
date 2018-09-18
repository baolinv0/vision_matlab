% NewToolStripSection Encapsulates a tool strip section.
%
%  This is a base class for specific types of tool strip sections. It
%  contains static methods for making different kinds of buttons.
%
%  NewToolStripSection properties:
%
%    Panel - Tool strip panel object. 
%
%  NewToolStripSection static methods:
%   
%    createButton              - Create a push button
%    createToggleButton        - Create a toggle button
%    createSplitButton         - Create a split button
%    createSplitButtonPopUp    - Create button's dropdown popup menu
%    createSlider              - Create a slider
%    createDropDownButton      - Create a drop-down button
%    createRadioButton         - Create a radio button
%    createCheckBox            - Create a check box
%    createLabel               - Create a text label
%    setToolTipText            - Add a tool tip to a given component

% Copyright 2016-2017 The MathWorks, Inc.

classdef NewToolStripSection < handle
    properties
        % Panel A tool strip panel object. You can add this object to a 
        %  toolstrip section.
        Section;
    end
    
    methods
        %------------------------------------------------------------------
        function column = addColumn(this, varargin)
            % addColumn adds a column to this panel and returns it.
            column = this.Section.addColumn(varargin{:});
        end
        
    end
    methods(Static)
        %------------------------------------------------------------------
        function setToolTipText(component, toolTipID)
        % setToolTipText Tool tip text for labels, buttons, and other components
        %  setToolTipText(component, toolTipID) sets a tool tip text for
        %  the given component. component is a tool strip control.
        %  toolTipID is the message catalog id of the tool tip message.
            component.Description = getString( message(toolTipID) );
        end

        %------------------------------------------------------------------
        function button = createButton(icon, titleID, tag)
        % createButton Create a tool strip push button
        %   button = createButton(icon, titleID, tag) returns a tool strip
        %   push button. icon is the button's icon. titleID is the message
        %   catalog id of the button's caption. tag is a string used to
        %   identify the button for testing. 
            button = matlab.ui.internal.toolstrip.Button(...
                vision.getMessage(titleID), icon);
            button.Tag = tag;
        end
            
        %------------------------------------------------------------------
        function splitButton = createSplitButton(icon, titleID, tag)
        % createSplitButton Create a split push button
        %   splitButton = createSplitButton(icon, titleID, tag) returns a
        %   split tool strip button. icon is the button's icon. titleID is
        %   the message catalog id of the button's caption. tag is a string
        %   used to identify the button for testing.
            splitButton = matlab.ui.internal.toolstrip.SplitButton(...
                vision.getMessage(titleID), icon);
            splitButton.Tag = tag;
        end
        
        %------------------------------------------------------------------
        function popup = createSplitButtonPopup(tag)
        % createSplitButtonPopup Create split button's popup menu.
        %  popup = createSplitButtonPopup(tag) returns the popup
        %  menu object. tag is a string used to identify the popup for
        %  testing. popup is an empty object to which PopupList items must
        %  be added.
            popup = matlab.ui.internal.toolstrip.PopupList();
            popup.Tag = tag;
            
        end
        
        %------------------------------------------------------------------
        function button = createDropDownButton(icon, titleID, tag)
        % createDropDownButton Create a drop-down push button
        %   button = createDropDownButton(icon, titleID, tag) returns a
        %   drop-down button. icon is the button's icon. titleID is the
        %   message catalog id of the button's caption. tag is a string
        %   used to identify the button for testing.
            button = matlab.ui.internal.toolstrip.DropDownButton(...
                getString(message(titleID)), icon);
            button.Tag = tag;
            
        end
        
        %------------------------------------------------------------------
        function toggleButton = createToggleButton( icon, titleID, tag, ...
                varargin)
        % toggleButton Create a toggle button.
        %   toggleButton = createToggleButton(icon, titleID, tag) returns a
        %   tool strip toggle button. icon is the button's icon. titleID is
        %   the message catalog id of the button's caption. tag is a string
        %   used to identify the button for testing.
        %
        %   toggleButton = createToggleButton(icon, titleID, tag, group)
        %   returns a toolstrip toggle button associated with the
        %   ButtonGroup group.
            if length(varargin)>=1
                group = varargin{1};
                toggleButton = matlab.ui.internal.toolstrip.ToggleButton(...
                    vision.getMessage(titleID), icon, group);
            else 
                toggleButton = matlab.ui.internal.toolstrip.ToggleButton(...
                    vision.getMessage(titleID), icon);
            end
            toggleButton.Tag = tag;
        end
        
        %------------------------------------------------------------------
        function label = createLabel(messageId)
        % createLabel Create a text label.
        %   label = createLabel(messageId) returns a tool strip label.
        %   messageId is the message catalog id of the text of the label.
            label = matlab.ui.internal.toolstrip.Label(...
                getString( message( messageId) ) );
        end
        
        %------------------------------------------------------------------
        function radioButton = createRadioButton(titleID, tag, toolTipId, ...
                group)
        % createRadioButton Create a tool strip radio button.
        %   radioButton = createRadioButton(titleId, tag, toolTipId)
        %   returns a tool strip radio button. titleId is the message 
        %   catalog id of the button's caption. tag is a string used to 
        %   identify the button for testing. toolTipId is the message 
        %   catalog id of the tool tip message. group is the ButtonGroup
        %   to which this radio button is associated.
            radioButton = matlab.ui.internal.toolstrip.RadioButton(...
                group, getString(message(titleID)));
            radioButton.Tag = tag;
            vision.internal.uitools.NewToolStripSection.setToolTipText(...
                radioButton, toolTipId);
        end
        
        %------------------------------------------------------------------
        function checkBox = createCheckBox(titleId, tag, toolTipId)
        % createCheckBox Create a tool strip check box.
        %   checkBox = createCheckBox(titleId, tag, toolTipId)
        %   returns a tool strip check box. titleId is the message 
        %   catalog id of the button's caption. tag is a string used to 
        %   identify the button for testing. toolTipId is the message 
        %   catalog id of the tool tip message.
            checkBox = matlab.ui.internal.toolstrip.CheckBox(...
                getString(message(titleId)));
            checkBox.Tag = tag;
            vision.internal.uitools.NewToolStripSection.setToolTipText(...
                checkBox, toolTipId);
        end
        
        %------------------------------------------------------------------
        function dropDown = createDropDown(list, tag, toolTipId)
        % createDropDown Create a tool strip drop down.
        %   checkBox = createDropDown(titleId, tag, toolTipId)
        %   returns a tool strip drop down. tag is a string used to 
        %   identify the drop down for testing. toolTipId is the message 
        %   catalog id of the tool tip message.
            assert(iscell(list) && iscolumn(list), 'List should be a column of strings.')
            dropDown = matlab.ui.internal.toolstrip.DropDown(list);
            dropDown.Tag = tag;
            vision.internal.uitools.NewToolStripSection.setToolTipText(...
                dropDown, toolTipId);
        end
        
        %------------------------------------------------------------------
        function slider = createSlider(range, startVal, tag, toolTipId)
        % createSlider Create a tool strip slider
        %   button = createSlider(range, startVal, tag, toolTipId) returns
        %   a tool strip slider. range is the [min max] values for the
        %   slider. startVal is the starting point for the slider,
        %   typically at the midpoint of the range. tag is a string used to
        %   identify the button for testing. toolTipId is the message
        %   catalog id of the tool tip message.
            slider = matlab.ui.internal.toolstrip.Slider(range, startVal);
            slider.Tag = tag;
            vision.internal.uitools.NewToolStripSection.setToolTipText(...
                slider, toolTipId);
        end
    end
    
end