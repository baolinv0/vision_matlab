% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer training panel which houses the buttons
% to initiate ocr training.

% Copyright 2015 The MathWorks, Inc.

classdef TrainingPanel < vision.internal.uitools.ToolStripPanel
    
    properties
        TrainButton       
    end
    
    %----------------------------------------------------------------------
    methods
        function this = TrainingPanel()
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
                                   
            this.addTrainButton();
                                  
            add(this.Panel, this.TrainButton, 'xy(1,1)');
                                  
        end                        
        
        %------------------------------------------------------------------
        function addTrainButton(this)
            icon =  toolpack.component.Icon.RUN_24;
            name = 'vision:ocrTrainer:TrainButton';
            
            this.TrainButton = this.createButton(icon,...
                name, 'btnTrain', 'vertical');
            
            this.setToolTipText(this.TrainButton, ...
                'vision:ocrTrainer:TrainButtonToolTip');
        end
             
        %------------------------------------------------------------------
        function addTrainButtonCallback(this, callback)
            addlistener(this.TrainButton,'ActionPerformed',...
                callback);
        end
    end
end

