% This class defines a dialog that shows instructions about the training
% images.
classdef TrainingImageBinarizationDlg < vision.internal.uitools.OkDlg
    
    properties
        ShowDialogAgain
    end
    
    methods
        function this = TrainingImageBinarizationDlg(groupName)
            dlgTitle = vision.getMessage('vision:ocrTrainer:BinarizationResultsDlg');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);
            
            this.DlgSize = [450 180];
            this.ShowDialogAgain = vision.internal.ocr.tool.OCRTrainer.showTrainingImagesDialog;
            createDialog(this);
            addMessage(this);
        end
    end
    
    methods(Access = private)
        function addMessage(this)
                                  
            part1 = vision.getMessage('vision:ocrTrainer:BinarizationPart1');                        
            
            part2 = vision.getMessage('vision:ocrTrainer:BinarizationPart2',...
                vision.getMessage('images:desktop:Tool_imageSegmenter_Label'));
            
            w = this.DlgSize(1);
            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', [5 100 w-5 50],...
                'HorizontalAlignment', 'Left',...
                'FontUnits', 'normalized', ...
                'FontSize', 0.25, ...
                'String', part1);                       
            
            [~] = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', [5 65 w-5 50],...
                'HorizontalAlignment', 'Left',...
                'FontUnits', 'normalized', ...
                'FontSize', 0.25, ...
                'String', part2);
            
            checkbox = uicontrol('Parent', this.Dlg, 'Style', 'checkbox',...
                'Position', [5 35 w 20], ...
                'FontUnits', 'normalized', ...
                'FontSize', 0.65, ...
                'String', vision.getMessage('vision:uitools:DoNotShowThisDialogAgain'));
            
            
            this.OkButton.Callback = @doOK;
            
            % get dialog info
            function doOK(varargin)
                this.ShowDialogAgain = ~checkbox.Value;    
                close(this);
            end
        end
    end
end
