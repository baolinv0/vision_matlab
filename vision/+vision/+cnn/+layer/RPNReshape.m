classdef RPNReshape < nnet.cnn.layer.Layer & nnet.internal.cnn.layer.Externalizable
    properties
        Name
    end
    
    methods
        function this = RPNReshape(privateLayer)
            this.PrivateLayer = privateLayer;
        end
        
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function this = set.Name(this, val)
            iAssertValidLayerName(val);
            this.PrivateLayer.Name = char(val);
        end
    end
    
    methods(Access = protected)
        function [description, type] = getOneLineDisplay(layer)
            
            description = 'Reshape for RPN';
            
            type = 'Reshape';
        end
    end
end

function iAssertValidLayerName(name)
    nnet.internal.cnn.layer.paramvalidation.validateLayerName(name);
end