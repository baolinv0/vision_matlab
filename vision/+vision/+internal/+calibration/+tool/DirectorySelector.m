% DirectorySelector A compound UI control for selecting a folder

% Copyright 2014 The MathWorks, Inc.

classdef DirectorySelector < handle
    properties          
        Parent;
        TextBox;
        BrowseButton;
        IsModifiedUsingBrowse = false;
    end
    
    properties(Dependent)
        SelectedDir;
    end
    
    methods
        function this = DirectorySelector(label, position, parent, initialDir)
            % add label
            uicontrol('Parent', parent,'Style','text', ...
                'HorizontalAlignment', 'left',...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Position', position, 'String', label);
            
            % add text box
            textBoxPos = position;
            textBoxPos(1) = textBoxPos(1);
            textBoxPos(2) = textBoxPos(2) - 30;
            textBoxPos(3) = textBoxPos(3);
            this.TextBox = uicontrol('Parent', parent, 'Style', 'edit', ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Position', textBoxPos, 'String', initialDir, ...
                'HorizontalAlignment', 'left');
            
            % add "Browse" button
            buttonPos = [textBoxPos(1) + textBoxPos(3) + 20, ...
                textBoxPos(2), 70, 20];
            this.BrowseButton = uicontrol('Parent', parent, ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Callback', @this.doBrowse,...
                'Position', buttonPos, 'String', 'Browse...');
        end
        
        %--------------------------------------------------------------
        function doBrowse(this, varargin)
            selectedDir = uigetdir(get(this.TextBox, 'String'));
            if selectedDir ~= 0
                set(this.TextBox, 'String', selectedDir);
                this.IsModifiedUsingBrowse = true;
            end
        end

        
        %------------------------------------------------------------------
        function selectedDir = get.SelectedDir(this)
            selectedDir = get(this.TextBox, 'String');
        end
    end
end
        