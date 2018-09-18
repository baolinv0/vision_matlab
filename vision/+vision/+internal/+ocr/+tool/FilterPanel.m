% This class is for internal use only and may change in the future.

% Copyright 2015 The MathWorks, Inc.

classdef FilterPanel < vision.internal.uitools.ToolStripPanel
    
    properties       
        AreaThreshold         
        MinAspectRatio        
        MaxAspectRatio
        AreaThresholdListener         
        MinAspectRatioListener    
        MaxAspectRatioListener 
    end
    
    %----------------------------------------------------------------------
    methods
        function this = FilterPanel()
            this.createPanel();
            this.layoutPanel();
        end
        
        %------------------------------------------------------------------        
        function createPanel(this)
                        
            % create panel with 2 columns and 1 rows.     
            col = 'f:p, 2dlu, f:p:g, 100px';
            row = 'f:p, 2dlu, f:p, 2dlu, f:p';
            this.Panel = toolpack.component.TSPanel(col,row);                            
            
        end
        
        %------------------------------------------------------------------
        function layoutPanel(this)
                                               
            areaThresholdLabel = toolpack.component.TSLabel(...
                vision.getMessage('vision:ocrTrainer:MinArea'));
            this.AreaThreshold = toolpack.component.TSSpinner(0, inf, 50);
            add(this.Panel, areaThresholdLabel, 'xy(1,1)');
            add(this.Panel, this.AreaThreshold, 'xywh(3,1,2,1)');
            
            minLabel = toolpack.component.TSLabel(...
                vision.getMessage('vision:ocrTrainer:MinAspectRatio'));
            maxLabel = toolpack.component.TSLabel(...
                vision.getMessage('vision:ocrTrainer:MaxAspectRatio'));
            
            this.MinAspectRatio = toolpack.component.TSSpinner(0, inf, 1/16);
            this.MaxAspectRatio = toolpack.component.TSSpinner(0, inf, 4);
            
            this.AreaThreshold.Name  = 'regionFiltMinArea';
            this.MinAspectRatio.Name = 'regionFiltMinAspect';
            this.MaxAspectRatio.Name = 'regionFiltMaxAspect';
            
            add(this.Panel, minLabel, 'xy(1,3)');
            add(this.Panel, this.MinAspectRatio, 'xywh(3,3,2,1)');
            add(this.Panel, maxLabel, 'xy(1,5)');
            add(this.Panel, this.MaxAspectRatio, 'xywh(3,5,2,1)');
            
            % set tool tips
            this.setToolTipText(this.MinAspectRatio, ...
                'vision:ocrTrainer:MinAspectTooltip');
            
            this.setToolTipText(this.MaxAspectRatio, ...
                'vision:ocrTrainer:MaxAspectTooltip');
            
            this.setToolTipText(this.AreaThreshold, ...
                'vision:ocrTrainer:MinAreaTooltip');
                           
            this.setToolTipText(areaThresholdLabel, ...
                'vision:ocrTrainer:MinAreaLabelTooltip');
            
            this.setToolTipText(minLabel, ...
                'vision:ocrTrainer:MinAspectLabelTooltip');
            
            this.setToolTipText(maxLabel, ...
                'vision:ocrTrainer:MaxAspectLabelTooltip');

        end                            
        
        %------------------------------------------------------------------
        function addListener(this, callback)
            this.AreaThresholdListener = ...
                addlistener(this.AreaThreshold,'StateChanged',...
                callback);
            
            this.MinAspectRatioListener = ...
                addlistener(this.MinAspectRatio,'StateChanged',...
                callback);
            
            this.MaxAspectRatioListener = ...
                addlistener(this.MaxAspectRatio,'StateChanged',...
                callback);          
        end  
        
        %------------------------------------------------------------------
        function disableListener(this)
             this.AreaThresholdListener.Enabled  = false;
             this.MinAspectRatioListener.Enabled = false;
             this.MaxAspectRatioListener.Enabled = false;                        
        end
        
        %------------------------------------------------------------------
        function enableListener(this)
             this.AreaThresholdListener.Enabled  = true;
             this.MinAspectRatioListener.Enabled = true;
             this.MaxAspectRatioListener.Enabled = true;          
        end
    end
end

