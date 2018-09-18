% SquareSizeDlg Dialog for getting the square size

% Copyright 2014 The MathWorks, Inc.

classdef SquareSizeDlg < vision.internal.uitools.OkCancelDlg
    
    properties
        SquareSize;
        Units;
        
        SizeSelector;
    end
    
    methods
        %------------------------------------------------------------------
        function this = SquareSizeDlg(groupName, initSquareSize, initUnits)
            dlgTitle = vision.getMessage('vision:caltool:BoardDimsTitle');
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);            
            this.DlgSize = [420, 90];
            createDialog(this);

            location = [10, 48];
            this.SizeSelector = ...
                vision.internal.calibration.tool.SquareSizeSelector(...
                   this.Dlg, location, initSquareSize, initUnits);
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            % Get all the settings off the dialog
            [this.SquareSize, this.Units] = getSizeAndUnits(this.SizeSelector);
            
            if this.SquareSize <= 0 || isnan(this.SquareSize)
                errordlg(getString(message('vision:caltool:invalidSquareSize')));
            else
                this.IsCanceled = false;
                close(this);
            end
        end
    end
end
