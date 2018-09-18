% This class is for internal use only and may change in the future.

% MessageDialog creates a message dialog with an OK button.

classdef MessageDialog < vision.internal.uitools.OkDlg
   
    methods
        function this = MessageDialog(groupName, title, msg)
            this  = this@vision.internal.uitools.OkDlg(groupName, title);
            
            this.DlgSize = [400 100];            
            
            createDialog(this);           
            
            addMessage(this,msg)   
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        function addMessage(this, msg)  
            
            w = this.DlgSize(1);
            h = this.DlgSize(2);
            
            position =  [5 h/3 w 40];
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', position,...
                'FontUnits', 'normalized', 'FontSize', 0.3, ...
                'HorizontalAlignment', 'Left',...
                'String', msg);
            
        end
    end
end