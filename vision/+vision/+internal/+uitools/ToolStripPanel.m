% ToolStripPanel Encapsulates a tool strip panel.
%
%  This is a base class for specific types of tool strip panels. It contains
%  static methods for making different kinds of buttons.
%
%  ToolStripPanel properties:
%
%    Panel - Tool strip panel object. 
%
%  ToolStripPanel static methods:
%   
%    createButton              - Create a push button
%    createToggleButton        - Create a toggle button
%    createSplitButton         - Create a split button
%    createVerticalSplitButton - Create a vertical split button
%    createSplitButtonPopUp    - Create button's dropdown popup menu
%    createDropDownButton      - Create a drop-down button
%    createRadioButton         - Create a radio button
%    createCheckBox            - Create a check box
%    createLabel               - Create a text label
%    setToolTipText            - Add a tool tip to a given component

% Copyright 2014 The MathWorks, Inc.

classdef ToolStripPanel < handle
    properties
        % Panel A tool strip panel object. You can add this object to a 
        %  toolstrip section.
        Panel;
    end
    
    methods(Static)
        %------------------------------------------------------------------
        function setToolTipText(component, toolTipID)
        % setToolTipText Tool tip text for labels, buttons, and other components
        %  setToolTipText(component, toolTipID) sets a tool tip text for
        %  the given component. component is a tool strip control.
        %  toolTipID is the message catalog id of the tool tip message.            
            component.Peer.setToolTipText(getString(message(toolTipID)));
        end

        %------------------------------------------------------------------
        function button = createButton(icon, titleID, tag, orientation)
        % createButton Create a tool strip push button
        %   button = createButton(icon, titleID, tag, orientation) returns 
        %   a tool strip push button. icon is the button's icon. titleID is
        %   the message catalog id of the button's caption. tag is a string
        %   used to identify the button for testing. orientation is a string
        %   with the values 'vertical' or 'horizontal'.
            button = toolpack.component.TSButton(...
                vision.getMessage(titleID), icon);
            button.Name = tag;
            button.Orientation = getOrientation(orientation);
        end
        
        %------------------------------------------------------------------
        function splitButton = createVerticalSplitButton(icon, titleID, tag)
        % createVerticalSplitButton Create a vertically split push button
        %   splitButton = createVerticalSplitButton(icon, titleID, tag)
        %   returns a vertically split tool strip button. icon is the
        %   button's icon. titleID is the message catalog id of the
        %   button's caption. tag is a string used to identify the button
        %   for testing.
            splitButton = ...
                vision.internal.uitools.ToolStripPanel.createSplitButton(...
                icon, titleID, tag, 'vertical');
        end
            
        %------------------------------------------------------------------
        function splitButton = createSplitButton( icon, titleID, tag, ...
                orientation)
        % createSplitButton Create a split push button
        %   splitButton = createSplitButton( icon, titleID, tag, orientation)
        %   returns a split tool strip button. icon is the
        %   button's icon. titleID is the message catalog id of the
        %   button's caption. tag is a string used to identify the button
        %   for testing. orientation is a string with values 'vertical' or
        %   'horizontal', that determines wether the button is split
        %   vertically or horizontally.
            splitButton = toolpack.component.TSSplitButton(...
                vision.getMessage(titleID), icon);
            splitButton.Name = tag;
            splitButton.Orientation = getOrientation(orientation);
        end
        
        %------------------------------------------------------------------
        function popup = createSplitButtonPopup(options, tag)
        % createSplitButtonPopup Create split button's popup menu.
        %  popup = createSplitButtonPopup(options, tag) returns the popup
        %  menu object. options contains the popup options. tag is a string 
        %  used to identify the popup for testing.            
            style = 'icon_text';
            popup = toolpack.component.TSDropDownPopup(...
                options, style);
            popup.Name = tag;
        end
        
        %------------------------------------------------------------------
        function button = createDropDownButton(icon, titleID, tag,...
                orientation)
        % createDropDownButton Create a drop-down push button
        %   button = createDropDownButton(icon, titleID, tag, orientation)
        %   returns a drop-down button. icon is the
        %   button's icon. titleID is the message catalog id of the
        %   button's caption. tag is a string used to identify the button
        %   for testing. orientation is a string with values 'vertical' or
        %   'horizontal', that determines wether the button is split
        %   vertically or horizontally.
            button = toolpack.component.TSDropDownButton(...
                getString(message(titleID)), icon);
            button.Name = tag;
            button.Orientation = getOrientation(orientation);
        end
        
        %------------------------------------------------------------------
        function toggleButton = createToggleButton( icon, titleID, tag, ...
                orientation)
        % toggleButton Create a toggle button.
        %   toggleButton = createToggleButton( icon, titleID, tag, orientation)
        %   returns a tool strip toggle button. icon is the
        %   button's icon. titleID is the message catalog id of the
        %   button's caption. tag is a string used to identify the button
        %   for testing. orientation is a string with values 'vertical' or
        %   'horizontal'.            
            toggleButton = toolpack.component.TSToggleButton(...
                vision.getMessage(titleID), icon);
            toggleButton.Name = tag;
            toggleButton.Orientation = getOrientation(orientation);
        end
        
        %------------------------------------------------------------------
        function label = createLabel(messageId)
        % createLabel Create a text label.
        %   label = createLabel(messageId) returns a tool strip label.
        %   messageId is the message catalog id of the text of the label.
            label = toolpack.component.TSLabel(getString(message(messageId)));
        end
        
        %------------------------------------------------------------------
        function radioButton = createRadioButton(titleId, tag, toolTipId)
        % createRadioButton Create a tool strip radio button.
        %   radioButton = createRadioButton(titleId, tag, toolTipId)
        %   returns a tool strip radio button. titleId is the message 
        %   catalog id of the button's caption. tag is a string used to 
        %   identify the button for testing. toolTipId is the message 
        %   catalog id of the tool tip message. 
            radioButton = toolpack.component.TSRadioButton(...
                getString(message(titleId)));
            radioButton.Name = tag;
            vision.internal.uitools.ToolStripPanel.setToolTipText(...
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
            checkBox = toolpack.component.TSCheckBox(...
                getString(message(titleId)));
            checkBox.Name = tag;
            vision.internal.uitools.ToolStripPanel.setToolTipText(...
                checkBox, toolTipId);
        end
    end
    
end

%--------------------------------------------------------------------------
% returns orientation object corresponding to orientationString
%--------------------------------------------------------------------------
function tsOrientation = getOrientation(orientationString)
switch orientationString
    case 'horizontal'
        tsOrientation = toolpack.component.ButtonOrientation.HORIZONTAL;
    case 'vertical'
        tsOrientation = toolpack.component.ButtonOrientation.VERTICAL;
end
end