% OkCancelDlg Dialog with an OK and Cancel buttons

% Copyright 2014 The MathWorks, Inc.

classdef OkCancelDlg < vision.internal.uitools.AbstractDlg
    properties
       OkButton;
       CancelButton;
       IsCanceled = true;
    end
    
    properties(Access=private)
        ButtonSize = [60, 20];
        ButtonHalfSpace = 10;
    end
    
    methods
        function this = OkCancelDlg(groupName, dlgTitle)
            this = this@vision.internal.uitools.AbstractDlg(...
                groupName, dlgTitle);
        end
       
        %------------------------------------------------------------------
        function createDialog(this)
            createDialog@vision.internal.uitools.AbstractDlg(this);
            addOK(this);
            addCancel(this);
        end
    end
    
    methods(Abstract, Access=protected)
        onOK(this, ~, ~);
    end
    
    methods(Access=protected)
       %------------------------------------------------------------------
        function addOK(this)
            x = this.DlgSize(1) / 2 - this.ButtonSize(1) - this.ButtonHalfSpace;
            this.OkButton = uicontrol('Parent', this.Dlg, 'Callback', @this.onOK,...              
                'Position', [x, 10, this.ButtonSize], ...
                'FontUnits', 'normalized', 'FontSize', 0.6,'String',...
                getString(message('MATLAB:uistring:popupdialogs:OK')));
        end
        
        %------------------------------------------------------------------
        function addCancel(this)
            x = this.DlgSize(1) / 2 + this.ButtonHalfSpace;
            this.CancelButton = uicontrol('Parent', this.Dlg, ...
                'Callback', @this.onCancel,...
                'Position',[x, 10, this.ButtonSize], ...
                'FontUnits', 'normalized', 'FontSize', 0.6, 'String',...
                getString(message('MATLAB:uistring:popupdialogs:Cancel')));
        end                
        
        %------------------------------------------------------------------
        function onCancel(this, ~, ~)            
            close(this);
        end
                
        %------------------------------------------------------------------
        function onKeyPress(this, ~, evd)
            switch(evd.Key)
                case {'return','space'}
                    onOK(this);
                case {'escape'}
                    onCancel(this);
            end
        end

    end
end
