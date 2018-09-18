% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer export panel which houses the buttons
% to generate example code that uses trained language model.

% Copyright 2015 The MathWorks, Inc.

classdef ExportPanel < vision.internal.uitools.ToolStripPanel
    
    properties
        EvaluateButton       
    end
    
    %----------------------------------------------------------------------
    methods
        function this = ExportPanel()
            this.createPanel();
            this.layoutPanel();
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 1 columns and 1 rows.     
            col = 'f:p'; 
            row = 'f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this)
                                   
            this.addExportButton();
                                  
            add(this.Panel, this.EvaluateButton, 'xy(1,1)');
                                  
        end                        
        
        %------------------------------------------------------------------
        function addExportButton(this)
            icon =  toolpack.component.Icon(...
                fullfile(matlabroot,'toolbox','images','icons',...
                'GenerateMATLABScript_Icon_24px.png'));
            
            name = 'vision:ocrTrainer:EvaluateButton';
                      
            this.EvaluateButton = this.createButton(icon, ...
                name, 'btnEvaluate', 'vertical');
                       
            this.setToolTipText(this.EvaluateButton, ...
                'vision:ocrTrainer:EvaluateButtonToolTip');
        end
            
        %------------------------------------------------------------------
        function addExportButtonCallback(this, callback)
            addlistener(this.EvaluateButton,'ActionPerformed',...
                callback);
        end
    end
end

