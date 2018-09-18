% Training complete dialog. 
classdef TrainingCompleteDlg < vision.internal.uitools.OkDlg
   
    properties(Access = private)        
        OutputDir
    end
    
    methods
        function this = TrainingCompleteDlg(groupName, lang, outdir)
            dlgTitle = vision.getMessage('vision:ocrTrainer:TrainingCompleteTitle');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);
                                                  
            this.DlgSize = [400 200];
            this.OutputDir = outdir;
            
            createDialog(this);
            addMessage(this, lang);
        end
    end
    
    methods(Access = private)
        function addMessage(this, lang)
            
            msg = vision.getMessage(...
                'vision:ocrTrainer:TrainingCompleteMessage', lang);           
            
            w = this.DlgSize(1);
            
            position =  [5 90 w 80];
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', position,...                
                'HorizontalAlignment', 'Left',...
                'String', msg);
            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', [5 70 390 40], ...
                'HorizontalAlignment', 'left',...
                'String', this.OutputDir);
            
            [~] = uicontrol('Parent',this.Dlg,'Style','pushbutton',...
                 'Position', [5 57 140 20], ...
                 'FontUnits','normalized',...
                 'FontSize', .5,...                 
                 'String', vision.getMessage('vision:ocrTrainer:TrainingCompleteCopyBtn'),...
                 'Callback',@(varargin)clipboard('copy',this.OutputDir));
            
        end
    end
end