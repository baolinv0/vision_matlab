classdef ROILabelerClipBoard < handle
    properties
        %CopiedROIs
        CopiedROIs
    end
   
    %----------------------------------------------------------------------
    % Copy/Cut/Paste
    %----------------------------------------------------------------------
    methods
        
        function add(this,rois)
            
            purge(this);
            
            for i = numel(rois):-1:1
                this.CopiedROIs{end+1} = rois{i};
            end
           
        end
        
        %------------------------------------------------------------------
        function purge(this)
             this.CopiedROIs = {};
        end
        
        %------------------------------------------------------------------
        function rois = contents(this)
            rois = this.CopiedROIs;
        end
        
        %------------------------------------------------------------------
        function TF = isempty(this)
            TF = isempty(this.CopiedROIs);
        end
        
    end
end