% This class handles the display of the set of Instructions.
classdef InstructionsSetDisplay < vision.internal.uitools.AppFigure
    
    properties(Constant)
        % Define heights of panels in char. char is used to scale across
        % different types of monitors (e.g. High DPI).
        AddLabelButtonHeight = 0.8 * 3;
    end
    
    properties
        InstructionsSetPanel
        
        % The width depends on height and system settings and is
        % initialized during construction.
        AddHelpTextWidth 
    end
    
    %======================================================================
    methods
        
        %------------------------------------------------------------------
        function this = InstructionsSetDisplay()
            %The name of the Instructions tab is set initially here. It
            %will be updated later based on the selected Algorithm Name
            %e.g. Pointtracker
            nameDisplayedInTab = vision.getMessage(...
                'vision:labeler:InstructionsName');
            this = this@vision.internal.uitools.AppFigure(nameDisplayedInTab);
            
            this.Fig.Resize = 'on'; 
                        
            initializeTextWidth(this);
                        
            helpSetPanelPos = uicontrolPositions(this);
            
            % Add scrollable panel. Set it's position using normalized
            % units so it expands to fit as app figure size is changed.
            this.InstructionsSetPanel = vision.internal.labeler.tool.InstructionsSetPanel(this.Fig, helpSetPanelPos);
            
            this.Fig.SizeChangedFcn = @(varargin)this.doPanelPositionUpdate;  
        end
    end
    
     methods
        %------------------------------------------------------------------
        % Returns the uicontrol positions relative to the figure position.
        % This is used to keep all the panels and controls in the correct
        % spot as the figure is resized.
        %------------------------------------------------------------------
        function helpSetPanel = uicontrolPositions(this)
            figPos = hgconvertunits(this.Fig, this.Fig.Position, this.Fig.Units, 'char', this.Fig);
           
            % scrollable panel units are normalized. This is just for
            % simplicity, and can be changed in the future.
            h = max(0, figPos(4));
            helpSetPanel = hgconvertunits(this.Fig, [0 0 figPos(3) h], 'char', 'normalized', this.Fig);                                                   
        end 
        
         %------------------------------------------------------------------
        % Initialize the text width based on the height, which is in
        % char. Equal values of char height and char width do not result in
        % a square, so button width is computed in pixels then converted to
        % char so we get a square button.
        %------------------------------------------------------------------
        function initializeTextWidth(this)
            
            % Figure out the width in char given the height in char. This
            % is all to get a square button in char units.
            pos = hgconvertunits(...
                this.Fig, [0 0 0 this.AddLabelButtonHeight], 'char', 'pixels', this.Fig);                        
            pos = hgconvertunits(this.Fig, [0 0 pos(4) pos(4)], 'pixels', 'char', this.Fig);            
            
            this.AddHelpTextWidth = pos(3);
        end
        
        %------------------------------------------------------------------
        function appendItem(this, data)
            this.InstructionsSetPanel.appendItem(data);
        end
        
        %------------------------------------------------------------------
        function deleteItem(this, data)
            this.InstructionsSetPanel.deleteItem(data);
        end
        
        %------------------------------------------------------------------
        function deleteAllItems(this)
            this.InstructionsSetPanel.deleteAllItems();
        end
        
     end
     
     
    %======================================================================
    % Callbacks
    %======================================================================
    methods
        function doPanelPositionUpdate(this)
            pos = uicontrolPositions(this);
            this.InstructionsSetPanel.Position  = pos;  
        end
    end     
end
