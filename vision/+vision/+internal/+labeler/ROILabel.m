% This class encapsulates an ROI Label. Create instances of this class when
% you want to pass around ROI Label data.
classdef ROILabel
    properties
        % ROI Description of the shape (rectangle, line, etc.)
        ROI labelType
        
        % Label The text attached to the ROI (e.g. car, person)
        Label
        
        % Description The user provided description of this ROI Label
        Description
        
        % Attributes
        Attributes
        
        % Color
        Color
        
        % Numerical ID for Pixel Labelling
        PixelLabelID
    end
    
    methods
        %-------------------------------------------------------------------
        function this = ROILabel(roi, label, description, attributes, labelID)
            this.ROI = roi;
            this.Label = label;
            this.Description = description;
            
            if nargin>3
                this.Attributes = attributes;
            end
            
            if nargin>4
                this.PixelLabelID = labelID;
            end
        end
    end
end