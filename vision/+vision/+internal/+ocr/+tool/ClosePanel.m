% This class is for internal use only and may change in the future.

% This class defines the OCRTrainer training panel which houses the buttons
% to initiate ocr training.

% Copyright 2015 The MathWorks, Inc.

classdef ClosePanel < vision.internal.uitools.ToolStripPanel
    
    properties
        ApplyButton       
        CancelButton
    end
    
    %----------------------------------------------------------------------
    methods
        function this = ClosePanel(acceptName, acceptTag, cancelName, cancelTag)
            this.createPanel();
            this.layoutPanel(acceptName, acceptTag, cancelName, cancelTag);
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 2 columns and 1 rows.     
            col = 'f:p, 2dlu, f:p';
            row = 'f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this, acceptName, acceptTag, cancelName, cancelTag)
                                   
            this.addApplyButton(acceptName, acceptTag);
            this.addCancelButton(cancelName, cancelTag);             
                        
            add(this.Panel, this.ApplyButton, 'xy(1,1)');
            add(this.Panel, this.CancelButton, 'xy(3,1)');                      
        end                        
        
        %------------------------------------------------------------------
        function addApplyButton(this, name, tag)            
                                  
            icon = toolpack.component.Icon.CONFIRM_24;
            
            this.ApplyButton = this.createButton(icon,...
                name, tag , 'vertical');
            
            
        end
            
        %------------------------------------------------------------------
        function setApplyButtonToolTip(this, id)
            this.setToolTipText(this.ApplyButton, id);
        end
        
        %------------------------------------------------------------------
        function addApplyButtonCallback(this, callback)
            addlistener(this.ApplyButton,'ActionPerformed',...
                callback);
        end
        
        %------------------------------------------------------------------
        function addCancelButton(this, name, tag)            
                                  
            icon = toolpack.component.Icon.CLOSE_24;
            
            this.CancelButton = this.createButton(icon,...
                name, tag, 'vertical');
       
        end
            
        %------------------------------------------------------------------
        function setCancelButtonToolTip(this, id)
            this.setToolTipText(this.CancelButton, id);
        end
        
        %------------------------------------------------------------------
        function addCancelButtonCallback(this, callback)
            addlistener(this.CancelButton,'ActionPerformed',...
                callback);
        end        
        
    end
end

