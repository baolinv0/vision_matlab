% Training complete but show list of images that were not used for
% training.
classdef TrainingCompleteWithErrorsDlg < vision.internal.uitools.OkDlg
   
    properties(Access = private)        
        OutputDir        
    end
    
    methods
        function this = TrainingCompleteWithErrorsDlg(groupName, lang, outdir, status)
            dlgTitle = vision.getMessage('vision:ocrTrainer:TrainingCompleteTitle');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);                                         
            
            this.DlgSize = [400 450];
            this.OutputDir = outdir;
            
            createDialog(this);
            addContent(this, lang, status);                                                
        end
    end
    
    methods(Access = private)
        function addContent(this, lang, status)
         
            msg = vision.getMessage(...
                'vision:ocrTrainer:TrainingCompleteMessage', lang);           
            
            w = this.DlgSize(1);
            
            position =  [5 360 w 80];
            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', position,...                
                'HorizontalAlignment', 'Left',...
                'String', msg);
            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', [5 320 390 50], ...
                'HorizontalAlignment', 'left',...
                'String', this.OutputDir);
                            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', [5 120 w 139] ,...
                'HorizontalAlignment', 'Left',...
                'String', vision.getMessage(...
                'vision:ocrTrainer:TrainingImageErrors'));
             
            [~] = uicontrol('Parent',this.Dlg,'Style','pushbutton',...
                 'Position', [5 300 140 20], ...
                 'FontUnits','normalized',...
                 'FontSize', .5,...                 
                 'String', vision.getMessage('vision:ocrTrainer:TrainingCompleteCopyBtn'),...
                 'Callback',@(varargin)clipboard('copy',this.OutputDir));
            
            [~] = uicontrol('Parent', this.Dlg, 'Style', 'listbox', ...
                'Units', 'pixels',...
                'Position', [20 55 350 139], ...
                'String', status.failedImages,...                
                'Tag','ImageList');
            
        end        
    end
end