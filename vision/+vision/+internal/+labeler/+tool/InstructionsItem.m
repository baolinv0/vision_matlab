% Each item contains one instruction step pertaining to the Algorithm
classdef InstructionsItem < vision.internal.labeler.tool.ListItem
    properties(Constant)
        MinWidth = 240;
        MinHeight = 2;
        SelectedBGColor = [0.75 0.75 0.75];
        UnselectedBGColor = [0.94 0.94 0.94];
    end
    properties
        Panel
        Index
        InstructionsText
    end
    methods
        function this = InstructionsItem(parent, idx, data)
            this.Index = idx;
            textWidth = length(data);
            panelPos = [0 0 textWidth 2];
            this.Panel = uipanel('Parent', parent, ...
                'Units', 'characters',...
                'Position', panelPos,...
                'BackgroundColor', this.UnselectedBGColor, ...
                'BorderType', 'none');
            
            textPos = [1 0 textWidth 1];
            this.InstructionsText = uicontrol('Style', 'text', ...
                'Parent', this.Panel,...
                'String', data,...
                'Units','characters',...
                'Position', textPos, ...
                'BackgroundColor', this.UnselectedBGColor, ...
                'HorizontalAlignment', 'left');
            
            % Alternate colors of instructions
            if ~mod(this.Index,2)
                set(this.Panel, 'BackgroundColor', this.SelectedBGColor);
                set(this.InstructionsText, 'BackgroundColor', this.SelectedBGColor)
            end
            
            this.Panel.Units = 'pixels';
            this.InstructionsText.Units = 'pixels';
            
            % The doPanelPositionUpdate call in InstructionsSetDisplay
            % adjusts the width and height of text uicontrol to fit
            % correctly on instantiation.

        end
        
        % select and unselect are abstract methods that must be implemented.
        function select(~)
            
        end
        
        function unselect(~)
            
        end
        
        %------------------------------------------------------------------
        function adjustWidth(this, parentWidth)
            
            this.Panel.Units = 'pixels';
            this.InstructionsText.Units = 'pixels';
            
            this.Panel.Position(3) = max(this.MinWidth, parentWidth);
            this.InstructionsText.Position(3) = this.Panel.Position(3)-4;
        end
        
        %------------------------------------------------------------------
        function adjustHeight(this, parentWidth)
            
            this.Panel.Units = 'pixels';
            this.InstructionsText.Units = 'pixels';
            
            % The parentWidth must not go below the full extent of the text
            % box including the width outside the user view when the
            % horizontal scrollbars are added. The parentWidth input to
            % this method is only the visible text width. It must be the
            % full text width.
            parentWidth = max(parentWidth,240);
            parentObj = ancestor(this.Panel, 'figure');
            parentPositionChars = hgconvertunits(parentObj, [0 0 floor(parentWidth) 0], this.InstructionsText.Units, 'char', parentObj);
            textHeight = max(this.MinHeight, ceil(numel(this.InstructionsText.String)/floor(parentPositionChars(3)))+2);

            textPositionPixels = hgconvertunits(parentObj, [0 0 0 textHeight], 'char', this.InstructionsText.Units, parentObj);
            this.Panel.Position(4) = textPositionPixels(4)+10;
            this.InstructionsText.Position(4) = textPositionPixels(4);

        end        
    end
end
