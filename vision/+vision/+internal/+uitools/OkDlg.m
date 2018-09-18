% OkCancelDlg Dialog with an OK button.  
%
% This dialog can only be used to display information to the user. Pressing 
% the OK button simply closes the dialog. No data from the user is
% captured.

% Copyright 2014 The MathWorks, Inc.

classdef OkDlg < vision.internal.uitools.AbstractDlg
    properties
        OkButton;
        ButtonTag = 'btnBoardOk';
    end
    
    properties(Access=private)
        ButtonSize = [60, 20];
    end
    
    methods
        function this = OkDlg(groupName, dlgTitle, buttonTag)
            this = this@vision.internal.uitools.AbstractDlg(...
                groupName, dlgTitle);
            if nargin > 2
                this.ButtonTag = buttonTag;
            end
        end
       
        %------------------------------------------------------------------
        function createDialog(this)
            createDialog@vision.internal.uitools.AbstractDlg(this);
            addOK(this);
        end
    end 
    
    
    methods(Access=private)
    %------------------------------------------------------------------
        function addOK(this)
            w = round(this.ButtonSize(1) / 2);
            this.OkButton = uicontrol('Parent',this.Dlg, ...
                'Callback', @(~, ~)this.close(),...
                'FontUnits', 'normalized', 'FontSize', 0.6, ...
                'Position',[round(this.DlgSize(1)/2)-w 10 2*w 20], 'String', ...
                getString(message('MATLAB:uistring:popupdialogs:OK')),...
                'Tag', this.ButtonTag);
        end
    end
    
    methods(Access=protected)        
        %------------------------------------------------------------------
        function onKeyPress(this, ~, evd)
            switch(evd.Key)
                case {'return', 'space', 'escape'}
                    close(this);
            end
        end
    end
end
