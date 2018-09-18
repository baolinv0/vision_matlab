classdef AutoLabelCompleteDlg < vision.internal.uitools.OkDlg
     
    methods
        function this = AutoLabelCompleteDlg(groupName, n, total, badImages)
            dlgTitle = vision.getMessage('vision:ocrTrainer:AutoLabelingDlg');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);
                                                  
            this.DlgSize = [400 250];
            
            createDialog(this);
            addStats(this, n, total, badImages);      
        end
    end
    
    methods(Access = private)
        function addStats(this, n, total, badImages)
            
            msg = vision.getMessage(...
                'vision:ocrTrainer:AutoLabelingStatus', n, total);
            
            w = this.DlgSize(1);
             
            position =  [5 200 w-5 40];
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', position,...
                'FontUnits', 'points', 'FontSize', 10, ...
                'HorizontalAlignment', 'Left',...
                'String', msg);
            
            [~] = uicontrol('Parent', this.Dlg, 'Style', 'listbox', ...
                'Units', 'pixels',...
                'Position', [20 55 350 139], ...
                'String', badImages,...                
                'Tag','ImageList');
        end
    end
end